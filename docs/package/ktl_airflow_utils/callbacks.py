"""Reusable callback functions for Airflow DAGs.

This module provides callback functions for task lifecycle events:
- on_failure_callback
- on_success_callback
- on_retry_callback

These are simplified versions that log events. For full notification
support (Slack, Teams, etc.), use the callbacks from dags/utils/callbacks.py
which integrate with NotificationService.

Usage:
    from package.ktl_airflow_utils.callbacks import on_failure_callback

    default_args = {
        "on_failure_callback": on_failure_callback,
    }
"""
from __future__ import annotations

import logging
from typing import Any, Dict

logger = logging.getLogger(__name__)


def on_failure_callback(context: Dict[str, Any]) -> None:
    """
    Callback executed when a task fails.
    
    Logs the failure. For notifications, configure via Airflow Variables
    or use the full NotificationService from dags/utils/.
    """
    task = context.get("task")
    task_id = task.task_id if task else "unknown"
    dag = context.get("dag")
    dag_id = dag.dag_id if dag else "unknown"
    exception = context.get("exception")

    message = f"Task '{task_id}' in DAG '{dag_id}' failed."
    if exception:
        message += f" Error: {str(exception)[:200]}"

    logger.error(message)


def on_success_callback(context: Dict[str, Any]) -> None:
    """
    Callback executed when a task succeeds.
    
    Logs the success.
    """
    task = context.get("task")
    task_id = task.task_id if task else "unknown"
    dag = context.get("dag")
    dag_id = dag.dag_id if dag else "unknown"

    logger.info(f"Task '{task_id}' in DAG '{dag_id}' completed successfully.")


def on_retry_callback(context: Dict[str, Any]) -> None:
    """
    Callback executed when a task is being retried.
    
    Logs the retry attempt.
    """
    task = context.get("task")
    ti = context.get("task_instance")
    task_id = task.task_id if task else "unknown"
    dag = context.get("dag")
    dag_id = dag.dag_id if dag else "unknown"
    try_number = ti.try_number if ti else 1
    max_tries = ti.max_tries if ti else "N/A"

    logger.warning(
        f"Task '{task_id}' in DAG '{dag_id}' is retrying "
        f"(attempt {try_number}/{max_tries})."
    )


def get_task_info(context: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extract common task information from Airflow context.
    
    Args:
        context: Airflow task context.
    
    Returns:
        Dict with task_id, dag_id, run_id, execution_date, try_number.
    """
    task = context.get("task")
    dag = context.get("dag")
    dag_run = context.get("dag_run")
    ti = context.get("task_instance")

    return {
        "task_id": task.task_id if task else None,
        "dag_id": dag.dag_id if dag else None,
        "run_id": dag_run.run_id if dag_run else None,
        "execution_date": str(dag_run.execution_date) if dag_run else None,
        "try_number": ti.try_number if ti else None,
        "max_tries": ti.max_tries if ti else None,
    }
