"""
Mart Refactor ETL DAG

This DAG runs mart_refactor dbt models for testing the new configuration-driven framework.
Uploads artifacts to S3 and publishes dbt metadata to DataHub (SQL only, no lineage).

Business Context:
- Runs models from mart_refactor folder only
- Publishes dbt metadata (SQL) to DataHub - no lineage or tests
- Includes SQL print job for debugging
- Supports full-refresh mode

Dependencies:
- Requires Spark operator running on Kubernetes
- Requires dbt project with mart_refactor models
"""

from __future__ import annotations

import os
from datetime import timedelta
from pathlib import Path
from typing import Optional

import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.models.param import Param
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonVirtualenvOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import SparkKubernetesOperator


def _var(name: str, default: Optional[str] = None) -> Optional[str]:
    """Get Airflow variable with fallback to default."""
    try:
        value = Variable.get(name)
        return value if value != "" else default
    except KeyError:
        return default


PROJECT_ROOT = str(Path(__file__).resolve().parents[1])

# Artifacts configuration
ARTIFACTS_SUFFIX = "mart_refactor"


def _publish_dbt_metadata_only(
    bucket: str,
    prefix: str,
    project_root: Optional[str] = None,
    gms_host: Optional[str] = None,
    token: Optional[str] = None,
    aws_endpoint: Optional[str] = None,
    aws_region: Optional[str] = None,
    aws_access_key: Optional[str] = None,
    aws_secret_key: Optional[str] = None,
    aws_session_token: Optional[str] = None,
    env: str = "PROD",
    dbt_platform_instance: str = "demo",
    asset_tag_name: Optional[str] = None,
) -> dict:
    """
    Publish dbt metadata to DataHub - SQL only, no lineage.
    
    This is a simplified version that:
    - Publishes dbt entities (models with SQL)
    - Skips column lineage completely
    - Skips iceberg metadata publishing
    """
    import sys

    if project_root and project_root not in sys.path:
        sys.path.insert(0, project_root)

    from utils.datahub_publisher import publish_dbt_to_datahub

    return publish_dbt_to_datahub(
        gms_host=gms_host,
        token=token,
        bucket=bucket,
        prefix=prefix,
        aws_endpoint_url=aws_endpoint,
        aws_region=aws_region,
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key,
        aws_session_token=aws_session_token,
        env=env,
        iceberg_platform_instance="demo",  # Still needed for sibling relation
        dbt_platform_instance=dbt_platform_instance,
        skip_dbt_entities=False,  # Create dbt entities with SQL
        skip_column_lineage=True,  # Skip lineage completely
        asset_tag_name=asset_tag_name,
    )


# Default arguments for the DAG
default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2024, 1, 1, tz="UTC"),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "catchup": False,
    "tags": ["dbt", "mart_refactor", "spark", "testing"],
}


# Create the DAG
with DAG(
    dag_id="mart_refactor_etl",
    default_args=default_args,
    schedule_interval=None,  # Manual trigger only
    description="Mart Refactor ETL: Run mart_refactor models with DataHub publishing",
    doc_md=__doc__,
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "mart_refactor", "spark", "testing"],
    params={
        "dbt_select": Param(
            default="mart_refactor",
            description="dbt selectors (default: mart_refactor)",
            type="string"
        ),
        "full_refresh": Param(
            default=False, 
            type="boolean", 
            description="Whether to pass --full-refresh"
        ),
        "cob_date": Param(
            default=None,
            type=["null", "string"],
            description="COB date (optional, format: YYYY-MM-DD)"
        ),
        "artifacts_suffix": Param(
            default=ARTIFACTS_SUFFIX,
            type="string",
            description="Suffix for dbt artifacts folder in S3"
        ),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:

    # Start and end markers
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end", trigger_rule="all_done")

    # =========================================================================
    # Load Job - Runs dbt models and uploads artifacts to S3
    # =========================================================================
    load_job = SparkKubernetesOperator(
        task_id="load_job",
        namespace="spark-jobs",
        application_file="dbt-runner.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
    )

    # =========================================================================
    # Publish dbt Metadata - SQL only, no lineage
    # =========================================================================
    # S3 prefix where artifacts are stored by dbt-runner.yaml
    prefix_template = (
        "{% set base_prefix = var.value.get('DBT_ARTIFACTS_PREFIX', None) %}"
        "{% if not base_prefix %}"
        "{% set base_prefix = 'dbt-artifacts/' ~ dag_run.run_id %}"
        "{% endif %}"
        "{{ base_prefix }}/{{ params.artifacts_suffix }}"
    )
    
    publish_dbt = PythonVirtualenvOperator(
        task_id="publish_dbt_metadata",
        python_callable=_publish_dbt_metadata_only,
        op_kwargs={
            "bucket": _var("DBT_ARTIFACTS_BUCKET", "data") or "data",
            "prefix": prefix_template,
            "project_root": PROJECT_ROOT,
            "gms_host": _var("DATAHUB_GMS_HOST", "http://192.168.1.173:8080"),
            "token": _var("DATAHUB_TOKEN", ""),
            "aws_endpoint": _var("AWS_ENDPOINT_URL", "http://192.168.1.151"),
            "aws_region": _var("AWS_DEFAULT_REGION", None),
            "aws_access_key": _var("AWS_ACCESS_KEY_ID", None),
            "aws_secret_key": _var("AWS_SECRET_ACCESS_KEY", None),
            "aws_session_token": _var("AWS_SESSION_TOKEN", None),
            "env": _var("DATAHUB_ENV", "PROD") or "PROD",
            "dbt_platform_instance": _var("DBT_PLATFORM_INSTANCE", "demo") or "demo",
            "asset_tag_name": None,  # No tagging
        },
        requirements=[
            "acryl-datahub[datahub-rest,dbt]",
            "boto3",
            "requests",
        ],
        system_site_packages=False,
        python_version="3.12",
        dag=dag,
    )

    # Flow: start -> print_sql -> load -> publish_dbt -> end
    start >> load_job >> publish_dbt >> end


dag.doc_md = """
# DAG `mart_refactor_etl`

**Purpose**

Run mart_refactor dbt models and publish SQL to DataHub.

**Execution flow**

1. `start` - Marker task
2. `print_sql_job` - Compile and print SQL to logs
3. `load_job` - Run dbt models, upload artifacts to S3
4. `publish_dbt_metadata` - Publish dbt entities with SQL to DataHub
5. `end` - Marker task

**Parameters**

- `dbt_select`: dbt selectors (default: `mart_refactor`)
- `full_refresh`: Pass --full-refresh flag
- `cob_date`: Optional COB date

**DataHub**

Models appear as dbt entities with compiled SQL visible.
No lineage or test results published.
"""


if __name__ == "__main__":
    from airflow.utils.cli import get_dag
    print(f"DAG validation: {get_dag(dag.dag_id)}")
