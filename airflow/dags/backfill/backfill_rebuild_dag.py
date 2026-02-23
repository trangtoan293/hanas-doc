"""
Backfill Rebuild Pipeline DAG (v2)

This DAG performs data correction using Iceberg branching:
1. Create branches for all target tables
2. Run fix SQL scripts on source data
3. Delete + Rebuild raw vault on branch
4. Delete + Rebuild data mart on branch

After completion, user reviews data then triggers backfill_merge_pipeline.
"""

from __future__ import annotations

import os
import yaml
from datetime import timedelta
from pathlib import Path

import pendulum
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup
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
    "retries": 2,
    "retry_delay": timedelta(seconds=30),
    "catchup": False,
}


with DAG(
    dag_id="backfill_rebuild_pipeline",
    default_args=default_args,
    schedule_interval=None,  # Manual trigger only
    description="Backfill v2: Create branch, fix data, rebuild vault & mart",
    catchup=False,
    max_active_runs=1,
    tags=["backfill", "spark", "dbt", "iceberg-branch"],
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
        
        # Spark dbt job resources
        "backfill_dbt_driver_cores": 3,
        "backfill_dbt_driver_memory": "6g",
        "backfill_dbt_executor_cores": 3,
        "backfill_dbt_executor_memory": "4g",
        "backfill_dbt_executor_instances": 3,
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    
    start = EmptyOperator(task_id="start")
    
    # =========================================================================
    # Phase 1: Create branches for all tables
    # =========================================================================
    create_branches = SparkKubernetesOperator(
        task_id="create_branches",
        namespace=SPARK_CONFIG['namespace'],
        application_file="spark-create-branch.yaml",
        random_name_suffix=True,
        kubernetes_conn_id=SPARK_CONFIG['kubernetes_conn_id'],
    )
    
    # =========================================================================
    # Phase 2: Run fix scripts on source data
    # =========================================================================
    run_fix_scripts = SparkKubernetesOperator(
        task_id="run_fix_scripts",
        namespace=SPARK_CONFIG['namespace'],
        application_file="backfill-spark-sql-fix.yaml",
        random_name_suffix=True,
        kubernetes_conn_id=SPARK_CONFIG['kubernetes_conn_id'],
    )
    
    # =========================================================================
    # Phase 3: Rebuild Raw Vault (on branch)
    # =========================================================================
    with TaskGroup("rebuild_raw_vault") as rebuild_raw_vault:
        
        # Delete vault data on branch
        delete_vault = SparkKubernetesOperator(
            task_id="delete_vault_on_branch",
            namespace=SPARK_CONFIG['namespace'],
            application_file="spark-run-sql.yaml",
            random_name_suffix=True,
            kubernetes_conn_id=SPARK_CONFIG['kubernetes_conn_id'],
            params={
                "sql_file": "sql/delete_vault.sql",
            },
        )
        
        # Rebuild vault with dbt (incremental from start_date)
        rebuild_vault = SparkKubernetesOperator(
            task_id="dbt_run_vault",
            namespace=SPARK_CONFIG['namespace'],
            application_file="spark-dbt-backfill-rawvault-run.yaml",
            random_name_suffix=True,
            kubernetes_conn_id=SPARK_CONFIG['kubernetes_conn_id'],
            params={
                "dbt_select": "tag:hub tag:sat tag:sat_der tag:lnk",
                "dbt_full_refresh": "false",
                "dbt_skip_tests": "true",
                "dbt_vars": f"initial_date: '{BACKFILL_CONFIG['start_date']}'",
            },
        )
        
        delete_vault >> rebuild_vault
    
    # =========================================================================
    # Phase 4: Rebuild Data Mart (on branch)
    # =========================================================================
    with TaskGroup("rebuild_data_mart") as rebuild_data_mart:
        
        # Delete data mart data on branch
        delete_mart = SparkKubernetesOperator(
            task_id="delete_mart_on_branch",
            namespace=SPARK_CONFIG['namespace'],
            application_file="spark-run-sql.yaml",
            random_name_suffix=True,
            kubernetes_conn_id=SPARK_CONFIG['kubernetes_conn_id'],
            params={
                "sql_file": "sql/delete_datamart.sql",
            },
        )
        
        # Rebuild dimensions
        rebuild_dim = SparkKubernetesOperator(
            task_id="dbt_run_dim",
            namespace=SPARK_CONFIG['namespace'],
            application_file="spark-dbt-backfill-datamart-run.yaml",
            random_name_suffix=True,
            kubernetes_conn_id=SPARK_CONFIG['kubernetes_conn_id'],
            params={
                "dbt_select": "dim_branch",
                "dbt_full_refresh": "false",
                "dbt_vars": f"start_date: '{BACKFILL_CONFIG['start_date']}', end_date: '{BACKFILL_CONFIG['end_date']}'",
            },
        )
        
        # Rebuild facts
        rebuild_fact = SparkKubernetesOperator(
            task_id="dbt_run_fact",
            namespace=SPARK_CONFIG['namespace'],
            application_file="spark-dbt-backfill-datamart-run.yaml",
            random_name_suffix=True,
            kubernetes_conn_id=SPARK_CONFIG['kubernetes_conn_id'],
            params={
                "dbt_select": "tag:fact",
                "dbt_exclude": "tag:backdate",
                "dbt_full_refresh": "false",
                "dbt_vars": f"start_date: '{BACKFILL_CONFIG['start_date']}', end_date: '{BACKFILL_CONFIG['end_date']}'",
            },
        )
        
        delete_mart >> rebuild_dim >> rebuild_fact
    
    end = EmptyOperator(task_id="end", trigger_rule="all_done")
    
    # Define task dependencies
    (start >> create_branches >> run_fix_scripts 
     >> rebuild_raw_vault >> rebuild_data_mart >> end)


dag.doc_md = f"""
## Backfill Rebuild Pipeline v2

### Overview
This DAG rebuilds raw vault and data mart on an Iceberg branch for data correction.
Uses **Delete + Incremental** approach (not full refresh) for efficiency.

### Current Configuration
- **Branch Name**: `{get_branch_name()}`
- **Date Range**: `{BACKFILL_CONFIG['start_date']}` → `{BACKFILL_CONFIG['end_date']}`
- **Catalog**: `{CATALOG}`

### Task Flow
1. **create_branches** - Create Iceberg branch for all target tables
2. **run_fix_scripts** - Execute fix SQL on source data
3. **rebuild_raw_vault**
   - Delete vault data >= start_date on branch
   - dbt run incremental (hub, sat, sat_der, lnk)
4. **rebuild_data_mart**
   - Delete mart data >= start_date on branch
   - dbt run dim_branch
   - dbt run fact tables (exclude backdate)

### After Completion
1. Review data on branch using Spark SQL:
   ```sql
   SELECT * FROM LakeHouse.integration.sat_gl.branch_{get_branch_name()} LIMIT 10;
   ```
2. If OK, trigger `backfill_merge_pipeline` to merge branch → main
3. If NOT OK, drop branches and investigate

### Monitoring
```bash
kubectl get sparkapplication -n spark-jobs
kubectl logs -n spark-jobs <pod-name>
```
"""
