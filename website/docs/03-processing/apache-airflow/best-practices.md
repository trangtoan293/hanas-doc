# Apache Airflow - Best Practices

## 1. Thiết Kế DAG — SODA+A Framework

Trước khi tạo DAG mới, áp dụng framework SODA+A để quyết định tách hay gom:

```
STEP 1: SCHEDULE — Khác schedule? → TẠO DAG RIÊNG
STEP 2: OWNERSHIP — Khác team/domain? → TẠO DAG RIÊNG
STEP 3: SLA/ALERTS — Khác SLA, retry strategy? → TẠO DAG RIÊNG
STEP 4: ATOMICITY — Có thể rerun độc lập? → TẠO TASK RIÊNG / FUNCTION
```

> **Ví dụ thực tế:** `demo_data_pipeline_e2e_init` và `demo_data_pipeline_e2e_incremental` tách riêng vì mode khác nhau (full refresh vs incremental) dù cùng owner.

---

## 2. Coding Standards

### 2.1 Sử dụng TaskGroup cho reusable patterns

```python
# ✅ ĐÚNG - Reusable TaskGroup (pattern production)
from raw_vault.taskgroups.dbt_etl_jobs_taskgroup import create_dbt_etl_jobs_taskgroup

taskgroup = create_dbt_etl_jobs_taskgroup(
    "raw_vault",
    dbt_select="integration.raw_vault",
    full_refresh=False,
    dag=dag,
    asset_tag_name=asset_tag_name,
)
```

```python
# ❌ SAI - Copy-paste logic giữa các DAGs
load_job = SparkKubernetesOperator(task_id="load", ...)
test_job = SparkKubernetesOperator(task_id="test", ...)
logging_job = SparkKubernetesOperator(task_id="log", ...)
# Lặp lại y hệt trong mỗi DAG
```

### 2.2 Safe Variable access

```python
# ✅ ĐÚNG - Helper function với fallback
def _var(name: str, default: Optional[str] = None) -> Optional[str]:
    try:
        value = Variable.get(name)
        return value if value != "" else default
    except KeyError:
        return default

asset_tag = _var("DATAHUB_ASSET_TAG_NAME", "data platform demo")
```

```python
# ❌ SAI - Variable.get không có fallback
tag = Variable.get("DATAHUB_ASSET_TAG_NAME")  # KeyError nếu chưa set
```

### 2.3 Callback pattern chuẩn

```python
# ✅ Production pattern - callbacks từ utils/callbacks.py
from utils.callbacks import on_failure_callback, on_retry_callback, sla_miss_callback

default_args = {
    "on_retry_callback": on_retry_callback,
    "on_failure_callback": on_failure_callback,
}

with DAG(..., sla_miss_callback=sla_miss_callback) as dag:
    end = EmptyOperator(
        task_id="end",
        trigger_rule="all_done",
        on_success_callback=on_success_callback,  # Chỉ trên end task
    )
```

### 2.4 DAG Parameters với type validation

```python
from airflow.models.param import Param

params={
    "cob_date": Param(default=None, type=["null", "string"]),
    "full_refresh": Param(default=False, type="boolean"),
    "dbt_select": Param(type="string", description="dbt selectors"),
    "notification_email": Param(
        default=None, type=["null", "string"],
        description="Recipient email for notifications.",
    ),
}
```

---

## 3. Performance

### 3.1 Tránh top-level heavy code

```python
# ✅ ĐÚNG - Import nhẹ, logic trong task
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)

# ❌ SAI - Heavy operations at parse time
import pandas as pd  # Parse mỗi 30s!
data = pd.read_csv("big_file.csv")
```

### 3.2 Giới hạn max_active_runs

```python
# ✅ Tất cả DAGs production đều set max_active_runs=1
with DAG(
    dag_id="demo_data_pipeline_e2e_incremental",
    max_active_runs=1,  # Ngăn chạy chồng chéo
    catchup=False,
    ...
)
```

### 3.3 Trigger Rules phù hợp

```python
# logging_job chạy kể cả khi test_job fail
logging_job = SparkKubernetesOperator(
    task_id="logging_job",
    trigger_rule="all_done",  # Luôn ghi metrics
    ...
)

# end task đợi tất cả hoàn thành
end = EmptyOperator(task_id="end", trigger_rule="all_done")
```

---

## 4. Bảo Mật

### 4.1 Credentials qua K8s Secrets

```yaml
# ✅ ĐÚNG - Credentials từ K8s Secrets
envFrom:
  - secretRef:
      name: spark-k8s-aws-credentials
  - secretRef:
      name: spark-k8s-oracle-credentials
```

```python
# ❌ SAI - Hardcode credentials trong DAG
api_key = "sk_test_12345"
password = "mypassword123"
```

### 4.2 Airflow Variables cho sensitive data

```python
# ✅ Dùng Airflow Variables (encrypted in DB)
api_key = Variable.get("MAILEROO_API_KEY")
password = Variable.get("dremio_password")
```

---

## 5. Vận Hành Production

### 5.1 Notification strategy

| Level | Channel | Khi nào |
|---|---|---|
| Task failure | Slack (immediate) | Mỗi task fail |
| Task retry | Slack | Mỗi retry attempt |
| SLA breach | Slack | DAG chạy quá 2 giờ |
| DAG completion | Email (Maileroo) | Sau khi DAG kết thúc (success/failure) |

### 5.2 Test job configuration

```python
# Test jobs KHÔNG retry — fail = alert immediately
test_job = SparkKubernetesOperator(
    task_id="test_job",
    retries=0,                            # No retry
    on_failure_callback=on_failure_callback,  # Alert ngay
    ...
)
```

### 5.3 Artifact separation

Tách artifacts `run/` và `test/` để:
- **Lineage data** (từ dbt run) không bị overwrite bởi test results
- **Data quality assertions** (từ dbt test) được publish riêng lên DataHub

---

## 6. Code Review Checklist

### Trước khi merge PR:

- [ ] **Design**: Đã áp dụng SODA+A framework?
- [ ] **Reuse**: Sử dụng `create_dbt_etl_jobs_taskgroup` cho pattern chuẩn?
- [ ] **Variables**: Dùng `_var()` helper với default value?
- [ ] **Callbacks**: Có `on_failure_callback`, `on_retry_callback`, `sla_miss_callback`?
- [ ] **Parameters**: Dùng `Param` với type validation?
- [ ] **Resources**: `max_active_runs=1`, `catchup=False`?
- [ ] **Tags**: DAG có tags phù hợp (`dbt`, `spark`, `kubernetes`, ...)?
- [ ] **Documentation**: DAG có `doc_md` mô tả purpose, flow, parameters?
- [ ] **Notifications**: Có `maileroo_notification_group` cho email?
