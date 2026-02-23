from __future__ import annotations

import json
import os
from datetime import timedelta
from typing import Dict, List, Optional

import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.models.param import Param
from airflow.operators.empty import EmptyOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)

from raw_vault.taskgroups.dbt_etl_jobs_taskgroup import create_dbt_etl_jobs_taskgroup
from taskgroups.maileroo_groups import maileroo_notification_group
from utils.callbacks import on_failure_callback, on_retry_callback, on_success_callback, sla_miss_callback


def _var(name: str, default: Optional[str] = None) -> Optional[str]:
    try:
        value = Variable.get(name)
        return value if value != "" else default
    except KeyError:
        return default


default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2024, 1, 1, tz="UTC"),
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 3,
    "retry_delay": timedelta(seconds=15),
    "catchup": False,
    "sla": timedelta(hours=2),
    "on_retry_callback": on_retry_callback,
    "on_failure_callback": on_failure_callback,  # Send Slack notification on task failure
}


DEFAULT_GROUPS: List[Dict[str, str]] = [
  {
    "group_id": "raw_vault",
    "dbt_select": "integration.raw_vault"
  },
  {
    "group_id": "data_mart",
    "dbt_select": "data_mart"
  }
]
DATA_PIPELINE_E2E_INCREMENTAL_GROUPS_RAW = _var("DEMO_DATA_PIPELINE_E2E_INCREMENTAL_GROUPS", "")
DATA_PIPELINE_E2E_INCREMENTAL_GROUPS: List[Dict[str, str]] = DEFAULT_GROUPS
if DATA_PIPELINE_E2E_INCREMENTAL_GROUPS_RAW:
    try:
        parsed = json.loads(DATA_PIPELINE_E2E_INCREMENTAL_GROUPS_RAW)
        if isinstance(parsed, list):
            validated: List[Dict[str, str]] = []
            for entry in parsed:
                group_id = entry.get("group_id")
                dbt_select = entry.get("dbt_select")
                if group_id and dbt_select:
                    validated.append({"group_id": group_id, "dbt_select": dbt_select})
            if validated:
                DATA_PIPELINE_E2E_INCREMENTAL_GROUPS = validated
    except json.JSONDecodeError:
        pass


with DAG(
    dag_id="demo_data_pipeline_e2e_incremental",
    default_args=default_args,
    schedule_interval=None,
    description="Reusable dbt taskgroups (incremental)",
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "spark", "kubernetes", "raw_vault", "data_mart", "incremental"],
    params={
        "cob_date": Param(default=None, type=["null", "string"]),
        "eod_ref_model": Param(default=None, type=["null", "string"]),
        "notification_email": Param(default=None, type=["null", "string"], description="Recipient email for DAG run notifications. If empty, no email is sent."),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
    sla_miss_callback=sla_miss_callback,  # Send Slack notification when SLA is breached
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(
        task_id="end",
        trigger_rule="all_done",
        on_success_callback=on_success_callback,  # Send Slack notification when DAG completes successfully
    )

    eod_view_job = SparkKubernetesOperator(
        task_id="build_vw_ref_eod",
        namespace="spark-jobs",
        application_file="dbt-runner.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
        params={
            "dbt_select": "vw_ref_eod",
            "full_refresh": True,
            "artifacts_suffix": "vw_ref_eod",
        },
    )

    start >> eod_view_job

    upstream = eod_view_job
    # Get asset tag from Airflow Variable (default: "data platform demo")
    asset_tag_name = _var("DATAHUB_ASSET_TAG_NAME", "data platform demo")
    for group in DATA_PIPELINE_E2E_INCREMENTAL_GROUPS:
        # For data_mart groups, exclude backdate tables directly in dbt_select
        select = group["dbt_select"]
        if "data_mart" in select:
            select = f"{select} --exclude *_backdate"
        taskgroup = create_dbt_etl_jobs_taskgroup(
            group["group_id"],
            dbt_select=select,
            full_refresh=False,
            dag=dag,
            load_job_task_id="data_incre_load_job",
            asset_tag_name=asset_tag_name,
        )
        upstream >> taskgroup
        upstream = taskgroup

    upstream >> end

    # Maileroo notification - sends email on success or failure
    # Recipient is read from DAG param `notification_email` at runtime
    notification = maileroo_notification_group("notification", dag=dag)
    end >> notification

dag.doc_md = """
# DAG `demo_data_pipeline_e2e_incremental`

**Purpose**

Run an incremental data pipeline on Spark-on-Kubernetes using reusable dbt taskgroups.  
The DAG uses an EOD reference table (`vw_ref_eod`) and an optional `cob_date` to determine the incremental window for dbt models.

**Execution flow**

1. `start`

2. `build_vw_ref_eod` (`SparkKubernetesOperator`)
   - Uses `k8s/dbt-runner.yaml` with:
     - `dbt_select = "vw_ref_eod"`.
     - `full_refresh = true`.
   - Ensures that `integration.vw_ref_eod` is populated with:
     - `cob_date`.
     - `last_cob_date`.
     - `run_time`.
     - `last_run_time`.

3. Incremental groups (`TaskGroup`s)
   - The DAG builds a chain of taskgroups using `create_dbt_etl_jobs_taskgroup` with `full_refresh = false`.
   - The concrete groups and selectors are defined by `DEFAULT_GROUPS` or overridden via the Airflow Variable `DEMO_DATA_PIPELINE_E2E_INCREMENTAL_GROUPS`.
   - For each group:
     - A `load_and_logging` task group runs:
       - `dbt-runner.yaml` for the selected models with incremental settings.  
       - `dbt-logger.yaml` to write ETL and SQL logs for that group into `LakeHouse.etladmin` tables.  
       - Uses `artifacts_suffix = group_id`, which becomes part of the S3 artifacts prefix.
     - A `publish_to_datahub` task group validates the dbt catalog for that prefix and publishes dbt and Iceberg metadata to DataHub.
   - The groups are linked linearly:
     - `start`  `build_vw_ref_eod`  first group  next groups  `end`.

4. `end` (trigger rule `all_done`)

**Configurable grouping**

- Airflow Variable `DEMO_DATA_PIPELINE_E2E_INCREMENTAL_GROUPS` (JSON string) can override `DEFAULT_GROUPS`.
- When set to a JSON list of objects with `group_id` and `dbt_select` keys:
  - Only entries with non-empty `group_id` and `dbt_select` are used.
  - The DAG replaces the default groups with these custom definitions and builds the same kind of chain of taskgroups.

**EOD / incremental window configuration**

- `k8s/dbt-runner-eod-vars.yaml` derives the dbt `--vars` argument from:
  - `dag_run.conf.cob_date` (optional).
  - `dag_run.conf.ref_eod_table` (optional).
  - `dag_run.conf.eod_ref_model` (optional).
  - The DAG param `cob_date` (nullable string).
- Logic in the template:
  - Chooses `ref_eod_table` from:
    - `params.ref_eod_table` (if present), or  
    - `dag_run.conf.eod_ref_model`, or  
    - `dag_run.conf.ref_eod_table`, or  
    - default `vw_ref_eod`.
  - Chooses `cob_date` from:
    - `params.cob_date`, or  
    - `dag_run.conf.cob_date`.
  - When any value is present, builds a `dbt_vars` dict and passes it to `ktl_dbt run` as:
    - `--vars '{{ dbt_vars | tojson }}'`.
- As documented in `dbt_project.yml`:
  - `ref_eod_table` is expected to have columns `cob_date`, `last_cob_date`, `run_time`, `last_run_time`.
  - `cob_date` is used by the raw vault models to compute incremental start and end timestamps.

**DAG parameters**

- `cob_date` (`Param`, default `null`, type `["null", "string"]`).
- `eod_ref_model` (`Param`, default `null`), defined at DAG level; the current EOD template reads `eod_ref_model` from `dag_run.conf`.

**Artifacts and metadata**

- For each group, dbt artifacts are written to S3 bucket `DBT_ARTIFACTS_BUCKET` (default `data`) under:

  - `<DBT_ARTIFACTS_PREFIX or default>/<group_id>`

  for example `dbt-artifacts/{{ dag_run.run_id }}/<group_id>` when using the default prefix.

- The `publish_to_datahub` taskgroups use these prefixes to:
  - Validate `catalog.json`.
  - Publish dbt transformation metadata and Iceberg schemas into DataHub.

**Related test scenario**

- The SQL file `dags/sql/demo_raw_vault_incremental_test.sql` contains a documented scenario that:
  - Inserts synthetic GL and CARD rows into landing tables.  
  - Inserts a synthetic EOD row into `LakeHouse.integration.vw_ref_eod`.  
  - Verifies that incremental loads write the expected LSAT and SAT rows and then cleans up the test data.

**Email Notifications (Maileroo)**

After the DAG completes (success or failure), the `notification` TaskGroup sends an email via Maileroo API.

- **Airflow Variables required:**
  - `MAILEROO_API_KEY`: Maileroo sending key.
  - `SENDER_EMAIL`: Verified sender address.
  - `AIRFLOW_BASE_URL`: Airflow UI URL (default: `http://localhost:8080`).
  - `DEFAULT_NOTIFICATION_EMAIL` (optional): Default recipient.

- **DAG Param:** `notification_email` - Recipient email specified at trigger time. If empty, falls back to `DEFAULT_NOTIFICATION_EMAIL`.

- If no recipient is configured anywhere, no email is sent.

**Scheduling**

- `schedule_interval = None`
- `catchup = False`
"""
