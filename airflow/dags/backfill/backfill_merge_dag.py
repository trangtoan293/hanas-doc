"""
Backfill Merge Pipeline DAG

This DAG merges Iceberg branches back to main after user review.
Should only be triggered AFTER backfill_rebuild_pipeline completes
and user has validated the data on branches.

Tasks:
1. Merge all branches to main
2. Drop all branches (cleanup)
"""

from __future__ import annotations

import os
import yaml
from datetime import timedelta
from pathlib import Path

import pendulum
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)


# Load configuration
config_path = Path(__file__).parent / "config" / "backfill_config.yaml"
with open(config_path, 'r') as f:
    config = yaml.safe_load(f)

# Extract config values
BACKFILL_CONFIG = config['backfill']
CATALOG = config['catalog']['name']
SPARK_CONFIG = config['spark']


def get_branch_name():
    """Generate branch name from config."""
    start_date = BACKFILL_CONFIG['start_date'].replace('-', '')
    end_date = BACKFILL_CONFIG['end_date'].replace('-', '')
    return f"{BACKFILL_CONFIG['branch_name_prefix']}_{start_date}_{end_date}"


default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2024, 1, 1, tz="UTC"),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(seconds=30),
    "catchup": False,
}


with DAG(
    dag_id="backfill_merge_pipeline",
    default_args=default_args,
    schedule_interval=None,  # Manual trigger ONLY
    description="Merge Iceberg branches to main after user review",
    catchup=False,
    max_active_runs=1,
    tags=["backfill", "spark", "iceberg-branch", "merge"],
    params={
        # Backfill parameters
        "start_date": BACKFILL_CONFIG['start_date'],
        "end_date": BACKFILL_CONFIG['end_date'],
        "branch_name": get_branch_name(),
        "catalog": CATALOG,
        
        # Spark SQL job resources
        "backfill_sql_driver_cores": 2,
        "backfill_sql_driver_memory": "4g",
        "backfill_sql_executor_cores": 2,
        "backfill_sql_executor_memory": "3g",
        "backfill_sql_executor_instances": 2,
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    
    start = EmptyOperator(task_id="start")
    
    # =========================================================================
    # Task 1: Merge all branches to main
    # =========================================================================
    merge_branches = SparkKubernetesOperator(
        task_id="merge_all_branches",
        namespace=SPARK_CONFIG['namespace'],
        application_file="spark-run-sql.yaml",
        random_name_suffix=True,
        kubernetes_conn_id=SPARK_CONFIG['kubernetes_conn_id'],
        params={
            "sql_file": "sql/merge_branch.sql",
        },
    )
    
    # =========================================================================
    # Task 2: Drop all branches (cleanup)
    # =========================================================================
    drop_branches = SparkKubernetesOperator(
        task_id="drop_all_branches",
        namespace=SPARK_CONFIG['namespace'],
        application_file="spark-run-sql.yaml",
        random_name_suffix=True,
        kubernetes_conn_id=SPARK_CONFIG['kubernetes_conn_id'],
        params={
            "sql_file": "sql/drop_branch.sql",
        },
    )
    
    end = EmptyOperator(task_id="end")
    
    # Define task dependencies
    start >> merge_branches >> drop_branches >> end


dag.doc_md = f"""
## Backfill Merge Pipeline

### ⚠️ WARNING
This DAG merges Iceberg branches to main. This action is **IRREVERSIBLE**.
Make sure to validate data on branches before triggering.

### Current Configuration
- **Branch Name**: `{get_branch_name()}`
- **Catalog**: `{CATALOG}`

### Pre-requisites
1. `backfill_rebuild_pipeline` completed successfully
2. Data on branch validated by user

### Validation Commands
```sql
-- Check data on branch
SELECT COUNT(*) FROM LakeHouse.integration.sat_gl.branch_{get_branch_name()};

-- Compare with main
SELECT 
    'main' as source, COUNT(*) as cnt FROM LakeHouse.integration.sat_gl
UNION ALL
SELECT 
    'branch' as source, COUNT(*) as cnt 
    FROM LakeHouse.integration.sat_gl.branch_{get_branch_name()};
```

### Task Flow
1. **merge_all_branches** - Merge all branches to main
2. **drop_all_branches** - Drop all branches (cleanup)

### Rollback
If merge fails partway through, some tables may be merged while others are not.
Check branch status and re-run merge for remaining tables.
"""
