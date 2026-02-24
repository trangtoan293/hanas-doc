from __future__ import annotations

from typing import Any, Dict, Optional

from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup
from airflow.utils.trigger_rule import TriggerRule

from package.ktl_airflow_utils.spark.k8s import create_spark_kubernetes_operator
from package.ktl_airflow_utils.airflow_vars import get_var


def create_dbt_spark_taskgroup(
    group_id: str,
    *,
    dag=None,
    dbt_select: str,
    full_refresh: bool,
    run_application_file: str = "dbt-runner.yaml",
    test_application_file: str = "dbt-test.yaml",
    logger_application_file: str = "dbt-logger.yaml",
    namespace: str = "spark-jobs",
    kubernetes_conn_id: str = "k8s_conn_id",
    use_spark_operator: bool = True,
    extra_params: Optional[Dict[str, Any]] = None,
) -> TaskGroup:
    """Simple dbt Spark taskgroup: run -> test -> logger."""
    params: Dict[str, Any] = {
        "dbt_select": dbt_select,
        "full_refresh": full_refresh,
    }
    if extra_params:
        params.update(extra_params)

    with TaskGroup(group_id=group_id, dag=dag) as tg:
        if use_spark_operator:
            run_job = create_spark_kubernetes_operator(
                task_id="dbt_run",
                namespace=namespace,
                application_file=run_application_file,
                kubernetes_conn_id=kubernetes_conn_id,
                dag=dag,
                params=params,
            )
            test_job = create_spark_kubernetes_operator(
                task_id="dbt_test",
                namespace=namespace,
                application_file=test_application_file,
                kubernetes_conn_id=kubernetes_conn_id,
                dag=dag,
                params=params,
                retries=0,
            )
            logger_job = create_spark_kubernetes_operator(
                task_id="dbt_logger",
                namespace=namespace,
                application_file=logger_application_file,
                kubernetes_conn_id=kubernetes_conn_id,
                dag=dag,
                params=params,
                trigger_rule="all_done",
            )
        else:
            run_job = EmptyOperator(task_id="dbt_run", dag=dag)
            test_job = EmptyOperator(task_id="dbt_test", dag=dag)
            logger_job = EmptyOperator(task_id="dbt_logger", dag=dag)

        run_job >> test_job >> logger_job

    return tg


def create_dbt_etl_taskgroup(
    group_id: str,
    *,
    dag=None,
    dbt_select: str,
    full_refresh: bool,
    ref_eod_table: Optional[str] = None,
    dbt_exclude: Optional[str] = None,
    run_application_file: str = "dbt-runner.yaml",
    test_application_file: str = "dbt-test.yaml",
    logger_application_file: str = "dbt-logger.yaml",
    namespace: str = "spark-jobs",
    kubernetes_conn_id: str = "k8s_conn_id",
    use_spark_operator: bool = True,
    load_job_task_id: str = "load_job",
    test_job_task_id: str = "test_job",
    logging_job_task_id: str = "logging_job",
) -> TaskGroup:
    """
    Full ETL taskgroup with separate run/test artifact folders.
    
    Artifact structure:
        .../<group_id>/run/   <- dbt run artifacts (manifest, run_results, catalog)
        .../<group_id>/test/  <- dbt test artifacts (manifest, run_results)
    
    Flow: load_job -> test_job -> logging_job
    """
    run_suffix = f"{group_id}/run"
    test_suffix = f"{group_id}/test"

    run_params: Dict[str, Any] = {
        "dbt_select": dbt_select,
        "full_refresh": full_refresh,
        "artifacts_suffix": run_suffix,
        "ref_eod_table": ref_eod_table,
        "dbt_exclude": dbt_exclude,
    }

    test_params: Dict[str, Any] = {
        "dbt_select": dbt_select,
        "full_refresh": full_refresh,
        "artifacts_suffix": test_suffix,
        "ref_eod_table": ref_eod_table,
    }

    logger_params: Dict[str, Any] = {
        "artifacts_suffix": run_suffix,
    }

    with TaskGroup(group_id=group_id, dag=dag) as tg:
        if use_spark_operator:
            load_job = create_spark_kubernetes_operator(
                task_id=load_job_task_id,
                namespace=namespace,
                application_file=run_application_file,
                kubernetes_conn_id=kubernetes_conn_id,
                dag=dag,
                params=run_params,
            )
            test_job = create_spark_kubernetes_operator(
                task_id=test_job_task_id,
                namespace=namespace,
                application_file=test_application_file,
                kubernetes_conn_id=kubernetes_conn_id,
                dag=dag,
                params=test_params,
                retries=0,
            )
            logging_job = create_spark_kubernetes_operator(
                task_id=logging_job_task_id,
                namespace=namespace,
                application_file=logger_application_file,
                kubernetes_conn_id=kubernetes_conn_id,
                dag=dag,
                params=logger_params,
                trigger_rule="all_done",
            )
        else:
            load_job = EmptyOperator(task_id=load_job_task_id, dag=dag)
            test_job = EmptyOperator(task_id=test_job_task_id, dag=dag)
            logging_job = EmptyOperator(
                task_id=logging_job_task_id,
                dag=dag,
                trigger_rule=TriggerRule.ALL_DONE,
            )

        load_job >> test_job >> logging_job

    return tg


def create_dbt_step_taskgroup(
    group_id: str,
    *,
    dag=None,
    dbt_select: str,
    full_refresh: bool,
    ref_eod_table: Optional[str] = None,
    artifacts_base: Optional[str] = None,
    run_application_file: str = "dbt-runner.yaml",
    test_application_file: str = "dbt-test.yaml",
    logger_application_file: str = "dbt-logger.yaml",
    namespace: str = "spark-jobs",
    kubernetes_conn_id: str = "k8s_conn_id",
    use_spark_operator: bool = True,
    asset_tag_name: Optional[str] = None,
) -> TaskGroup:
    """
    Create a TaskGroup for a single pipeline step with load -> test -> logging.
    
    Uses SEPARATE artifact folders for run vs test to preserve both:
    - Lineage data (from dbt run artifacts in /run folder)
    - Data quality assertions (from dbt test artifacts in /test folder)
    
    Artifact structure:
        .../<artifacts_base>/<group_id>/run/   <- dbt run artifacts
        .../<artifacts_base>/<group_id>/test/  <- dbt test artifacts
    
    Args:
        group_id: TaskGroup ID and artifact folder name.
        artifacts_base: Base folder for artifacts (default: group_id).
            Use "mdm_etl_job" for MDM pipelines, or any custom prefix.
    
    Flow: load_job -> test_job -> logging_job
    """
    base = artifacts_base or group_id
    base_suffix = f"{base}/{group_id}" if artifacts_base else group_id
    run_suffix = f"{base_suffix}/run"
    test_suffix = f"{base_suffix}/test"

    base_prefix_var = get_var("DBT_ARTIFACTS_PREFIX", None)
    if base_prefix_var:
        run_prefix = f"{base_prefix_var}/{run_suffix}"
        test_prefix = f"{base_prefix_var}/{test_suffix}"
    else:
        run_prefix = "dbt-artifacts/{{ dag_run.run_id }}/" + run_suffix
        test_prefix = "dbt-artifacts/{{ dag_run.run_id }}/" + test_suffix

    run_params: Dict[str, Any] = {
        "dbt_select": dbt_select,
        "full_refresh": full_refresh,
        "artifacts_suffix": run_suffix,
        "ref_eod_table": ref_eod_table,
    }

    test_params: Dict[str, Any] = {
        "dbt_select": dbt_select,
        "full_refresh": full_refresh,
        "artifacts_suffix": test_suffix,
        "ref_eod_table": ref_eod_table,
    }

    logger_params: Dict[str, Any] = {
        "artifacts_suffix": run_suffix,
    }

    with TaskGroup(group_id=group_id, dag=dag) as tg:
        if use_spark_operator:
            load_job = create_spark_kubernetes_operator(
                task_id="load_job",
                namespace=namespace,
                application_file=run_application_file,
                kubernetes_conn_id=kubernetes_conn_id,
                dag=dag,
                params=run_params,
            )
            test_job = create_spark_kubernetes_operator(
                task_id="test_job",
                namespace=namespace,
                application_file=test_application_file,
                kubernetes_conn_id=kubernetes_conn_id,
                dag=dag,
                params=test_params,
                retries=0,
            )
            logging_job = create_spark_kubernetes_operator(
                task_id="logging_job",
                namespace=namespace,
                application_file=logger_application_file,
                kubernetes_conn_id=kubernetes_conn_id,
                dag=dag,
                params=logger_params,
                trigger_rule="all_done",
            )
        else:
            load_job = EmptyOperator(task_id="load_job", dag=dag)
            test_job = EmptyOperator(task_id="test_job", dag=dag)
            logging_job = EmptyOperator(
                task_id="logging_job",
                dag=dag,
                trigger_rule=TriggerRule.ALL_DONE,
            )

        # Publish placeholder (unified publish would be added externally or via import)
        # For now, just create the ETL flow
        # Flow: load -> test -> logging
        load_job >> test_job >> logging_job

    return tg
