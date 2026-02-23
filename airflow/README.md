# 🚀 Enterprise Airflow Best Practices Guide

**Version:** 2.0  
**Last Updated:** June 2025  
**Target:** Data Engineering & AI Teams  

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Repository Structure](#-repository-structure)
3. [Naming Conventions](#-naming-conventions)
4. [DAG Development Standards](#-dag-development-standards)
5. [Configuration Management](#-configuration-management)
6. [Testing Guidelines](#-testing-guidelines)
7. [Deployment Process](#-deployment-process)
8. [Monitoring & Alerting](#-monitoring--alerting)
9. [Security & Governance](#-security--governance)
10. [Troubleshooting](#-troubleshooting)
11. [Resources & Training](#-resources--training)

---

## 🎯 Project Overview

Đây là hướng dẫn chuẩn hóa cho việc phát triển và triển khai Apache Airflow workflows tại enterprise scale. Tài liệu này giúp data team xây dựng pipelines có tính:

- **Scalability** - Dễ dàng mở rộng
- **Maintainability** - Dễ bảo trì và debug
- **Reliability** - Ổn định và fault-tolerant
- **Security** - Tuân thủ security standards
- **Governance** - Có thể audit và monitor

### 🏗️ Architecture Overview

```mermaid
graph TB
    A[Data Sources] --> B[Ingestion Layer]
    B --> C[Processing Layer]
    C --> D[Storage Layer]
    D --> E[Analytics/ML Layer]
    
    subgraph "Airflow Components"
        F[Scheduler]
        G[Webserver]
        H[Workers]
        I[Metadata DB]
    end
    
    B -.-> F
    C -.-> F
    D -.-> F
    E -.-> F
```

---

## 📁 Repository Structure

### Multi-Repository Strategy

Mỗi domain/team có repository riêng biệt:

```
enterprise-data-platform/
├── data-engineering/          # Core data pipelines
├── ml-ops/                   # ML training & inference
├── analytics/                # Business intelligence
├── shared-components/        # Common operators & utilities
└── infrastructure/           # Airflow configs & deployment
```

### Individual Project Structure

```
project-name/
├── dags/
│   ├── __init__.py
│   ├── ingestion/
│   │   ├── __init__.py
│   │   ├── api_ingestion_dag.py
│   │   └── database_sync_dag.py
│   ├── processing/
│   │   ├── data_transformation_dag.py
│   │   └── feature_engineering_dag.py
│   ├── ml_workflows/
│   │   ├── model_training_dag.py
│   │   └── batch_inference_dag.py
│   └── .airflowignore
├── plugins/
│   ├── __init__.py
│   ├── operators/
│   │   ├── custom_spark_operator.py
│   │   ├── data_quality_operator.py
│   │   └── ml_model_operator.py
│   ├── hooks/
│   │   ├── custom_api_hook.py
│   │   ├── mlflow_hook.py
│   │   └── warehouse_hook.py
│   ├── sensors/
│   │   ├── data_availability_sensor.py
│   │   └── model_performance_sensor.py
│   └── utils/
│       ├── data_quality_checks.py
│       ├── notification_helpers.py
│       └── metric_collectors.py
├── include/
│   ├── sql/
│   │   ├── transformations/
│   │   └── data_quality/
│   ├── configs/
│   │   ├── dev.yaml
│   │   ├── staging.yaml
│   │   └── prod.yaml
│   ├── schemas/
│   │   ├── source_schemas.json
│   │   └── target_schemas.json
│   └── templates/
├── tests/
│   ├── __init__.py
│   ├── unit/
│   │   ├── test_operators.py
│   │   └── test_hooks.py
│   ├── integration/
│   │   └── test_dags.py
│   └── fixtures/
│       └── sample_data.json
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   └── troubleshooting.md
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── .gitignore
└── README.md
```

---

## 🏷️ Naming Conventions

### File & Directory Naming

| Component | Pattern | Example |
|-----------|---------|---------|
| DAG Files | `{domain}_{process}_{version}_dag.py` | `finance_daily_reconciliation_v2_dag.py` |
| Operator Files | `{purpose}_operator.py` | `spark_etl_operator.py` |
| Hook Files | `{service}_hook.py` | `snowflake_hook.py` |
| Config Files | `{env}.yaml` | `production.yaml` |
| Test Files | `test_{component}.py` | `test_data_quality_operator.py` |

### DAG & Task Naming

```python
# DAG ID Convention
dag_id = f"{DOMAIN}_{ENVIRONMENT}_{PROCESS}_{VERSION}"
# Example: "ml_ops_prod_model_training_v3"

# Task ID Convention  
task_id = f"{action}_{object}_{sequence}"
# Examples:
# - "extract_customer_data_01"
# - "transform_features_02"  
# - "train_model_03"
# - "validate_predictions_04"
```

### Variable & Connection Naming

```python
# Airflow Variables
VAR_NAME = "{ENV}_{DOMAIN}_{PURPOSE}"
# Examples:
# - "PROD_ML_MODEL_BUCKET"
# - "DEV_FINANCE_DATABASE_URL"

# Airflow Connections
CONN_ID = "{env}_{service}_{purpose}"
# Examples:
# - "prod_snowflake_warehouse"
# - "dev_s3_data_lake"
```

---

## 🔧 DAG Development Standards

### DAG Template Structure

```python
"""
DAG: {DAG Name}
Description: {Purpose and business logic}
Owner: {Team/Individual}
Schedule: {Cron expression}
Dependencies: {External systems or upstream DAGs}

Business Context:
- {Key business requirements}
- {SLA requirements}
- {Data sources and targets}
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup
from plugins.operators.custom_operator import CustomOperator
from plugins.utils.notification_helpers import send_failure_notification

# Configuration
from include.configs.config_loader import load_config
config = load_config()

# Default arguments
default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'on_failure_callback': send_failure_notification,
}

# DAG Definition
dag = DAG(
    dag_id='domain_env_process_v1',
    default_args=default_args,
    description='Brief description of the workflow',
    schedule_interval='@daily',
    catchup=False,
    max_active_runs=1,
    tags=['domain', 'priority-high', 'team-data-eng'],
    doc_md=__doc__,
)

# Task Groups for better organization
with dag:
    with TaskGroup('data_ingestion') as ingestion_group:
        # Ingestion tasks here
        pass
    
    with TaskGroup('data_processing') as processing_group:
        # Processing tasks here  
        pass
    
    with TaskGroup('data_quality') as quality_group:
        # Quality checks here
        pass
    
    # Define dependencies
    ingestion_group >> processing_group >> quality_group
```

### Task Design Principles

#### 1. **Atomicity**
```python
# ❌ Bad: Multiple operations in one task
def bad_etl_task():
    extract_data()
    transform_data()  
    load_data()
    send_notification()

# ✅ Good: Separate atomic tasks
extract_task = PythonOperator(task_id='extract_data', ...)
transform_task = PythonOperator(task_id='transform_data', ...)
load_task = PythonOperator(task_id='load_data', ...)
notify_task = PythonOperator(task_id='send_notification', ...)
```

#### 2. **Idempotency**
```python
# ✅ Good: Idempotent task design
def idempotent_data_load(**context):
    execution_date = context['execution_date']
    
    # Use upsert instead of insert
    query = f"""
    MERGE INTO target_table t
    USING source_data s
    ON t.id = s.id AND t.date = '{execution_date}'
    WHEN MATCHED THEN UPDATE SET ...
    WHEN NOT MATCHED THEN INSERT ...
    """
```

#### 3. **Error Handling**
```python
def robust_task(**context):
    try:
        # Main business logic
        result = process_data()
        
        # Data quality validation
        if not validate_data_quality(result):
            raise ValueError("Data quality check failed")
            
        return result
        
    except Exception as e:
        # Log detailed error information
        logger.error(f"Task failed: {str(e)}")
        
        # Send notification with context
        send_error_notification(
            error=str(e),
            context=context,
            dag_id=context['dag'].dag_id,
            task_id=context['task'].task_id
        )
        raise
```

### Dynamic DAG Generation

```python
# configs/dag_configs.yaml
dags:
  - name: "customer_data_pipeline"
    schedule: "0 2 * * *"
    source_tables: ["customers", "orders", "products"]
    target_schema: "analytics"
    
  - name: "sales_data_pipeline"  
    schedule: "0 3 * * *"
    source_tables: ["sales", "transactions"]
    target_schema: "reporting"

# dag_factory.py
def create_etl_dag(dag_config):
    dag = DAG(
        dag_id=dag_config['name'],
        schedule_interval=dag_config['schedule'],
        **default_args
    )
    
    for table in dag_config['source_tables']:
        # Create tasks dynamically
        extract_task = create_extract_task(table)
        transform_task = create_transform_task(table)
        load_task = create_load_task(table, dag_config['target_schema'])
        
        extract_task >> transform_task >> load_task
    
    return dag

# Generate DAGs from config
for dag_config in load_dag_configs():
    globals()[dag_config['name']] = create_etl_dag(dag_config)
```

---

## ⚙️ Configuration Management

### Environment-Based Configuration

```yaml
# include/configs/production.yaml
database:
  warehouse:
    host: "prod-warehouse.company.com"
    database: "analytics"
    schema: "core"
    
storage:
  data_lake:
    bucket: "prod-data-lake"
    prefix: "raw-data/"
    
ml_models:
  model_registry: "prod-mlflow.company.com"
  experiment_tracking: true
  
notifications:
  slack_webhook: "{{ var.value.PROD_SLACK_WEBHOOK }}"
  email_alerts: ["data-team@company.com"]
  
monitoring:
  metrics_endpoint: "{{ var.value.PROD_METRICS_ENDPOINT }}"
  log_level: "INFO"
```

### Configuration Loader

```python
# include/configs/config_loader.py
import os
import yaml
from airflow.models import Variable

def load_config(env=None):
    """Load environment-specific configuration"""
    if env is None:
        env = Variable.get("ENVIRONMENT", default_var="dev")
    
    config_path = f"/opt/airflow/include/configs/{env}.yaml"
    
    with open(config_path, 'r') as file:
        config = yaml.safe_load(file)
    
    # Replace template variables
    config = replace_template_vars(config)
    
    return config

def replace_template_vars(config):
    """Replace Airflow variables in config"""
    import json
    config_str = json.dumps(config)
    
    # Replace {{ var.value.VAR_NAME }} patterns
    # Implementation depends on your templating needs
    
    return json.loads(config_str)
```

### Secrets Management

```python
# Use Airflow Connections for sensitive data
from airflow.hooks.base import BaseHook

def get_database_connection():
    """Get database connection from Airflow Connections"""
    conn = BaseHook.get_connection('prod_warehouse_conn')
    return {
        'host': conn.host,
        'port': conn.port,
        'username': conn.login,
        'password': conn.password,
        'database': conn.schema
    }

# ❌ Never do this
DATABASE_PASSWORD = "hardcoded_password"  # NEVER!

# ✅ Use Airflow Variables for non-sensitive config
MODEL_BUCKET = Variable.get("PROD_ML_MODEL_BUCKET")

# ✅ Use Connections for sensitive data
db_conn = BaseHook.get_connection('warehouse_connection')
```

---

## 🧪 Testing Guidelines

### Unit Testing

```python
# tests/unit/test_data_quality_operator.py
import pytest
from unittest.mock import Mock, patch
from plugins.operators.data_quality_operator import DataQualityOperator

class TestDataQualityOperator:
    
    @pytest.fixture
    def operator(self):
        return DataQualityOperator(
            task_id='test_data_quality',
            table_name='test_table',
            quality_checks=[
                {'check': 'not_null', 'column': 'id'},
                {'check': 'unique', 'column': 'email'}
            ]
        )
    
    def test_execute_success(self, operator):
        """Test successful data quality check"""
        context = {'execution_date': '2024-01-01'}
        
        with patch.object(operator, 'run_quality_checks') as mock_check:
            mock_check.return_value = {'passed': True, 'failed_checks': []}
            
            result = operator.execute(context)
            
            assert result['status'] == 'passed'
            mock_check.assert_called_once()
    
    def test_execute_failure(self, operator):
        """Test failed data quality check"""
        context = {'execution_date': '2024-01-01'}
        
        with patch.object(operator, 'run_quality_checks') as mock_check:
            mock_check.return_value = {
                'passed': False, 
                'failed_checks': ['null_check_failed']
            }
            
            with pytest.raises(ValueError):
                operator.execute(context)
```

### Integration Testing

```python
# tests/integration/test_dags.py
import pytest
from airflow.models import DagBag
from airflow.utils.dag_cycle import check_cycle

class TestDAGIntegrity:
    
    def setup_method(self):
        self.dagbag = DagBag()
    
    def test_no_import_errors(self):
        """Test that all DAGs load without import errors"""
        assert len(self.dagbag.import_errors) == 0, \
            f"DAG import failures: {self.dagbag.import_errors}"
    
    def test_no_cycles(self):
        """Test that DAGs don't have cycles"""
        for dag_id, dag in self.dagbag.dags.items():
            check_cycle(dag)
    
    def test_dag_tags(self):
        """Test that all DAGs have required tags"""
        required_tags = ['team', 'priority']
        
        for dag_id, dag in self.dagbag.dags.items():
            dag_tags = dag.tags or []
            
            for required_tag in required_tags:
                assert any(tag.startswith(required_tag) for tag in dag_tags), \
                    f"DAG {dag_id} missing required tag pattern: {required_tag}"
    
    @pytest.mark.parametrize("dag_id", ["finance_daily_reconciliation_v2"])
    def test_specific_dag_structure(self, dag_id):
        """Test specific DAG requirements"""
        dag = self.dagbag.get_dag(dag_id)
        
        assert dag is not None
        assert dag.catchup is False
        assert dag.max_active_runs == 1
        assert len(dag.task_dict) > 0
```

### Data Pipeline Testing

```python
# tests/integration/test_data_pipeline.py
import pytest
from airflow.models import TaskInstance
from airflow.utils.state import State
from datetime import datetime

class TestDataPipeline:
    
    @pytest.fixture
    def execution_date(self):
        return datetime(2024, 1, 1)
    
    def test_end_to_end_pipeline(self, execution_date):
        """Test complete data pipeline execution"""
        
        # Setup test data
        self.setup_test_data()
        
        # Run DAG
        dag = self.dagbag.get_dag('data_processing_pipeline')
        dag.run(execution_date=execution_date, ignore_dependencies=True)
        
        # Verify results
        self.verify_pipeline_output(execution_date)
        
        # Cleanup
        self.cleanup_test_data()
    
    def setup_test_data(self):
        """Setup test data in source systems"""
        # Create test data in databases, file systems, etc.
        pass
    
    def verify_pipeline_output(self, execution_date):
        """Verify pipeline produced expected outputs"""
        # Check output data quality, completeness, etc.
        pass
    
    def cleanup_test_data(self):
        """Clean up test data"""
        pass
```

---

## 🚀 Deployment Process

### CI/CD Pipeline

```yaml
# .github/workflows/airflow-ci-cd.yml
name: Airflow CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov
      
      - name: Run linting
        run: |
          flake8 dags/ plugins/ tests/
          black --check dags/ plugins/ tests/
      
      - name: Run unit tests
        run: |
          pytest tests/unit/ -v --cov=plugins
      
      - name: Run DAG validation
        run: |
          python -m pytest tests/integration/test_dags.py -v
      
      - name: Security scan
        run: |
          bandit -r dags/ plugins/
  
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to production
        run: |
          # Your deployment script here
          ./scripts/deploy.sh prod
```

### Environment Promotion

```bash
#!/bin/bash
# scripts/deploy.sh

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

echo "Deploying to $ENVIRONMENT environment..."

# Validate DAGs
echo "Validating DAGs..."
python -m pytest tests/integration/test_dags.py

# Deploy based on environment
case $ENVIRONMENT in
    "dev")
        echo "Deploying to development..."
        # Copy files to dev Airflow instance
        ;;
    "staging")
        echo "Deploying to staging..."
        # Copy files to staging Airflow instance
        ;;
    "prod")
        echo "Deploying to production..."
        # Copy files to production Airflow instance
        # Additional production validations
        ;;
    *)
        echo "Unknown environment: $ENVIRONMENT"
        exit 1
        ;;
esac

echo "Deployment completed successfully!"
```

### Deployment Checklist

#### Pre-Deployment
- [ ] All tests pass
- [ ] Code review completed
- [ ] Security scan passed
- [ ] Configuration updated
- [ ] Documentation updated
- [ ] Rollback plan prepared

#### Deployment
- [ ] Deploy to staging first
- [ ] Validate in staging environment
- [ ] Deploy to production
- [ ] Verify DAGs are loaded correctly
- [ ] Check scheduler is processing DAGs

#### Post-Deployment
- [ ] Monitor DAG executions
- [ ] Check error logs
- [ ] Validate data pipeline outputs
- [ ] Confirm alerting is working
- [ ] Update deployment documentation

---

## 📊 Monitoring & Alerting

### Key Metrics to Monitor

```python
# plugins/utils/metric_collectors.py
from airflow.models import DagRun, TaskInstance
from airflow.utils.state import State
import logging

class AirflowMetricsCollector:
    
    def collect_dag_metrics(self, dag_id, days=7):
        """Collect DAG performance metrics"""
        
        # Success rate
        total_runs = DagRun.find(dag_id=dag_id, 
                                execution_date_gte=days_ago(days))
        successful_runs = [run for run in total_runs 
                          if run.state == State.SUCCESS]
        success_rate = len(successful_runs) / len(total_runs) if total_runs else 0
        
        # Average duration
        durations = [run.end_date - run.start_date 
                    for run in successful_runs if run.end_date]
        avg_duration = sum(durations, timedelta()) / len(durations) if durations else timedelta()
        
        # SLA misses
        sla_misses = TaskInstance.find(
            dag_id=dag_id,
            execution_date_gte=days_ago(days),
            state=State.UP_FOR_RETRY
        )
        
        return {
            'dag_id': dag_id,
            'success_rate': success_rate,
            'avg_duration': avg_duration,
            'sla_misses': len(sla_misses),
            'total_runs': len(total_runs)
        }
```

### Alerting Configuration

```python
# plugins/utils/notification_helpers.py
import requests
import json
from airflow.models import Variable

def send_failure_notification(context):
    """Send notification when DAG/Task fails"""
    
    dag_id = context['dag'].dag_id
    task_id = context['task'].task_id
    execution_date = context['execution_date']
    exception = context.get('exception')
    
    message = {
        'text': f"🚨 Airflow Alert - Task Failed",
        'blocks': [
            {
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': f"*DAG:* {dag_id}\n*Task:* {task_id}\n*Execution Date:* {execution_date}\n*Error:* {str(exception)}"
                }
            },
            {
                'type': 'actions',
                'elements': [
                    {
                        'type': 'button',
                        'text': {'type': 'plain_text', 'text': 'View in Airflow'},
                        'url': f"{Variable.get('AIRFLOW_BASE_URL')}/graph?dag_id={dag_id}"
                    }
                ]
            }
        ]
    }
    
    # Send to Slack
    slack_webhook = Variable.get('SLACK_WEBHOOK_URL')
    requests.post(slack_webhook, json=message)
    
    # Send to monitoring system
    send_to_monitoring_system({
        'alert_type': 'task_failure',
        'dag_id': dag_id,
        'task_id': task_id,
        'timestamp': execution_date,
        'severity': 'high'
    })

def send_sla_miss_notification(dag, task_list, blocking_task_list, slas, blocking_tis):
    """Handle SLA miss notifications"""
    
    message = f"SLA Miss: DAG {dag.dag_id} has missed SLA"
    
    # Detailed SLA miss information
    details = {
        'dag_id': dag.dag_id,
        'missed_tasks': [task.task_id for task in task_list],
        'blocking_tasks': [task.task_id for task in blocking_task_list],
        'sla_time': str(slas[0]) if slas else None
    }
    
    # Send notification
    send_critical_alert(message, details)
```

### Custom Dashboard

```python
# plugins/operators/metrics_operator.py
from airflow import DAG
from airflow.operators.python import PythonOperator
from plugins.utils.metric_collectors import AirflowMetricsCollector

def collect_and_send_metrics(**context):
    """Collect Airflow metrics and send to monitoring system"""
    
    collector = AirflowMetricsCollector()
    
    # Get all active DAGs
    dag_ids = [dag_id for dag_id in context['dag_bag'].dag_ids]
    
    metrics = []
    for dag_id in dag_ids:
        dag_metrics = collector.collect_dag_metrics(dag_id)
        metrics.append(dag_metrics)
    
    # Send to monitoring system (Grafana, Datadog, etc.)
    send_metrics_to_monitoring_system(metrics)
    
    # Generate daily report
    generate_daily_report(metrics)

# DAG for metrics collection
metrics_dag = DAG(
    'airflow_metrics_collection',
    schedule_interval='@daily',
    catchup=False
)

collect_metrics_task = PythonOperator(
    task_id='collect_airflow_metrics',
    python_callable=collect_and_send_metrics,
    dag=metrics_dag
)
```

---

## 🔒 Security & Governance

### Access Control

```yaml
# RBAC Configuration
roles:
  data_engineer:
    permissions:
      - can_read_dag
      - can_edit_dag
      - can_trigger_dag
      - can_read_task_instance
      - can_clear_task_instance
    
  data_analyst:
    permissions:
      - can_read_dag
      - can_read_task_instance
      - can_read_task_log
    
  admin:
    permissions:
      - all_permissions

users:
  - username: "john.doe@company.com"
    role: "data_engineer"
    teams: ["data-platform"]
  
  - username: "jane.smith@company.com" 
    role: "data_analyst"
    teams: ["analytics"]
```

### Code Review Guidelines

#### Mandatory Review Checklist

- [ ] **Security**: No hardcoded credentials or sensitive data
- [ ] **Performance**: No heavy computations in DAG top-level code  
- [ ] **Idempotency**: Tasks can be safely re-run
- [ ] **Error Handling**: Proper exception handling and logging
- [ ] **Documentation**: Clear docstrings and comments
- [ ] **Testing**: Unit tests for custom operators/hooks
- [ ] **Naming**: Follows naming conventions
- [ ] **Dependencies**: Proper task dependencies defined

#### Review Template

```markdown
## Code Review Checklist

### Security & Compliance
- [ ] No hardcoded secrets or credentials
- [ ] Proper use of Airflow Connections and Variables
- [ ] No PII/sensitive data in logs
- [ ] Follows data governance policies

### Performance & Scalability  
- [ ] No expensive operations in DAG definition
- [ ] Proper resource allocation (memory, CPU)
- [ ] Efficient data processing patterns
- [ ] Appropriate retry and timeout settings

### Code Quality
- [ ] Clear and descriptive naming
- [ ] Proper error handling
- [ ] Adequate logging and monitoring
- [ ] Code follows team standards

### Testing & Documentation
- [ ] Unit tests for custom components
- [ ] Integration tests where applicable  
- [ ] Clear documentation and comments
- [ ] README updated if needed

### Comments
[Reviewer comments here]
```

### Audit & Compliance

```python
# plugins/utils/audit_logger.py
import json
from datetime import datetime
from airflow.models import Variable
from airflow.hooks.base import BaseHook

class AuditLogger:
    
    def log_data_access(self, user, dataset, operation, context=None):
        """Log data access for audit purposes"""
        
        audit_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'user': user,
            'dataset': dataset,
            'operation': operation,
            'context': context or {},
            'dag_id': context.get('dag', {}).get('dag_id') if context else None,
            'task_id': context.get('task', {}).get('task_id') if context else None
        }
        
        # Send to audit log storage
        self._send_to_audit_storage(audit_entry)
    
    def log_model_deployment(self, model_name, version, deployer, environment):
        """Log ML model deployment for compliance"""
        
        deployment_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': 'model_deployment',
            'model_name': model_name,
            'model_version': version,
            'deployed_by': deployer,
            'environment': environment,
            'compliance_check': True
        }
        
        self._send_to_audit_storage(deployment_entry)
    
    def _send_to_audit_storage(self, entry):
        """Send audit entry to storage system"""
        
        # Send to centralized logging system
        audit_endpoint = Variable.get('AUDIT_LOG_ENDPOINT')
        
        # Implementation depends on your audit system
        # (Elasticsearch, Splunk, AWS CloudTrail, etc.)
        pass
```

---

## 🔧 Troubleshooting

### Common Issues & Solutions

#### 1. **DAG Import Errors**

```bash
# Check DAG import errors
airflow dags list-import-errors

# Test DAG parsing locally
python /path/to/your/dag.py
```

**Common Causes:**
- Missing imports or dependencies
- Syntax errors in DAG definition
- Circular imports
- Missing environment variables

**Solutions:**
```python
# Add proper error handling in DAG files
try:
    from custom_module import CustomOperator
except ImportError as e:
    # Graceful fallback or clear error message
    raise ImportError(f"Failed to import CustomOperator: {e}")

# Validate required variables exist
required_vars = ['DATABASE_URL', 'API_KEY']
for var in required_vars:
    if not Variable.get(var, default_var=None):
        raise ValueError(f"Required Airflow Variable '{var}' not found")
```

#### 2. **Task Stuck in Running State**

**Diagnosis:**
```bash
# Check task instances
airflow tasks list <dag_id> --state running

# Check worker logs
docker logs airflow-worker

# Check for zombie processes
airflow celery flower  # If using Celery executor
```

**Solutions:**
- Increase task timeout settings
- Check worker resource availability
- Verify database connections
- Clear stuck task instances: `airflow tasks clear <dag_id> <task_id>`

#### 3. **Memory Issues**

**Symptoms:**
- Tasks getting killed unexpectedly
- Worker pods restarting (in Kubernetes)
- Out of Memory errors in logs

**Solutions:**
```python
# Set appropriate resource limits
task = PythonOperator(
    task_id='memory_intensive_task',
    python_callable=process_large_dataset,
    pool='high_memory_pool',  # Use resource pools
    executor_config={
        'KubernetesExecutor': {
            'request_memory': '4Gi',
            'limit_memory': '8Gi'
        }
    }
)

# Process data in chunks
def process_large_dataset():
    chunk_size = 10000
    for chunk in pd.read_csv('large_file.csv', chunksize=chunk_size):
        process_chunk(chunk)
        # Clear memory
        del chunk
```

#### 4. **DAG Not Scheduling**

**Check:**
- DAG is not paused: `airflow dags unpause <dag_id>`
- Start date is in the past
- Schedule interval is valid
- Catchup setting is appropriate

```python
# Debug scheduling
from airflow.models import DagModel
dag_model = DagModel.get_dagmodel('<dag_id>')
print(f"Is paused: {dag_model.is_paused}")
print(f"Next dagrun: {dag_model.next_dagrun}")
```

#### 5. **Connection Issues**

```bash
# Test connections
airflow connections test <connection_id>

# List all connections
airflow connections list

# Add connection via CLI
airflow connections add 'my_conn' \
    --conn-type 'postgres' \
    --conn-host 'localhost' \
    --conn-login 'user' \
    --conn-password 'password' \
    --conn-schema 'schema'
```

### Debugging Tools

#### 1. **DAG Testing**

```python
# Test DAG locally
import sys
sys.path.append('/opt/airflow')

from dags.my_dag import dag
from airflow.utils.dag_cycle import check_cycle

# Check for cycles
check_cycle(dag)

# Test task execution
from airflow.models import TaskInstance
from datetime import datetime

ti = TaskInstance(
    task=dag.get_task('my_task'),
    execution_date=datetime.now()
)
ti.run(ignore_dependencies=True)
```

#### 2. **Log Analysis**

```bash
# View task logs
airflow tasks logs <dag_id> <task_id> <execution_date>

# Follow scheduler logs
tail -f $AIRFLOW_HOME/logs/scheduler/latest/scheduler.log

# View webserver logs
tail -f $AIRFLOW_HOME/logs/webserver/webserver.log
```

#### 3. **Performance Profiling**

```python
# Add profiling to tasks
import cProfile
import pstats

def profiled_task(**context):
    profiler = cProfile.Profile()
    profiler.enable()
    
    # Your task logic here
    result = expensive_operation()
    
    profiler.disable()
    
    # Save profiling results
    stats = pstats.Stats(profiler)
    stats.dump_stats(f'/tmp/profile_{context["task_instance_key_str"]}.prof')
    
    return result
```

---

## 📚 Resources & Training

### Internal Documentation

- **Architecture Documentation**: `docs/architecture.md`
- **Deployment Guide**: `docs/deployment.md`
- **API Documentation**: `docs/api.md`
- **Troubleshooting Guide**: `docs/troubleshooting.md`

### External Resources

#### Official Documentation
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [Astronomer Documentation](https://www.astronomer.io/docs/)
- [Airflow Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)

#### Training Materials
- [Airflow Fundamentals Course](https://academy.astronomer.io/)
- [Advanced Airflow Concepts](https://academy.astronomer.io/advanced-concepts)
- [Airflow for Data Engineering](https://www.datacamp.com/courses/introduction-to-airflow-in-python)

#### Community Resources
- [Airflow Slack Community](https://apache-airflow.slack.com/)
- [Airflow Summit](https://airflowsummit.org/)
- [Stack Overflow - Apache Airflow](https://stackoverflow.com/questions/tagged/apache-airflow)

### Team Training Plan

#### Week 1: Fundamentals
- [ ] Airflow architecture overview
- [ ] DAG and task concepts
- [ ] Basic operator usage
- [ ] Airflow UI navigation

#### Week 2: Development Standards
- [ ] Repository structure
- [ ] Naming conventions
- [ ] Configuration management
- [ ] Testing practices

#### Week 3: Advanced Topics
- [ ] Custom operators and hooks
- [ ] Dynamic DAG generation
- [ ] Performance optimization
- [ ] Monitoring and alerting

#### Week 4: Production Deployment
- [ ] CI/CD pipeline setup
- [ ] Security best practices
- [ ] Troubleshooting techniques
- [ ] Incident response procedures

---

## 📋 Quick Reference

### Common Commands

```bash
# DAG Management
airflow dags list                           # List all DAGs
airflow dags show <dag_id>                  # Show DAG structure
airflow dags state <dag_id> <execution_date> # Check DAG state
airflow dags pause <dag_id>                 # Pause DAG
airflow dags unpause <dag_id>               # Unpause DAG

# Task Management  
airflow tasks list <dag_id>                 # List tasks in DAG
airflow tasks test <dag_id> <task_id> <date> # Test single task
airflow tasks run <dag_id> <task_id> <date>  # Run single task
airflow tasks clear <dag_id>                # Clear task instances

# Connection Management
airflow connections list                    # List connections
airflow connections test <conn_id>          # Test connection
airflow connections add <conn_id> ...       # Add connection

# Variable Management
airflow variables list                      # List variables
airflow variables get <key>                 # Get variable value
airflow variables set <key> <value>         # Set variable

# Database Management
airflow db init                            # Initialize database
airflow db upgrade                         # Upgrade database schema
airflow db reset                           # Reset database (⚠️ Destructive)
```

### Environment Variables

```bash
# Core Airflow Settings
export AIRFLOW_HOME=/opt/airflow
export AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/dags
export AIRFLOW__CORE__PLUGINS_FOLDER=/opt/airflow/plugins
export AIRFLOW__CORE__EXECUTOR=CeleryExecutor

# Database Configuration
export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql://user:pass@host:port/db

# Security Settings
export AIRFLOW__WEBSERVER__SECRET_KEY=your-secret-key
export AIRFLOW__WEBSERVER__AUTHENTICATE=True

# Performance Tuning
export AIRFLOW__CORE__PARALLELISM=32
export AIRFLOW__CORE__MAX_ACTIVE_RUNS_PER_DAG=16
export AIRFLOW__CORE__DAG_CONCURRENCY=16
```

### File Templates

#### New DAG Template

```python
"""
DAG Template for Data Engineering Team

Copy this template to create new DAGs:
1. Replace placeholders with actual values
2. Update import statements as needed
3. Add your business logic
4. Follow naming conventions
5. Add appropriate tags
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup

# TODO: Update these values
DAG_ID = "domain_environment_process_version"
DESCRIPTION = "Brief description of what this DAG does"
SCHEDULE = "@daily"  # or cron expression
TAGS = ["team-data-eng", "domain-your-domain", "priority-medium"]

default_args = {
    'owner': 'data-engineering-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    dag_id=DAG_ID,
    default_args=default_args,
    description=DESCRIPTION,
    schedule_interval=SCHEDULE,
    catchup=False,
    max_active_runs=1,
    tags=TAGS,
    doc_md=__doc__,
)

# TODO: Add your tasks here
def your_task_function(**context):
    """
    Your task logic here
    """
    pass

with dag:
    # TODO: Define your tasks
    task1 = PythonOperator(
        task_id='your_task_1',
        python_callable=your_task_function,
    )
    
    # TODO: Define task dependencies
    # task1 >> task2 >> task3
```

---

## 🚨 Emergency Procedures

### Incident Response

#### 1. **Production DAG Failure**

**Immediate Actions:**
1. Assess impact scope
2. Check if data corruption occurred
3. Notify stakeholders
4. Implement temporary workaround if possible

**Investigation:**
1. Check task logs: `airflow tasks logs <dag_id> <task_id> <date>`
2. Review system resources
3. Check external dependencies
4. Verify configuration changes

**Resolution:**
1. Fix root cause
2. Clear failed tasks if safe
3. Re-run affected DAG runs
4. Verify data integrity
5. Update monitoring/alerting

#### 2. **Scheduler Down**

**Detection:**
- No new DAG runs being created
- Tasks stuck in queued state
- Scheduler health check failing

**Recovery:**
```bash
# Check scheduler status
ps aux | grep airflow-scheduler

# Restart scheduler (Docker)
docker restart airflow-scheduler

# Restart scheduler (Kubernetes)
kubectl rollout restart deployment airflow-scheduler

# Check scheduler logs
kubectl logs -f deployment/airflow-scheduler
```

#### 3. **Database Issues**

**Symptoms:**
- Tasks failing with database connection errors
- Webserver returning 500 errors
- Slow query performance

**Recovery:**
```bash
# Check database connectivity
airflow db check

# Reset database connections
airflow db reset-db-connections

# Upgrade database if needed
airflow db upgrade

# Check database performance
EXPLAIN ANALYZE SELECT * FROM task_instance WHERE state='running';
```

### Contact Information

| Role | Contact | Escalation |
|------|---------|------------|
| On-Call Engineer | #data-oncall | @data-team-lead |
| Database Admin | #database-team | @database-manager |
| Infrastructure | #devops-team | @devops-manager |
| Security Team | #security-team | @security-manager |

---

## 📈 Success Metrics

### Team Adoption Metrics

- [ ] **Code Quality**: 90% of DAGs follow naming conventions
- [ ] **Testing**: 80% test coverage for custom operators
- [ ] **Documentation**: All DAGs have proper documentation
- [ ] **Security**: 100% of credentials use Airflow Connections

### Operational Metrics

- [ ] **Reliability**: 99.5% DAG success rate
- [ ] **Performance**: <5 minute average task queue time
- [ ] **Monitoring**: <2 minute alert response time
- [ ] **Recovery**: <30 minute incident resolution time

### Business Impact

- [ ] **Efficiency**: 50% reduction in pipeline development time
- [ ] **Quality**: 90% reduction in data quality issues
- [ ] **Scalability**: Support for 10x current data volume
- [ ] **Compliance**: 100% audit trail coverage

---

## 🔄 Continuous Improvement

### Monthly Review Process

1. **Performance Review**
   - Analyze DAG execution metrics
   - Identify bottlenecks and optimization opportunities
   - Review resource utilization

2. **Code Quality Assessment**
   - Review new DAGs for best practice compliance
   - Update templates and documentation
   - Share learnings with team

3. **Security Audit**
   - Review access controls and permissions
   - Check for credential leaks or misuse
   - Update security policies

4. **Process Improvement**
   - Gather team feedback
   - Update best practices based on learnings
   - Plan training and knowledge sharing

### Quarterly Planning

- [ ] Technology roadmap review
- [ ] Skill gap analysis and training plan
- [ ] Tool evaluation and upgrades
- [ ] Best practice documentation updates

---

## 📝 Changelog

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | June 2025 | Complete rewrite for Airflow 3.x compatibility |
| 1.5 | March 2025 | Added security and governance sections |
| 1.0 | January 2025 | Initial enterprise best practices guide |

---

## 📞 Support & Feedback

### Getting Help

1. **Documentation**: Check this README and linked documentation
2. **Team Chat**: Post in #data-engineering-help channel
3. **Office Hours**: Weekly office hours every Tuesday 2-3 PM
4. **Escalation**: Contact @data-platform-team for urgent issues

### Providing Feedback

We continuously improve this guide based on team feedback:

- 📝 **Suggestions**: Submit issues in the repository
- 💬 **Discussion**: Join monthly best practices review meeting
- 🔄 **Updates**: Contribute improvements via pull requests

### Contributing

To contribute to this guide:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
5. Request review from data platform team

---

**Remember**: This guide is a living document. As Apache Airflow evolves and our team grows, we'll continue to update these best practices to ensure we're following the most current and effective approaches.

**Questions?** Reach out to the Data Platform Team or join our weekly office hours!

---

*Last updated: June 26, 2025*  
*Maintained by: Data Platform Team*  
*Next review: July 2025*