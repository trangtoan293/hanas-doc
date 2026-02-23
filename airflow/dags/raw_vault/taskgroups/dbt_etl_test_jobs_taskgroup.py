from __future__ import annotations

from pathlib import Path
from typing import Optional

from airflow.models import Variable
from airflow.operators.python import PythonVirtualenvOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)
from airflow.utils.task_group import TaskGroup

from raw_vault.taskgroups.publish_to_datahub_taskgroup import (
    create_publish_to_datahub_taskgroup,
    _publish_test_results,
)
from utils.callbacks import on_failure_callback


def _var(name: str, default: Optional[str] = None) -> Optional[str]:
    try:
        value = Variable.get(name)
        return value if value != "" else default
    except KeyError:
        return default


PROJECT_ROOT = str(Path(__file__).resolve().parents[2])


def create_dbt_etl_jobs_taskgroup(
    group_id: str,
    *,
    dbt_select: str,
    full_refresh: bool,
    dag=None,
    ref_eod_table: Optional[str] = None,
    load_job_task_id: str = "load_job",
    logging_job_task_id: str = "logging_job",
) -> TaskGroup:
    artifacts_suffix = group_id
    base_prefix_var = _var("DBT_ARTIFACTS_PREFIX", None)
    if base_prefix_var:
        prefix_value = f"{base_prefix_var}/{artifacts_suffix}"
    else:
        prefix_value = "dbt-artifacts/{{ dag_run.run_id }}/" + artifacts_suffix

    with TaskGroup(group_id=group_id, dag=dag) as tg:
        load_and_logging = create_dbt_load_logging_taskgroup(
            group_id="load_and_logging",
            dbt_select=dbt_select,
            full_refresh=full_refresh,
            dag=dag,
            ref_eod_table=ref_eod_table,
            artifacts_suffix=artifacts_suffix,
            prefix_value=prefix_value,
            load_job_task_id=load_job_task_id,
            logging_job_task_id=logging_job_task_id,
        )

        publish_to_datahub = create_publish_to_datahub_taskgroup(
            prefix_value=prefix_value,
            artifacts_suffix=artifacts_suffix,
            dag=dag,
        )

        load_and_logging >> publish_to_datahub

    return tg


def create_dbt_load_logging_taskgroup(
    group_id: str,
    *,
    dbt_select: str,
    full_refresh: bool,
    dag=None,
    ref_eod_table: Optional[str] = None,
    artifacts_suffix: str,
    prefix_value: str,
    load_job_task_id: str,
    test_job_task_id: str = "test_job",
    logging_job_task_id: str,
) -> TaskGroup:
    with TaskGroup(group_id=group_id, dag=dag) as tg:
        load_job = SparkKubernetesOperator(
            task_id=load_job_task_id,
            namespace="spark-jobs",
            application_file="dbt-runner.yaml",
            random_name_suffix=True,
            kubernetes_conn_id="k8s_conn_id",
            dag=dag,
            params={
                "dbt_select": dbt_select,
                "full_refresh": full_refresh,
                "artifacts_suffix": artifacts_suffix,
                "ref_eod_table": ref_eod_table,
            },
        )

        test_job = SparkKubernetesOperator(
            task_id=test_job_task_id,
            namespace="spark-jobs",
            application_file="dbt-test.yaml",
            random_name_suffix=True,
            kubernetes_conn_id="k8s_conn_id",
            dag=dag,
            retries=0,  # No retry for test jobs - notify immediately on failure
            on_failure_callback=on_failure_callback,
            params={
                "dbt_select": dbt_select,
                "full_refresh": full_refresh,
                "artifacts_suffix": artifacts_suffix,
                "ref_eod_table": ref_eod_table,
            },
        )

        # Publish test results to DataHub - runs even if test_job fails
        publish_test_assertions = PythonVirtualenvOperator(
            task_id="publish_test_assertions",
            python_callable=_publish_test_results,
            trigger_rule="all_done",  # Run even if test_job fails
            op_kwargs={
                "bucket": _var("DBT_ARTIFACTS_BUCKET", "data") or "data",
                "prefix": prefix_value,
                "project_root": PROJECT_ROOT,
                "gms_host": _var("DATAHUB_GMS_HOST", "http://192.168.1.173:8080"),
                "token": _var("DATAHUB_TOKEN", ""),
                "platform": "iceberg",
                "platform_instance": _var("DATAHUB_PLATFORM_INSTANCE", "demo")
                or "demo",
                "env": _var("DATAHUB_ENV", "PROD") or "PROD",
                "aws_endpoint": _var(
                    "AWS_ENDPOINT_URL", "http://192.168.1.151"
                ),
                "aws_region": _var("AWS_DEFAULT_REGION", None),
                "aws_access_key": _var("AWS_ACCESS_KEY_ID", None),
                "aws_secret_key": _var("AWS_SECRET_ACCESS_KEY", None),
                "aws_session_token": _var("AWS_SESSION_TOKEN", None),
            },
            requirements=[
                "boto3",
                "requests",
            ],
            system_site_packages=False,
            python_version="3.12",
            dag=dag,
            params={
                "artifacts_suffix": artifacts_suffix,
            },
        )

        logging_job = SparkKubernetesOperator(
            task_id=logging_job_task_id,
            namespace="spark-jobs",
            application_file="dbt-logger.yaml",
            random_name_suffix=True,
            kubernetes_conn_id="k8s_conn_id",
            dag=dag,
            trigger_rule="all_done",  # Run even if test_job fails
            params={"artifacts_suffix": artifacts_suffix},
        )

        # After test_job, both publish_test_assertions and logging_job run in parallel
        load_job >> test_job >> [publish_test_assertions, logging_job]

    return tg
