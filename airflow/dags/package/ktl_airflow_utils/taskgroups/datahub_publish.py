from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, Optional

from airflow.operators.python import PythonVirtualenvOperator
from airflow.utils.task_group import TaskGroup

from ..airflow_vars import get_var, get_bool_var


def _publish_dbt_to_datahub(
    *,
    bucket: str,
    prefix: str,
    project_root: Optional[str] = None,
    gms_host: Optional[str] = None,
    token: Optional[str] = None,
    aws_endpoint: Optional[str] = None,
    aws_region: Optional[str] = None,
    aws_access_key: Optional[str] = None,
    aws_secret_key: Optional[str] = None,
    aws_session_token: Optional[str] = None,
    env: str = "PROD",
    platform_instance: str = "demo",
) -> Dict[str, Any]:
    import sys

    if project_root and project_root not in sys.path:
        sys.path.insert(0, project_root)

    from package.ktl_airflow_utils.datahub.publishers import publish_dbt_to_datahub

    return publish_dbt_to_datahub(
        gms_host=gms_host or "",
        token=token,
        bucket=bucket,
        prefix=prefix,
        aws_endpoint_url=aws_endpoint,
        aws_region=aws_region,
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key,
        aws_session_token=aws_session_token,
        env=env,
        target_platform_instance=platform_instance,
    )


def _publish_iceberg_to_datahub(
    *,
    bucket: str,
    prefix: str,
    project_root: Optional[str] = None,
    gms_host: Optional[str] = None,
    token: Optional[str] = None,
    env: str = "PROD",
    platform_instance: str = "LakeHouse",
    s3_endpoint: Optional[str] = None,
    s3_region: Optional[str] = None,
    s3_access_key: Optional[str] = None,
    s3_secret_key: Optional[str] = None,
    s3_session_token: Optional[str] = None,
    include_db: bool = True,
    emit_both: bool = False,
) -> Dict[str, Any]:
    import sys

    if project_root and project_root not in sys.path:
        sys.path.insert(0, project_root)

    from package.ktl_airflow_utils.datahub.publishers import publish_iceberg_from_catalog

    return publish_iceberg_from_catalog(
        gms_host=gms_host or "",
        token=token,
        bucket=bucket,
        prefix=prefix,
        env=env,
        platform_instance=platform_instance,
        include_database_in_name=bool(include_db),
        emit_both_name_variants=bool(emit_both),
        aws_endpoint_url=s3_endpoint,
        aws_region=s3_region,
        aws_access_key_id=s3_access_key,
        aws_secret_access_key=s3_secret_key,
        aws_session_token=s3_session_token,
    )


def _publish_test_results(
    *,
    bucket: str,
    prefix: str,
    project_root: Optional[str] = None,
    gms_host: Optional[str] = None,
    token: Optional[str] = None,
    platform: str = "iceberg",
    platform_instance: str = "demo",
    env: str = "PROD",
    aws_endpoint: Optional[str] = None,
    aws_region: Optional[str] = None,
    aws_access_key: Optional[str] = None,
    aws_secret_key: Optional[str] = None,
    aws_session_token: Optional[str] = None,
) -> Dict[str, Any]:
    import sys

    if project_root and project_root not in sys.path:
        sys.path.insert(0, project_root)

    from package.ktl_airflow_utils.datahub.publishers import publish_test_results_to_datahub

    return publish_test_results_to_datahub(
        gms_host=gms_host or "",
        token=token,
        bucket=bucket,
        prefix=prefix,
        platform=platform,
        platform_instance=platform_instance,
        env=env,
        aws_endpoint_url=aws_endpoint,
        aws_region=aws_region,
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key,
        aws_session_token=aws_session_token,
    )


def create_publish_to_datahub_taskgroup(
    *,
    group_id: str = "publish_to_datahub",
    prefix_value: str,
    dag=None,
    python_version: str = "3.12",
    requirements_dbt: Optional[list[str]] = None,
    requirements_iceberg: Optional[list[str]] = None,
    requirements_tests: Optional[list[str]] = None,
) -> TaskGroup:
    project_root = str(Path(__file__).resolve().parents[3])

    def _default_reqs(base: list[str]) -> list[str]:
        return base

    requirements_dbt = requirements_dbt or _default_reqs(
        [
            "acryl-datahub[datahub-rest,dbt]",
            "boto3",
            "requests",
        ]
    )
    requirements_iceberg = requirements_iceberg or _default_reqs(
        [
            "boto3",
            "requests",
        ]
    )
    requirements_tests = requirements_tests or _default_reqs(
        [
            "boto3",
            "requests",
        ]
    )

    bucket = get_var("DBT_ARTIFACTS_BUCKET", "data") or "data"

    with TaskGroup(group_id=group_id, dag=dag) as tg:
        publish_dbt_transformation = PythonVirtualenvOperator(
            task_id="publish_dbt_transformation",
            python_callable=_publish_dbt_to_datahub,
            op_kwargs={
                "bucket": bucket,
                "prefix": prefix_value,
                "project_root": project_root,
                "gms_host": get_var("DATAHUB_GMS_HOST", None),
                "token": get_var("DATAHUB_TOKEN", ""),
                "aws_endpoint": get_var("AWS_ENDPOINT_URL", None),
                "aws_region": get_var("AWS_DEFAULT_REGION", None),
                "aws_access_key": get_var("AWS_ACCESS_KEY_ID", None),
                "aws_secret_key": get_var("AWS_SECRET_ACCESS_KEY", None),
                "aws_session_token": get_var("AWS_SESSION_TOKEN", None),
                "env": get_var("DATAHUB_ENV", "PROD") or "PROD",
                "platform_instance": get_var("DATAHUB_PLATFORM_INSTANCE", "demo")
                or "demo",
            },
            requirements=requirements_dbt,
            system_site_packages=False,
            python_version=python_version,
            dag=dag,
        )

        publish_iceberg_metadata = PythonVirtualenvOperator(
            task_id="publish_iceberg_metadata",
            python_callable=_publish_iceberg_to_datahub,
            op_kwargs={
                "bucket": bucket,
                "prefix": prefix_value,
                "project_root": project_root,
                "gms_host": get_var("DATAHUB_GMS_HOST", None),
                "token": get_var("DATAHUB_TOKEN", ""),
                "env": get_var("DATAHUB_ENV", "PROD") or "PROD",
                "platform_instance": get_var(
                    "DATAHUB_ICEBERG_PLATFORM_INSTANCE", "LakeHouse"
                )
                or "LakeHouse",
                "s3_endpoint": get_var("AWS_ENDPOINT_URL", None),
                "s3_region": get_var("AWS_DEFAULT_REGION", None),
                "s3_access_key": get_var("AWS_ACCESS_KEY_ID", None),
                "s3_secret_key": get_var("AWS_SECRET_ACCESS_KEY", None),
                "s3_session_token": get_var("AWS_SESSION_TOKEN", None),
                "include_db": get_bool_var(
                    "DATAHUB_INCLUDE_DATABASE_IN_NAME", True
                ),
                "emit_both": get_bool_var(
                    "DATAHUB_EMIT_BOTH_NAME_VARIANTS", False
                ),
            },
            requirements=requirements_iceberg,
            system_site_packages=False,
            python_version=python_version,
            dag=dag,
        )

        publish_test_results = PythonVirtualenvOperator(
            task_id="publish_test_results",
            python_callable=_publish_test_results,
            trigger_rule="all_done",
            op_kwargs={
                "bucket": bucket,
                "prefix": prefix_value,
                "project_root": project_root,
                "gms_host": get_var("DATAHUB_GMS_HOST", None),
                "token": get_var("DATAHUB_TOKEN", ""),
                "platform": "iceberg",
                "platform_instance": get_var("DATAHUB_PLATFORM_INSTANCE", "demo")
                or "demo",
                "env": get_var("DATAHUB_ENV", "PROD") or "PROD",
                "aws_endpoint": get_var("AWS_ENDPOINT_URL", None),
                "aws_region": get_var("AWS_DEFAULT_REGION", None),
                "aws_access_key": get_var("AWS_ACCESS_KEY_ID", None),
                "aws_secret_key": get_var("AWS_SECRET_ACCESS_KEY", None),
                "aws_session_token": get_var("AWS_SESSION_TOKEN", None),
            },
            requirements=requirements_tests,
            system_site_packages=False,
            python_version=python_version,
            dag=dag,
        )

        publish_dbt_transformation >> [publish_test_results, publish_iceberg_metadata]

    return tg
