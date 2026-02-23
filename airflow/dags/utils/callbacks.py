"""
Callback functions for Airflow DAGs.

This module provides reusable callback functions for task lifecycle events:
- on_failure_callback
- on_success_callback  
- on_retry_callback
- sla_miss_callback

Usage in DAG:
    from utils.callbacks import on_failure_callback, on_retry_callback, sla_miss_callback

    default_args = {
        "on_failure_callback": on_failure_callback,
        "on_retry_callback": on_retry_callback,
    }

    with DAG(..., sla_miss_callback=sla_miss_callback) as dag:
        ...
"""
import logging
from typing import Any, Dict, List

from airflow.models import Variable


def on_failure_callback(context: Dict[str, Any]):
    """
    Callback executed when a task fails.

    Sends notification via configured channels (Slack, Teams) for immediate alerting.
    Email notifications are handled separately by the end-of-DAG notification group.

    :param context: Airflow task context.
    """
    try:
        from utils.notification_service import NotificationService

        task = context.get('task')
        task_id = task.task_id if task else 'unknown'
        dag_id = context.get('dag').dag_id if context.get('dag') else 'unknown'
        exception = context.get('exception')

        message = f"Task `{task_id}` in DAG `{dag_id}` failed."
        if exception:
            message += f"\nError: {str(exception)[:200]}"

        # Get channels - for immediate alerts, typically Slack/Teams (not email, to avoid spam)
        immediate_channels_str = Variable.get("IMMEDIATE_ALERT_CHANNELS", default_var='["slack"]')
        try:
            import json
            immediate_channels = json.loads(immediate_channels_str)
        except Exception:
            immediate_channels = ["slack"]

        service = NotificationService()
        service.notify(
            context=context,
            status='FAILED',
            message=message,
            failed_tasks=task_id,
            channels=immediate_channels,
        )

    except Exception as e:
        logging.error(f"on_failure_callback error: {e}")


def on_success_callback(context: Dict[str, Any]):
    """
    Callback executed when a task succeeds.

    By default, this only logs the success. Enable per-task success notifications
    by setting NOTIFY_ON_TASK_SUCCESS=true in Airflow Variables.

    :param context: Airflow task context.
    """
    task = context.get('task')
    task_id = task.task_id if task else 'unknown'
    dag_id = context.get('dag').dag_id if context.get('dag') else 'unknown'

    logging.info(f"Task {task_id} in DAG {dag_id} completed successfully.")

    # Optional: send notification on task success (disabled by default to reduce noise)
    if Variable.get("NOTIFY_ON_TASK_SUCCESS", default_var="false").lower() == "true":
        try:
            from utils.notification_service import NotificationService
            service = NotificationService()
            service.notify(
                context=context,
                status='TASK_SUCCESS',
                message=f"Task `{task_id}` completed successfully.",
                channels=["slack"],  # Only Slack for task-level success
            )
        except Exception as e:
            logging.error(f"on_success_callback notification error: {e}")


def on_retry_callback(context: Dict[str, Any]):
    """
    Callback executed when a task is being retried.

    Sends notification to alert team that a task is having issues.

    :param context: Airflow task context.
    """
    try:
        from utils.notification_service import NotificationService

        task = context.get('task')
        ti = context.get('task_instance')
        task_id = task.task_id if task else 'unknown'
        dag_id = context.get('dag').dag_id if context.get('dag') else 'unknown'
        try_number = ti.try_number if ti else 1
        max_tries = ti.max_tries if ti else 'N/A'

        message = f"Task `{task_id}` in DAG `{dag_id}` is retrying (attempt {try_number}/{max_tries})."

        # Get channels for retry alerts
        retry_channels_str = Variable.get("RETRY_ALERT_CHANNELS", default_var='["slack"]')
        try:
            import json
            retry_channels = json.loads(retry_channels_str)
        except Exception:
            retry_channels = ["slack"]

        service = NotificationService()
        service.notify(
            context=context,
            status='RETRYING',
            message=message,
            channels=retry_channels,
        )

    except Exception as e:
        logging.error(f"on_retry_callback error: {e}")


def sla_miss_callback(dag, task_list, blocking_task_list, slas, blocking_tis):
    """
    Callback executed when a DAG misses its SLA.

    Sends notification to all configured channels about the SLA breach.

    :param dag: The DAG object.
    :param task_list: List of tasks that missed their SLA.
    :param blocking_task_list: List of tasks that blocked the SLA.
    :param slas: List of SLA objects.
    :param blocking_tis: List of blocking task instances.
    """
    try:
        from utils.notification_service import NotificationService

        dag_id = dag.dag_id
        task_ids = [t.task_id for t in task_list] if task_list else []

        logging.warning(f"SLA breach for DAG {dag_id}, tasks: {task_ids}")

        service = NotificationService()
        service.notify_sla_breach(
            dag_id=dag_id,
            slas=slas,
            channels=None,  # Use default channels
        )

    except Exception as e:
        logging.error(f"sla_miss_callback error: {e}")


def on_execute_callback(context: Dict[str, Any]):
    """
    Callback executed when a task starts execution.

    Useful for tracking job progress. Updates progress tracker if enabled.

    :param context: Airflow task context.
    """
    task = context.get('task')
    task_id = task.task_id if task else 'unknown'
    dag_id = context.get('dag').dag_id if context.get('dag') else 'unknown'

    logging.info(f"Task {task_id} in DAG {dag_id} started execution.")

    # Optional: Update progress tracker
    if Variable.get("ENABLE_PROGRESS_TRACKING", default_var="false").lower() == "true":
        try:
            from utils.progress_tracker import ProgressTracker
            ProgressTracker.update(
                context=context,
                status='RUNNING',
                progress=0,
                metrics={'task_id': task_id, 'dag_id': dag_id},
            )
        except Exception as e:
            logging.error(f"Progress tracker update error: {e}")
