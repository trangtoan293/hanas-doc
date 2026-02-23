from __future__ import annotations

from typing import Any, Dict, Optional

from airflow.operators.python import PythonOperator
from airflow.utils.state import TaskInstanceState
from airflow.utils.task_group import TaskGroup
from airflow.utils.trigger_rule import TriggerRule

from ..maileroo import MailerooClient


def create_maileroo_notification_group(
    group_id: str,
    *,
    dag=None,
    recipient_email: Optional[str] = None,
    dag_param_name: str = "notification_email",
    max_failed_tasks: int = 50,
) -> TaskGroup:
    with TaskGroup(group_id=group_id, dag=dag) as tg:

        def notify_dag_status(**context: Dict[str, Any]):
            dag_run = context.get("dag_run")
            task_instance = context.get("task_instance")
            if not dag_run or not task_instance:
                return

            current_task_id = task_instance.task_id
            task_instances = dag_run.get_task_instances()

            failed = [
                ti.task_id
                for ti in task_instances
                if ti.task_id != current_task_id
                and ti.state in {TaskInstanceState.FAILED, TaskInstanceState.UPSTREAM_FAILED}
            ]

            upstream_failed_count = sum(
                1
                for ti in task_instances
                if ti.task_id != current_task_id and ti.state == TaskInstanceState.UPSTREAM_FAILED
            )

            effective_recipient = recipient_email
            if not effective_recipient:
                params = context.get("params") or {}
                effective_recipient = params.get(dag_param_name)

            client = MailerooClient()

            if failed:
                shown = failed[:max_failed_tasks]
                truncated = len(failed) - len(shown)
                failed_tasks_str = ", ".join(shown)
                if truncated > 0:
                    failed_tasks_str = f"{failed_tasks_str} ... (+{truncated} more)"
                failed_tasks_str = (
                    f"FAILED/UPSTREAM_FAILED({len(failed)}), UPSTREAM_FAILED({upstream_failed_count}): {failed_tasks_str}"
                )
                client.send_failure(context, failed_tasks=failed_tasks_str, recipient=effective_recipient)
            else:
                client.send_success(context, recipient=effective_recipient)

        PythonOperator(
            task_id="notify_dag_status",
            python_callable=notify_dag_status,
            trigger_rule=TriggerRule.ALL_DONE,
            dag=dag,
        )

    return tg
