from __future__ import annotations

import os
from pathlib import Path
from typing import Optional

from airflow.models import Variable
from airflow.operators.python import PythonVirtualenvOperator
from airflow.utils.task_group import TaskGroup


def _var(name: str, default: Optional[str] = None) -> Optional[str]:
    try:
        value = Variable.get(name)
        return value if value != "" else default
    except KeyError:
        return default


PROJECT_ROOT = str(Path(__file__).resolve().parents[2])


def _publish_dbt_to_datahub(
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
    iceberg_platform_instance: str = "demo",
    dbt_platform_instance: str = "demo",
    skip_dbt_entities: bool = False,
    skip_column_lineage: bool = False,
    asset_tag_name: Optional[str] = None,
) -> dict:
    """
    Publish column lineage to DataHub.
    
    Args:
        skip_dbt_entities: If True, skip dbt source ingestion entirely
            and only publish iceberg-to-iceberg column lineage.
        skip_column_lineage: If True, skip column lineage publishing.
            Default is False (publish lineage). Set to True for /test folders.
        asset_tag_name: If provided, automatically add this tag to all ingested
            datasets.
    """
    import sys

    if project_root and project_root not in sys.path:
        sys.path.insert(0, project_root)

    from utils.datahub_publisher import publish_dbt_to_datahub

    return publish_dbt_to_datahub(
        gms_host=gms_host,
        token=token,
        bucket=bucket,
        prefix=prefix,
        aws_endpoint_url=aws_endpoint,
        aws_region=aws_region,
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key,
        aws_session_token=aws_session_token,
        env=env,
        iceberg_platform_instance=iceberg_platform_instance,
        dbt_platform_instance=dbt_platform_instance,
        skip_dbt_entities=skip_dbt_entities,
        skip_column_lineage=skip_column_lineage,
        asset_tag_name=asset_tag_name,
    )


def _validate_catalog(
    bucket: str,
    prefix: str,
    project_root: Optional[str] = None,
    aws_endpoint: Optional[str] = None,
    aws_region: Optional[str] = None,
    aws_access_key: Optional[str] = None,
    aws_secret_key: Optional[str] = None,
    ca_bundle_path: Optional[str] = None,
    insecure: bool = False,
) -> dict:
    import sys

    if project_root and project_root not in sys.path:
        sys.path.insert(0, project_root)

    import json

    try:
        import boto3
    except ImportError:
        return {"error": "boto3 not available"}

    s3_kwargs = {}
    if aws_endpoint:
        s3_kwargs["endpoint_url"] = aws_endpoint
    if aws_region:
        s3_kwargs["region_name"] = aws_region
    if aws_access_key and aws_secret_key:
        s3_kwargs["aws_access_key_id"] = aws_access_key
        s3_kwargs["aws_secret_access_key"] = aws_secret_key
    verify = True
    if insecure:
        verify = False
    elif ca_bundle_path:
        verify = ca_bundle_path
    s3 = boto3.client("s3", verify=verify, **s3_kwargs)

    key = f"{prefix.strip('/')}/catalog.json"
    print(f"4a5 Checking s3://{bucket}/{key}")

    try:
        response = s3.get_object(Bucket=bucket, Key=key)
        catalog = json.loads(response["Body"].read())

        nodes = catalog.get("nodes", {})
        total = len(nodes)

        with_cols = 0
        without_cols = []

        for node_id, node in nodes.items():
            cols = node.get("columns", {})
            if cols:
                with_cols += 1
            else:
                meta = node.get("metadata", {})
                name = meta.get("name") or node.get("name") or node_id
                without_cols.append(name)

        print("\n4ca Catalog Analysis:")
        print(f"   Total nodes: {total}")
        print(f"   197 With columns: {with_cols}")
        print(f"   6ab Without columns: {total - with_cols}")

        if without_cols:
            print("\n6a0  Nodes missing columns (first 20):")
            for name in without_cols[:20]:
                print(f"   - {name}")
            if len(without_cols) > 20:
                print(f"   ... and {len(without_cols) - 20} more")

        if with_cols == 0:
            print("\n");
            print("CRITICAL: No nodes have column information!")
            print("   dbt docs generate couldn't introspect any tables.")
            print("   Check dbt logs for connectivity issues.")
        elif total - with_cols > 0:
            print("\n")
            print("Partial column data - DataHub will show empty schemas for missing nodes.")
        else:
            print("\n")
            print("All nodes have column information!")

        if total == 0:
            try:
                import tempfile

                man_key = f"{prefix.strip('/')}/manifest.json"
                rr_key = f"{prefix.strip('/')}/run_results.json"
                s3.head_object(Bucket=bucket, Key=man_key)
                s3.head_object(Bucket=bucket, Key=rr_key)
                man_obj = s3.get_object(Bucket=bucket, Key=man_key)
                rr_obj = s3.get_object(Bucket=bucket, Key=rr_key)
                try:
                    from datahub.sql_parsing.sqlglot_lineage import (  # noqa: F401
                        create_lineage_sql_parsed_result,
                    )

                    print(
                        "DataHub SQL parser is AVAILABLE in validate_catalog_completeness venv"
                    )
                except Exception as _e:
                    print(
                        "DataHub SQL parser NOT available in validate_catalog_completeness venv:"
                    )
                    print(_e)
                with tempfile.NamedTemporaryFile(delete=False) as mf:
                    mf.write(man_obj["Body"].read())
                    man_path = mf.name
                with tempfile.NamedTemporaryFile(delete=False) as rf:
                    rf.write(rr_obj["Body"].read())
                    rr_path = rf.name
                with tempfile.NamedTemporaryFile(delete=False) as cf:
                    cat_out_path = cf.name
                try:
                    from utils.dbt_catalog import DbtCatalogBuilder

                    added = int(
                        DbtCatalogBuilder.build_from_manifest_sql(
                            man_path,
                            rr_path,
                            cat_out_path,
                        )
                    )
                finally:
                    try:
                        os.unlink(man_path)
                    except Exception:
                        pass
                    try:
                        os.unlink(rr_path)
                    except Exception:
                        pass
                if added > 0:
                    with open(cat_out_path, "rb") as fh:
                        s3.put_object(Bucket=bucket, Key=key, Body=fh.read())
                    try:
                        with open(cat_out_path, "r", encoding="utf-8") as fh:
                            catalog = json.load(fh)
                    finally:
                        try:
                            os.unlink(cat_out_path)
                        except Exception:
                            pass
                    nodes = catalog.get("nodes", {})
                    total = len(nodes)
                    with_cols = sum(1 for n in nodes.values() if n.get("columns"))
                    print(
                        "Rebuilt catalog.json from manifest SQL with"
                    )
                    print(total)
                    print("nodes and uploaded to")
                    print(f"s3://{bucket}/{key}")
                else:
                    try:
                        os.unlink(cat_out_path)
                    except Exception:
                        pass
                    print("Rebuild produced 0 nodes; leaving catalog.json unchanged")
            except Exception as e:
                print("Rebuild from manifest SQL failed:")
                print(e)

        return {
            "total_nodes": total,
            "nodes_with_columns": with_cols,
            "nodes_without_columns": total - with_cols,
            "missing_nodes_sample": without_cols[:10],
        }
    except Exception as e:
        print("Error reading catalog:")
        print(e)
        return {"error": str(e)}


def _publish_iceberg_to_datahub(
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
    asset_tag_name: Optional[str] = None,
) -> dict:
    import sys

    if project_root and project_root not in sys.path:
        sys.path.insert(0, project_root)

    from utils.datahub_publisher import publish_iceberg_from_catalog

    return publish_iceberg_from_catalog(
        gms_host=gms_host,
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
        asset_tag_name=asset_tag_name,
    )


def _publish_test_results(
    bucket: str,
    prefix: str,
    project_root: Optional[str] = None,
    gms_host: Optional[str] = None,
    token: Optional[str] = None,
    iceberg_platform_instance: str = "demo",
    dbt_platform_instance: str = "demo",
    env: str = "PROD",
    aws_endpoint: Optional[str] = None,
    aws_region: Optional[str] = None,
    aws_access_key: Optional[str] = None,
    aws_secret_key: Optional[str] = None,
    aws_session_token: Optional[str] = None,
) -> dict:
    """Wrapper for PythonVirtualenvOperator to publish test results to DataHub."""
    import sys

    if project_root and project_root not in sys.path:
        sys.path.insert(0, project_root)

    from utils.datahub_publisher import publish_test_results_to_datahub

    return publish_test_results_to_datahub(
        gms_host=gms_host,
        token=token,
        bucket=bucket,
        prefix=prefix,
        iceberg_platform_instance=iceberg_platform_instance,
        dbt_platform_instance=dbt_platform_instance,
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
    artifacts_suffix: str,
    dag=None,
    asset_tag_name: Optional[str] = None,
) -> TaskGroup:
    with TaskGroup(group_id=group_id, dag=dag) as tg:
        extract_dbt_catalog = PythonVirtualenvOperator(
            task_id="extract_dbt_catalog",
            python_callable=_validate_catalog,
            op_kwargs={
                "bucket": _var("DBT_ARTIFACTS_BUCKET", "data") or "data",
                "prefix": prefix_value,
                "project_root": PROJECT_ROOT,
                "aws_endpoint": _var(
                    "AWS_ENDPOINT_URL", "http://192.168.1.151"
                ),
                "aws_region": _var("AWS_DEFAULT_REGION", None),
                "aws_access_key": _var("AWS_ACCESS_KEY_ID", None),
                "aws_secret_key": _var("AWS_SECRET_ACCESS_KEY", None),
                "ca_bundle_path": _var("S3_CA_BUNDLE_PATH", None),
                "insecure": (
                    _var("S3_INSECURE_SKIP_VERIFY", "false") or "false"
                ).lower()
                in {"1", "true", "yes", "y"},
            },
            requirements=[
                "boto3",
                "acryl-datahub[datahub-rest,dbt]",
                "patchy",
            ],
            system_site_packages=False,
            python_version="3.12",
            dag=dag,
        )

        publish_dbt_transformation = PythonVirtualenvOperator(
            task_id="publish_dbt_transformation",
            python_callable=_publish_dbt_to_datahub,
            op_kwargs={
                "bucket": _var("DBT_ARTIFACTS_BUCKET", "data") or "data",
                "prefix": prefix_value,
                "project_root": PROJECT_ROOT,
                "gms_host": _var("DATAHUB_GMS_HOST", "http://192.168.1.173:8080"),
                "token": _var("DATAHUB_TOKEN", ""),
                "aws_endpoint": _var(
                    "AWS_ENDPOINT_URL", "http://192.168.1.151"
                ),
                "aws_region": _var("AWS_DEFAULT_REGION", None),
                "aws_access_key": _var("AWS_ACCESS_KEY_ID", None),
                "aws_secret_key": _var("AWS_SECRET_ACCESS_KEY", None),
                "aws_session_token": _var("AWS_SESSION_TOKEN", None),
                "env": _var("DATAHUB_ENV", "PROD") or "PROD",
                "iceberg_platform_instance": _var("ICEBERG_PLATFORM_INSTANCE", "demo") or "demo",
                "dbt_platform_instance": _var("DBT_PLATFORM_INSTANCE", "demo") or "demo",
                "skip_column_lineage": False,  # Publish lineage for /run folders
                "asset_tag_name": asset_tag_name,
            },
            requirements=[
                "acryl-datahub[datahub-rest,dbt,sql-parsing]",
                "boto3",
                "requests",
            ],
            system_site_packages=False,
            python_version="3.12",
            dag=dag,
            params={
                "artifacts_suffix": artifacts_suffix,
            },
        )

        publish_iceberg_metadata = PythonVirtualenvOperator(
            task_id="publish_iceberg_metadata",
            python_callable=_publish_iceberg_to_datahub,
            op_kwargs={
                "bucket": _var("DBT_ARTIFACTS_BUCKET", "data") or "data",
                "prefix": prefix_value,
                "project_root": PROJECT_ROOT,
                "gms_host": _var("DATAHUB_GMS_HOST", "http://192.168.1.173:8080"),
                "token": _var("DATAHUB_TOKEN", ""),
                "env": _var("DATAHUB_ENV", "PROD") or "PROD",
                "platform_instance": _var(
                    "ICEBERG_PLATFORM_INSTANCE", "demo"
                )
                or "demo",
                "s3_endpoint": _var(
                    "AWS_ENDPOINT_URL", "http://192.168.1.151"
                ),
                "s3_region": _var("AWS_DEFAULT_REGION", None),
                "s3_access_key": _var("AWS_ACCESS_KEY_ID", None),
                "s3_secret_key": _var("AWS_SECRET_ACCESS_KEY", None),
                "s3_session_token": _var("AWS_SESSION_TOKEN", None),
                "include_db": (
                    _var("DATAHUB_INCLUDE_DATABASE_IN_NAME", "false") or "false"
                ).lower()
                in {"1", "true", "yes", "y"},
                "emit_both": (
                    _var("DATAHUB_EMIT_BOTH_NAME_VARIANTS", "false")
                    or "false"
                )
                .lower()
                in {"1", "true", "yes", "y"},
                "asset_tag_name": asset_tag_name,
            },
            requirements=[
                "requests",
                "boto3",
            ],
            system_site_packages=False,
            python_version="3.12",
            dag=dag,
            params={
                "artifacts_suffix": artifacts_suffix,
            },
        )

        extract_dbt_catalog >> publish_dbt_transformation >> publish_iceberg_metadata

    return tg


def create_publish_test_to_datahub_taskgroup(
    *,
    group_id: str = "publish_test",
    prefix_value: str,
    artifacts_suffix: str,
    dag=None,
) -> TaskGroup:
    """
    Lightweight TaskGroup for publishing test results to DataHub.
    
    Only runs dbt source ingestion for test assertions.
    No iceberg metadata publishing (tests don't produce new tables).
    
    Uses /test folder artifacts which contain:
    - manifest.json (with test definitions)
    - run_results.json (with test results)
    """
    with TaskGroup(group_id=group_id, dag=dag) as tg:
        # Only publish dbt transformation (which includes test assertions via dbt source)
        # skip_dbt_entities=False ensures dbt source runs and creates assertions
        publish_dbt_tests = PythonVirtualenvOperator(
            task_id="publish_dbt_tests",
            python_callable=_publish_dbt_to_datahub,
            trigger_rule="all_done",  # Run even if test_job fails
            op_kwargs={
                "bucket": _var("DBT_ARTIFACTS_BUCKET", "data") or "data",
                "prefix": prefix_value,
                "project_root": PROJECT_ROOT,
                "gms_host": _var("DATAHUB_GMS_HOST", "http://192.168.1.173:8080"),
                "token": _var("DATAHUB_TOKEN", ""),
                "aws_endpoint": _var(
                    "AWS_ENDPOINT_URL", "http://192.168.1.151"
                ),
                "aws_region": _var("AWS_DEFAULT_REGION", None),
                "aws_access_key": _var("AWS_ACCESS_KEY_ID", None),
                "aws_secret_key": _var("AWS_SECRET_ACCESS_KEY", None),
                "aws_session_token": _var("AWS_SESSION_TOKEN", None),
                "env": _var("DATAHUB_ENV", "PROD") or "PROD",
                "iceberg_platform_instance": _var("ICEBERG_PLATFORM_INSTANCE", "demo") or "demo",
                "dbt_platform_instance": _var("DBT_PLATFORM_INSTANCE", "demo") or "demo",
                "skip_dbt_entities": False,  # Run dbt source for assertions
                "skip_column_lineage": True,  # Skip column lineage for /test folders
            },
            requirements=[
                "acryl-datahub[datahub-rest,dbt,sql-parsing]",
                "boto3",
                "requests",
            ],
            system_site_packages=False,
            python_version="3.12",
            dag=dag,
            params={
                "artifacts_suffix": artifacts_suffix,
            },
        )

    return tg


def create_unified_publish_to_datahub_taskgroup(
    *,
    group_id: str = "publish_datahub",
    run_prefix_value: str,
    test_prefix_value: str,
    run_artifacts_suffix: str,
    test_artifacts_suffix: str,
    dag=None,
    asset_tag_name: Optional[str] = None,
) -> TaskGroup:
    """
    Unified TaskGroup for publishing both lineage and test results to DataHub.
    
    Combines publish_run and publish_test into a single block with 4 sequential jobs:
    1. extract_dbt_catalog - Validate and rebuild catalog from manifest
    2. publish_dbt_transformation - Publish dbt metadata and lineage
    3. publish_iceberg_metadata - Publish Iceberg table schemas
    4. publish_dbt_tests - Publish test assertions
    
    Args:
        run_prefix_value: S3 prefix for dbt run artifacts
        test_prefix_value: S3 prefix for dbt test artifacts
        run_artifacts_suffix: Suffix for run artifacts folder
        test_artifacts_suffix: Suffix for test artifacts folder
        dag: Airflow DAG
        asset_tag_name: Optional tag to apply to all ingested datasets
    """
    with TaskGroup(group_id=group_id, dag=dag) as tg:
        # 1. Extract/validate dbt catalog (from run artifacts)
        extract_dbt_catalog = PythonVirtualenvOperator(
            task_id="extract_dbt_catalog",
            python_callable=_validate_catalog,
            op_kwargs={
                "bucket": _var("DBT_ARTIFACTS_BUCKET", "data") or "data",
                "prefix": run_prefix_value,
                "project_root": PROJECT_ROOT,
                "aws_endpoint": _var(
                    "AWS_ENDPOINT_URL", "http://192.168.1.151"
                ),
                "aws_region": _var("AWS_DEFAULT_REGION", None),
                "aws_access_key": _var("AWS_ACCESS_KEY_ID", None),
                "aws_secret_key": _var("AWS_SECRET_ACCESS_KEY", None),
                "ca_bundle_path": _var("S3_CA_BUNDLE_PATH", None),
                "insecure": (
                    _var("S3_INSECURE_SKIP_VERIFY", "false") or "false"
                ).lower()
                in {"1", "true", "yes", "y"},
            },
            requirements=[
                "boto3",
                "acryl-datahub[datahub-rest,dbt]",
                "patchy",
            ],
            system_site_packages=False,
            python_version="3.12",
            dag=dag,
        )

        # 2. Publish dbt transformation and lineage (from run artifacts)
        publish_dbt_transformation = PythonVirtualenvOperator(
            task_id="publish_dbt_transformation",
            python_callable=_publish_dbt_to_datahub,
            op_kwargs={
                "bucket": _var("DBT_ARTIFACTS_BUCKET", "data") or "data",
                "prefix": run_prefix_value,
                "project_root": PROJECT_ROOT,
                "gms_host": _var("DATAHUB_GMS_HOST", "http://192.168.1.173:8080"),
                "token": _var("DATAHUB_TOKEN", ""),
                "aws_endpoint": _var(
                    "AWS_ENDPOINT_URL", "http://192.168.1.151"
                ),
                "aws_region": _var("AWS_DEFAULT_REGION", None),
                "aws_access_key": _var("AWS_ACCESS_KEY_ID", None),
                "aws_secret_key": _var("AWS_SECRET_ACCESS_KEY", None),
                "aws_session_token": _var("AWS_SESSION_TOKEN", None),
                "env": _var("DATAHUB_ENV", "PROD") or "PROD",
                "iceberg_platform_instance": _var("ICEBERG_PLATFORM_INSTANCE", "demo") or "demo",
                "dbt_platform_instance": _var("DBT_PLATFORM_INSTANCE", "demo") or "demo",
                "skip_column_lineage": False,
                "asset_tag_name": asset_tag_name,
            },
            requirements=[
                "acryl-datahub[datahub-rest,dbt,sql-parsing]",
                "boto3",
                "requests",
            ],
            system_site_packages=False,
            python_version="3.12",
            dag=dag,
            params={
                "artifacts_suffix": run_artifacts_suffix,
            },
        )

        # 3. Publish Iceberg metadata (from run artifacts)
        publish_iceberg_metadata = PythonVirtualenvOperator(
            task_id="publish_iceberg_metadata",
            python_callable=_publish_iceberg_to_datahub,
            op_kwargs={
                "bucket": _var("DBT_ARTIFACTS_BUCKET", "data") or "data",
                "prefix": run_prefix_value,
                "project_root": PROJECT_ROOT,
                "gms_host": _var("DATAHUB_GMS_HOST", "http://192.168.1.173:8080"),
                "token": _var("DATAHUB_TOKEN", ""),
                "env": _var("DATAHUB_ENV", "PROD") or "PROD",
                "platform_instance": _var("ICEBERG_PLATFORM_INSTANCE", "demo") or "demo",
                "s3_endpoint": _var(
                    "AWS_ENDPOINT_URL", "http://192.168.1.151"
                ),
                "s3_region": _var("AWS_DEFAULT_REGION", None),
                "s3_access_key": _var("AWS_ACCESS_KEY_ID", None),
                "s3_secret_key": _var("AWS_SECRET_ACCESS_KEY", None),
                "s3_session_token": _var("AWS_SESSION_TOKEN", None),
                "include_db": (
                    _var("DATAHUB_INCLUDE_DATABASE_IN_NAME", "false") or "false"
                ).lower()
                in {"1", "true", "yes", "y"},
                "emit_both": (
                    _var("DATAHUB_EMIT_BOTH_NAME_VARIANTS", "false")
                    or "false"
                )
                .lower()
                in {"1", "true", "yes", "y"},
                "asset_tag_name": asset_tag_name,
            },
            requirements=[
                "requests",
                "boto3",
            ],
            system_site_packages=False,
            python_version="3.12",
            dag=dag,
            params={
                "artifacts_suffix": run_artifacts_suffix,
            },
        )

        # 4. Publish dbt test assertions (from test artifacts)
        publish_dbt_tests = PythonVirtualenvOperator(
            task_id="publish_dbt_tests",
            python_callable=_publish_dbt_to_datahub,
            trigger_rule="all_done",  # Run even if previous tasks fail
            op_kwargs={
                "bucket": _var("DBT_ARTIFACTS_BUCKET", "data") or "data",
                "prefix": test_prefix_value,
                "project_root": PROJECT_ROOT,
                "gms_host": _var("DATAHUB_GMS_HOST", "http://192.168.1.173:8080"),
                "token": _var("DATAHUB_TOKEN", ""),
                "aws_endpoint": _var(
                    "AWS_ENDPOINT_URL", "http://192.168.1.151"
                ),
                "aws_region": _var("AWS_DEFAULT_REGION", None),
                "aws_access_key": _var("AWS_ACCESS_KEY_ID", None),
                "aws_secret_key": _var("AWS_SECRET_ACCESS_KEY", None),
                "aws_session_token": _var("AWS_SESSION_TOKEN", None),
                "env": _var("DATAHUB_ENV", "PROD") or "PROD",
                "iceberg_platform_instance": _var("ICEBERG_PLATFORM_INSTANCE", "demo") or "demo",
                "dbt_platform_instance": _var("DBT_PLATFORM_INSTANCE", "demo") or "demo",
                "skip_dbt_entities": False,  # Run dbt source for assertions
                "skip_column_lineage": True,  # Skip column lineage for tests
            },
            requirements=[
                "acryl-datahub[datahub-rest,dbt,sql-parsing]",
                "boto3",
                "requests",
            ],
            system_site_packages=False,
            python_version="3.12",
            dag=dag,
            params={
                "artifacts_suffix": test_artifacts_suffix,
            },
        )

        # Sequential flow: catalog -> transformation -> iceberg -> tests
        extract_dbt_catalog >> publish_dbt_transformation >> publish_iceberg_metadata >> publish_dbt_tests

    return tg
