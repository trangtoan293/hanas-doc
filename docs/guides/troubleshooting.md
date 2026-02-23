# Troubleshooting — Xử Lý Sự Cố Thường Gặp

---

## 1. NiFi

### NiFi flow stopped / không chạy

| Triệu chứng | Nguyên nhân | Giải pháp |
|---|---|---|
| Flow status = Stopped | Manual stop hoặc error | Check Bulletins, restart flow |
| Connection pool failed | Oracle down / credentials | Test JDBC connection, check Oracle status |
| Queue đầy (back pressure) | Consumer chậm hơn producer | Tăng `Back Pressure Object Threshold` hoặc scale consumer |
| `PutS3Object` fail | MinIO down / bucket không tồn tại | Check MinIO health, verify bucket exists |

### Kiểm tra

```bash
# NiFi health
curl -s http://nifi:8443/nifi-api/system-diagnostics | jq '.systemDiagnostics.aggregateSnapshot'

# Check bulletin board errors
curl -s http://nifi:8443/nifi-api/flow/bulletin-board | jq '.bulletinBoard.bulletins[:5]'
```

---

## 2. Apache Kafka

### Consumer lag cao

| Triệu chứng | Nguyên nhân | Giải pháp |
|---|---|---|
| Lag > 10,000 | Consumer chậm | Scale consumer group, tăng partitions |
| Lag tăng liên tục | Producer rate > consumer rate | Tối ưu consumer processing, thêm consumers |
| No active consumers | Consumer crash | Restart consumer, check logs |

### Kiểm tra

```bash
# Check consumer lag
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group spark-streaming --describe

# Check topic info
kafka-topics.sh --bootstrap-server kafka:9092 --describe --topic oracle-prod.SRC_CUSTOMERS
```

---

## 3. MinIO

### Không ghi được file

| Triệu chứng | Nguyên nhân | Giải pháp |
|---|---|---|
| `AccessDenied` | Sai credentials hoặc policy | Verify access key, check bucket policy |
| `NoSuchBucket` | Bucket chưa tạo | `mc mb myminio/landing` |
| `Connection refused` | MinIO service down | `docker restart hanas-minio` |
| Disk full | Storage hết dung lượng | Mở rộng PV, archive old data |

### Kiểm tra

```bash
# MinIO health
mc admin info myminio

# Disk usage
mc du myminio/landing
mc du myminio/warehouse
```

---

## 4. Apache Spark

### Job thất bại

| Triệu chứng | Nguyên nhân | Giải pháp |
|---|---|---|
| `OutOfMemoryError` | Data quá lớn / executor memory thiếu | Tăng `executor_memory`, partitioning tốt hơn |
| `FileNotFoundException` | Iceberg metadata stale | Refresh catalog: `CALL system.expire_snapshots()` |
| `ClassNotFoundException` | Thiếu dependency | Check `packages` / `jars` config |
| Shuffle spill | Partition quá lớn | Tăng `spark.sql.shuffle.partitions` |
| Task timeout | Skewed data | Enable AQE: `spark.sql.adaptive.enabled=true` |

### Kiểm tra

```bash
# Spark UI → check failed stages
open http://spark-master:8080

# Spark driver logs
kubectl logs -f spark-driver-pod -n spark-jobs
```

### Tối ưu thường dùng

```python
# AQE (Adaptive Query Execution) — BẬT
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")

# Iceberg write optimization
spark.conf.set("spark.sql.catalog.hanas.write.target-file-size-bytes", "134217728")  # 128MB
```

---

## 5. Apache Airflow

### DAG không xuất hiện trên UI

| Triệu chứng | Nguyên nhân | Giải pháp |
|---|---|---|
| DAG missing | Import error | Check `airflow dags list-import-errors` |
| DAG grayed out | Paused | Toggle DAG on/off |
| DAG load chậm | File quá nhiều / complex import | Optimize imports, check `.airflowignore` |

### Task failed

| Triệu chứng | Nguyên nhân | Giải pháp |
|---|---|---|
| `SparkKubernetesOperator` fail | Spark pod crash | Check K8s pod logs: `kubectl logs <pod>` |
| Timeout | Job chạy quá lâu | Tăng `execution_timeout`, tối ưu Spark job |
| Sensor timeout | Dữ liệu landing chưa có | Check NiFi flow, tăng sensor `timeout` |
| `Variable not found` | Missing Airflow Variable | Add Variable via UI hoặc CLI |

### Kiểm tra

```bash
# List import errors
airflow dags list-import-errors

# Check specific DAG
airflow dags show demo_data_pipeline_e2e_incremental

# Trigger DAG manually
airflow dags trigger demo_data_pipeline_e2e_incremental --conf '{"cob_date": "2024-01-15"}'

# Check task logs
airflow tasks logs demo_data_pipeline_e2e_incremental load_hub_customer 2024-01-15
```

---

## 6. dbt

### Model fail

| Triệu chứng | Nguyên nhân | Giải pháp |
|---|---|---|
| `Compilation Error` | SQL syntax / ref() sai | `dbt compile`, check generated SQL |
| `Database Error` | Iceberg table missing | Verify table exists in catalog |
| `Merge conflict` | Concurrent writes | Retry, check Iceberg snapshot isolation |
| Test fail | Data quality issue | Check data source, fix upstream |

### Kiểm tra

```bash
# Compile & check SQL
dbt compile --select my_model --profiles-dir .

# Run single model
dbt run --select my_model --profiles-dir .

# Run tests
dbt test --select my_model --profiles-dir .

# Debug
dbt debug --profiles-dir .
```

---

## 7. Dremio

### Query chậm

| Triệu chứng | Nguyên nhân | Giải pháp |
|---|---|---|
| Full scan | Thiếu Reflection | Tạo Raw/Aggregation Reflection |
| Reflection not used | Reflection chưa refresh | Manual refresh, check schedule |
| Metadata stale | Iceberg metadata cũ | Refresh source metadata |
| Memory error | Dataset quá lớn | Filter/limit query, add acceleration |

### Kiểm tra

```sql
-- Check query profile
-- Dremio UI → Jobs → click query → Job Profile

-- Check reflection usage
SELECT * FROM sys.reflections WHERE dataset_name = 'Customer360';

-- Refresh metadata
ALTER TABLE lakehouse.warehouse.data_mart.dim_customer REFRESH METADATA;
```

---

## 8. Iceberg Table Issues

### Small files problem

```python
# Compact small files (chạy weekly qua Airflow)
spark.sql("""
    CALL demo.system.rewrite_data_files(
        table => 'integration.hub_customer',
        options => map('target-file-size-bytes', '134217728')
    )
""")
```

### Metadata bloat

```python
# Expire old snapshots
spark.sql("""
    CALL demo.system.expire_snapshots(
        table => 'integration.hub_customer',
        older_than => TIMESTAMP '2024-01-08 00:00:00',
        retain_last => 5
    )
""")

# Remove orphan files
spark.sql("""
    CALL demo.system.remove_orphan_files(
        table => 'integration.hub_customer'
    )
""")
```

---

## 9. Quy Trình Escalation

| Level | Ai xử lý | Thời gian | Kênh |
|---|---|---|---|
| **L1** | Data Engineer on-call | < 30 phút | Slack channel |
| **L2** | Senior Data Engineer | < 2 giờ | Slack + Email |
| **L3** | Platform Team Lead | < 4 giờ | Slack + Email + Meeting |
| **L4** | Vendor support | Theo SLA | Ticket system |
