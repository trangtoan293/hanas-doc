from __future__ import annotations

import os
from datetime import timedelta
from typing import Optional

import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.models.param import Param
from airflow.operators.empty import EmptyOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)

from raw_vault.taskgroups.dbt_etl_jobs_taskgroup import create_mdm_step_taskgroup
from taskgroups.maileroo_groups import maileroo_notification_group
from utils.callbacks import on_retry_callback, sla_miss_callback


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
}


# MDM steps: (step_id, dbt_select)
MDM_STEPS = [
    ("mdm_source", "mdm.mdm_source_corecif"),
    ("mdm_cleansed", "mdm.mdm_corecif_cleansed"),
    ("mdm_validated", "mdm.mdm_corecif_validate mdm.mdm_corecif_invalid"),
    ("mdm_match", "mdm.mdm_corecif_match"),
    ("mdm_merge", "mdm.mdm_corecif_merge"),
    ("mdm_golden", "mdm.mdm_corecif_golden_records"),
]


with DAG(
    dag_id="demo_mdm_pipeline_e2e_incremental",
    default_args=default_args,
    schedule_interval=None,
    description="MDM incremental pipeline with per-step load/test/publish",
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "spark", "kubernetes", "mdm", "incremental"],
    params={
        "cob_date": Param(default=None, type=["null", "string"]),
        "eod_ref_model": Param(default=None, type=["null", "string"]),
        "notification_email": Param(default=None, type=["null", "string"], description="Recipient email for DAG run notifications. If empty, no email is sent."),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end", trigger_rule="all_done")

    # Build EOD reference view (always full refresh)
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

    # Build MDM steps sequentially, each with load -> test -> publish
    upstream = eod_view_job
    # Get asset tag from Airflow Variable (default: "data platform demo")
    asset_tag_name = _var("DATAHUB_ASSET_TAG_NAME", "data platform demo")
    for step_id, dbt_select in MDM_STEPS:
        step_taskgroup = create_mdm_step_taskgroup(
            group_id=step_id,
            dbt_select=dbt_select,
            full_refresh=False,  # Incremental mode
            dag=dag,
            asset_tag_name=asset_tag_name,
        )
        upstream >> step_taskgroup
        upstream = step_taskgroup

    start >> eod_view_job
    upstream >> end

    # Maileroo notification
    notification = maileroo_notification_group("notification", dag=dag)
    end >> notification

dag.doc_md = """
# DAG `demo_mdm_pipeline_e2e_incremental`

**Purpose**

Run the Master Data Management (MDM) pipeline as an **incremental** load.

**Execution flow**

1. `start`
2. `build_vw_ref_eod` - Build EOD reference view (always full refresh)

Each MDM step is a self-contained TaskGroup with:
- `load_job` → Runs `dbt run` for the step's models (incremental)
- `test_job` → Runs `dbt test` for the step's models  
- `publish_lineage` → Publishes lineage to DataHub (from load artifacts)
- `publish_test_assertions` → Publishes data quality to DataHub (from test artifacts)
- `logging_job` → Logs ETL metrics

**Steps:**
3. `mdm_source` (load → test → publish)
4. `mdm_cleansed` (load → test → publish)
5. `mdm_validated` (load → test → publish)
6. `mdm_match` (load → test → publish)
7. `mdm_merge` (load → test → publish)
8. `mdm_golden` (load → test → publish)
9. `end`
10. `notification`

**Artifacts Structure**

Each step writes to separate folders:
- `.../mdm_etl_job/<step>/run/` - dbt run artifacts (for lineage)
- `.../mdm_etl_job/<step>/test/` - dbt test artifacts (for data quality)

**Email Notifications (Maileroo)**

After completion, the `notification` TaskGroup sends email via Maileroo API.

**Scheduling**

- `schedule_interval = None`
- `catchup = False`
"""
