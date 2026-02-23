# Apache Spark - Thông Tin Version

## Version Hiện Tại

| Thông tin | Giá trị |
|---|---|
| **Spark** | 3.5.1 (Bitnami base) |
| **Deploy mode** | Kubernetes (Spark Operator) |
| **Image** | `dbt-spark-k8s-ktl` |

## Version Matrix

### Runtime (Docker Image)

| Component | Version | Nguồn |
|---|---|---|
| Spark | 3.5.1 | `bitnami/spark:3.5.1` |
| Iceberg Spark Runtime | 1.8.1 | `iceberg-spark-runtime-3.5_2.12` |
| Iceberg AWS Bundle | 1.8.1 | `iceberg-aws-bundle` |
| Hadoop AWS | 3.3.4 | `hadoop-aws` |
| AWS Java SDK Bundle | 1.12.772 | `aws-java-sdk-bundle` |

### JDBC Drivers

| Driver | Version | Image |
|---|---|---|
| Oracle JDBC (ojdbc11) | 23.7.0.25.01 | Standard image |
| MySQL Connector/J | 8.0.33 | Extended image (`Dockerfile.new`) |
| MSSQL JDBC | 12.8.1.jre11 | Extended image (`Dockerfile.new`) |

### Python Dependencies

| Package | Version |
|---|---|
| pyspark | ≥ 3.5.1 |
| dbt-spark | 1.9.0 |
| pyiceberg | ≥ 0.7.0 (hive, s3fs) |
| pandas | ≥ 2.0.0 |
| numpy | ≥ 2.0.0, < 3.0.0 |
| pyarrow | ≥ 12.0.0 |
| boto3 | ≥ 1.26.0 |
| oracledb | ≥ 2.0.0 |

### Infrastructure

| Component | Version |
|---|---|
| Kubernetes | v1.24+ |
| Spark Operator CRD | `sparkoperator.k8s.io/v1beta2` |
| Git-sync | v4.1.0 (`registry.k8s.io/git-sync/git-sync`) |
| Helm | v3.0+ |

## Tương Thích

| Spark Version | Iceberg Version | Scala Version | Java Version |
|---|---|---|---|
| 3.5.x | 1.8.x | 2.12 | 11+ |
| 3.4.x | 1.4.x – 1.6.x | 2.12 | 8+ |

### Lưu Ý Tương Thích

- Iceberg Spark Runtime JAR **phải khớp** major version của Spark (ví dụ: `iceberg-spark-runtime-3.5_2.12` cho Spark 3.5.x)
- Bitnami Spark image sử dụng **OpenJDK** bundled, không cần cài riêng
- `dbt-spark==1.9.0` tương thích với Spark 3.5.x qua method `session`
- Git-sync v4.x sử dụng biến `GIT_SYNC_*` (v3.x dùng `GITSYNC_*` → khác tên biến)

## Lịch Sử Thay Đổi

| Ngày | Thay đổi |
|---|---|
| 2025-10 | Khởi tạo Spark on K8s với Spark 3.5.1 + Iceberg 1.8.1 |
| 2025-10 | Thêm dbt-spark 1.9.0 integration |
| 2025-10 | Thêm git-sync sidecar pattern cho dbt-project |
| 2025-10 | Thêm MSSQL JDBC driver (extended image) |
