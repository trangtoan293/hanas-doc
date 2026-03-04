# Apache Polaris - Thông Tin Version

## Version Hiện Tại Trong Hanas Platform

| Component | Version | Ghi chú |
|---|---|---|
| **Apache Polaris** | 1.3.0 | Top-level Apache project |
| **PostgreSQL** | 16.x | Persistence backend |
| **Iceberg REST API** | v1 | Catalog API specification |

## Ma Trận Tương Thích

### Polaris ↔ Engine Compatibility

| Polaris | Iceberg Spec | Spark | Dremio | Trino | Flink |
|---|---|---|---|---|---|
| **1.3.x** | v1, v2 | 3.4, 3.5 | 24.x+ | 430+ | 1.18+ |
| **1.2.x** | v1, v2 | 3.4, 3.5 | 24.x+ | 430+ | 1.18+ |
| **1.1.x** | v1, v2 | 3.4, 3.5 | 24.x+ | 430+ | 1.17+ |
| **1.0.x** | v1, v2 | 3.4, 3.5 | 24.x+ | 430+ | 1.17+ |

### Polaris ↔ Storage Compatibility

| Storage | Polaris 1.0 | Polaris 1.1 | Polaris 1.2+ |
|---|---|---|---|
| **AWS S3** | ✅ | ✅ | ✅ |
| **Azure Blob** | ✅ | ✅ | ✅ |
| **GCS** | ✅ | ✅ | ✅ |
| **MinIO** | ⚠️ | ⚠️ | ✅ |

> ⚠️ MinIO hoạt động trên v1.0/v1.1 nhưng chưa được test chính thức. Từ v1.2 trở đi, MinIO được hỗ trợ và kiểm thử đầy đủ.

### Polaris ↔ Hanas Components

| Hanas Component | Version | Tương thích Polaris 1.3 | Ghi chú |
|---|---|---|---|
| **MinIO** | Latest | ✅ | S3-compatible, path-style access |
| **Apache Spark** | 3.5.1 | ✅ | Qua iceberg-spark-runtime |
| **Dremio** | 24.x+ | ✅ | Iceberg REST catalog source |
| **Apache Airflow** | 2.x | ✅ | REST API integration |
| **dbt-spark** | 1.7+ | ✅ | Qua Spark session config |
| **DataHub** | 0.14+ | ✅ | Metadata ingestion |
| **Apache Iceberg** | 1.5+ | ✅ | Table format |

## Lịch Sử Phát Hành

### v1.3.0 (Tháng 12/2025)

**Tính năng mới:**
- Generic Tables chính thức GA — hỗ trợ đăng ký table formats khác ngoài Iceberg
- Cải thiện cloud integration
- Helm chart: thêm `topologySpreadConstraints`, `priorityClassName`, Gateway API support
- Bug fixes và stability improvements

### v1.2.0 (Tháng 10/2025)

**Tính năng mới:**
- Fine-grained privileges cho table modifications
- Sub-catalog RBAC cho federated catalogs
- **MinIO** được hỗ trợ chính thức
- Wider object storage compatibility

### v1.1.0 (Tháng 9/2025)

**Tính năng mới:**
- **Catalog Federation** — hỗ trợ federate external catalogs
- **Hive Metastore Federation** — federate HMS tables vào Polaris
- Enhanced external identity provider support
- Helm chart configuration improvements

### v1.0.0 (Tháng 7/2025)

**Major milestone:**
- Bản release production-ready đầu tiên
- Packaged binaries cho download
- **Official Helm chart** cho Kubernetes deployment
- Stable REST API
- PostgreSQL persistence (JDBC)
- RBAC 2 lớp (Principal Roles + Catalog Roles)
- Credential vending
- OAuth2 authentication

### Pre-1.0 (Incubating Phase)

| Thời điểm | Sự kiện |
|---|---|
| **06/2024** | Snowflake open-source Polaris Catalog |
| **08/2024** | Apache Software Foundation nhận Polaris vào incubation |
| **02/2026** | Polaris graduated thành top-level Apache project |

## Upgrade Guide

### Từ v1.2.x → v1.3.x

```bash
# 1. Backup PostgreSQL database
pg_dump -h <HOST> -U polaris -d polaris \
  --format=custom --file=polaris_pre_upgrade.dump

# 2. Update Helm chart
helm repo update
helm upgrade polaris apache-polaris/polaris \
  --namespace polaris \
  --values polaris-values.yaml \
  --version 1.3.0

# 3. Verify upgrade
kubectl rollout status deployment/polaris -n polaris
curl -s http://polaris:8182/q/health/ready | jq .

# 4. Verify catalogs
curl -s http://polaris:8181/api/management/v1/catalogs \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### Breaking Changes

| Version | Breaking change | Giải pháp |
|---|---|---|
| v1.3.0 | Không có breaking changes | — |
| v1.2.0 | Privilege model thay đổi cho table modifications | Review và update RBAC policies |
| v1.1.0 | Không có breaking changes | — |
| v1.0.0 | First stable release | — |

## Tham Khảo

| Tài nguyên | URL |
|---|---|
| **Apache Polaris Website** | [polaris.apache.org](https://polaris.apache.org) |
| **GitHub Repository** | [github.com/apache/polaris](https://github.com/apache/polaris) |
| **Iceberg REST Catalog Spec** | [iceberg.apache.org/spec](https://iceberg.apache.org/spec/) |
| **Helm Chart** | [ArtifactHub](https://artifacthub.io/packages/helm/apache-polaris/polaris) |
| **Slack Community** | [apache-polaris.slack.com](https://join.slack.com/t/apache-polaris/shared_invite/zt-2y3l3r0fr-VtoW42ltir~nSzCYOrQgfw) |
| **Mailing List** | [dev@polaris.apache.org](https://lists.apache.org/list.html?dev@polaris.apache.org) |
