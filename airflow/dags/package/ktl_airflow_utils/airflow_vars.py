from __future__ import annotations

import json
import os
from typing import Any, Optional


def _get_airflow_variable(name: str) -> Optional[str]:
    try:
        from airflow.models import Variable  # type: ignore

        value = Variable.get(name)
        if value == "":
            return None
        return str(value)
    except Exception:
        return None


def get_var(name: str, default: Optional[str] = None) -> Optional[str]:
    value = _get_airflow_variable(name)
    if value is not None:
        return value

    env_value = os.environ.get(name)
    if env_value is not None and env_value != "":
        return env_value

    return default


def get_bool_var(name: str, default: bool = False) -> bool:
    raw = get_var(name, None)
    if raw is None:
        return bool(default)
    return str(raw).strip().lower() in {"1", "true", "yes", "y", "on"}


def get_json_var(name: str, default: Any) -> Any:
    raw = get_var(name, None)
    if raw is None:
        return default
    try:
        return json.loads(raw)
    except Exception:
        return default
