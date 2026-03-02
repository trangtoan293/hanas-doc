# Đào Tạo Vận Hành Platform (Operations Training)

## Tổng Quan

| Thông tin | Chi tiết |
|-----------|---------|
| **Đối tượng** | DevOps Engineers, SREs, Support Engineers, Platform Engineers |
| **Thời lượng** | 4 tuần (full-time) |
| **Lịch học** | Mỗi ngày 8 giờ: 4 giờ theory + 4 giờ hands-on |
| **Thực tập** | Tuần 3-4: Thực hành với hệ thống thật |

## Điều Kiện Tiên Quyết

- Linux cơ bản (`cd`, `ls`, `grep`, `curl`)
- Docker cơ bản (`docker run`, `docker ps`)
- SQL cơ bản (`SELECT`, `JOIN`)
- **Không yêu cầu**: Kubernetes chuyên sâu, Spark, Airflow (sẽ đào tạo trong khóa)

## Kết Quả Sau Đào Tạo

Sau 4 tuần, học viên có khả năng:

- Triển khai hệ thống mới cho khách hàng (30 phút)
- Xử lý sự cố khi hệ thống down (MTTR < 30 phút)
- Giám sát hệ thống 24/7
- Giao tiếp với khách hàng khi có vấn đề
- Quản lý backup và disaster recovery

---

## Tuần 1: Foundation (Nền Tảng)

**Mục tiêu**: Hiểu Hanas là gì và cách các thành phần hoạt động cùng nhau.

### Ngày 1: Giới Thiệu Hanas Data Platform

#### Buổi sáng — Theory (4 giờ)

**Bài 1: Kiến trúc tổng quan (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Data Lakehouse là gì? So sánh Data Lake vs Data Warehouse vs Lakehouse | 30 phút |
| 7 Lớp của Hanas (chi tiết bên dưới) | 90 phút |
| Luồng dữ liệu end-to-end: CSV → MinIO → Spark → Iceberg → Dremio → Dashboard | 30 phút |

**7 Lớp Kiến Trúc Hanas:**

| Lớp | Tên | Công nghệ | Vai trò |
|-----|-----|-----------|---------|
| 1 | Ingestion (Thu thập) | NiFi, Kafka (Confluent / Debezium + AKHQ) | Thu thập dữ liệu batch & streaming (CDC) |
| 2 | Storage (Lưu trữ) | MinIO, Iceberg | Object storage & table format |
| 3 | Processing (Xử lý) | Airflow, Spark | Orchestration & compute |
| 4 | Data Model (Mô hình) | dbt, Data Vault 2.0 | Transformation & modeling |
| 5 | Governance (Quản trị) | DataHub | Metadata, lineage, quality |
| 6 | Federation (Liên kết) | Dremio | Query engine & semantic layer |
| 7 | Consumption (Tiêu thụ) | BI Tools | Dashboard & reporting |

> AI Service Layer (Dify, vLLM, Langfuse) mở rộng nền tảng với khả năng AI/ML.

📖 Tài liệu: [Kiến trúc tổng thể](../00-overview/architecture.md)

**Bài 2: Công nghệ cốt lõi (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Kubernetes cơ bản: Pod, Deployment, Service, Namespace | 60 phút |
| Container & Microservices: Docker image, registry, versioning | 45 phút |
| GitOps: Git repository, ArgoCD, Infrastructure as Code | 45 phút |

#### Buổi chiều — Hands-on (4 giờ)

**Lab 1: Khám phá hệ thống (2 giờ)**

```bash
# Xem cấu trúc cluster
kubectl get nodes
kubectl get namespaces

# Xem các services đang chạy
kubectl get pods -n hanas-demo
kubectl describe pod <pod-name>

# Xem logs
kubectl logs -n hanas-demo -l app=minio --tail=50

# Truy cập UI
# MinIO: http://localhost:9001
# Airflow: http://localhost:8081
# Dremio: http://localhost:9047
```

**Lab 2: Chạy pipeline đầu tiên (2 giờ)**

```bash
# Upload file CSV lên MinIO
mc cp data.csv myminio/landing/

# Trigger Airflow DAG
airflow dags trigger demo_pipeline

# Theo dõi Spark job
kubectl get sparkapplications -n hanas-demo

# Query trong Dremio
# SELECT * FROM raw_vault.hub_customer LIMIT 10;

# Kiểm tra kết quả
mc ls myminio/warehouse/raw_vault/
```

📖 Bài tập: Đọc [architecture.md](../00-overview/architecture.md) và mô tả luồng dữ liệu qua 7 lớp.

---

### Ngày 2: Storage Layer — MinIO + Iceberg

#### Buổi sáng — Theory (4 giờ)

**Bài 3: Object Storage với MinIO (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Object Storage: so sánh File/Block/Object, S3 API compatibility | 30 phút |
| MinIO Architecture: single node vs distributed, erasure coding, site replication | 45 phút |
| Buckets & Objects: policies, metadata, versioning, lifecycle | 45 phút |

📖 Tài liệu: [MinIO Documentation](../02-storage/minio/README.md)

**Bài 4: Apache Iceberg (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Table Format: tại sao cần, so sánh Hive vs Iceberg vs Delta Lake | 30 phút |
| Iceberg Features: ACID transactions, time travel, schema evolution, hidden partitioning | 60 phút |
| Maintenance: compaction, snapshot expiration, orphan cleanup | 30 phút |

📖 Tài liệu: [Iceberg Documentation](../02-storage/apache-iceberg/README.md)

#### Buổi chiều — Hands-on (4 giờ)

**Lab 3: Thao tác với MinIO (2 giờ)**

```bash
# Tạo bucket & upload/download files
mc mb myminio/test-bucket
mc cp localfile.csv myminio/test-bucket/
mc cp myminio/test-bucket/localfile.csv ./

# Xem cấu trúc Hanas buckets
mc ls myminio/
# Output: landing/  raw-vault/  business-vault/  information-mart/

# Bucket policies & giám sát
mc policy set download myminio/public-bucket
mc admin info myminio
mc du myminio/warehouse
```

**Lab 4: Thao tác với Iceberg (2 giờ)**

```python
# Tạo table với partitioning
spark.sql("""
CREATE TABLE demo.raw_vault.test_table (
    id INT, name STRING, created_at TIMESTAMP
) USING ICEBERG
PARTITIONED BY (days(created_at))
""")

# Insert data
spark.sql("""
INSERT INTO demo.raw_vault.test_table
VALUES (1, 'Alice', CURRENT_TIMESTAMP()),
       (2, 'Bob', CURRENT_TIMESTAMP())
""")

# Time travel — query data từ thời điểm quá khứ
spark.read.option("as-of-timestamp", "2024-01-15T10:00:00") \
    .table("demo.raw_vault.test_table")

# Maintenance: compact files & expire snapshots
spark.sql("CALL demo.system.rewrite_data_files(table => 'raw_vault.test_table')")
spark.sql("CALL demo.system.expire_snapshots(table => 'raw_vault.test_table', older_than => TIMESTAMP '2024-01-01 00:00:00')")
```

---

### Ngày 2.5: Streaming Layer — Apache Kafka & CDC

#### Buổi sáng — Theory (4 giờ)

**Bài 2.5a: Apache Kafka Fundamentals (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Kafka Architecture: brokers, topics, partitions, consumer groups, KRaft mode | 45 phút |
| Hai phiên bản: Confluent Platform vs Apache Kafka + Debezium + AKHQ | 30 phút |
| Luồng CDC: Oracle → Kafka Connect (CDC Source) → Topic → Iceberg Sink → MinIO | 45 phút |

**Bài 2.5b: Kafka Connect & Debezium (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Kafka Connect: Source vs Sink connectors, SMT transforms | 45 phút |
| Confluent Oracle CDC Source: LogMiner, redo log, heartbeat, schema capture | 45 phút |
| Iceberg Sink Connector: auto-create table, schema evolution, SMT chain | 30 phút |

📖 Tài liệu: [Kafka Documentation](../01-ingestion/apache-kafka/README.md)

#### Buổi chiều — Hands-on (4 giờ)

**Lab 2.5a: Quản lý Kafka (2 giờ)**

```bash
# Liệt kê topics
kafka-topics.sh --bootstrap-server kafka.confluent.svc.cluster.local:9071 --list

# Mô tả topic CDC
kafka-topics.sh --bootstrap-server kafka:9092 \
  --describe --topic ORACLE.DEMO_LAKE.TBL_TRANSACTION

# Kiểm tra consumer lag
kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
  --describe --group consum_sink_demo_group2

# Browse messages (AKHQ)
# Truy cập http://akhq.hanas.local → Topics → chọn topic → Data tab
```

**Lab 2.5b: Quản lý Kafka Connect connectors (2 giờ)**

```bash
# Kiểm tra connector status
curl -s http://connect:8083/connectors/DEMO_GROUP3/status | jq .
curl -s http://connect:8083/connectors/DEMO_SINK_GROUP2/status | jq .

# Restart connector task khi FAILED
curl -X POST http://connect:8083/connectors/DEMO_GROUP3/tasks/0/restart

# Pause / Resume connector
curl -X PUT http://connect:8083/connectors/DEMO_GROUP3/pause
curl -X PUT http://connect:8083/connectors/DEMO_GROUP3/resume

# Liệt kê connector plugins
curl -s http://connect:8083/connector-plugins | jq '.[].class'
```

📖 Bài tập: Đọc [Kafka user-guide](../01-ingestion/apache-kafka/user-guide.md), thực hành pause/resume connector và monitor consumer lag.

---

### Ngày 3: Processing Layer — Airflow + Spark

#### Buổi sáng — Theory (4 giờ)

**Bài 5: Apache Airflow (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Workflow Orchestration: DAG, dependencies, tại sao cần orchestration | 30 phút |
| Core Concepts: DAGs, Operators, Sensors, Hooks, XCom | 60 phút |
| Scheduling: cron expressions, backfill, KubernetesExecutor | 30 phút |

📖 Tài liệu: [Airflow Documentation](../03-processing/apache-airflow/README.md)

**Bài 6: Apache Spark (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Distributed Computing: Spark vs Hadoop, in-memory processing | 30 phút |
| Spark Architecture: Driver, Executors, K8s cluster manager | 45 phút |
| Spark + Iceberg: đọc/ghi tables, catalog config, optimization | 45 phút |

📖 Tài liệu: [Spark Documentation](../03-processing/apache-spark/README.md)

#### Buổi chiều — Hands-on (4 giờ)

**Lab 5: Tạo Airflow DAG (2 giờ)**

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import SparkKubernetesOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'hanas',
    'depends_on_past': False,
    'email_on_failure': True,
    'email': ['ops@hanas.local'],
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'customer_onboarding_pipeline',
    default_args=default_args,
    description='Simple ETL pipeline',
    schedule_interval=timedelta(hours=1),
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['customer', 'etl'],
) as dag:

    extract = PythonOperator(
        task_id='extract_from_source',
        python_callable=extract_data,
    )

    transform = SparkKubernetesOperator(
        task_id='transform_data',
        namespace='hanas-demo',
        application_file='spark-transform.yaml',
        do_xcom_push=True,
    )

    load = PythonOperator(
        task_id='load_to_warehouse',
        python_callable=load_data,
    )

    extract >> transform >> load
```

**Lab 6: Submit Spark Job trên Kubernetes (2 giờ)**

```yaml
# SparkApplication manifest
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: etl-job
  namespace: hanas-demo
spec:
  type: Python
  pythonVersion: "3"
  mode: cluster
  image: hanas/spark:3.5.1
  mainApplicationFile: s3a://scripts/etl.py
  sparkVersion: "3.5.1"
  restartPolicy:
    type: OnFailure
    onFailureRetries: 3
  driver:
    cores: 1
    memory: "2g"
    serviceAccount: spark
  executor:
    cores: 2
    instances: 3
    memory: "4g"
```

```bash
# Submit & theo dõi
kubectl apply -f spark-job.yaml
kubectl get sparkapplications -n hanas-demo
kubectl logs -f etl-job-driver -n hanas-demo
```

---

### Ngày 4: Governance & Federation — DataHub + Dremio

#### Buổi sáng — Theory (4 giờ)

**Bài 7: DataHub (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Data Governance: metadata management, lineage, quality, compliance | 30 phút |
| DataHub Features: catalog, lineage, business glossary, quality assertions | 60 phút |
| Integration: Airflow lineage, Spark lineage, dbt metadata | 30 phút |

📖 Tài liệu: [DataHub Documentation](../05-governance/datahub/README.md)

**Bài 8: Dremio (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Data Federation: query nhiều nguồn, virtual datasets, semantic layer | 30 phút |
| Dremio Architecture: coordinators, executors, reflections, C3 cache | 45 phút |
| Query Acceleration: raw/aggregation reflections, best practices | 45 phút |

📖 Tài liệu: [Dremio Documentation](../06-federation/dremio/README.md)

#### Buổi chiều — Hands-on (4 giờ)

**Lab 7: Khám phá DataHub (2 giờ)**

- Truy cập DataHub UI → Tìm kiếm dataset `hub_customer`
- Xem schema, owners, tags
- Xem lineage: nguồn dữ liệu đến từ đâu, đi đến đâu
- Kiểm tra data quality assertions

**Lab 8: Query trong Dremio (2 giờ)**

```sql
-- Basic query
SELECT * FROM raw_vault.hub_customer LIMIT 10;

-- Join tables
SELECT h.customer_id, s.full_name, s.email
FROM raw_vault.hub_customer h
JOIN raw_vault.sat_customer_details s
    ON h.hub_customer_hk = s.hub_customer_hk;

-- Tạo virtual dataset
CREATE VIRTUAL DATASET customer_360 AS
SELECT h.customer_id, s.full_name, s.email, s.phone, s.city
FROM raw_vault.hub_customer h
JOIN raw_vault.sat_customer_details s
    ON h.hub_customer_hk = s.hub_customer_hk;

-- Tạo Reflection (tăng tốc query)
ALTER DATASET customer_360 CREATE RAW REFLECTION customer_360_raw;
```

---

### Ngày 5: Tổng Kết Tuần 1 + Kiểm Tra

#### Buổi sáng — Review (4 giờ)

- Tóm tắt 7 lớp kiến trúc + AI Service layer
- Q&A giải đáp thắc mắc
- Best practices cho mỗi layer

**Thực hành tổng hợp**: Deploy pipeline hoàn chỉnh (upload data → trigger DAG → verify Spark → query Dremio → check lineage DataHub)

#### Buổi chiều — Kiểm Tra (4 giờ)

| Phần | Nội dung | Tiêu chí |
|------|----------|---------|
| Lý thuyết | 20 câu trắc nghiệm + 5 câu tự luận | Pass: 80% |
| Thực hành | Deploy mini pipeline + xử lý lỗi + query & verify | Hoàn thành đúng |

---

## Tuần 2: Operations & Troubleshooting

**Mục tiêu**: Biết cách giám sát hệ thống và xử lý sự cố.

### Ngày 6: Monitoring & Alerting

#### Buổi sáng — Theory (4 giờ)

**Bài 9: Monitoring Fundamentals (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| 3 Pillars of Observability: Metrics, Logs, Traces | 45 phút |
| OpenObserve Platform: log collection, metrics dashboards, alert config | 45 phút |
| Dashboard Design: executive, technical, customer-specific | 30 phút |

📖 Tài liệu: [OpenObserve Documentation](../07-system-management/openobserve/README.md)

**Bài 10: Alerting Best Practices (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Alert Classification: P1 (page immediately), P2 (business hours), P3 (next day) | 45 phút |
| Alert Fatigue Prevention: actionable alerts, proper thresholds, notification routing | 45 phút |
| On-call Rotation: PagerDuty setup, escalation policies, handoff procedures | 30 phút |

#### Buổi chiều — Hands-on (4 giờ)

**Lab 9: Tạo Dashboard**

```yaml
# Executive Dashboard: Customer Data Platform Health
Panels:
  1. Data Freshness (SLA: < 1h lag)
     Alert if > 60 minutes
  2. Pipeline Success Rate (SLA: > 99%)
     Alert if < 99%
  3. Query Performance (p95 < 5s)
     Alert if > 5s
  4. Cost per Month (Compute + Storage + Network)
```

**Lab 10: Cấu hình Alerting**

```yaml
# alerts.yaml
- alert: DataFreshnessSLABreach
  expr: data_freshness_minutes > 60
  for: 5m
  labels:
    severity: p1
    team: platform
  annotations:
    summary: "Data freshness SLA breached for {{ $labels.customer }}"
    runbook_url: "https://wiki/runbooks/data-freshness"

- alert: HighErrorRate
  expr: rate(error_count[5m]) > 0.01
  for: 10m
  labels:
    severity: p2
```

---

### Ngày 7: Backup & Disaster Recovery

#### Buổi sáng — Theory (4 giờ)

**Bài 11: Backup Strategies (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Backup Types: full vs incremental, hot vs cold, RPO | 45 phút |
| Velero for K8s: backup clusters, restore, schedule automation | 45 phút |
| MinIO Site Replication: real-time sync, bandwidth optimization, failover | 30 phút |

📖 Tài liệu: [Hạ tầng — Velero](../08-infrastructure/README.md)

**Bài 12: Disaster Recovery (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| DR Planning: RTO, business impact analysis, communication plans | 45 phút |
| DR Execution: failover decision tree, step-by-step procedures, validation | 45 phút |
| Testing: quarterly DR drills, documentation updates, lessons learned | 30 phút |

#### Buổi chiều — Hands-on (4 giờ)

**Lab 11: Thực hành Backup/Restore**

```bash
# Tạo backup
velero backup create daily-backup \
  --include-namespaces hanas-demo \
  --ttl 720h0m0s

# List & restore
velero backup get
velero restore create --from-backup daily-backup \
  --namespace-mappings hanas-demo:hanas-restore-test

# Verify
kubectl get pods -n hanas-restore-test
mc ls myminio-restore/warehouse/
```

**Lab 12: DR Drill Simulation**

```bash
# Simulate DC failure (dry-run)
kubectl delete namespace hanas-demo --dry-run=client

# Activate DR (theo runbook RB-006)
# Verify services in DR site
kubectl get pods -n hanas-demo-dr

# Đo RTO: Thời gian từ declare failure → service restored
```

---

### Ngày 8: Incident Response

#### Buổi sáng — Theory (4 giờ)

**Bài 13: Incident Management (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Incident Lifecycle: Detection → Triage → Response → Resolution → Post-mortem | 45 phút |
| Severity: Sev1 (all down), Sev2 (degraded), Sev3 (minor), Sev4 (request) | 45 phút |
| Communication: internal, customer, status page | 30 phút |

**Bài 14: Post-Mortem Process (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Blameless Culture: focus on systems, psychological safety | 45 phút |
| Post-Mortem Template: timeline, root cause (5 Whys), action items | 45 phút |
| Follow-up: action item tracking, metrics improvement, knowledge sharing | 30 phút |

#### Buổi chiều — Hands-on (4 giờ)

**Lab 13: Xử lý sự cố mô phỏng**

| Scenario | Thời gian | Mô tả |
|----------|----------|-------|
| NiFi Down | 1 giờ | Detect → triage → follow runbook RB-001 → communicate → resolve |
| Pipeline Failure | 1 giờ | Check Airflow UI → Spark logs → fix config → retry → verify quality |
| **Kafka Connector FAILED** | 1 giờ | Check connector status → review error log → restart task → verify consumer lag |
| Query Slow | 1 giờ | Check metrics → identify bottleneck → create reflection → verify |

---

### Ngày 9: Security Operations

#### Buổi sáng — Theory (4 giờ)

**Bài 15: Security for Operators (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Security Principles: least privilege, defense in depth, zero trust | 45 phút |
| Kubernetes Security: RBAC, network policies, pod security | 45 phút |
| Data Security: encryption at rest/in transit, secrets management (Vault) | 30 phút |

📖 Tài liệu: [An toàn thông tin](../09-security/README.md)

**Bài 16: Vulnerability Management (2 giờ)**

| Nội dung | Thời lượng |
|----------|-----------|
| Scanning: Trivy (images), Snyk (dependencies), SonarQube (code) | 45 phút |
| Patch Management: critical 24h, high 1 week, maintenance windows | 45 phút |
| Compliance: access reviews, audit logging, evidence collection | 30 phút |

#### Buổi chiều — Hands-on (4 giờ)

**Lab 14: Security Scanning**

```bash
# Scan Docker image
trivy image hanas/spark:latest

# Check RBAC permissions
kubectl auth can-i --list --namespace hanas-demo

# Review audit logs
kubectl logs -n kube-apiserver | grep hanas-demo
```

**Lab 15: Security Incident Response** — Kịch bản phát hiện unauthorized access: disable account → rotate credentials → review audit logs → assess exposure → notify stakeholders.

---

### Ngày 10: Tổng Kết Tuần 2 + Thi

#### Buổi sáng — Review (4 giờ)
- Review operations procedures
- Practice scenarios
- Q&A

#### Buổi chiều — Bài Thi Thực Hành (4 giờ)

**Scenario: Customer production outage**

> **Given**: Alert "Data pipeline failing for customer-abc", Customer: "No data since 2 hours"

| Bước | Thời gian |
|------|----------|
| 1. Triage and assess impact | 15 phút |
| 2. Identify root cause | 30 phút |
| 3. Implement fix | 60 phút |
| 4. Verify resolution | 30 phút |
| 5. Communicate to customer | 15 phút |
| 6. Write post-mortem | 30 phút |

**Pass criteria**: MTTR < 2 hours, communication chuyên nghiệp, root cause đúng, post-mortem đầy đủ.

---

## Tuần 3: Customer Support & Communication

**Mục tiêu**: Biết cách hỗ trợ khách hàng và giao tiếp chuyên nghiệp.

### Ngày 11-12: Customer Support Model (16 giờ)

**Nội dung chính:**

| Chủ đề | Mô tả |
|--------|-------|
| Support Tiers | L1 (basic), L2 (technical), L3 (engineering) |
| Ticketing System | Zendesk/Jira workflow |
| SLA Management | Response time, resolution time theo severity |
| Escalation | Quy trình escalation từ L1 → L3 |

📖 Tham khảo: [SLA & Cam kết](../11-maintenance/sla.md)

**Hands-on:**
- Mock support tickets — phân loại và xử lý
- Role play: Customer calls — giao tiếp chuyên nghiệp
- Viết knowledge base articles

---

### Ngày 13-14: Customer Onboarding (16 giờ)

**Nội dung chính:**

| Giai đoạn | Hoạt động |
|-----------|----------|
| Kickoff | Requirements gathering, sizing, security questionnaire |
| Provisioning | Deploy namespace, services, monitoring, alerts |
| Training Delivery | Admin training, DE training, Analyst training |
| Data Migration | Historical load, CDC setup, reconciliation |
| Go-live | Pre-go-live checklist, cutover, hypercare |

📖 Tham khảo: [Quy trình Onboarding Khách Hàng](customer-onboarding-guide.md)

**Hands-on:**
- Mock customer onboarding end-to-end
- Deliver training session cho customer giả lập
- Handle onboarding issues (chậm access, migration fail, scope creep)

---

### Ngày 15: Tuần 3 Review (8 giờ)

**Thực hành tổng hợp:**
- Onboard a test customer end-to-end
- Handle simulated support tickets
- Customer communication assessment

---

## Tuần 4: Advanced Topics & Certification

**Mục tiêu**: Chuyên sâu và chứng nhận.

### Ngày 16-17: Performance Tuning (16 giờ)

| Chủ đề | Nội dung |
|--------|---------|
| Spark Optimization | Resource tuning, shuffle optimization, caching |
| Iceberg Maintenance | Compaction, snapshot management, partition evolution |
| Dremio Query Tuning | Reflection strategies, C3 cache, query profiling |
| Capacity Planning | Growth projection, resource scaling, cost optimization |

**Hands-on**: Optimize slow queries, tune Spark jobs, plan capacity for growth.

---

### Ngày 18-19: Advanced Scenarios (16 giờ)

| Scenario | Mô tả |
|----------|-------|
| Multi-region Deployment | DR cross-region, data replication, failover |
| Large-scale Data Migration | Terabyte-scale migration, parallelism, validation |
| Complex Security | Multi-tenant RBAC, encryption, compliance audit |
| Custom Integrations | API integration, custom connectors, webhook |

---

### Ngày 20: Certification (8 giờ)

#### Buổi sáng — Thi (4 giờ)

| Phần | Nội dung | Tiêu chí |
|------|----------|---------|
| Written Exam | 50 câu hỏi | Pass: 85% |
| Practical Exam | Deploy customer + troubleshoot + write runbook | Pass |

#### Buổi chiều — Review & Feedback (4 giờ)
- Kết quả thi
- Personal development plan
- Next steps

---

## Tiêu Chí Chứng Nhận

### Yêu cầu đạt chứng nhận:

| Yêu cầu | Tiêu chí |
|----------|---------|
| Attendance | > 90% (tối đa 2 ngày nghỉ) |
| Weekly Assessment Tuần 1 | ≥ 80% |
| Weekly Assessment Tuần 2 | ≥ 80% |
| Weekly Assessment Tuần 3 | Pass practical |
| Final Written Exam | ≥ 85% |
| Final Practical Exam | Pass |
| Customer Communication | Pass |

### Cấp bậc chứng nhận:

| Cấp | Tên | Điều kiện |
|-----|-----|-----------|
| Bronze | Junior Operator | Passed Tuần 1-2 |
| Silver | Operator | Passed cả 4 tuần |
| Gold | Senior Operator | Silver + Excellence in practical |

---

## Lộ Trình Sau Đào Tạo

1. **Tuần 1-2 sau khóa**: Shadow senior engineer
2. **Tuần 3+**: On-call L1
3. **3 tháng**: Review performance và promotion path

---

## Tài Liệu Tham Khảo Bắt Buộc

| Tài liệu | Đường dẫn |
|-----------|----------|
| Kiến trúc tổng thể | [architecture.md](../00-overview/architecture.md) |
| Apache Kafka (CDC & Streaming) | [Kafka Documentation](../01-ingestion/apache-kafka/README.md) |
| Troubleshooting Guide | [troubleshooting.md](../guides/troubleshooting.md) |
| Quickstart Guide | [quickstart.md](../guides/quickstart.md) |
| End-to-End Tutorial | [end-to-end-tutorial.md](../guides/end-to-end-tutorial.md) |
| SLA & Cam kết | [sla.md](../11-maintenance/sla.md) |
| Quy trình bảo trì | [maintenance-process.md](../11-maintenance/maintenance-process.md) |

## Tài Liệu Tham Khảo Mở Rộng

- Kubernetes Basics — [kubernetes.io](https://kubernetes.io)
- Spark: The Definitive Guide (chapters 1-5)
- Site Reliability Engineering (Google book)

---

## Lịch Tổng Hợp

| Tuần | Trọng tâm | Hoạt động chính |
|------|-----------|----------------|
| **Tuần 1** | Foundation | Kiến trúc, components, basic operations |
| **Tuần 2** | Operations | Monitoring, DR, incident response, security |
| **Tuần 3** | Customer Support | Support model, onboarding, communication |
| **Tuần 4** | Advanced + Cert | Performance, scenarios, certification |
