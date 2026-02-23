from __future__ import annotations

from pathlib import Path
from typing import Optional

from airflow.models import Variable
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)
from airflow.utils.task_group import TaskGroup

from raw_vault.taskgroups.publish_to_datahub_taskgroup import (
    create_publish_to_datahub_taskgroup,
    create_publish_test_to_datahub_taskgroup,
    create_unified_publish_to_datahub_taskgroup,
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
    dbt_exclude: Optional[str] = None,
    asset_tag_name: Optional[str] = None,
) -> TaskGroup:
    """
    Create a TaskGroup for ETL jobs with load -> test -> publish sequence.
    
    Uses SEPARATE artifact folders for run vs test to preserve both:
    - Lineage data (from dbt run artifacts in /run folder)
    - Data quality assertions (from dbt test artifacts in /test folder)
    
    Artifact structure:
        .../<group_id>/run/   <- dbt run artifacts
        .../<group_id>/test/  <- dbt test artifacts
    
    Args:
        dbt_exclude: Optional dbt exclude pattern (e.g., "*_backdate" to skip backdate tables)
    """
    base_suffix = group_id
    run_suffix = f"{base_suffix}/run"
    test_suffix = f"{base_suffix}/test"
    
    base_prefix_var = _var("DBT_ARTIFACTS_PREFIX", None)
    if base_prefix_var:
        run_prefix = f"{base_prefix_var}/{run_suffix}"
        test_prefix = f"{base_prefix_var}/{test_suffix}"
    else:
        run_prefix = "dbt-artifacts/{{ dag_run.run_id }}/" + run_suffix
        test_prefix = "dbt-artifacts/{{ dag_run.run_id }}/" + test_suffix

    with TaskGroup(group_id=group_id, dag=dag) as tg:
        # Load and logging sub-taskgroup (no publish inside)
        load_and_logging = _create_load_test_logging_subgroup(
            group_id="load_and_logging",
            dbt_select=dbt_select,
            full_refresh=full_refresh,
            dag=dag,
            ref_eod_table=ref_eod_table,
            run_suffix=run_suffix,
            test_suffix=test_suffix,
            load_job_task_id=load_job_task_id,
            logging_job_task_id=logging_job_task_id,
            dbt_exclude=dbt_exclude,
        )

        # Unified publish taskgroup with 4 jobs:
        # extract_dbt_catalog -> publish_dbt_transformation -> publish_iceberg_metadata -> publish_dbt_tests
        publish_datahub = create_unified_publish_to_datahub_taskgroup(
            group_id="publish_datahub",
            run_prefix_value=run_prefix,
            test_prefix_value=test_prefix,
            run_artifacts_suffix=run_suffix,
            test_artifacts_suffix=test_suffix,
            dag=dag,
            asset_tag_name=asset_tag_name,
        )

        # Flow: load_and_logging -> publish_datahub
        load_and_logging >> publish_datahub

    return tg


def _create_load_test_logging_subgroup(
    group_id: str,
    *,
    dbt_select: str,
    full_refresh: bool,
    dag=None,
    ref_eod_table: Optional[str] = None,
    run_suffix: str,
    test_suffix: str,
    load_job_task_id: str,
    test_job_task_id: str = "test_job",
    logging_job_task_id: str,
    dbt_exclude: Optional[str] = None,
) -> TaskGroup:
    """
    Internal helper: load -> test -> logging sub-taskgroup.
    
    Uses SEPARATE folders:
    - load_job writes to /run folder
    - test_job writes to /test folder
    
    publish_test is handled at parent level after publish_run.
    """
    with TaskGroup(group_id=group_id, dag=dag) as tg:
        # Load job - writes to /run folder
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
                "artifacts_suffix": run_suffix,
                "ref_eod_table": ref_eod_table,
                "dbt_exclude": dbt_exclude,
            },
        )

        # Test job - writes to /test folder (separate from run)
        test_job = SparkKubernetesOperator(
            task_id=test_job_task_id,
            namespace="spark-jobs",
            application_file="dbt-test.yaml",
            random_name_suffix=True,
            kubernetes_conn_id="k8s_conn_id",
            dag=dag,
            retries=0,
            on_failure_callback=on_failure_callback,
            params={
                "dbt_select": dbt_select,
                "full_refresh": full_refresh,
                "artifacts_suffix": test_suffix,
                "ref_eod_table": ref_eod_table,
            },
        )

        # Logging job (uses run artifacts for ETL metrics)
        logging_job = SparkKubernetesOperator(
            task_id=logging_job_task_id,
            namespace="spark-jobs",
            application_file="dbt-logger.yaml",
            random_name_suffix=True,
            kubernetes_conn_id="k8s_conn_id",
            dag=dag,
            trigger_rule="all_done",
            params={"artifacts_suffix": run_suffix},
        )

        # Flow: load -> test -> logging
        load_job >> test_job >> logging_job

    return tg



def create_mdm_step_taskgroup(
    group_id: str,
    *,
    dbt_select: str,
    full_refresh: bool,
    dag=None,
    ref_eod_table: Optional[str] = None,
    asset_tag_name: Optional[str] = None,
) -> TaskGroup:
    """
    Create a TaskGroup for a single MDM step with load -> test -> publish sequence.
    
    Uses SEPARATE artifact folders for run vs test to preserve both:
    - Lineage data (from dbt run artifacts in /run folder)
    - Data quality assertions (from dbt test artifacts in /test folder)
    
    Artifact structure:
        .../mdm_etl_job/<step_id>/run/   <- dbt run artifacts (manifest + run_results for models)
        .../mdm_etl_job/<step_id>/test/  <- dbt test artifacts (manifest + run_results for tests)
    
    Publish flows:
        publish_run: extract_catalog -> publish_dbt_transformation -> publish_iceberg_metadata
        publish_test: publish_dbt_tests (assertions with "Provided by dbt" branding)
    """
    base_suffix = f"mdm_etl_job/{group_id}"
    run_suffix = f"{base_suffix}/run"
    test_suffix = f"{base_suffix}/test"
    
    base_prefix_var = _var("DBT_ARTIFACTS_PREFIX", None)
    if base_prefix_var:
        run_prefix = f"{base_prefix_var}/{run_suffix}"
        test_prefix = f"{base_prefix_var}/{test_suffix}"
    else:
        run_prefix = "dbt-artifacts/{{ dag_run.run_id }}/" + run_suffix
        test_prefix = "dbt-artifacts/{{ dag_run.run_id }}/" + test_suffix

    with TaskGroup(group_id=group_id, dag=dag) as tg:
        # Load job - writes to /run folder
        load_job = SparkKubernetesOperator(
            task_id="load_job",
            namespace="spark-jobs",
            application_file="dbt-runner.yaml",
            random_name_suffix=True,
            kubernetes_conn_id="k8s_conn_id",
            dag=dag,
            params={
                "dbt_select": dbt_select,
                "full_refresh": full_refresh,
                "artifacts_suffix": run_suffix,
                "ref_eod_table": ref_eod_table,
            },
        )

        # Test job - writes to /test folder (separate from run)
        test_job = SparkKubernetesOperator(
            task_id="test_job",
            namespace="spark-jobs",
            application_file="dbt-test.yaml",
            random_name_suffix=True,
            kubernetes_conn_id="k8s_conn_id",
            dag=dag,
            retries=0,
            on_failure_callback=on_failure_callback,
            params={
                "dbt_select": dbt_select,
                "full_refresh": full_refresh,
                "artifacts_suffix": test_suffix,
                "ref_eod_table": ref_eod_table,
            },
        )

        # Unified publish taskgroup (Catalog -> Transform -> Iceberg -> Tests)
        publish_datahub = create_unified_publish_to_datahub_taskgroup(
            group_id="publish_datahub",
            run_prefix_value=run_prefix,
            test_prefix_value=test_prefix,
            run_artifacts_suffix=run_suffix,
            test_artifacts_suffix=test_suffix,
            dag=dag,
            asset_tag_name=asset_tag_name,
        )

        # Logging job (uses run artifacts for ETL metrics)
        logging_job = SparkKubernetesOperator(
            task_id="logging_job",
            namespace="spark-jobs",
            application_file="dbt-logger.yaml",
            random_name_suffix=True,
            kubernetes_conn_id="k8s_conn_id",
            dag=dag,
            trigger_rule="all_done",
            params={"artifacts_suffix": run_suffix},
        )

        # Flow: load -> test -> [publish_datahub, logging_job]
        load_job >> test_job >> [publish_datahub, logging_job]

    return tg

