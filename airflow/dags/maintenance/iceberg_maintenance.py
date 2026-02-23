"""
Iceberg Table Maintenance DAG

This DAG performs maintenance operations on Apache Iceberg tables:
1. **Compaction (rewrite_data_files)**: Merges small files into larger ones for better query performance
2. **Snapshot Expiration (expire_snapshots)**: Removes old snapshots to reclaim storage space
3. **Orphan File Cleanup (remove_orphan_files)**: Removes files not referenced by any snapshot
4. **Rewrite Manifests (rewrite_manifests)**: Consolidates manifest files after cleanup

Business Context:
- Addresses "Maintenance Time" requirement from technical RFP (Item 1)
- Prevents query performance degradation due to small file accumulation
- Controls storage costs by cleaning up expired data
- Should run during low-traffic periods (e.g., 4 AM daily)

Error Handling (Graceful Failure):
- Uses --soft-fail flag: if one table fails, the job continues to process remaining tables
- Individual table failures are logged but don't fail the Airflow task
- Expire/orphan steps run with trigger_rule=all_done to continue after upstream issues
- Skip flags short-circuit only the targeted step
- Check Spark logs for detailed error information on specific tables

Configuration:
- Tables to maintain are configured via Airflow Variables or DAG params
- Snapshot retention period defaults to 7 days
- Compaction target file size defaults to 512MB
- Orphan cleanup retains files for at least 3 days

Dependencies:
- Requires Spark operator running on Kubernetes
- Requires Hive Metastore connectivity
- Requires MinIO/S3 access for Iceberg tables

Airflow Variables:
  * iceberg_default_catalog         -> Default catalog to maintain when targets is empty (required)
  * iceberg_snapshot_retention_days -> Number of days to retain snapshots (default: 7)
  * iceberg_target_file_size_mb    -> Target file size in MB for compaction (default: 512)
"""

from __future__ import annotations

import os
from datetime import timedelta
from typing import List, Optional

import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.models.param import Param
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator, get_current_context
from airflow.exceptions import AirflowSkipException

from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)


def _var(key: str, default: str = "") -> str:
    value = Variable.get(key, default_var=default)
    return str(value).strip() if value is not None else ""


# Configuration
SNAPSHOT_RETENTION_DAYS = int(_var("iceberg_snapshot_retention_days", "7") or "7")
TARGET_FILE_SIZE_MB = int(_var("iceberg_target_file_size_mb", "512") or "512")
ORPHAN_RETENTION_DAYS = int(_var("iceberg_orphan_retention_days", "3") or "3")


class _SkipAwareSparkKubernetesOperator(SparkKubernetesOperator):
    def __init__(self, *, skip_param: str, **kwargs):
        self.skip_param = skip_param
        super().__init__(**kwargs)

    def execute(self, context):
        params = context.get("params") or {}
        if params.get(self.skip_param, False):
            raise AirflowSkipException(f"Skipped because `{self.skip_param}` is true")
        return super().execute(context)


def _build_runner_params() -> dict:
    context = get_current_context()
    params = context.get("params") or {}

    targets_raw = params.get("targets")
    targets = str(targets_raw or "").strip()

    default_catalog = ""
    if not targets:
        default_catalog = _var("iceberg_default_catalog") or ""
        if not default_catalog:
            raise ValueError(
                "DAG param `targets` is empty. "
                "Airflow Variable `iceberg_default_catalog` must be set."
            )

    execution_date = (
        context.get("execution_date")
        or context.get("logical_date")
        or pendulum.now("UTC")
    )
    reference_ts = execution_date.in_timezone("UTC").isoformat()

    return {
        "targets": targets,
        "default_catalog": default_catalog,
        "reference_timestamp": reference_ts,
    }


# Default arguments for the DAG
default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2024, 1, 1, tz="UTC"),
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=10),
    "catchup": False,
    "tags": ["iceberg", "maintenance", "compaction", "spark"],
}


# Create the DAG
with DAG(
    dag_id="iceberg_maintenance",
    default_args=default_args,
    schedule_interval="0 4 * * *",  # Run daily at 4 AM UTC
    description="Iceberg table maintenance: compaction, snapshot expiration, orphan cleanup, rewrite manifests",
    doc_md=__doc__,
    catchup=False,
    max_active_runs=1,
    tags=["iceberg", "maintenance", "compaction", "kubernetes"],
    params={
        "targets": Param(
            default=None,
            type=["string", "null"],
            description="Targets to maintain (JSON list or comma-separated): catalog.* | catalog.schema.* | catalog.schema.table. If empty, all tables in iceberg_default_catalog are maintained."
        ),
        "target_file_size_mb": Param(
            default=TARGET_FILE_SIZE_MB,
            type="integer",
            description="Compaction target file size in MB (default from iceberg_target_file_size_mb)."
        ),
        "snapshot_retention_days": Param(
            default=SNAPSHOT_RETENTION_DAYS,
            type="integer",
            description="Days to retain snapshots (default from iceberg_snapshot_retention_days)."
        ),
        "orphan_retention_days": Param(
            default=ORPHAN_RETENTION_DAYS,
            type="integer",
            description="Only remove orphan files older than this many days."
        ),
        "skip_compaction": Param(
            default=False,
            type="boolean",
            description="Skip the compaction step"
        ),
        "skip_expire_snapshots": Param(
            default=False,
            type="boolean",
            description="Skip the expire snapshots step"
        ),
        "skip_orphan_cleanup": Param(
            default=False,
            type="boolean",
            description="Skip the orphan file cleanup step"
        ),
        "skip_rewrite_manifests": Param(
            default=False,
            type="boolean",
            description="Skip the rewrite manifests step"
        ),
        "enable_tuning": Param(
            default=False,
            type="boolean",
            description="Enable Spark performance monitoring"
        ),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:

    # Start and end markers
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end", trigger_rule="all_done")

    build_runner_params = PythonOperator(
        task_id="build_runner_params",
        python_callable=_build_runner_params,
        do_xcom_push=True,
    )

    compaction = _SkipAwareSparkKubernetesOperator(
        task_id="compaction",
        namespace="spark-jobs",
        application_file="spark-sql-runner.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        skip_param="skip_compaction",
        params={
            "runner_params_task_id": "build_runner_params",
            "operation": "compaction",
        },
        dag=dag,
    )

    expire_snapshots = _SkipAwareSparkKubernetesOperator(
        task_id="expire_snapshots",
        namespace="spark-jobs",
        application_file="spark-sql-runner.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        trigger_rule="all_done",
        skip_param="skip_expire_snapshots",
        params={
            "runner_params_task_id": "build_runner_params",
            "operation": "expire_snapshots",
        },
        dag=dag,
    )

    orphan_cleanup = _SkipAwareSparkKubernetesOperator(
        task_id="orphan_cleanup",
        namespace="spark-jobs",
        application_file="spark-sql-runner.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        trigger_rule="all_done",
        skip_param="skip_orphan_cleanup",
        params={
            "runner_params_task_id": "build_runner_params",
            "operation": "orphan_cleanup",
        },
        dag=dag,
    )

    rewrite_manifests = _SkipAwareSparkKubernetesOperator(
        task_id="rewrite_manifests",
        namespace="spark-jobs",
        application_file="spark-sql-runner.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        trigger_rule="all_done",
        skip_param="skip_rewrite_manifests",
        params={
            "runner_params_task_id": "build_runner_params",
            "operation": "rewrite_manifests",
        },
        dag=dag,
    )

    # Define task dependencies
    # Compaction -> Expire Snapshots -> Remove Orphans -> Rewrite Manifests
    # This order ensures:
    # 1. Files are first compacted into larger ones
    # 2. Old snapshots are removed (which may reference old small files)
    # 3. Orphan files (no longer referenced) are cleaned up
    # 4. Manifest files are consolidated after cleanup
    start >> build_runner_params >> compaction >> expire_snapshots >> orphan_cleanup >> rewrite_manifests >> end


# DAG Documentation
_DOC_TEMPLATE = """
# DAG `iceberg_maintenance`

## Purpose
Perform routine maintenance operations on Apache Iceberg tables to ensure optimal performance and storage efficiency.

## Operations

### 1. Compaction (`rewrite_data_files`)
- **What it does**: Merges small data files into larger ones
- **Why**: Prevents "small file problem" which degrades query performance
- **Target file size**: __TARGET_SIZE__MB
- **Impact during execution**: Slight increase in I/O, but queries remain available

### 2. Snapshot Expiration (`expire_snapshots`)
- **What it does**: Removes snapshots older than __RETENTION__ days
- **Why**: Frees up storage by allowing old data files to be deleted
- **Safety**: Always retains at least 2 snapshots for recovery

### 3. Orphan File Cleanup (`remove_orphan_files`)
- **What it does**: Deletes data files not referenced by any snapshot
- **Why**: Reclaims storage from files left behind after failures or manual operations
- **Safety**: Only removes files older than __ORPHAN_RETENTION__ days

### 4. Rewrite Manifests (`rewrite_manifests`)
- **What it does**: Rewrites manifest files for faster planning
- **Why**: Consolidates manifest metadata after cleanup steps

## Scheduling
- **Schedule**: Daily at 4:00 AM UTC
- **Max Concurrent Runs**: 1
- **Catchup**: Disabled

## Configuration

### Airflow Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `iceberg_default_catalog` | (required if `targets` is empty) | Default catalog to maintain |
| `iceberg_snapshot_retention_days` | 7 | Days to retain snapshots |
| `iceberg_target_file_size_mb` | 512 | Target compacted file size |
| `iceberg_orphan_retention_days` | 3 | Days to keep orphan files |

### DAG Parameters (for manual runs)
| Parameter | Type | Description |
|-----------|------|-------------|
| `targets` | string | Patterns for discovery: `catalog.*`, `catalog.schema.*`, or `catalog.schema.table` |
| `target_file_size_mb` | integer | Override compaction target file size |
| `snapshot_retention_days` | integer | Override snapshot retention days |
| `orphan_retention_days` | integer | Override orphan cleanup retention |
| `skip_compaction` | boolean | Skip compaction step |
| `skip_expire_snapshots` | boolean | Skip snapshot expiration |
| `skip_orphan_cleanup` | boolean | Skip orphan file cleanup |
| `skip_rewrite_manifests` | boolean | Skip rewrite manifests |
| `enable_tuning` | boolean | Enable Spark performance monitoring |

## Troubleshooting

### Compaction fails with OOM
- Reduce `executor.memory` in spark-sql-runner.yaml
- Or process fewer tables per run

### Expire snapshots fails
- Check that the table exists and is accessible
- Verify Hive Metastore connectivity

### Orphan cleanup takes too long
- This is normal for large tables with many files
- Consider running less frequently (weekly instead of daily)
"""

dag.doc_md = (
    _DOC_TEMPLATE
    .replace("__TARGET_SIZE__", str(TARGET_FILE_SIZE_MB))
    .replace("__RETENTION__", str(SNAPSHOT_RETENTION_DAYS))
    .replace("__ORPHAN_RETENTION__", str(ORPHAN_RETENTION_DAYS))
)
