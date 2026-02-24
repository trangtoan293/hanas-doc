from __future__ import annotations

import json
import logging
import socket
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, Optional
from urllib.parse import quote

from package.ktl_airflow_utils.airflow_vars import get_var

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class MailerooConfig:
    api_key: Optional[str]
    sender_email: Optional[str]
    default_recipient_email: Optional[str]
    airflow_base_url: Optional[str]
    api_url: str = "https://smtp.maileroo.com/api/v2/emails"


def _split_recipients(to_email: str) -> list[str]:
    return [e.strip() for e in (to_email or "").split(",") if e.strip()]


class MailerooClient:
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        config = config or {}

        self._config = MailerooConfig(
            api_key=config.get("MAILEROO_API_KEY") or get_var("MAILEROO_API_KEY"),
            sender_email=config.get("SENDER_EMAIL") or get_var("SENDER_EMAIL"),
            default_recipient_email=config.get("DEFAULT_NOTIFICATION_EMAIL")
            or get_var("DEFAULT_NOTIFICATION_EMAIL"),
            airflow_base_url=config.get("AIRFLOW_BASE_URL") or get_var("AIRFLOW_BASE_URL"),
            api_url=config.get("MAILEROO_API_URL") or MailerooConfig.api_url,
        )

        if not self._config.api_key:
            logger.warning("MAILEROO_API_KEY not configured")
        if not self._config.sender_email:
            logger.warning("SENDER_EMAIL not configured")

    def get_dag_run_url(self, context: Dict[str, Any]) -> Optional[str]:
        base_url = self._config.airflow_base_url
        if not base_url:
            return None

        dag_run = context.get("dag_run")
        if not dag_run:
            return None

        try:
            dag_id = dag_run.dag_id
            run_id = dag_run.run_id
        except Exception:
            return None

        return f"{base_url.rstrip('/')}/dags/{dag_id}/grid?dag_run_id={quote(run_id)}"

    def send_success(self, context: Dict[str, Any], recipient: Optional[str] = None) -> None:
        dag_run = context.get("dag_run")
        if not dag_run:
            return

        log_url = self.get_dag_run_url(context)
        log_section = f"\nView logs: {log_url}\n" if log_url else ""

        content = (
            "DAG Run Successful\n\n"
            f"DAG: {dag_run.dag_id}\n"
            f"Run ID: {dag_run.run_id}\n"
            f"Execution Date: {dag_run.execution_date}\n"
            "Status: SUCCESS\n"
            f"{log_section}"
            "---\n"
            f"Sent by Airflow at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        )

        self.send_plain(
            to_email=recipient or self._config.default_recipient_email,
            subject=f"Success: {dag_run.dag_id}",
            content=content,
        )

    def send_failure(
        self,
        context: Dict[str, Any],
        failed_tasks: str,
        recipient: Optional[str] = None,
    ) -> None:
        dag_run = context.get("dag_run")
        if not dag_run:
            return

        log_url = self.get_dag_run_url(context)
        log_section = f"\nView logs: {log_url}\n" if log_url else ""

        content = (
            "DAG Run Failed\n\n"
            f"DAG: {dag_run.dag_id}\n"
            f"Run ID: {dag_run.run_id}\n"
            f"Execution Date: {dag_run.execution_date}\n"
            "Status: FAILED\n"
            f"Failed Tasks: {failed_tasks}\n"
            f"{log_section}"
            "---\n"
            f"Sent by Airflow at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        )

        self.send_plain(
            to_email=recipient or self._config.default_recipient_email,
            subject=f"Failure: {dag_run.dag_id}",
            content=content,
        )

    def _tcp_check(self, host: str, port: int, timeout_seconds: float = 5.0) -> bool:
        try:
            with socket.create_connection((host, port), timeout=timeout_seconds):
                return True
        except Exception:
            return False

    def send_plain(self, to_email: Optional[str], subject: str, content: str) -> None:
        if not to_email:
            logger.info("No recipient email specified. Skipping email.")
            return

        if not self._config.api_key or not self._config.sender_email:
            logger.error("Missing MAILEROO_API_KEY or SENDER_EMAIL. Cannot send email.")
            return

        recipients = _split_recipients(to_email)
        if not recipients:
            logger.error("No valid recipient emails provided.")
            return

        try:
            import requests  # type: ignore
        except Exception as e:
            logger.error("requests not available: %s", e)
            return

        if not self._tcp_check("smtp.maileroo.com", 443):
            logger.warning("Maileroo TCP precheck failed (smtp.maileroo.com:443)")

        headers = {
            "X-API-Key": self._config.api_key,
            "Content-Type": "application/json",
            "Connection": "close",
        }

        payload = {
            "from": {"address": self._config.sender_email, "display_name": "Airflow Notification"},
            "to": [{"address": email} for email in recipients],
            "subject": subject,
            "plain": content,
        }

        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")

        session = requests.Session()
        try:
            resp = session.post(
                self._config.api_url,
                headers=headers,
                data=body,
                timeout=(10, 30),
            )

            if resp.status_code != 200:
                logger.error("Maileroo HTTP %s: %s", resp.status_code, resp.text)
                return

            try:
                data = resp.json()
            except Exception:
                logger.error("Maileroo returned non-JSON body")
                return

            if not data.get("success"):
                logger.error("Maileroo API error: %s", data)
                return

            logger.info("Email sent successfully via Maileroo.")
        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout) as e:
            logger.error("Maileroo request error: %s", e)
        except Exception as e:
            logger.error("Unexpected Maileroo error: %s", e)
        finally:
            try:
                session.close()
            except Exception:
                pass
