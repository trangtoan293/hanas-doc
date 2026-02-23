"""
Maileroo Notification Service for Airflow DAGs.

This module provides a service to send email notifications via the Maileroo API.
It is designed to be used with Airflow TaskGroups for DAG success/failure notifications.
"""
import logging
import requests
from datetime import datetime
from typing import Dict

from airflow.models import Variable


class MailerooNotificationService:
    """Service class for sending email notifications via Maileroo API."""

    MAILEROO_API_URL = "https://smtp.maileroo.com/api/v2/emails"

    def __init__(self, config: Dict = None):
        """
        Initialize the Maileroo service.

        :param config: Optional dictionary with keys: MAILEROO_API_KEY, SENDER_EMAIL, DEFAULT_NOTIFICATION_EMAIL.
                       If not provided, values are read from Airflow Variables.
        """
        if config is None:
            config = {}

        self.api_key = config.get('MAILEROO_API_KEY') or Variable.get("MAILEROO_API_KEY", default_var=None)
        self.sender_email = config.get('SENDER_EMAIL') or Variable.get("SENDER_EMAIL", default_var=None)
        self.default_notification_email = config.get('DEFAULT_NOTIFICATION_EMAIL') or Variable.get("DEFAULT_NOTIFICATION_EMAIL", default_var=None)

        if not self.api_key:
            logging.warning("MAILEROO_API_KEY not configured. Emails will not be sent.")
        if not self.sender_email:
            logging.warning("SENDER_EMAIL not configured. Emails will not be sent.")

        # Simple plain text templates (Maileroo drops connections with complex HTML)
        self.success_template = """DAG Run Successful

DAG: {dag_id}
Run ID: {run_id}
Execution Date: {execution_date}
Status: SUCCESS
{log_section}
---
Sent by Airflow at {send_time}
"""

        self.error_template = """DAG Run Failed

DAG: {dag_id}
Run ID: {run_id}
Execution Date: {execution_date}
Status: FAILED
Failed Tasks: {failed_tasks}
{log_section}
---
Sent by Airflow at {send_time}
"""

    def get_dag_run_url(self, context: Dict) -> str:
        """
        Construct the URL to the DAG Run's Grid View in Airflow UI.

        :param context: Airflow task context.
        :return: URL string or None if AIRFLOW_BASE_URL is not configured.
        """
        base_url = Variable.get("AIRFLOW_BASE_URL", default_var=None)
        if not base_url:
            return None

        dag_run = context.get('dag_run')
        dag_id = dag_run.dag_id
        run_id = dag_run.run_id

        from urllib.parse import quote
        url = f"{base_url}/dags/{dag_id}/grid?dag_run_id={quote(run_id)}"
        return url

    def send_success_notification(self, context: Dict, recipient: str = None):
        """Send success notification email."""
        to_email = recipient or self.default_notification_email
        if not to_email:
            logging.info("No recipient email specified. Skipping success notification.")
            return

        dag_run = context.get('dag_run')
        dag_id = dag_run.dag_id
        run_id = dag_run.run_id
        execution_date = str(dag_run.execution_date)
        log_url = self.get_dag_run_url(context)
        log_section = f"\nView logs: {log_url}\n" if log_url else ""

        html_content = self.success_template.format(
            dag_id=dag_id,
            run_id=run_id,
            execution_date=execution_date,
            log_section=log_section,
            send_time=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        )

        subject = f"Success: {dag_id}"
        self._send_email(to_email, subject, html_content)

    def send_error_notification(self, context: Dict, failed_tasks: str, recipient: str = None):
        """Send error notification email."""
        to_email = recipient or self.default_notification_email
        if not to_email:
            logging.info("No recipient email specified. Skipping error notification.")
            return

        dag_run = context.get('dag_run')
        dag_id = dag_run.dag_id
        run_id = dag_run.run_id
        execution_date = str(dag_run.execution_date)
        log_url = self.get_dag_run_url(context)
        log_section = f"\nView logs: {log_url}\n" if log_url else ""

        html_content = self.error_template.format(
            dag_id=dag_id,
            run_id=run_id,
            execution_date=execution_date,
            failed_tasks=failed_tasks,
            log_section=log_section,
            send_time=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        )

        subject = f"Failure: {dag_id}"
        self._send_email(to_email, subject, html_content)

    def _send_email(self, to_email: str, subject: str, content: str):
        """Send email via Maileroo API (plain text only).
        
        Args:
            to_email: Single email or comma-separated list of emails.
            subject: Email subject.
            content: Plain text email content.
        """
        import time
        
        if not self.api_key or not self.sender_email:
            logging.error("Missing API Key or Sender Email. Cannot send email.")
            return

        # Parse comma-separated emails into list
        recipients = [email.strip() for email in to_email.split(",") if email.strip()]
        if not recipients:
            logging.error("No valid recipient emails provided.")
            return

        logging.info(f"Sending email to {len(recipients)} recipient(s): {', '.join(recipients)}...")

        headers = {
            "X-API-Key": self.api_key,
            "Content-Type": "application/json",
        }

        payload = {
            "from": {
                "address": self.sender_email,
                "display_name": "Airflow Notification"
            },
            "to": [{"address": email} for email in recipients],
            "subject": subject,
            "plain": content,
        }

        max_retries = 3
        retry_delay = 5

        for attempt in range(1, max_retries + 1):
            try:
                response = requests.post(
                    self.MAILEROO_API_URL,
                    headers=headers,
                    json=payload,
                    timeout=30,
                )

                if response.status_code == 200:
                    resp_data = response.json()
                    if resp_data.get('success'):
                        logging.info("Email sent successfully via Maileroo.")
                        return
                    else:
                        logging.error(f"Maileroo API error: {resp_data}")
                        return
                else:
                    logging.error(f"Maileroo HTTP {response.status_code}: {response.text}")
                    return

            except (requests.exceptions.ConnectionError, requests.exceptions.Timeout) as e:
                logging.warning(f"Attempt {attempt}/{max_retries} failed: {e}")
                if attempt < max_retries:
                    time.sleep(retry_delay)
                else:
                    logging.error("All retry attempts failed.")
            except Exception as e:
                logging.error(f"Unexpected error: {e}")
                return
