# Đào Tạo Xử Lý Dữ Liệu (Data Processing)

## Tổng Quan

| Thông tin | Chi tiết |
|-----------|---------|
| **Đối tượng** | Data Engineer, ETL Developer |
| **Thời lượng** | 2 tuần (full-time) |
| **Lịch học** | Mỗi ngày 8 giờ: 4 giờ theory + 4 giờ hands-on |
| **Điều kiện** | SQL trung cấp, Python cơ bản, hiểu biết về data pipeline |

## Kết Quả Sau Đào Tạo

Sau 2 tuần, học viên có khả năng:

- Phát triển Airflow DAGs sử dụng `SparkKubernetesOperator` và TaskGroup patterns
- Viết Spark jobs (PySpark/Spark SQL) tích hợp Iceberg trên Kubernetes
- Xây dựng dbt models theo phương pháp Data Vault 2.0 (Hub, Link, Satellite)
- Thiết kế NiFi data flows cho batch ingestion
- Tạo pipeline end-to-end: Source → Landing → Raw Vault → Business Vault → Information Mart

---

## Tuần 1: Ingestion & Processing

### Ngày 1-2: Apache NiFi — Data Ingestion (16 giờ)

#### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| NiFi Architecture | Processor groups, controller services, backpressure | 2 giờ |
| Data Flow Design | Batch ingestion patterns, error handling, retry | 2 giờ |
| NiFi + MinIO | PutS3Object, FetchS3Object, Landing zone pattern | 2 giờ |
| **Apache Kafka & CDC** | Kafka architecture, Confluent Oracle CDC Source, Debezium (PostgreSQL/MySQL), Iceberg Sink Connector, lồng CDC end-to-end | 2 giờ |

#### Hands-on

**NiFi:**
- Thiết kế NiFi flow: Database → Extract → Transform → MinIO Landing
- Cấu hình controller services cho database connections
- Xử lý error handling và retry patterns
- Test flow end-to-end

**Kafka Connect (CDC):**

```bash
# Kiểm tra connectors đang chạy
curl -s http://connect:8083/connectors | jq .

# Xem status Oracle CDC connector
curl -s http://connect:8083/connectors/DEMO_GROUP3/status | jq .

# Xem status Iceberg Sink connector  
curl -s http://connect:8083/connectors/DEMO_SINK_GROUP2/status | jq .

# Kiểm tra consumer lag của sink
kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
  --describe --group consum_sink_demo_group2

# Browse Kafka topic messages
kafka-console-consumer.sh --bootstrap-server kafka:9092 \
  --topic ORACLE.DEMO_LAKE.TBL_TRANSACTION \
  --from-beginning --max-messages 5
```

📖 Tài liệu:
- [NiFi Documentation](../01-ingestion/apache-nifi/README.md)
- [Kafka Documentation](../01-ingestion/apache-kafka/README.md)
- [Kafka Configuration](../01-ingestion/apache-kafka/configuration.md)
- [Kafka User Guide](../01-ingestion/apache-kafka/user-guide.md)

---

### Ngày 3-4: Apache Airflow — Workflow Orchestration (16 giờ)

#### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| DAG Development | DAG structure, operators, sensors, hooks, XCom | 3 giờ |
| SparkKubernetesOperator | Submit Spark jobs on K8s, monitoring, error handling | 2 giờ |
| TaskGroup Patterns | Reusable task groups (`ktl_airflow_utils`), DRY patterns | 2 giờ |
| Scheduling & Backfill | Cron expressions, catchup, backfill, KubernetesExecutor | 1 giờ |

#### Hands-on: Xây dựng DAG hoàn chỉnh

```python
from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import SparkKubernetesOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'hanas',
    'depends_on_past': False,
    'email_on_failure': True,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'customer_etl_pipeline',
    default_args=default_args,
    schedule_interval='@daily',
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['etl', 'data-vault'],
) as dag:

    # Spark ETL job trên Kubernetes
    raw_vault_load = SparkKubernetesOperator(
        task_id='raw_vault_load',
        namespace='hanas-demo',
        application_file='spark-raw-vault.yaml',
        do_xcom_push=True,
    )

    business_vault_transform = SparkKubernetesOperator(
        task_id='business_vault_transform',
        namespace='hanas-demo',
        application_file='spark-business-vault.yaml',
    )

    raw_vault_load >> business_vault_transform
```

📖 Tài liệu:
- [Airflow Documentation](../03-processing/apache-airflow/README.md)
- [Hướng dẫn Airflow + Spark Pipeline](../guides/integration/airflow-spark-pipeline.md)
- [Mẫu Airflow DAG](../guides/examples/sample-airflow-dag.md)

---

### Ngày 5: Apache Spark trên Kubernetes (8 giờ)

#### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| Spark Architecture on K8s | Driver, executors, Spark Operator | 1.5 giờ |
| Spark + Iceberg | Hive catalog (`demo`), đọc/ghi Iceberg tables | 1.5 giờ |
| Optimization | Resource tuning, shuffle, caching, partition strategy | 1 giờ |

#### Hands-on

```yaml
# SparkApplication manifest
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: raw-vault-etl
  namespace: hanas-demo
spec:
  type: Python
  pythonVersion: "3"
  mode: cluster
  image: hanas/spark:3.5.1
  mainApplicationFile: s3a://scripts/raw_vault_load.py
  sparkVersion: "3.5.1"
  sparkConf:
    spark.sql.catalog.demo: org.apache.iceberg.spark.SparkCatalog
    spark.sql.catalog.demo.type: hive
  driver:
    cores: 1
    memory: "2g"
    serviceAccount: spark
    env:
      - name: AWS_ACCESS_KEY_ID
        valueFrom:
          secretKeyRef:
            name: minio-credentials
            key: access-key
  executor:
    cores: 2
    instances: 3
    memory: "4g"
```

📖 Tài liệu:
- [Spark Documentation](../03-processing/apache-spark/README.md)
- [Ví dụ Spark Job](../guides/examples/sample-spark-job.md)

---

## Tuần 2: Data Modeling & Quality

### Ngày 6-8: dbt & Data Vault 2.0 (24 giờ)

#### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| Data Vault 2.0 | Hub, Link, Satellite patterns, hash keys | 4 giờ |
| dbt Core | Models, sources, tests, documentation, macros | 4 giờ |
| dbt + Spark | dbt-spark adapter, Iceberg materialization | 2 giờ |
| Advanced Models | PIT tables, Bridge tables, Business Satellite | 2 giờ |

#### Hands-on: Xây dựng Data Vault Models

```sql
-- Hub: Entity chính (Business Key)
-- models/raw_vault/hub_customer.sql
{{
  config(
    materialized='incremental',
    unique_key='hub_customer_hk',
    file_format='iceberg'
  )
}}

SELECT
    {{ dbt_utils.surrogate_key(['customer_id']) }} as hub_customer_hk,
    customer_id,
    CURRENT_TIMESTAMP() as load_date,
    'source_system' as record_source
FROM {{ source('landing', 'customers') }}
{% if is_incremental() %}
WHERE load_date > (SELECT MAX(load_date) FROM {{ this }})
{% endif %}
```

```sql
-- Satellite: Attributes thay đổi theo thời gian
-- models/raw_vault/sat_customer_details.sql
SELECT
    {{ dbt_utils.surrogate_key(['customer_id']) }} as hub_customer_hk,
    {{ dbt_utils.surrogate_key(['customer_id', 'full_name', 'email']) }} as hash_diff,
    full_name,
    email,
    phone,
    city,
    CURRENT_TIMESTAMP() as load_date,
    'source_system' as record_source
FROM {{ source('landing', 'customers') }}
```

📖 Tài liệu:
- [dbt & Data Vault](../04-data-model/README.md)
- [Hướng dẫn dbt + Data Vault](../guides/integration/dbt-data-vault.md)
- [Mẫu dbt Models](../guides/examples/sample-dbt-models.md)

---

### Ngày 9: Data Quality & Testing (8 giờ)

#### Nội dung

| Chủ đề | Nội dung |
|--------|---------|
| dbt Tests | Schema tests, data tests, custom tests |
| Data Assertions | Not null, unique, accepted values, relationships |
| DataHub Integration | dbt metadata push, lineage tracking |
| Data Reconciliation | Row count, hash comparison, source-target validation |

#### Hands-on

```yaml
# dbt schema tests
models:
  - name: hub_customer
    columns:
      - name: hub_customer_hk
        tests:
          - not_null
          - unique
      - name: customer_id
        tests:
          - not_null
          - unique
      - name: load_date
        tests:
          - not_null
```

📖 Tài liệu: [DataHub & Data Quality](../05-governance/datahub/README.md)

---

### Ngày 10: Pipeline Workshop & Tổng Kết (8 giờ)

#### Workshop: Xây dựng Pipeline End-to-End

Bài tập tổng hợp — xây dựng pipeline hoàn chỉnh:

| Bước | Công cụ | Nội dung |
|------|---------|---------|
| 1. Ingest (Batch) | NiFi | Database → Landing zone (MinIO) |
| 1b. Ingest (CDC) | Kafka Connect | Oracle CDC Source → Kafka Topic → Iceberg Sink → MinIO |
| 2. Stage | Spark | Landing → Staging (Iceberg table) |
| 3. Raw Vault | dbt | Staging → Hub, Link, Satellite |
| 4. Business Vault | dbt | Raw Vault → PIT, Bridge tables |
| 5. Information Mart | dbt | Business Vault → Star Schema |
| 6. Orchestrate | Airflow | Schedule DAG, monitor, handle errors |
| 7. Validate | DataHub | Check lineage, verify quality |

```bash
# Customer commits first DAG
git add dags/customer_pipeline.py
git commit -m "feat: Add customer data pipeline"
git push

# ArgoCD auto-deploy
argocd app sync hanas-demo
```

---

## Kiểm Tra & Đánh Giá

| Phần | Nội dung | Tiêu chí |
|------|----------|---------|
| Lý thuyết | 30 câu hỏi (Airflow, Spark, dbt, Data Vault) | ≥ 80% |
| Thực hành | Xây dựng pipeline NiFi → Airflow → Spark → dbt hoàn chỉnh | Hoàn thành trong 4 giờ |
| Code Review | DAG code, dbt models, Spark config | Đạt coding standards |

## Tài Liệu Tham Khảo

- [Thu thập dữ liệu — NiFi, Kafka](../01-ingestion/README.md)
- [Apache Kafka (CDC & Streaming)](../01-ingestion/apache-kafka/README.md)
- [Lưu trữ — MinIO, Iceberg](../02-storage/README.md)
- [Xử lý — Airflow, Spark](../03-processing/README.md)
- [Mô hình — dbt, Data Vault](../04-data-model/README.md)
- [Quản trị dữ liệu — DataHub](../05-governance/README.md)
- [Quickstart Guide](../guides/quickstart.md)
- [End-to-End Tutorial](../guides/end-to-end-tutorial.md)
