# DataHub - Best Practices

## Thiết Kế & Kiến Trúc Metadata

### 1. Tổ Chức Domains

Phân chia Domains theo cấu trúc nghiệp vụ doanh nghiệp, không theo kỹ thuật:

```
Domains (Hanas Platform)
├── Finance           → GL, PnL, Treasury, ...
├── Risk              → Credit Risk, Market Risk, Operational Risk
├── Operations        → Branch, ATM, Core Banking
├── Customer          → CIF, KYC, AML, Segmentation
├── HR                → Nhân sự, Lương, Tuyển dụng
└── Platform          → System datasets, audit logs, ETL metadata
```

> **Nguyên tắc**: Mỗi dataset chỉ thuộc **một Domain** duy nhất. Domain owner chịu trách nhiệm review và approve metadata changes.

### 2. Naming Conventions

| Entity | Convention | Ví dụ |
|---|---|---|
| **Dataset** | `<zone>.<table_name>` | `raw_vault.hub_customer`, `information_mart.dim_branch` |
| **Pipeline (Airflow)** | `<project>_<purpose>` | `demo_data_pipeline_e2e_incremental` |
| **Glossary Term** | Title Case, viết tắt trong ngoặc | `Close of Business Date (COB)` |
| **Tag** | lowercase, hyphenated | `pii`, `golden-source`, `deprecated` |
| **Domain** | Title Case | `Finance`, `Risk Management` |

### 3. Tagging Strategy

Xây dựng **taxonomy tags** chuẩn hóa cho toàn platform:

| Category | Tags | Mục đích |
|---|---|---|
| **Data Classification** | `pii`, `sensitive`, `confidential`, `public` | Phân loại bảo mật |
| **Data Quality** | `golden-source`, `derived`, `staging`, `deprecated` | Mức độ tin cậy |
| **Data Zone** | `landing`, `raw-vault`, `business-vault`, `information-mart` | Vùng dữ liệu |
| **Compliance** | `gdpr`, `sox`, `regulatory`, `audit-required` | Tuân thủ quy định |
| **Lifecycle** | `active`, `archived`, `to-be-retired` | Trạng thái vòng đời |

### 4. Ownership Model

Áp dụng mô hình **Three Lines of Defense** cho data governance:

| Vai trò | Trách nhiệm | Trong DataHub |
|---|---|---|
| **Data Owner** (Line 1) | Đơn vị nghiệp vụ sở hữu dữ liệu | Business Owner |
| **Data Steward** (Line 2) | Quản lý chất lượng, metadata, tuân thủ | Technical Owner + Edit policies |
| **Data Custodian** (Line 3) | Vận hành kỹ thuật, bảo trì hạ tầng | Platform Admin |

---

## Hiệu Năng

### Elasticsearch Optimization

| Tham số | Khuyến nghị | Lý do |
|---|---|---|
| **Heap size** | 50% RAM, max 4 GB | Quá lớn → GC pauses, quá nhỏ → OOM |
| **Replicas** | 3 nodes (production) | High availability, query throughput |
| **Refresh interval** | `30s` (default) | Tăng lên `60s` nếu ingestion nặng |
| **Max clause count** | `4096` | Hỗ trợ complex search queries |

```yaml
# production elasticsearch config
elasticsearch:
  replicas: 3
  esJavaOpts: "-Xms4g -Xmx4g"
  resources:
    requests:
      memory: "8Gi"
      cpu: "2"
    limits:
      memory: "8Gi"
      cpu: "4"
```

### Kafka Optimization

| Tham số | Khuyến nghị | Lý do |
|---|---|---|
| **Partitions** | 3–6 per topic | Parallelism cho consumers |
| **Retention** | 7 ngày | Đủ để replay nếu cần |
| **Replication factor** | 3 (production) | Durability |

### Ingestion Performance

- **Batch ingestion**: Chạy ngoài giờ cao điểm (vd: 2:00 AM)
- **Incremental ingestion**: Sử dụng `stateful_ingestion` để chỉ pull metadata mới
- **Parallelism**: Không chạy quá 3 ingestion sources cùng lúc (GMS overload)
- **Large catalogs**: Dùng `include_tables` filter để chia nhỏ ingestion

```yaml
# Ví dụ: Stateful Ingestion (chỉ pull metadata thay đổi)
source:
  type: iceberg
  config:
    stateful_ingestion:
      enabled: true
      remove_stale_metadata: true
```

---

## Bảo Mật

### 1. Authentication

| Môi trường | Phương pháp | Ghi chú |
|---|---|---|
| **Dev/Test** | Native (username/password) | Đổi default credentials |
| **Production** | OIDC SSO | Tích hợp Identity Provider (Keycloak, AD, Okta) |
| **API/Automation** | Personal Access Tokens | Rotate mỗi 90 ngày |

### 2. Authorization (RBAC)

Nguyên tắc **Least Privilege**:

```
Roles Hierarchy
├── Admin           → Full access (chỉ Platform Admin)
├── Editor          → Edit metadata trên assigned domains
├── Reader          → Read-only access
└── Custom Policies → Fine-grained domain/tag-based
```

Best practices:
- **Không dùng Admin role** cho người dùng thông thường
- Tạo **Metadata Policies** restrict theo Domain (mỗi team chỉ edit domain mình)
- Tạo **Platform Policies** restrict quyền manage ingestion, users
- **Policies apply sau ~60 giây** (caching) — user cần refresh session

### 3. Network Security

- DataHub **KHÔNG nên expose** ra public internet
- Sử dụng Kubernetes Ingress với authentication
- GMS API (`port 8080`) chỉ accessible từ internal network
- Bật `METADATA_SERVICE_AUTH_ENABLED=true` cho production

### 4. Secrets Management

- Credentials trong ingestion recipes → **Kubernetes Secrets** hoặc **HashiCorp Vault**
- **KHÔNG** hardcode passwords trong YAML files
- Sử dụng `${ENV_VAR}` placeholder trong recipes → inject qua env

---

## Vận Hành Production

### 1. Backup Strategy

| Thành phần | Phương pháp | Tần suất |
|---|---|---|
| **MySQL** | `mysqldump` hoặc Velero PVC backup | Daily |
| **Elasticsearch** | ES Snapshot API → MinIO bucket | Daily |
| **Kafka** | Topic retention đủ dài (7+ ngày) | Continuous |
| **Ingestion Recipes** | Git-managed YAML files | Mỗi thay đổi |

```bash
# Backup MySQL
mysqldump -h <MYSQL_HOST> -u root -p datahub > datahub_backup_$(date +%F).sql

# Backup Elasticsearch snapshots
curl -X PUT "http://<ES_HOST>:9200/_snapshot/hanas_backup/snapshot_$(date +%F)" \
  -H 'Content-Type: application/json' \
  -d '{"indices": "datahub*", "ignore_unavailable": true}'
```

### 2. Monitoring

Kết hợp với OpenObserve (năng lực System Management/Operations):

| Metric | Alert threshold | Hành động |
|---|---|---|
| GMS health endpoint | Non-200 > 3 lần | Restart GMS pod |
| Elasticsearch cluster status | `red` | Kiểm tra storage, restart nodes |
| Kafka consumer lag | > 10,000 | Scale MAE/MCE consumers |
| Ingestion failure rate | > 50% | Kiểm tra source connectivity |
| GMS response time | p99 > 5s | Tăng resources, kiểm tra ES |

### 3. Upgrade Checklist

1. [ ] Đọc [Release Notes](https://github.com/datahub-project/datahub/releases) cho breaking changes
2. [ ] Backup MySQL database
3. [ ] Backup Elasticsearch snapshots
4. [ ] Test upgrade trên staging environment
5. [ ] Cập nhật image tags trong Helm values
6. [ ] `helm upgrade` với `--wait`
7. [ ] Verify health checks pass
8. [ ] Verify search hoạt động (reindex nếu cần)
9. [ ] Verify ingestion sources vẫn chạy đúng
10. [ ] Verify Airflow `publish_datahub` TaskGroup hoạt động

### 4. Capacity Planning

| Scale | Datasets | Users | Resources tối thiểu |
|---|---|---|---|
| **Small** | < 1,000 | < 20 | 2 CPU, 8 GB RAM |
| **Medium** | 1,000–10,000 | 20–100 | 8 CPU, 32 GB RAM |
| **Large** | 10,000–100,000 | 100–500 | 16 CPU, 64 GB RAM, ES cluster 3 nodes |

---

## Tích Hợp Best Practices — ktl_airflow_utils

### Airflow → DataHub (ETL Pipeline)

- **Luôn sử dụng** `create_unified_publish_to_datahub_taskgroup` trong mọi ETL pipeline
- Import từ `package.ktl_airflow_utils.taskgroups`, **không** tự viết custom publish logic
- Đảm bảo variables đã set: `DATAHUB_GMS_HOST`, `DBT_ARTIFACTS_BUCKET`, AWS credentials
- `publish_dbt_tests` dùng `trigger_rule="all_done"` → vẫn chạy kể cả khi upstream task fail
- Nếu DataHub down → ETL pipeline vẫn tiếp tục (publish tasks fail nhưng không block pipeline chính)

### dbt → DataHub (Metadata Publishing)

- dbt artifacts (`manifest.json`, `catalog.json`, `run_results.json`) phải upload lên S3 **đúng prefix**
- `publish_dbt_to_datahub` sử dụng `acryl-datahub Pipeline` → tự parse manifest + emit lineage
- Platform instance: `DATAHUB_PLATFORM_INSTANCE=demo` (dbt), `target_platform=iceberg`
- Sử dụng dbt `description` field cho mọi model và column → tự động publish lên DataHub
- dbt tests → tự động thành DataHub Assertions (assertion URN = MD5(test_unique_id)[:16])

### Iceberg → DataHub (Schema Publishing)

- `publish_iceberg_from_catalog` đọc `catalog.json` từ S3 → emit `schemaMetadata` qua GMS MCP API
- Platform instance: `DATAHUB_ICEBERG_PLATFORM_INSTANCE=LakeHouse`
- `DATAHUB_INCLUDE_DATABASE_IN_NAME=false` (default) → dataset name: `schema.table`
- Schema evolution trên Iceberg → tự động phản ánh trên DataHub sau lần publish tiếp theo

### BI Lineage — Dremio & Superset

- Sử dụng `emit_dremio_lineage` để tạo lineage Dremio View → Iceberg Table
  - Tự động parse SQL từ Dremio API → extract source table references
  - Column-level lineage bằng cách match column names giữa Dremio schema và DataHub schema
  - `source_to_iceberg_platform_instance`: JSON mapping source name → platform instance (vd: `{"LakeHouse": "demo"}`)
- Sử dụng `emit_superset_dataset_lineage` cho Superset → Dremio
  - Phân biệt Physical vs Virtual Dataset: Virtual → parse SQL trực tiếp
  - Column mapping qua `SELECT` clause parsing
- Cả 2 functions chạy trong `PythonVirtualenvOperator` với `requirements=["requests"]`
