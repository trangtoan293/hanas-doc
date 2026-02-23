"""
Backdate ETL Pipeline DAG.

This DAG performs the following steps:
1. Creates the backdate table in Iceberg format using Spark
2. Creates 3 views in Dremio DATA_MART space via API
3. Creates raw reflections for the views  for query optimization

Configuration is loaded from backdate/config/backdate_config.yaml
"""

from __future__ import annotations

import os
import yaml
from datetime import timedelta
from pathlib import Path

import pendulum
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)
from airflow.models import Variable

# Import Dremio client from local utils folder
# Add current directory to Python path for imports
import sys
dag_dir = Path(__file__).parent
if str(dag_dir) not in sys.path:
    sys.path.insert(0, str(dag_dir))

from utils.dremio_client import DremioClient


# Load configuration from YAML
config_path = Path(__file__).parent / "config" / "backdate_config.yaml"
with open(config_path, 'r') as f:
    config = yaml.safe_load(f)

# Extract config values
DATE_CONFIG = config['date_range']
VIEWS_CONFIG = config['views']

# Load Dremio config from Airflow Variables
DREMIO_CONFIG = {
    'base_url': Variable.get('dremio_host', default_var='http://192.168.1.193:9047') + ':9047',
    'username': Variable.get('dremio_username', default_var='vaultadmin'),
    'password': Variable.get('dremio_password'),
    'ssl_verify': Variable.get('dremio_ssl_verify', default_var='false').lower() == 'true',
    'space': Variable.get('dremio_space', default_var='DATA_MART')
}


def create_dremio_views(**context):
    """Create views in Dremio using API."""
    import logging
    logger = logging.getLogger(__name__)
    
    # Initialize Dremio client
    client = DremioClient(
        base_url=DREMIO_CONFIG['base_url'],
        username=DREMIO_CONFIG['username'],
        password=DREMIO_CONFIG['password'],
        ssl_verify=DREMIO_CONFIG['ssl_verify']
    )
    
    try:
        # Login to Dremio
        client.login()
        
        # Create each view
        sql_dir = Path(__file__).parent / "sql"
        
        for view_config in VIEWS_CONFIG:
            view_name = view_config['name']
            sql_file = view_config['sql_file']
            
            # Read SQL file
            sql_path = sql_dir / sql_file
            with open(sql_path, 'r') as f:
                sql = f.read()
            
            logger.info(f"Creating view {view_name} in space {DREMIO_CONFIG['space']}")
            
            # Create or update view
            result = client.create_vds(
                space=DREMIO_CONFIG['space'],
                view_name=view_name,
                sql=sql
            )
            
            logger.info(f"Successfully created/updated view {view_name}")
            
            # Store dataset ID for reflection creation
            context['ti'].xcom_push(key=f'{view_name}_id', value=result['id'])
            
    finally:
        client.close()


def create_dremio_reflections(**context):
    """Create raw reflections for all views."""
    import logging
    logger = logging.getLogger(__name__)
    
    # Initialize Dremio client
    client = DremioClient(
        base_url=DREMIO_CONFIG['base_url'],
        username=DREMIO_CONFIG['username'],
        password=DREMIO_CONFIG['password'],
        ssl_verify=DREMIO_CONFIG['ssl_verify']
    )
    
    try:
        # Login to Dremio
        client.login()
        
        # Create reflection for each view
        for view_config in VIEWS_CONFIG:
            view_name = view_config['name']
            
            # Get dataset ID from XCom
            dataset_id = context['ti'].xcom_pull(key=f'{view_name}_id')
            
            if dataset_id:
                logger.info(f"Creating raw reflection for {view_name}")
                client.create_raw_reflection(
                    dataset_id=dataset_id,
                    display_columns=None  # Display all columns
                )
                logger.info(f"Successfully created reflection for {view_name}")
            else:
                logger.warning(f"No dataset ID found for {view_name}, skipping reflection creation")
                
    finally:
        client.close()


default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2024, 1, 1, tz="UTC"),
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(seconds=30),
    "catchup": False,
    "tags": ["backdate", "etl", "dremio", "iceberg"],
}


with DAG(
    dag_id="backdate_etl_pipeline",
    default_args=default_args,
    schedule_interval=None,  # Manual trigger only
    description="Backdate ETL pipeline: table creation, view creation, and reflection setup",
    catchup=False,
    max_active_runs=1,
    tags=["backdate", "spark", "dremio"],
    params={
        "start_date": DATE_CONFIG['start_date'],
        "end_date": DATE_CONFIG['end_date'],
        "sql_file": "/opt/spark/sql/create_backdate_table.sql",
        "backdate_sql_driver_cores": 3,
        "backdate_sql_driver_memory": "6g",
        "backdate_sql_executor_cores": 3,
        "backdate_sql_executor_memory": "4g",
        "backdate_sql_executor_instances": 3,
        "backdate_dbt_driver_cores": 2,
        "backdate_dbt_driver_memory": "4g",
        "backdate_dbt_executor_cores": 2,
        "backdate_dbt_executor_memory": "3g",
        "backdate_dbt_executor_instances": 2,
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    
    start = EmptyOperator(task_id="start")
    
    # Task 1: Create backdate table using Spark
    create_backdate_table = SparkKubernetesOperator(
        task_id="create_backdate_table",
        namespace="spark-jobs",
        application_file="backdate-spark-job.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
        params={
            "sql_file": "/opt/spark/sql/create_backdate_table.sql",
            "start_date": "{{ params.start_date }}",
            "end_date": "{{ params.end_date }}"
        },
    )
    
    # Task 2: Run dbt backdate models
    run_dbt_backdate_models = SparkKubernetesOperator(
        task_id="run_dbt_backdate_models",
        namespace="spark-jobs",
        application_file="spark-dbt-backdate-run.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
    )
    
    # Task 3: Create Dremio views
    create_views = PythonOperator(
        task_id="create_dremio_views",
        python_callable=create_dremio_views,
        provide_context=True,
    )
    
    # Task 4: Create Dremio reflections
    create_reflections = PythonOperator(
        task_id="create_dremio_reflections",
        python_callable=create_dremio_reflections,
        provide_context=True,
    )
    
    end = EmptyOperator(task_id="end", trigger_rule="all_done")
    
    # Define task dependencies
    start >> create_backdate_table >> run_dbt_backdate_models >> end


dag.doc_md = """
## Backdate ETL Pipeline

### Overview
This DAG creates a backdate data flow by:
1. Creating `landing.gl_poc_backdate` table in Iceberg format
2. Running dbt models to create 6 data_mart backdate tables (detail + summary for PL/DP/LN)
3. Creating 6 views in Dremio DATA_MART space:
   - FACT_PL_DETAIL_BACKDATE & FACT_PL_SUMMARY_BACKDATE (Profit & Loss)
   - FACT_DP_DETAIL_BACKDATE & FACT_DP_SUMMARY_BACKDATE (Deposits)
   - FACT_LN_DETAIL_BACKDATE & FACT_LN_SUMMARY_BACKDATE (Loans)
4. Creating raw reflections for query optimization

### Configuration
- **Config file**: `backdate/config/backdate_config.yaml`
- **Start date**: {start_date}
- **End date**: {end_date}
- **Dremio space**: DATA_MART
- **Dremio API**: http://10.10.101.54:9047/api/v3

### Task Flow
1. **start** - Entry point
2. **create_backdate_table** - Spark job to drop/create Iceberg landing table
3. **run_dbt_backdate_models** - Spark dbt job to build 6 data_mart backdate models
4. **create_dremio_views** - Python task to create 6 views via Dremio API
5. **create_dremio_reflections** - Python task to create raw reflections
6. **end** - Exit point

### Monitoring
- **Airflow UI**: Check task logs for each step
- **Dremio UI**: http://dremio.hanas.local/ - Verify views and reflections in DATA_MART space
- **Kubernetes**:
  ```bash
  kubectl get sparkapplication -n spark-jobs
  kubectl logs -n spark-jobs <pod-name>
  ```

### Parameters
Parameters available on the DAG run configuration form:

- `start_date`: Start date (inclusive) for the backdate range.
- `end_date`: End date (inclusive) for the backdate range.

Backdate SQL Spark job resource parameters (`backdate-spark-job.yaml`):

- `backdate_sql_driver_cores`: Number of CPU cores requested for the Spark driver (default: 3).
- `backdate_sql_driver_memory`: Memory allocated to the Spark driver (default: `"6g"`).
- `backdate_sql_executor_cores`: Number of CPU cores requested per executor (default: 3).
- `backdate_sql_executor_memory`: Memory allocated per executor (default: `"4g"`).
- `backdate_sql_executor_instances`: Number of executor instances (default: 3).

Backdate dbt Spark job resource parameters (`spark-dbt-backdate-run.yaml`):

- `backdate_dbt_driver_cores`: Number of CPU cores requested for the Spark driver (default: 2).
- `backdate_dbt_driver_memory`: Memory allocated to the Spark driver (default: `"4g"`).
- `backdate_dbt_executor_cores`: Number of CPU cores requested per executor (default: 2).
- `backdate_dbt_executor_memory`: Memory allocated per executor (default: `"3g"`).
- `backdate_dbt_executor_instances`: Number of executor instances (default: 2).
""".format(
    start_date=DATE_CONFIG['start_date'],
    end_date=DATE_CONFIG['end_date']
)
