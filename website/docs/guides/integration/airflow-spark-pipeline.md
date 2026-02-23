# Integration Guide: Airflow + Spark Pipeline

## Tổng Quan

Hướng dẫn cách Airflow điều phối Spark jobs trên Kubernetes để chạy dbt transformations, xử lý dữ liệu từ Landing Zone thành Raw Vault / Data Mart trên Iceberg tables.

```
┌──────────────┐  SparkKubernetesOperator  ┌──────────────────┐  Spark pods   ┌──────────────┐
│   Airflow    │─────────────────────────▶│  Spark Operator  │─────────────▶│  Spark       │
│  Scheduler   │  Submit SparkApplication  │  (K8s CRD)      │  create       │  Driver +    │
└──────────────┘                          └──────────────────┘               │  Executors   │
                                                                             └──────┬───────┘
                                                                                    │
                                            ┌──────────────┐                        │ dbt / ktl_dbt
                                            │  Git Repo    │◀── git-sync ───────────┤
                                            │  (dbt project)│   init container      │
                                            └──────────────┘                        │
                                                                                    ▼
┌──────────────┐                          ┌──────────────┐               ┌──────────────┐
│   DataHub    │◀── publish metadata ─────│  dbt Artifacts│◀── upload ───│    MinIO      │
│  (Metadata)  │                          │  (S3)        │               │  (Iceberg     │
└──────────────┘                          └──────────────┘               │   Warehouse)  │
                                                                         └──────────────┘
```

---

## 1. SparkKubernetesOperator — Cách Sử Dụng

### 1.1 Cấu hình cơ bản

```python
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)

# Submit Spark job lên K8s cluster
task = SparkKubernetesOperator(
    task_id="build_vw_ref_eod",
    namespace="spark-jobs",                    # K8s namespace
    application_file="dbt-runner.yaml",        # K8s YAML template (SparkApplication CRD)
    random_name_suffix=True,                   # Unique pod name per run
    kubernetes_conn_id="k8s_conn_id",          # Airflow K8s connection
    dag=dag,
    params={
        "dbt_select": "vw_ref_eod",            # Passed to YAML template as {{ params.dbt_select }}
        "full_refresh": True,
        "artifacts_suffix": "vw_ref_eod",
    },
)
```

### 1.2 K8s YAML Template (SparkApplication CRD)

```yaml
# dags/raw_vault/k8s/dbt-runner.yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: dbt-run-rawvault
  namespace: spark-jobs
spec:
  type: Python
  mode: cluster
  image: "trangtoan293/dbt-spark-k8s-ktl:ktl-dbt"
  mainApplicationFile: "local:///opt/spark/work-dir/dbt-project/dbt-project/dbt_runner.py"
  arguments:
    - "--use-subprocess"
    - "--dbt-command"
    - "ktl_dbt"                      # Custom dbt for Data Vault
    - "--upload-artifacts"
    - "--s3-bucket"
    - "data"
    - "run"
    - "--target"
    - "dev"
    # Conditionally add --full-refresh
    {% if params.full_refresh %}
    - "--full-refresh"
    {% endif %}
    # Dynamically add --select arguments
    {% if params.dbt_select %}
    - "--select"
    {% for tok in params.dbt_select.split(' ') if tok %}
    - "{{ tok }}"
    {% endfor %}
    {% endif %}

  sparkVersion: "3.5.1"

  sparkConf:
    # Iceberg catalog
    spark.sql.extensions: "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
    spark.sql.catalog.demo: "org.apache.iceberg.spark.SparkCatalog"
    spark.sql.catalog.demo.type: "hive"
    spark.sql.catalog.demo.uri: "thrift://<hive-metastore>:9083"
    spark.sql.catalog.demo.io-impl: "org.apache.iceberg.aws.s3.S3FileIO"
    spark.sql.catalog.demo.s3.endpoint: "http://<minio-host>"
    spark.sql.catalog.demo.warehouse: "s3a://data/warehouse/"
    spark.sql.defaultCatalog: "demo"
    # Optimizations
    spark.sql.adaptive.enabled: "true"
    spark.sql.adaptive.coalescePartitions.enabled: "true"

  driver:
    cores: 3
    memory: "5g"
    serviceAccount: spark
    initContainers:
      - name: git-sync                 # Pull dbt project from Git
        image: registry.k8s.io/git-sync/git-sync:v4.1.0
        envFrom:
          - configMapRef:
              name: git-sync-config
    envFrom:
      - secretRef:
          name: spark-k8s-aws-credentials
      - secretRef:
          name: spark-k8s-oracle-credentials

  executor:
    cores: 3
    memory: "4g"
    instances: 2
    envFrom:
      - secretRef:
          name: spark-k8s-aws-credentials

  restartPolicy:
    type: OnFailure
    onFailureRetries: 2
    onFailureRetryInterval: 10
```

### 1.3 Template Variables

YAML templates sử dụng Jinja2 templating với các biến từ Airflow:

| Template Variable | Source | Ví dụ |
|---|---|---|
| `{{ params.dbt_select }}` | `SparkKubernetesOperator.params` | `"integration.raw_vault"` |
| `{{ params.full_refresh }}` | `SparkKubernetesOperator.params` | `True` / `False` |
| `{{ params.artifacts_suffix }}` | `SparkKubernetesOperator.params` | `"raw_vault/run"` |
| `{{ dag_run.run_id }}` | Airflow DAG Run | `"manual__2024-01-15T..."` |
| `{{ var.value.DBT_ARTIFACTS_PREFIX }}` | Airflow Variable | `"dbt-artifacts/custom"` |

---

## 2. Patterns DAG Production

### 2.1 Reusable TaskGroup Pattern

```python
# ✅ Production pattern - tái sử dụng TaskGroup
from raw_vault.taskgroups.dbt_etl_jobs_taskgroup import create_dbt_etl_jobs_taskgroup

# Mỗi group tạo: load_job → test_job → logging_job → publish_datahub
taskgroup = create_dbt_etl_jobs_taskgroup(
    "raw_vault",
    dbt_select="integration.raw_vault",
    full_refresh=False,
    dag=dag,
    load_job_task_id="data_incre_load_job",
    asset_tag_name="data platform demo",
)
```

### 2.2 Sequential Pipeline với Dynamic Groups

```python
# Configurable groups - override via Airflow Variable
DEFAULT_GROUPS = [
    {"group_id": "raw_vault",  "dbt_select": "integration.raw_vault"},
    {"group_id": "data_mart",  "dbt_select": "data_mart"},
]

# Chain groups tuần tự
upstream = eod_view_job
for group in GROUPS:
    select = group["dbt_select"]
    if "data_mart" in select:
        select = f"{select} --exclude *_backdate"    # Exclude backdate tables

    taskgroup = create_dbt_etl_jobs_taskgroup(
        group["group_id"],
        dbt_select=select,
        full_refresh=False,
        dag=dag,
    )
    upstream >> taskgroup
    upstream = taskgroup

upstream >> end
```

### 2.3 MDM Pipeline (Step-by-Step)

```python
from raw_vault.taskgroups.dbt_etl_jobs_taskgroup import create_mdm_step_taskgroup

MDM_STEPS = [
    ("mdm_source",    "mdm.mdm_source_corecif"),
    ("mdm_cleansed",  "mdm.mdm_corecif_cleansed"),
    ("mdm_validated", "mdm.mdm_corecif_validate mdm.mdm_corecif_invalid"),
    ("mdm_match",     "mdm.mdm_corecif_match"),
    ("mdm_merge",     "mdm.mdm_corecif_merge"),
    ("mdm_golden",    "mdm.mdm_corecif_golden_records"),
]

upstream = eod_view_job
for step_id, dbt_select in MDM_STEPS:
    step = create_mdm_step_taskgroup(
        group_id=step_id,
        dbt_select=dbt_select,
        full_refresh=False,
        dag=dag,
    )
    upstream >> step
    upstream = step
```

---

## 3. Error Handling & Retry

### 3.1 DAG-level defaults

```python
from utils.callbacks import on_failure_callback, on_retry_callback, sla_miss_callback

default_args = {
    "owner": "data-engineering",
    "retries": 3,
    "retry_delay": timedelta(seconds=15),
    "sla": timedelta(hours=2),
    "on_retry_callback": on_retry_callback,       # Alert on retry
    "on_failure_callback": on_failure_callback,    # Alert on failure
}

with DAG(
    ...,
    sla_miss_callback=sla_miss_callback,           # Alert on SLA breach
    max_active_runs=1,
    catchup=False,
) as dag:
    ...
```

### 3.2 Test job — no retry

```python
# Test jobs fail immediately → alert
test_job = SparkKubernetesOperator(
    task_id="test_job",
    retries=0,                                    # Override: no retries
    on_failure_callback=on_failure_callback,
    ...
)
```

### 3.3 Logging job — always runs

```python
# Logging runs even if test fails
logging_job = SparkKubernetesOperator(
    task_id="logging_job",
    trigger_rule="all_done",                      # Run regardless of upstream status
    ...
)
```

### 3.4 K8s-level retry

```yaml
# SparkApplication CRD restart policy
restartPolicy:
  type: OnFailure
  onFailureRetries: 2
  onFailureRetryInterval: 10
  onSubmissionFailureRetries: 3
  onSubmissionFailureRetryInterval: 20
```

---

## 4. Email Notifications (Maileroo)

```python
from taskgroups.maileroo_groups import maileroo_notification_group

# Add notification TaskGroup sau end task
notification = maileroo_notification_group("notification", dag=dag)
end >> notification
```

Notification group tự động:
- Gửi email thành công (với DAG link) khi tất cả tasks pass
- Gửi email failure (với task details) khi có task fail
- Đọc recipient từ DAG param `notification_email` hoặc Variable `DEFAULT_NOTIFICATION_EMAIL`

---

## 5. Best Practices

### 5.1 DAG Design

| Practice | Mô tả |
|---|---|
| `max_active_runs=1` | Ngăn chạy chồng chéo |
| `catchup=False` | Không backfill tự động |
| Reusable TaskGroups | Dùng `create_dbt_etl_jobs_taskgroup` |
| `_var()` helper | Safe Variable access với fallback |
| Separate run/test artifacts | Tách lineage và data quality |

### 5.2 Spark-on-K8s Integration

| Practice | Mô tả |
|---|---|
| **K8s YAML templates** | Định nghĩa SparkApplication CRD, không hardcode trong Python |
| **git-sync sidecar** | Tự động pull dbt project từ Git |
| **K8s Secrets** | Credentials qua `secretRef`, không hardcode |
| **Namespace isolation** | Spark jobs chạy trong `spark-jobs` namespace riêng |
| **Resource params** | Cho phép override driver/executor resources qua DAG params |

### 5.3 Monitoring

```bash
# Xem Spark jobs
kubectl get sparkapplication -n spark-jobs

# Xem driver logs
kubectl logs -n spark-jobs <driver-pod>

# Xem Spark UI (port-forward nếu cần)
kubectl port-forward -n spark-jobs <driver-pod> 4040:4040
```
