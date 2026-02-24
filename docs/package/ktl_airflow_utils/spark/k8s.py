from __future__ import annotations

from typing import Any, Dict, Optional


def _import_spark_operator():
    from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (  # type: ignore
        SparkKubernetesOperator,
    )

    return SparkKubernetesOperator


def create_spark_kubernetes_operator(
    *,
    task_id: str,
    application_file: str,
    namespace: str = "spark-jobs",
    kubernetes_conn_id: str = "k8s_conn_id",
    dag=None,
    params: Optional[Dict[str, Any]] = None,
    **kwargs: Any,
):
    SparkKubernetesOperator = _import_spark_operator()

    return SparkKubernetesOperator(
        task_id=task_id,
        namespace=namespace,
        application_file=application_file,
        random_name_suffix=True,
        kubernetes_conn_id=kubernetes_conn_id,
        dag=dag,
        params=params or {},
        **kwargs,
    )
