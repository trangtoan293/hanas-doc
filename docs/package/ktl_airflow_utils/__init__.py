from __future__ import annotations

from package.ktl_airflow_utils.airflow_vars import get_var, get_bool_var, get_json_var
from package.ktl_airflow_utils.maileroo import MailerooClient
from package.ktl_airflow_utils.callbacks import (
    on_failure_callback,
    on_success_callback,
    on_retry_callback,
    get_task_info,
)

__all__ = [
    # Airflow variables
    "get_var",
    "get_bool_var",
    "get_json_var",
    # Maileroo
    "MailerooClient",
    # Callbacks
    "on_failure_callback",
    "on_success_callback",
    "on_retry_callback",
    "get_task_info",
]
