from __future__ import annotations

import os
from datetime import timedelta
from typing import Optional

import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.models.param import Param
from airflow.operators.empty import EmptyOperator

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
    dag_id="demo_mdm_pipeline_e2e_init",
    default_args=default_args,
    schedule_interval=None,
    description="MDM initial (full refresh) pipeline with per-step load/test/publish",
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "spark", "kubernetes", "mdm", "data_init"],
    params={
        "notification_email": Param(default=None, type=["null", "string"], description="Recipient email for DAG run notifications. If empty, no email is sent."),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end", trigger_rule="all_done")

    # Build MDM steps sequentially, each with load -> test -> publish
    upstream = start
    # Get asset tag from Airflow Variable (default: "data platform demo")
    asset_tag_name = _var("DATAHUB_ASSET_TAG_NAME", "data platform demo")
    for step_id, dbt_select in MDM_STEPS:
        step_taskgroup = create_mdm_step_taskgroup(
            group_id=step_id,
            dbt_select=dbt_select,
            full_refresh=True,
            dag=dag,
            asset_tag_name=asset_tag_name,
        )
        upstream >> step_taskgroup
        upstream = step_taskgroup

    upstream >> end

    # Maileroo notification
    notification = maileroo_notification_group("notification", dag=dag)
    end >> notification

dag.doc_md = """
# DAG `demo_mdm_pipeline_e2e_init`

**Purpose**

Run the Master Data Management (MDM) pipeline as an **initial (full refresh)** load.

**Execution flow**

Each MDM step is a self-contained TaskGroup with:
- `load_job` → Runs `dbt run` for the step's models
- `test_job` → Runs `dbt test` for the step's models  
- `publish_lineage` → Publishes lineage to DataHub (from load artifacts)
- `publish_test_assertions` → Publishes data quality to DataHub (from test artifacts)
- `logging_job` → Logs ETL metrics

**Steps:**
1. `start`
2. `mdm_source` (load → test → publish)
3. `mdm_cleansed` (load → test → publish)
4. `mdm_validated` (load → test → publish)
5. `mdm_match` (load → test → publish)
6. `mdm_merge` (load → test → publish)
7. `mdm_golden` (load → test → publish)
8. `end`
9. `notification`

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
