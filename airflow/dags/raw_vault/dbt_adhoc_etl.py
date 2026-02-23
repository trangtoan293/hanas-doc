"""
dbt Adhoc ETL DAG

This DAG runs ad-hoc dbt models using Spark on Kubernetes.
It uses the same taskgroup structure as demo_data_pipeline_e2e_init.

Business Context:
- Executes dbt models for any selected models
- Processes data using Spark for scalability
- Supports incremental and full-refresh modes
- Includes dbt test job for data quality assertions
- Publishes metadata to DataHub

Dependencies:
- Requires Spark operator running on Kubernetes
- Requires git-sync ConfigMap for dbt project synchronization
- Requires MinIO/S3 access for Iceberg tables
- Requires Hive Metastore for catalog management
- Requires dbt project with models
"""

from __future__ import annotations

import os
from datetime import timedelta
from typing import Optional

import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.models.param import Param
from airflow.operators.empty import EmptyOperator

from raw_vault.taskgroups.dbt_etl_jobs_taskgroup import create_dbt_etl_jobs_taskgroup
from taskgroups.maileroo_groups import maileroo_notification_group
from utils.callbacks import on_retry_callback, sla_miss_callback


def _var(name: str, default: Optional[str] = None) -> Optional[str]:
    """Get Airflow variable with fallback to default."""
    try:
        value = Variable.get(name)
        return value if value != "" else default
    except KeyError:
        return default


# Default arguments for the DAG
default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2024, 1, 1, tz="UTC"),
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "catchup": False,
    "tags": ["dbt", "raw_vault", "spark", "data-vault"],
    "sla": timedelta(hours=2),
    "on_retry_callback": on_retry_callback,
}


# Create the DAG
with DAG(
    dag_id="dbt_adhoc_etl",
    default_args=default_args,
    schedule_interval=None,  # Manual trigger only
    description="dbt adhoc ETL: Run dbt models on Spark with test and publish",
    doc_md=__doc__,
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "raw_vault", "spark", "kubernetes"],
    sla_miss_callback=sla_miss_callback,
    params={
        "dbt_select": Param(description="Space-separated dbt selectors to pass to --select", type="string"),
        "full_refresh": Param(default=False, type="boolean", description="Whether to pass --full-refresh"),
        "notification_email": Param(default=None, type=["null", "string"], description="Recipient email for DAG run notifications. If empty, no email is sent."),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:

    # Start and end markers (matching E2E pipeline naming)
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end", trigger_rule="all_done")

    # Get asset tag from Airflow Variable (default: "data platform demo")
    asset_tag_name = _var("DATAHUB_ASSET_TAG_NAME", "data platform demo")

    # Create ETL TaskGroup using reusable component
    # Structure: load_and_logging (load_job -> test_job -> logging_job) -> publish_datahub
    # Note: dbt_select and full_refresh are passed to SparkKubernetesOperator's params,
    # which are then used in the YAML template via {{ params.dbt_select }} etc.
    adhoc_etl_job = create_dbt_etl_jobs_taskgroup(
        "adhoc_etl_job",
        dbt_select="{{ params.dbt_select }}",  # Will be templated in YAML
        full_refresh=False,  # Default value; YAML uses {{ params.full_refresh }}
        dag=dag,
        load_job_task_id="load_job",
        logging_job_task_id="logging_job",
        asset_tag_name=asset_tag_name,
    )

    # Flow: start -> taskgroup -> end
    start >> adhoc_etl_job >> end

    # Maileroo notification - sends email on success or failure
    notification = maileroo_notification_group("notification", dag=dag)
    end >> notification


dag.doc_md = """
# DAG `dbt_adhoc_etl`

**Purpose**

Run ad-hoc dbt transformations on Spark-on-Kubernetes, then publish metadata to DataHub.

**Execution flow**

1. `start` - Marker task

2. `adhoc_etl_job` (`TaskGroup`)
   - `load_and_logging` sub-taskgroup:
     - `load_job`: Runs dbt models using `dbt-runner.yaml`
     - `test_job`: Runs dbt tests using `dbt-test.yaml`
     - `logging_job`: Logs ETL metadata using `dbt-logger.yaml`
   - `publish_datahub` sub-taskgroup:
     - `extract_dbt_catalog`: Validates/rebuilds catalog.json
     - `publish_dbt_transformation`: Publishes dbt metadata to DataHub
     - `publish_iceberg_metadata`: Publishes Iceberg schemas to DataHub
     - `publish_dbt_tests`: Publishes test assertions to DataHub

3. `end` (trigger rule `all_done`)

4. `notification` - Email notification via Maileroo

**Parameters**

- `dbt_select` (string): Space-separated dbt selectors passed to `--select`
- `full_refresh` (boolean): When true, passes `--full-refresh`
- `notification_email` (string): Recipient email for notifications

**Scheduling**

- `schedule_interval = None`
- `catchup = False`
- `max_active_runs = 1`
"""


if __name__ == "__main__":
    from airflow.utils.cli import get_dag
    print(f"DAG validation: {get_dag(dag.dag_id)}")
