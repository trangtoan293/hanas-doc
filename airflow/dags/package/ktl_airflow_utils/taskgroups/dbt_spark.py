from __future__ import annotations

from typing import Any, Dict, Optional

from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

from ..spark.k8s import create_spark_kubernetes_operator


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
