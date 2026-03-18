# Apache Airflow - Hướng Dẫn Sử Dụng

## 1. Truy Cập Airflow UI

- **URL**: Xem Airflow Variable `AIRFLOW_BASE_URL` (default: `http://localhost:8080`)
- **Giao diện chính**:
  - **DAGs**: Danh sách DAGs, toggle on/off, trigger
  - **Grid View**: Trạng thái task theo thời gian
  - **Graph View**: Sơ đồ dependency giữa tasks
  - **Task Logs**: Xem log chi tiết của từng task

---

## 2. Trigger DAG

### 2.1 E2E Init (Full Refresh)

**DAG**: `demo_data_pipeline_e2e_init`

Dùng khi cần load toàn bộ dữ liệu từ đầu (lần đầu setup hoặc rebuild).

**Parameters:**

| Param | Type | Default | Mô tả |
|---|---|---|---|
| `notification_email` | string | `null` | Email nhận thông báo kết quả |

**Flow:**

```
start → build_vw_ref_eod → raw_vault_etl_job → data_mart_etl_job → end → notification
```

### 2.2 E2E Incremental

**DAG**: `demo_data_pipeline_e2e_incremental`

Dùng cho daily load, chỉ xử lý dữ liệu mới kể từ lần chạy trước.

**Parameters:**

| Param | Type | Default | Mô tả |
|---|---|---|---|
| `cob_date` | string | `null` | Close-of-Business date (format: `YYYY-MM-DD`) |
| `eod_ref_model` | string | `null` | EOD reference model name |
| `notification_email` | string | `null` | Email nhận thông báo |

**Flow:**

```
start → build_vw_ref_eod → [raw_vault group] → [data_mart group] → end → notification
```

> **Customize groups:** Override via Airflow Variable `DEMO_DATA_PIPELINE_E2E_INCREMENTAL_GROUPS` (JSON).

### 2.3 MDM Pipeline (Incremental)

**DAG**: `demo_mdm_pipeline_e2e_incremental`

Pipeline Master Data Management chạy tuần tự 6 bước.

**Parameters:** Giống E2E Incremental (`cob_date`, `eod_ref_model`, `notification_email`).

**Flow:**

```
start → build_vw_ref_eod → mdm_source → mdm_cleansed → mdm_validated
                                                              ↓
notification ← end ← mdm_golden ← mdm_merge ← mdm_match
```

### 2.4 Ad-hoc dbt ETL

**DAG**: `dbt_adhoc_etl`

Chạy bất kỳ dbt model nào theo yêu cầu.

**Parameters:**

| Param | Type | Default | Mô tả |
|---|---|---|---|
| `dbt_select` | string | _(bắt buộc)_ | dbt selectors (space-separated) |
| `full_refresh` | boolean | `false` | Có dùng `--full-refresh` không |
| `notification_email` | string | `null` | Email nhận thông báo |

**Ví dụ `dbt_select`:**

```
integration.raw_vault          # Tất cả raw vault models
data_mart                      # Tất cả data mart models
sat_gl sat_snp_gl              # Chỉ 2 models cụ thể
mdm.mdm_corecif_golden_records # MDM golden records
```

### 2.5 Backfill Pipeline

**DAG**: `backfill_etl_pipeline`

Sửa lỗi dữ liệu và rebuild tables trong khoảng thời gian chỉ định.

**Flow:**

```
start → fix_dr_cr_flag → delete_raw_vault_data → rebuild_raw_vault → rebuild_data_mart → end
```

**Parameters:** `start_date`, `end_date`, Spark resource params (driver/executor cores, memory, instances).

### 2.6 Backdate Pipeline

**DAG**: `backdate_etl_pipeline`

Tạo backdate tables và views trên Dremio.

**Flow:**

```
start → create_backdate_table → run_dbt_backdate_models → end
```

**Parameters:** `start_date`, `end_date`, Spark resource params.

---

## 3. Hiểu TaskGroup Pattern

Mỗi ETL TaskGroup trong pipeline gồm 2 sub-groups:

```
┌─────────────────── TaskGroup: <group_id> ──────────────────────┐
│                                                                │
│  ┌── load_and_logging ──────┐   ┌── publish_datahub ─────────┐ │
│  │                          │   │                            │ │
│  │  load_job (dbt run)      │   │  extract_dbt_catalog       │ │
│  │       ↓                  │   │       ↓                    │ │
│  │  test_job (dbt test)     │──▶│  publish_dbt_transformation│ │
│  │       ↓                  │   │       ↓                    │ │
│  │  logging_job (metrics)   │   │  publish_iceberg_metadata  │ │
│  │                          │   │       ↓                    │ │
│  └──────────────────────────┘   │  publish_dbt_tests         │ │
│                                 └────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

### Chi tiết mỗi task:

| Task | K8s Template | Chức năng |
|---|---|---|
| `load_job` | `dbt-runner.yaml` | Chạy `ktl_dbt run --select <models>` |
| `test_job` | `dbt-test.yaml` | Chạy `dbt test` (retries=0, fail = immediate alert) |
| `logging_job` | `dbt-logger.yaml` | Ghi ETL logs vào `LakeHouse.etladmin` (trigger_rule=`all_done`) |
| `extract_dbt_catalog` | PythonOperator | Validate catalog.json từ S3 artifacts |
| `publish_dbt_transformation` | PythonOperator | Publish dbt lineage lên DataHub |
| `publish_iceberg_metadata` | PythonOperator | Publish Iceberg schemas lên DataHub |
| `publish_dbt_tests` | PythonOperator | Publish data quality assertions lên DataHub |

---

## 4. Giám Sát & Monitoring

### 4.1 Airflow UI

- **DAGs page**: Kiểm tra trạng thái (success/failed/running)
- **Grid View**: Xem timeline execution
- **Task Instance logs**: Click vào task → View Log

### 4.2 Kubernetes

```bash
# Xem Spark jobs đang chạy
kubectl get sparkapplication -n spark-jobs

# Xem chi tiết một job
kubectl describe sparkapplication <app-name> -n spark-jobs

# Xem logs của Spark driver
kubectl logs -n spark-jobs <driver-pod-name>

# Xem logs của Spark executor
kubectl logs -n spark-jobs <executor-pod-name>
```

### 4.3 Notifications

| Event | Channel | Cấu hình |
|---|---|---|
| Task failure | Slack | `IMMEDIATE_ALERT_CHANNELS` variable |
| Task retry | Slack | `RETRY_ALERT_CHANNELS` variable |
| SLA breach (>2h) | Slack | `sla_miss_callback` trên DAG |
| DAG completion | Email (Maileroo) | `notification_email` DAG param |

---

## 5. Troubleshooting Thường Gặp

### DAG không hiển thị trên UI

```bash
# Kiểm tra DAG parse errors
python -c "from airflow.models import DagBag; db = DagBag(); print(db.import_errors)"

# Kiểm tra file trong dags folder
ls -la $AIRFLOW_HOME/dags/
```

### Spark job stuck ở "Running"

```bash
# Kiểm tra trạng thái SparkApplication
kubectl get sparkapplication -n spark-jobs | grep <dag-run-id>

# Kiểm tra events
kubectl describe sparkapplication <app-name> -n spark-jobs | grep -A 20 "Events:"

# Kill job thủ công
kubectl delete sparkapplication <app-name> -n spark-jobs
```

### dbt test fail

- Test job có `retries=0` — fail sẽ trigger `on_failure_callback` ngay
- `logging_job` vẫn chạy (trigger_rule=`all_done`) để ghi metrics
- Kiểm tra test results trong dbt artifacts: `s3://data/dbt-artifacts/<run_id>/<group_id>/test/`

### Email notification không gửi

1. Kiểm tra Airflow Variables: `MAILEROO_API_KEY`, `SENDER_EMAIL`
2. Kiểm tra `notification_email` param khi trigger DAG
3. Nếu không set `notification_email`, fallback là `DEFAULT_NOTIFICATION_EMAIL`
4. Nếu cả hai đều trống → không gửi email (by design)
