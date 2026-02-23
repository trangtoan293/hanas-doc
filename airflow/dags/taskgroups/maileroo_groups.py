"""
Maileroo Notification TaskGroup for Airflow DAGs.

This module provides a reusable TaskGroup that sends email notifications
on DAG success or failure using the Maileroo API.
"""
from airflow.utils.task_group import TaskGroup
from airflow.operators.python import PythonOperator
from airflow.utils.trigger_rule import TriggerRule
from airflow.utils.state import TaskInstanceState

from utils.maileroo_utils import MailerooNotificationService


def maileroo_notification_group(group_id: str, dag, recipient_email: str = None):
    """
    Create a TaskGroup for sending success/failure notifications via Maileroo.

    The TaskGroup contains a single task `notify_dag_status` that:
    - Runs with TriggerRule.ALL_DONE (guaranteed to execute).
    - Inspects all task instances in the DAG run to determine if any failed.
    - Sends the appropriate Success or Failure email.

    :param group_id: The group_id for the TaskGroup.
    :param dag: The DAG object.
    :param recipient_email: Optional recipient email. If None, uses default from config.
    :return: The TaskGroup object.
    """
    with TaskGroup(group_id=group_id, dag=dag) as tg:

        def notify_dag_status(**context):
            """
            Determine DAG run status and send appropriate notification.

            This function inspects all task instances (excluding itself) in the current
            DAG run to check for any failures. It then sends either a success or
            failure email via the MailerooNotificationService.
            
            The recipient email is determined by:
            1. The `recipient_email` argument passed to maileroo_notification_group (if provided).
            2. Otherwise, the DAG param `notification_email` (if provided at trigger time).
            3. Otherwise, falls back to DEFAULT_NOTIFICATION_EMAIL from Airflow Variables.
            """
            dag_run = context.get('dag_run')
            task_instance = context.get('task_instance')
            current_task_id = task_instance.task_id

            # Get all task instances for this DAG run
            task_instances = dag_run.get_task_instances()

            # Check for failures (excluding the current notification task)
            failed_tasks = [
                ti.task_id for ti in task_instances
                if ti.state == TaskInstanceState.FAILED and ti.task_id != current_task_id
            ]
            upstream_failed_count = sum(
                1
                for ti in task_instances
                if ti.state == TaskInstanceState.UPSTREAM_FAILED and ti.task_id != current_task_id
            )

            # Determine recipient: explicit arg > DAG param > default config
            effective_recipient = recipient_email
            if not effective_recipient:
                params = context.get('params', {})
                effective_recipient = params.get('notification_email')

            service = MailerooNotificationService()

            if failed_tasks or upstream_failed_count > 0:
                max_tasks_in_email = 50
                shown = failed_tasks[:max_tasks_in_email]
                truncated = len(failed_tasks) - len(shown)
                failed_tasks_str = ", ".join(shown)
                if truncated > 0:
                    failed_tasks_str = f"{failed_tasks_str} ... (+{truncated} more)"
                failed_tasks_str = f"FAILED({len(failed_tasks)}), UPSTREAM_FAILED({upstream_failed_count}): {failed_tasks_str}"
                service.send_error_notification(context, failed_tasks=failed_tasks_str, recipient=effective_recipient)
            else:
                service.send_success_notification(context, recipient=effective_recipient)

        PythonOperator(
            task_id='notify_dag_status',
            python_callable=notify_dag_status,
            trigger_rule=TriggerRule.ALL_DONE,
            dag=dag,
        )

    return tg
