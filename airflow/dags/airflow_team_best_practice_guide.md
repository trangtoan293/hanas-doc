# Airflow DAG Development Best Practice Guide

## Version: 1.0
**Last Updated:** October 2025  
**Audience:** Technical Team (Data Engineers, ML Engineers, Data Scientists)  
**Purpose:** Standardized guideline for developing, reviewing, and maintaining Airflow DAGs

---

## 🎯 Mục Tiêu Chính

1. **Consistency**: Tất cả DAG tuân theo cùng một chuẩn
2. **Maintainability**: Dễ debug, dễ update, dễ scale
3. **Reliability**: Các DAG hoạt động ổn định, có recovery tự động
4. **Performance**: DAG parse nhanh, không overload scheduler
5. **Scalability**: Hỗ trợ team growth mà không cần refactor toàn bộ

---

## 📋 Phần 1: DAG Design - Khi Nào Tách/Gom?

### 1.1 Quyết Định Chiến Lược: Framework SODA+A

Trước khi code, trả lời các câu hỏi này theo thứ tự:

```
┌─────────────────────────────────────────────────────────┐
│ STEP 1: SCHEDULE                                        │
│ Workflow này chạy theo lịch KHÁC workflow cũ?          │
│ YES → TẠO DAG RIÊNG | NO → TIẾP STEP 2                │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 2: OWNERSHIP/DOMAIN                                │
│ Thuộc domain/team KHÁC?                                 │
│ YES → TẠO DAG RIÊNG | NO → TIẾP STEP 3                │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 3: SLA/ALERTS/RETRIES                             │
│ SLA, retry strategy, alert khác nhau?                   │
│ YES → TẠO DAG RIÊNG | NO → TIẾP STEP 4                │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 4: ATOMICITY                                       │
│ Là một unit of work độc lập (có thể rerun riêng)?      │
│ YES → TẠO TASK RIÊNG | NO → DÙNG FUNCTION             │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Ví Dụ Áp Dụng

#### ❌ SAI - Monolithic DAG

```python
# Mục tiêu: 1 cái DAG xử lý tất cả
# Kết quả: Maintenance nightmare

with DAG('everything_etl', schedule_interval='@daily'):
    # Extract từ 5 nguồn (có 3 cái chạy hàng giờ?)
    extract_api = PythonOperator(...)
    extract_db = PythonOperator(...)
    
    # Transform (chạy hàng ngày)
    transform = PythonOperator(...)
    
    # ML Training (chạy hàng tuần)
    ml_train = PythonOperator(...)
    
    # Report (chạy hàng tháng)
    report = PythonOperator(...)
```

**Vấn Đề**:
- Extract API hay chạy hourly nhưng DAG cũ chạy daily
- ML Training fail → Report delay (không liên quan)
- SLA metrics không clear

#### ✅ ĐÚNG - Modular DAGs

```python
# DAG 1: Hourly (owns: Data Eng Team)
hourly_extraction_dag = DAG(
    'hourly_data_extraction',
    schedule_interval='@hourly',
    owner='data_engineering',
    sla=timedelta(minutes=30),
    tags=['extraction', 'hourly']
)

# DAG 2: Daily (owns: Data Eng Team)
daily_transformation_dag = DAG(
    'daily_data_transformation',
    schedule_interval='@daily',
    owner='data_engineering',
    sla=timedelta(hours=2),
    depends_on_dag_id='hourly_data_extraction'
)

# DAG 3: Weekly (owns: ML Team)
weekly_ml_training_dag = DAG(
    'weekly_ml_training',
    schedule_interval='@weekly',
    owner='ml_team',
    sla=timedelta(hours=4),
)

# DAG 4: Monthly (owns: Analytics Team)
monthly_reporting_dag = DAG(
    'monthly_analytics_report',
    schedule_interval='@monthly',
    owner='analytics_team'
)
```

---

## 📁 Phần 2: Cấu Trúc Thư Mục (Repository Structure)

```
airflow-dags/
├── README.md                          # Hướng dẫn repo
├── GUIDELINES.md                      # Guideline này
├── dags/
│   ├── __init__.py
│   ├── config/
│   │   ├── __init__.py
│   │   ├── dev.yaml
│   │   ├── staging.yaml
│   │   └── prod.yaml
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── db_helpers.py              # Reusable DB functions
│   │   ├── api_helpers.py             # Reusable API functions
│   │   ├── data_validation.py         # Data quality checks
│   │   └── logger.py                  # Logging setup
│   ├── custom_operators/
│   │   ├── __init__.py
│   │   ├── custom_spark_operator.py
│   │   └── custom_ml_operator.py
│   ├── data_extraction/
│   │   ├── hourly_api_extraction.py
│   │   ├── daily_db_extraction.py
│   │   └── extract_operators.py       # Reusable extract logic
│   ├── data_transformation/
│   │   ├── daily_transformation.py
│   │   └── transform_operators.py
│   ├── ml_models/
│   │   ├── weekly_model_training.py
│   │   └── model_operators.py
│   └── analytics/
│       ├── monthly_reporting.py
│       └── report_operators.py
├── tests/
│   ├── __init__.py
│   ├── unit/
│   │   ├── test_extract_operators.py
│   │   ├── test_transform_operators.py
│   │   └── test_data_validation.py
│   ├── integration/
│   │   ├── test_hourly_extraction_dag.py
│   │   └── test_daily_transformation_dag.py
│   └── conftest.py                    # Pytest configuration
├── scripts/
│   ├── validate_dags.py               # DAG validation script
│   ├── test_runner.py
│   └── lint_checker.py
└── .github/workflows/
    ├── ci.yml                         # CI/CD pipeline
    └── deployment.yml
```

---

## 🏗️ Phần 3: DAG Coding Standards

### 3.1 DAG Definition Template

```python
# FILE: dags/data_extraction/hourly_api_extraction.py

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.http.operators.http import SimpleHttpOperator
import logging

# Logger setup
logger = logging.getLogger(__name__)

# ==========================================
# 1. DEFAULT ARGS - Cấu hình mặc định
# ==========================================
default_args = {
    'owner': 'data_engineering_team',
    'depends_on_past': False,           # Không wait previous run
    'email': ['data-eng@company.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'retry_exponential_backoff': True,  # Exponential backoff: 5min, 10min, 20min
    'max_retry_delay': timedelta(minutes=30),
}

# ==========================================
# 2. DAG DEFINITION - Metadata
# ==========================================
dag = DAG(
    dag_id='hourly_api_data_extraction',
    description='Extract data from external APIs every hour',
    default_args=default_args,
    schedule_interval='@hourly',        # Chạy hàng giờ
    start_date=datetime(2025, 1, 1),
    catchup=False,                      # Không catch up old runs
    tags=['extraction', 'hourly', 'api'],
    doc_md="""
    # Hourly API Data Extraction
    
    ## Purpose
    - Extracts raw data from external APIs
    - Stores in staging layer (S3/Data Lake)
    
    ## Dependencies
    - External APIs must be available
    - Target S3 bucket must have write access
    
    ## Schedule
    - Runs every hour at :00 (UTC)
    - Max run time: ~30 minutes
    
    ## Owner
    - Data Engineering Team
    - Slack: #data-eng-support
    """,
)

# ==========================================
# 3. TASK FUNCTIONS - Business Logic
# ==========================================

def extract_from_api_1(**context):
    """
    Extract data from API 1.
    
    Args:
        **context: Airflow context (task instance, execution date, etc.)
    
    Returns:
        dict: API response data
    
    Raises:
        Exception: If API call fails
    """
    import requests
    
    logger.info("Starting extraction from API 1")
    
    try:
        response = requests.get(
            'https://api.example.com/data',
            timeout=30,
            params={'format': 'json'}
        )
        response.raise_for_status()
        
        data = response.json()
        logger.info(f"Successfully extracted {len(data)} records from API 1")
        
        return {'api_1_records': len(data)}
        
    except Exception as e:
        logger.error(f"Failed to extract from API 1: {str(e)}")
        raise

def validate_raw_data(raw_data, **context):
    """
    Validate extracted raw data before storing.
    
    Args:
        raw_data: Raw data from API
        **context: Airflow context
        
    Returns:
        dict: Validation results
    """
    from utils.data_validation import validate_schema
    
    logger.info("Validating raw data")
    
    validation_result = validate_schema(raw_data)
    
    if not validation_result['is_valid']:
        raise ValueError(f"Validation failed: {validation_result['errors']}")
    
    logger.info("Data validation passed")
    return {'validated': True}

def store_to_staging(raw_data, **context):
    """
    Store validated data to staging (S3).
    
    Args:
        raw_data: Validated data
        **context: Airflow context
    """
    from utils.s3_helpers import upload_to_s3
    import json
    
    execution_date = context['execution_date']
    partition_date = execution_date.strftime('%Y-%m-%d')
    partition_hour = execution_date.strftime('%H')
    
    s3_path = f"s3://data-lake/raw/api_1/{partition_date}/{partition_hour}/data.json"
    
    logger.info(f"Storing data to {s3_path}")
    
    upload_to_s3(
        data=json.dumps(raw_data),
        bucket_key=s3_path
    )
    
    logger.info("Data successfully stored to S3")

# ==========================================
# 4. TASK DEFINITIONS - Operators
# ==========================================

extract_task = PythonOperator(
    task_id='extract_from_api_1',
    python_callable=extract_from_api_1,
    retries=3,
    retry_delay=timedelta(minutes=5),
    do_xcom_push=True,              # Push result to XCom
    pool='api_calls',               # Resource pool (concurrency control)
    pool_slots=1,                   # Số slots cần từ pool
    queue='high_priority',          # Celery queue
    trigger_rule='all_success',
    provide_context=True,
)

validate_task = PythonOperator(
    task_id='validate_data',
    python_callable=validate_raw_data,
    op_args=[extract_task.output],  # Pass extracted data
    retries=2,
    trigger_rule='all_success',
    provide_context=True,
)

store_task = PythonOperator(
    task_id='store_to_s3',
    python_callable=store_to_staging,
    op_args=[extract_task.output],
    retries=2,
    provide_context=True,
)

# ==========================================
# 5. TASK DEPENDENCIES - DAG Graph
# ==========================================
extract_task >> validate_task >> store_task
```

### 3.2 Coding Principles

#### ✅ DO - Các Quy Tắc

1. **Avoid Top-Level Code** (Except DAG definition)

```python
# ❌ SAI - Gọi API khi DAG parse (mỗi 30s!)
import requests
api_response = requests.get('https://api.example.com/data')

with DAG(...) as dag:
    task = PythonOperator(...)

# ✅ ĐÚNG - Gọi API bên trong task
def fetch_data():
    import requests
    api_response = requests.get('https://api.example.com/data')
    return api_response.json()

with DAG(...) as dag:
    task = PythonOperator(python_callable=fetch_data)
```

2. **Use Local Imports for Heavy Libraries**

```python
# ❌ SAI - Parse chậm (import numpy mỗi 30s)
import numpy as np  # Heavy library at top level

with DAG(...) as dag:
    @task
    def process_data():
        pass

# ✅ ĐÚNG
with DAG(...) as dag:
    @task
    def process_data():
        import numpy as np  # Import chỉ khi chạy task
        return np.array([1, 2, 3])
```

3. **Tasks Must Be Idempotent**

```python
# ❌ SAI - INSERT → Duplicate nếu rerun
def load_data(data):
    sql = f"INSERT INTO users VALUES (...)"
    execute_query(sql)

# ✅ ĐÚNG - UPSERT → Idempotent
def load_data(data, **context):
    execution_date = context['execution_date']
    partition_date = execution_date.strftime('%Y-%m-%d')
    
    sql = f"""
    INSERT INTO users (id, name, updated_date)
    VALUES (...)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        updated_date = EXCLUDED.updated_date
    WHERE users.updated_date < EXCLUDED.updated_date
    """
    execute_query(sql)
```

4. **Use XCom for Small Messages Only**

```python
# ❌ SAI - Large data (~500MB)
def process_large_file():
    data = load_large_csv()  # 500MB
    return data  # XCom limits ~100KB

# ✅ ĐÚNG - Store path, not data
def process_large_file(**context):
    data = load_large_csv()
    s3_path = 's3://bucket/processed_data.parquet'
    save_to_s3(data, s3_path)
    return {'s3_path': s3_path}  # Return path only
```

5. **Use Execution Date, Not "Today"**

```python
# ❌ SAI - Rerun sẽ lấy data khác
def extract_data():
    from datetime import date
    today = date.today()
    sql = f"SELECT * FROM users WHERE date = '{today}'"

# ✅ ĐÚNG - Lấy từ DAG execution date
def extract_data(**context):
    execution_date = context['execution_date']
    partition_date = execution_date.strftime('%Y-%m-%d')
    sql = f"SELECT * FROM users WHERE date = '{partition_date}'"
```

#### ❌ DON'T - Các Điều Tránh

| Rule | ❌ SAI | ✅ ĐÚNG |
|------|--------|---------|
| **File Storage** | Store in local filesystem | Use S3/HDFS/Remote storage |
| **Large Data** | Pass via XCom | Pass S3 path via XCom |
| **Credentials** | Hardcode in DAG | Use Airflow Connections/Variables |
| **Top-Level Imports** | `import numpy` at top | Import inside task function |
| **Randomness** | `random.choice()` in task | Deterministic logic |
| **Delete Tasks** | `del dag.tasks[...]` | Create new DAG version |

---

## 🧪 Phần 4: Testing Strategy

### 4.1 Unit Tests - Test Reusable Functions

```python
# FILE: tests/unit/test_data_validation.py

import pytest
from utils.data_validation import validate_schema

def test_validate_schema_valid_data():
    """Test validation passes for valid data"""
    valid_data = {
        'id': 1,
        'name': 'John',
        'email': 'john@example.com'
    }
    
    result = validate_schema(valid_data)
    assert result['is_valid'] == True

def test_validate_schema_invalid_data():
    """Test validation fails for invalid data"""
    invalid_data = {
        'id': 'not_a_number',  # Should be int
        'name': 'John'
    }
    
    result = validate_schema(invalid_data)
    assert result['is_valid'] == False
    assert 'id' in result['errors']

def test_validate_schema_missing_fields():
    """Test validation fails when required fields missing"""
    incomplete_data = {'id': 1}
    
    result = validate_schema(incomplete_data)
    assert result['is_valid'] == False
```

### 4.2 Integration Tests - Test DAG Tasks

```python
# FILE: tests/integration/test_hourly_extraction_dag.py

import pytest
from airflow import DAG
from airflow.utils.state import DagRunState
from airflow.models import DagRun
from dags.data_extraction.hourly_api_extraction import dag

@pytest.fixture
def dag_instance():
    return dag

def test_dag_is_valid(dag_instance):
    """Test DAG has no cycles"""
    assert dag_instance.dag_id == 'hourly_api_data_extraction'
    assert not dag_instance.has_cycles()

def test_dag_tasks_exist(dag_instance):
    """Test all expected tasks exist"""
    task_ids = {task.task_id for task in dag_instance.tasks}
    
    assert 'extract_from_api_1' in task_ids
    assert 'validate_data' in task_ids
    assert 'store_to_s3' in task_ids

def test_dag_task_dependencies(dag_instance):
    """Test task dependencies are correct"""
    extract_task = dag_instance.get_task('extract_from_api_1')
    validate_task = dag_instance.get_task('validate_data')
    store_task = dag_instance.get_task('store_to_s3')
    
    # Check dependencies
    assert validate_task in extract_task.downstream_list
    assert store_task in validate_task.downstream_list
```

### 4.3 DAG Validation Checklist

```python
# FILE: scripts/validate_dags.py

import os
from airflow.models import DAG
from airflow import settings
from airflow.utils import module_loading
import logging

logger = logging.getLogger(__name__)

def validate_dag_file(dag_file):
    """Validate single DAG file"""
    
    checks = {
        'has_description': False,
        'has_tags': False,
        'has_owner': False,
        'has_sla': False,
        'no_cycles': False,
        'task_count_reasonable': False,
        'tasks_have_doc': False,
    }
    
    try:
        # Load DAG
        module = module_loading.import_module(dag_file)
        dag = getattr(module, 'dag', None)
        
        if not dag:
            logger.error(f"No DAG found in {dag_file}")
            return False
        
        # Run checks
        checks['has_description'] = dag.description is not None
        checks['has_tags'] = len(dag.tags) > 0
        checks['has_owner'] = dag.owner is not None
        checks['no_cycles'] = not dag.has_cycles()
        checks['task_count_reasonable'] = 5 <= len(dag.tasks) <= 50
        
        # Check tasks have documentation
        all_tasks_documented = all(
            task.doc or task.doc_md 
            for task in dag.tasks
        )
        checks['tasks_have_doc'] = all_tasks_documented
        
        # Optional: SLA (depends on criticality)
        if dag.sla is None:
            logger.warning(f"{dag.dag_id}: No SLA defined")
        
        return all(checks.values())
        
    except Exception as e:
        logger.error(f"Error validating {dag_file}: {str(e)}")
        return False

def validate_all_dags():
    """Validate all DAG files in dags folder"""
    dag_folder = settings.DAGS_FOLDER
    
    valid_count = 0
    invalid_count = 0
    
    for root, dirs, files in os.walk(dag_folder):
        for file in files:
            if file.endswith('.py'):
                dag_file = os.path.join(root, file)
                
                if validate_dag_file(dag_file):
                    valid_count += 1
                    logger.info(f"✓ {dag_file}")
                else:
                    invalid_count += 1
                    logger.error(f"✗ {dag_file}")
    
    print(f"\nValidation Results: {valid_count} passed, {invalid_count} failed")
    
    return invalid_count == 0

if __name__ == '__main__':
    success = validate_all_dags()
    exit(0 if success else 1)
```

---

## 🔄 Phần 5: Code Review Checklist

### Trước Khi Merge PR

- [ ] **Design Decision**
  - [ ] Tác giả đã trả lời SODA+A framework?
  - [ ] DAG/Task separation hợp lý?
  - [ ] Schedule, ownership, SLA rõ ràng?

- [ ] **Code Quality**
  - [ ] Không có heavy top-level code?
  - [ ] Local imports cho heavy libraries?
  - [ ] Tasks có docstrings?
  - [ ] Tên tasks có ý nghĩa?

- [ ] **Error Handling**
  - [ ] Có retry logic?
  - [ ] Có error alerting?
  - [ ] SLA được định nghĩa?

- [ ] **Data Integrity**
  - [ ] Tasks idempotent?
  - [ ] Dùng UPSERT chứ không INSERT?
  - [ ] Sử dụng execution_date chứ không date.today()?

- [ ] **Performance**
  - [ ] DAG parse speed acceptable?
  - [ ] XCom data < 100KB?
  - [ ] Task count hợp lý (5-15)?

- [ ] **Documentation**
  - [ ] DAG có doc_md?
  - [ ] Tasks có docstrings?
  - [ ] Hợp lệ với test?

- [ ] **Testing**
  - [ ] Unit tests viết rồi?
  - [ ] Integration tests pass?
  - [ ] Validation script pass?

---

## 📊 Phần 6: Configuration Management

### 6.1 Environment-Specific Config

```yaml
# FILE: dags/config/dev.yaml
environment: development
api_endpoints:
  api_1: 'https://dev-api.example.com'
database:
  host: 'dev-db.internal'
  port: 5432
s3_bucket: 'data-lake-dev'
alert_email: 'data-eng-dev@company.com'
default_retries: 2
```

```python
# FILE: dags/utils/config_loader.py

import yaml
import os

def load_config():
    env = os.getenv('AIRFLOW_ENV', 'dev')
    config_file = f'config/{env}.yaml'
    
    with open(config_file, 'r') as f:
        return yaml.safe_load(f)

# Usage in DAGs
config = load_config()

dag = DAG(
    dag_id='my_dag',
    ...
)

task = PythonOperator(
    task_id='api_call',
    op_kwargs={'api_url': config['api_endpoints']['api_1']},
    ...
)
```

---

## 🚀 Phần 7: Deployment & CI/CD

### 7.1 GitHub Actions CI Pipeline

```yaml
# FILE: .github/workflows/ci.yml

name: Airflow DAG CI

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main ]

jobs:
  validate-and-test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      
      - name: Install dependencies
        run: |
          pip install apache-airflow pytest pylint
          pip install -r requirements.txt
      
      - name: Lint with pylint
        run: pylint dags/ --disable=C0111,R0903
      
      - name: Validate DAGs
        run: python scripts/validate_dags.py
      
      - name: Run unit tests
        run: pytest tests/unit/ -v
      
      - name: Run integration tests
        run: pytest tests/integration/ -v
```

---

## 📝 Phần 8: Troubleshooting Guide

### Problem: DAG Parsing Slow

```python
# ❌ Nguyên nhân thường gặp
import pandas as pd  # Heavy import at top
import numpy as np
import requests

# ✅ Giải pháp
# Move imports inside task functions
```

### Problem: Task Keeps Retrying

```python
# ❌ Nguyên nhân: Không idempotent
INSERT INTO table VALUES (...)  # Lỗi ở nửa sau → Duplicate data

# ✅ Giải pháp
INSERT OR REPLACE INTO table VALUES (...)
-- hoặc
DELETE WHERE date = execution_date; INSERT INTO table ...
```

### Problem: XCom Size Error

```python
# ❌ Nguyên nhân: Push data quá lớn
return large_dataframe  # ~500MB

# ✅ Giải pháp
s3_path = save_to_s3(large_dataframe)
return {'s3_path': s3_path}  # ~1KB
```

---

## 🎓 Phần 9: Team Onboarding

### Cho Nhân Viên Mới

1. **Week 1: Foundations**
   - Đọc guidelines này
   - Chạy ví dụ DAGs
   - Hiểu SODA+A framework

2. **Week 2-3: Development**
   - Tạo DAG đơn giản
   - Code review từ senior
   - Learn từ feedback

3. **Week 4: Advanced**
   - Custom Operators
   - Complex workflows
   - Performance optimization

### Resources

- [Apache Airflow Official Docs](https://airflow.apache.org/docs/)
- [Airflow Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)
- Internal Wiki: `https://wiki.company.com/airflow`

---

## 📞 Support & Escalation

| Issue | Contact | Response Time |
|-------|---------|---|
| DAG design review | #data-eng-help Slack | < 4 hours |
| Production incident | #data-eng-oncall | < 30 min |
| Best practice question | data-eng-team@company.com | < 24 hours |

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Oct 2025 | Initial release |
| (Future) | | TBD |

---

## Appendix A: SODA+A Decision Tree (Printable)

```
Do I need a NEW DAG or add to EXISTING?

┌─ STEP 1: SCHEDULE INDEPENDENCE
│  Different schedule than existing DAG?
│  YES → NEW DAG
│  NO  → Continue to STEP 2
│
├─ STEP 2: OWNERSHIP/DOMAIN
│  Different team/domain?
│  YES → NEW DAG
│  NO  → Continue to STEP 3
│
├─ STEP 3: SLA/ALERTS/STRATEGY
│  Different SLA, retries, or alerts?
│  YES → NEW DAG
│  NO  → Continue to STEP 4
│
├─ STEP 4: ATOMICITY
│  Can this run/rerun independently?
│  YES → NEW TASK (trong DAG hiện tại)
│  NO  → FUNCTION (trong task hiện tại)
└─ Done!
```

---

## Appendix B: Common DAG Patterns

### Pattern 1: ETL Pipeline

```python
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'data_engineering',
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='daily_etl_pipeline',
    schedule_interval='@daily',
    start_date=datetime(2025, 1, 1),
    default_args=default_args,
    tags=['etl', 'daily']
) as dag:
    
    extract = PythonOperator(
        task_id='extract_data',
        python_callable=extract_data_func,
    )
    
    validate = PythonOperator(
        task_id='validate_data',
        python_callable=validate_data_func,
    )
    
    transform = PythonOperator(
        task_id='transform_data',
        python_callable=transform_data_func,
    )
    
    load = PythonOperator(
        task_id='load_to_warehouse',
        python_callable=load_data_func,
    )
    
    # Sequential dependencies
    extract >> validate >> transform >> load
```

### Pattern 2: Parallel Processing

```python
with DAG(
    dag_id='parallel_extraction',
    schedule_interval='@hourly',
    ...
) as dag:
    
    # Extract từ 3 nguồn song song
    extract_db = PythonOperator(
        task_id='extract_from_db',
        python_callable=extract_from_db_func,
    )
    
    extract_api_1 = PythonOperator(
        task_id='extract_from_api_1',
        python_callable=extract_from_api_1_func,
    )
    
    extract_api_2 = PythonOperator(
        task_id='extract_from_api_2',
        python_callable=extract_from_api_2_func,
    )
    
    # Merge kết quả
    merge = PythonOperator(
        task_id='merge_all_sources',
        python_callable=merge_data_func,
    )
    
    # Song song
    [extract_db, extract_api_1, extract_api_2] >> merge
```

### Pattern 3: Branching Logic

```python
from airflow.operators.branching import BranchPythonOperator

def check_data_quality(**context):
    """Decide which branch to take based on data quality"""
    quality_score = check_quality(...)
    
    if quality_score > 0.9:
        return 'load_to_production'
    else:
        return 'alert_data_quality_issue'

with DAG(dag_id='conditional_workflow', ...) as dag:
    
    extract = PythonOperator(task_id='extract', ...)
    
    check_quality = BranchPythonOperator(
        task_id='check_quality',
        python_callable=check_data_quality,
    )
    
    load_prod = PythonOperator(
        task_id='load_to_production',
        python_callable=load_to_prod_func,
    )
    
    alert_issue = PythonOperator(
        task_id='alert_data_quality_issue',
        python_callable=send_alert_func,
    )
    
    extract >> check_quality >> [load_prod, alert_issue]
```

### Pattern 4: Dynamic Task Generation

```python
def get_list_of_sources():
    """Get list of sources to process"""
    return ['source_1', 'source_2', 'source_3']

with DAG(dag_id='dynamic_extraction', ...) as dag:
    
    sources = get_list_of_sources()
    
    # Dynamically create tasks
    extract_tasks = [
        PythonOperator(
            task_id=f'extract_from_{source}',
            python_callable=extract_from_source,
            op_kwargs={'source': source},
        )
        for source in sources
    ]
    
    merge = PythonOperator(
        task_id='merge_all',
        python_callable=merge_func,
    )
    
    extract_tasks >> merge
```

### Pattern 5: Scheduled Dependency (Wait for Another DAG)

```python
from airflow.sensors.external_task import ExternalTaskSensor

with DAG(dag_id='dependent_workflow', ...) as dag:
    
    # Wait for daily_extraction DAG to complete
    wait_for_extraction = ExternalTaskSensor(
        task_id='wait_for_daily_extraction',
        external_dag_id='daily_extraction_dag',
        external_task_id='load_to_s3',
        execution_delta=timedelta(hours=0),  # Expect to complete same hour
        mode='poke',
        timeout=3600,  # Wait max 1 hour
    )
    
    transform = PythonOperator(
        task_id='transform_data',
        python_callable=transform_func,
    )
    
    wait_for_extraction >> transform
```

---

## Appendix C: Reusable Operator Library

### 1. Database Operator

```python
# FILE: dags/custom_operators/database_operator.py

from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults
import logging

logger = logging.getLogger(__name__)

class DatabaseQueryOperator(BaseOperator):
    """
    Execute query against database and return results.
    
    :param sql_query: SQL query to execute
    :param conn_id: Airflow connection ID
    :param database: Target database
    """
    
    template_fields = ('sql_query',)
    
    @apply_defaults
    def __init__(
        self,
        sql_query,
        conn_id='postgres_default',
        database='default',
        *args,
        **kwargs
    ):
        super().__init__(*args, **kwargs)
        self.sql_query = sql_query
        self.conn_id = conn_id
        self.database = database
    
    def execute(self, context):
        from airflow.providers.postgres.hooks.postgres import PostgresHook
        
        hook = PostgresHook(postgres_conn_id=self.conn_id)
        
        logger.info(f"Executing query: {self.sql_query}")
        
        results = hook.get_records(self.sql_query)
        
        logger.info(f"Query returned {len(results)} records")
        
        return results
```

### 2. Data Validation Operator

```python
# FILE: dags/custom_operators/data_validation_operator.py

from airflow.models import BaseOperator
from airflow.exceptions import AirflowException

class DataValidationOperator(BaseOperator):
    """
    Validate data against schema and quality rules.
    
    :param data_path: Path to data file
    :param schema: Expected schema
    :param quality_rules: List of validation rules
    """
    
    def __init__(
        self,
        data_path,
        schema,
        quality_rules=None,
        *args,
        **kwargs
    ):
        super().__init__(*args, **kwargs)
        self.data_path = data_path
        self.schema = schema
        self.quality_rules = quality_rules or []
    
    def execute(self, context):
        import pandas as pd
        from jsonschema import validate
        
        # Load data
        df = pd.read_parquet(self.data_path)
        
        # Schema validation
        try:
            for record in df.to_dict('records'):
                validate(instance=record, schema=self.schema)
        except Exception as e:
            raise AirflowException(f"Schema validation failed: {str(e)}")
        
        # Quality rules
        for rule_name, rule_func in self.quality_rules:
            if not rule_func(df):
                raise AirflowException(f"Quality rule '{rule_name}' failed")
        
        return {'valid': True, 'record_count': len(df)}
```

---

## Appendix D: Performance Tuning Checklist

| Issue | Symptom | Solution |
|-------|---------|----------|
| Slow DAG parsing | Airflow UI slow, high CPU | Remove top-level imports, move to task |
| Too many tasks | DAG UI hard to read | Combine micro-tasks into logical tasks |
| XCom bottleneck | Memory errors | Pass S3 path instead of data |
| Scheduler lag | Tasks delayed | Increase scheduler capacity, optimize DAG |
| Worker overload | Tasks timeout | Use pools, reduce parallelism |
| Database size | Slow queries | Archive old task logs |

---

## Appendix E: Monitoring & Alerting Setup

### Alert Configuration Example

```python
from airflow.models import DAG
from airflow.providers.slack.operators.slack_webhook import SlackWebhookOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data_engineering',
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'email': ['data-eng@company.com'],
    'email_on_failure': True,
}

def alert_to_slack(**context):
    """Send alert to Slack on failure"""
    task_instance = context['task_instance']
    dag_id = context['dag'].dag_id
    
    message = f"""
    ❌ *DAG Failed*
    - DAG: {dag_id}
    - Task: {task_instance.task_id}
    - Status: {task_instance.state}
    - Log: {task_instance.log_url}
    """
    
    SlackWebhookOperator(
        task_id='slack_alert',
        http_conn_id='slack_webhook',
        message=message,
    ).execute(context)

with DAG(
    dag_id='monitored_dag',
    schedule_interval='@daily',
    default_args=default_args,
    on_failure_callback=alert_to_slack,  # Custom alert
    tags=['critical']
) as dag:
    
    task = PythonOperator(
        task_id='process',
        python_callable=process_func,
        sla=timedelta(hours=2),  # Alert if > 2 hours
    )
```

---

## Appendix F: FAQ - Câu Hỏi Thường Gặp

### Q1: Tôi có schedule cùng (@daily) nhưng 2 pipeline khác nhau. Nên tạo DAG riêng không?

**A:** YES, nếu:
- Khác team (ownership)
- Khác SLA hoặc retry strategy
- Khác alert requirements

Nếu tất cả giống hệt nhau, có thể merge thành 1 DAG nhưng tách thành parallel branches.

### Q2: Task của tôi có 100 dòng code. Nên tách thành sub-tasks không?

**A:** Không cần, miễn là:
- Có thể rerun toàn bộ
- Logic liên kết chặt chẽ
- Không có error retry điểm khác nhau

Nếu logic tách biệt, hãy tách.

### Q3: Nên dùng bao nhiêu tasks per DAG?

**A:** Best practice: 5-15 tasks per DAG
- Quá ít: Khó debug
- Quá nhiều: DAG parser chậm, UI rối

### Q4: Khi nào nên dùng Dynamic Task vs Static Task?

**A:** 
- **Dynamic**: Số lượng tasks không cố định (ví dụ: 1000 files trong folder)
- **Static**: Số lượng tasks cố định từ lúc design

### Q5: Làm sao để test DAG offline trước khi deploy?

**A:**
```bash
# Validate DAG file
python -m py_compile dags/my_dag.py

# Parse DAG locally
python dags/my_dag.py

# Run unit tests
pytest tests/unit/test_my_dag.py -v

# Run integration tests
pytest tests/integration/test_my_dag.py -v
```

### Q6: DAG của tôi chạy mỗi ngày nhưng một số tasks chỉ chạy thứ 2. Nên làm gì?

**A:** Dùng `trigger_rule` hoặc branching logic:

```python
from airflow.utils.dates import days_ago

with DAG(...) as dag:
    
    daily_task = PythonOperator(
        task_id='daily_process',
        python_callable=process_daily,
    )
    
    weekly_task = PythonOperator(
        task_id='weekly_process',
        python_callable=process_weekly,
        trigger_rule='none_skipped',  # Skip on non-Monday
    )
    
    # Skip task on non-Monday
    from airflow.models.skipmixin import SkipMixin
    from datetime import datetime
    
    def should_run_weekly(**context):
        execution_date = context['execution_date']
        if execution_date.weekday() == 0:  # Monday
            return 'weekly_process'
        return 'skip_weekly'
    
    branch = BranchPythonOperator(
        task_id='check_day_of_week',
        python_callable=should_run_weekly,
    )
    
    daily_task >> branch >> weekly_task
```

---

## Appendix G: Security Best Practices

### 1. Credentials Management

```python
# ❌ SAI - Hardcoded credentials
api_key = 'sk_test_12345'
password = 'mypassword123'

# ✅ ĐÚNG - Airflow Connections
from airflow.models import Variable
from airflow.hooks.base import BaseHook

# Retrieve from Airflow
api_key = Variable.get('api_key')
conn = BaseHook.get_connection('postgres_connection')
password = conn.password
```

### 2. Secrets Management

```python
# Store secrets in:
# 1. Airflow Connections (UI or CLI)
# 2. Environment variables
# 3. Secrets backend (AWS Secrets Manager, HashiCorp Vault)

# Never in:
# ❌ DAG code
# ❌ Git repository
# ❌ Log files
```

### 3. DAG File Permissions

```bash
# Make DAG files readable by Airflow but not world-readable
chmod 640 dags/*.py

# Restrict DAGS_FOLDER
chmod 750 dags/
```

---

## Appendix H: Scaling Guidelines

### For Small Teams (1-3 engineers)

- 5-10 DAGs
- Single Airflow instance (all-in-one)
- Basic monitoring
- Weekly code reviews

### For Medium Teams (4-10 engineers)

- 20-50 DAGs
- HA Airflow setup (separate scheduler, workers)
- Automated testing (CI/CD)
- Daily standups
- Dedicated DAG reviewer

### For Large Teams (10+ engineers)

- 100+ DAGs
- Distributed Airflow (Celery executor)
- Comprehensive monitoring/alerting
- Automated governance
- DAG templates for common patterns
- Dedicated platform team

---

## Appendix I: Migration Checklist (Legacy Code)

Khi migrate từ legacy code sang guideline này:

- [ ] Analyze current DAGs
- [ ] Identify business domains
- [ ] Split into separate DAGs by domain
- [ ] Extract reusable functions
- [ ] Add unit tests
- [ ] Add integration tests
- [ ] Document each DAG
- [ ] Setup CI/CD validation
- [ ] Code review with team
- [ ] Deploy to staging
- [ ] Monitor in production
- [ ] Archive old code

---

## Appendix J: Troubleshooting Scenarios

### Scenario 1: "Task is stuck in running state"

```
Diagnosis:
1. Check worker logs: airflow-worker.log
2. Check task logs: Task Instance → View Log
3. Verify resource availability (CPU, memory)

Common Causes:
- Network issue (API timeout)
- Database connection pool exhausted
- Worker crashed

Solution:
1. Manually mark task as failed in UI (if critical)
2. Add timeout and retry logic
3. Increase worker capacity
4. Check external service health
```

### Scenario 2: "DAG is in parse error state"

```
Diagnosis:
1. Run: python dags/my_dag.py
2. Check for syntax errors
3. Check for circular imports

Common Causes:
- Python syntax error
- Top-level import failure
- Circular dependency

Solution:
1. Fix syntax
2. Move imports to task level
3. Use local imports for heavy libraries
```

### Scenario 3: "Tasks are not starting despite DAG schedule"

```
Diagnosis:
1. Check Airflow scheduler: ps aux | grep scheduler
2. Check scheduler logs
3. Verify DAG is unpaused in UI

Common Causes:
- Scheduler not running
- DAG is paused
- start_date is in future
- Backfill not run

Solution:
1. Restart scheduler
2. Unpause DAG in UI
3. Fix start_date
4. Run backfill if needed
```

---

**END OF GUIDE**

Last updated: October 2025
For questions or updates, contact: data-engineering@company.com