"""
Backfill ETL Pipeline DAG.

This DAG performs data correction for gl_poc_streaming source table:
1. Fix DR_CR_FLG that was incorrectly swapped between 'D' and 'C'
2. Delete old raw vault data (sat_gl, sat_snp_gl) from start_date
3. Rebuild raw vault tables using dbt incremental
4. Rebuild data mart backfill fact tables

Configuration is loaded from backfill/config/backfill_config.yaml
"""

from __future__ import annotations

import os
import yaml
import json
from datetime import timedelta
from pathlib import Path

import pendulum
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)
from airflow.models import Variable


# Load configuration from YAML
config_path = Path(__file__).parent / "config" / "backfill_config.yaml"
with open(config_path, 'r') as f:
    config = yaml.safe_load(f)

# Extract config values
DATE_CONFIG = config['date_range']
RAW_VAULT_CONFIG = config['dbt_raw_vault']
DATA_MART_CONFIG = config['dbt_data_mart']


default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2024, 1, 1, tz="UTC"),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(seconds=30),
    "catchup": False,
    "tags": ["backfill", "data-correction", "etl"],
}


with DAG(
    dag_id="backfill_etl_pipeline",
    default_args=default_args,
    schedule_interval=None,  # Manual trigger only
    description="Backfill ETL pipeline: fix source data, rebuild raw vault and data mart",
    catchup=False,
    max_active_runs=1,
    tags=["backfill", "spark", "dbt"],
    params={
        # Date parameters
        "start_date": DATE_CONFIG['start_date'],
        "end_date": DATE_CONFIG['end_date'],
        
        # dbt parameters
        "dbt_schema": "integration",
        
        # SQL Spark job resource parameters
        "backfill_sql_driver_cores": 3,
        "backfill_sql_driver_memory": "6g",
        "backfill_sql_executor_cores": 3,
        "backfill_sql_executor_memory": "4g",
        "backfill_sql_executor_instances": 3,
        
        # dbt Spark job resource parameters
        "backfill_dbt_driver_cores": 2,
        "backfill_dbt_driver_memory": "4g",
        "backfill_dbt_executor_cores": 2,
        "backfill_dbt_executor_memory": "3g",
        "backfill_dbt_executor_instances": 2,
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    
    start = EmptyOperator(task_id="start")
    
    # Task 1: Fix DR_CR_FLG in source table
    fix_dr_cr_flag = SparkKubernetesOperator(
        task_id="fix_dr_cr_flag",
        namespace="spark-jobs",
        application_file="backfill-spark-sql-fix.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
    )
    
    # Task 2: Delete old raw vault data from start_date
    # NOTE: This is a placeholder for future incremental logic
    # Currently using --full-refresh, so this step can be skipped
    # TODO: Update to use EOD_DATE-based incremental when ktl_autovault supports it
    delete_raw_vault_data = SparkKubernetesOperator(
        task_id="delete_raw_vault_data",
        namespace="spark-jobs",
        application_file="backfill-spark-sql-delete.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
    )
    
    # Task 3: Rebuild raw vault tables using dbt full-refresh
    # Use --full-refresh since incre_start_date filters by DV_LDT, not EOD_DATE
    raw_vault_models = " ".join(RAW_VAULT_CONFIG['models'])
    
    rebuild_raw_vault = SparkKubernetesOperator(
        task_id="rebuild_raw_vault",
        namespace="spark-jobs",
        application_file="spark-dbt-backfill-rawvault-run.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
        params={
            "dbt_select": raw_vault_models,
            "dbt_full_refresh": "true",  # Use full-refresh instead of incremental
            "dbt_skip_tests": "true",  # Skip tests for backfill (relationship tests may fail)
            "dbt_schema": "integration",
        },
    )
    
    # Task 4: Rebuild data mart backfill tables
    data_mart_models = " ".join(DATA_MART_CONFIG['models'])
    # Use YAML format for vars to avoid curly braces breaking YAML parsing
    dbt_vars_data_mart = f"backfill_start_date: '{DATE_CONFIG['start_date']}'"
    
    rebuild_data_mart = SparkKubernetesOperator(
        task_id="rebuild_data_mart",
        namespace="spark-jobs",
        application_file="spark-dbt-backfill-datamart-run.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
        params={
            "dbt_select": data_mart_models,
            "dbt_vars": dbt_vars_data_mart,
            "dbt_schema": "backfill",
        },
    )
    
    end = EmptyOperator(task_id="end", trigger_rule="all_done")
    
    # Define task dependencies
    start >> fix_dr_cr_flag >> delete_raw_vault_data >> rebuild_raw_vault >> rebuild_data_mart >> end


dag.doc_md = """
## Backfill ETL Pipeline

### Overview
This DAG performs data correction for `gl_poc_streaming` source table where `DR_CR_FLG` was incorrectly swapped between 'D' and 'C' from {start_date} to {end_date}.

### Task Flow
1. **fix_dr_cr_flag** - UPDATE gl_poc_streaming to swap DR_CR_FLG back
2. **delete_raw_vault_data** - DELETE from sat_gl, sat_snp_gl where EOD_DATE >= start_date
3. **rebuild_raw_vault** - dbt build sat_gl sat_snp_gl with incremental from start_date
4. **rebuild_data_mart** - dbt build backfill fact tables from start_date to current

### Parameters
- `start_date`: Start date for data fix and rebuild (default: {start_date})
- `end_date`: End date for source data fix only (default: {end_date})

### Notes
- `sat_snp_gl_sbv` is NOT affected (uses different source: gl_sbv_streaming)
- Data mart fact tables are cumulative, so rebuild from start_date to current_date
- Raw vault uses Option B: Delete + Incremental (not full-refresh)

### Monitoring
```bash
kubectl get sparkapplication -n spark-jobs
kubectl logs -n spark-jobs <pod-name>
```
""".format(
    start_date=DATE_CONFIG['start_date'],
    end_date=DATE_CONFIG['end_date']
)
