from __future__ import annotations

import os
from datetime import timedelta

import pendulum
from airflow import DAG
from airflow.models.param import Param
from airflow.operators.empty import EmptyOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)

from raw_vault.taskgroups.dbt_etl_jobs_taskgroup import create_dbt_etl_jobs_taskgroup
from taskgroups.maileroo_groups import maileroo_notification_group
from utils.callbacks import on_retry_callback, sla_miss_callback
from airflow.models import Variable


def _var(name: str, default = None):
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
}


with DAG(
    dag_id="demo_data_pipeline_e2e_init",
    default_args=default_args,
    schedule_interval=None,
    description="Reusable dbt taskgroups (full refresh)",
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "spark", "kubernetes", "raw_vault", "data_mart", "data_init"],
    params={
        "notification_email": Param(default=None, type=["null", "string"], description="Recipient email for DAG run notifications. If empty, no email is sent."),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end", trigger_rule="all_done")

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

    # Get asset tag from Airflow Variable (default: "data platform demo")
    asset_tag_name = _var("DATAHUB_ASSET_TAG_NAME", "data platform demo")

    taskgroup_1 = create_dbt_etl_jobs_taskgroup(
        "raw_vault_etl_job",
        dbt_select="integration.raw_vault",
        full_refresh=True,
        dag=dag,
        load_job_task_id="raw_vault_init_load_job",
        logging_job_task_id="raw_vault_init_logging_job",
        asset_tag_name=asset_tag_name,
    )

    taskgroup_1a = create_dbt_etl_jobs_taskgroup(
        "data_mart_etl_job",
        dbt_select="data_mart --exclude *_backdate",  # Exclude backdate tables
        full_refresh=True,
        dag=dag,
        load_job_task_id="data_mart_init_load_job",
        logging_job_task_id="data_mart_init_logging_job",
        asset_tag_name=asset_tag_name,
    )

    start >> eod_view_job >> taskgroup_1 >> taskgroup_1a >> end

    # Maileroo notification - sends email on success or failure
    # Recipient is read from DAG param `notification_email` at runtime
    notification = maileroo_notification_group("notification", dag=dag)
    end >> notification

dag.doc_md = """
# DAG `demo_data_pipeline_e2e_init`

**Purpose**

Run an end-to-end **initial (full refresh)** data pipeline that:

- Builds the EOD reference table `integration.vw_ref_eod`.
- Loads the raw vault integration layer.
- Builds data mart models.

**Execution flow**

1. `start`

2. `build_vw_ref_eod` (`SparkKubernetesOperator`)
   - Uses `k8s/dbt-runner.yaml` with:
     - `dbt_select = "vw_ref_eod"`.
     - `full_refresh = true`.
   - Builds the Iceberg table `integration.vw_ref_eod` from `source('landing', 'ref_eod')`, with:
     - `cob_date`.
     - `last_cob_date`.
     - `run_time`.
     - `last_run_time`.

3. `raw_vault_etl_job` (`TaskGroup`)
   - Created by `create_dbt_etl_jobs_taskgroup` with `dbt_select = "integration.raw_vault"` and `full_refresh = true`.
   - Within this task group:
     - A nested `load_and_logging` task group runs:
       - `dbt-runner.yaml` to build raw vault integration tables in the `demo.integration` catalog.
       - `dbt-logger.yaml` to log ETL and SQL execution metadata into `LakeHouse.etladmin` tables.
     - A `publish_to_datahub` task group validates the dbt catalog and publishes dbt and Iceberg metadata for these models to DataHub.

4. `data_mart_etl_job` (`TaskGroup`)
   - Created by `create_dbt_etl_jobs_taskgroup` with `dbt_select = "data_mart"` and `full_refresh = true`.
   - Builds data mart models configured under the `data_mart` schema in `dbt_project.yml` (Iceberg tables).
   - Uses the same pattern as `raw_vault_etl_job` to:
     - Run dbt and the LakeHouse logger.
     - Validate the catalog and publish dbt and Iceberg metadata to DataHub.

5. `end` (trigger rule `all_done`)

**Artifacts and metadata**

- For each group, dbt artifacts are written to S3 bucket `DBT_ARTIFACTS_BUCKET` (default `data`) under prefixes:

  - `dbt-artifacts/{{ dag_run.run_id }}/raw_vault_etl_job`  
  - `dbt-artifacts/{{ dag_run.run_id }}/data_mart_etl_job`  

  or the equivalent paths if `DBT_ARTIFACTS_PREFIX` overrides the default.

- DataHub receives:

  - dbt transformation and lineage metadata for raw vault and data mart models.
  - Iceberg table schemas based on the `catalog.json` for each artifacts prefix.

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
