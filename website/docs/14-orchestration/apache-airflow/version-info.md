# Apache Airflow - Thông Tin Version

## Version Hiện Tại

| Thông tin | Giá trị |
|---|---|
| **Apache Airflow Version** | `2.x` — version production chính xác cần đối chiếu image/Helm release |
| **Airflow Image** | `<CẦN ĐIỀN IMAGE TAG/DIGEST>` |
| **Spark Version** | 3.5.1 |
| **Spark Operator Image** | `<REGISTRY>/<NAMESPACE>/dbt-spark-k8s-ktl:<PINNED_TAG>` |
| **dbt Command** | `ktl_dbt` (custom Data Vault dbt) |
| **Git-Sync** | `registry.k8s.io/git-sync/git-sync:v4.1.0` |
| **Môi trường** | Kubernetes |
| **Spark Mode** | `cluster` |

## Tương Thích

| Component | Version | Ghi chú |
|---|---|---|
| **Apache Spark** | 3.5.1 | Cluster mode trên K8s |
| **Apache Iceberg** | Spark Runtime 3.5 | Iceberg extensions cho Spark |
| **Hive Metastore** | Thrift protocol | Quản lý Iceberg catalogs |
| **MinIO** | S3-compatible | Object storage qua S3A FileIO |
| **dbt-spark** | 1.9.0 | Chạy transformation trong Spark runtime |
| **DataHub** | REST API | Metadata publishing |
| **Kubernetes** | 1.24+ | Spark Operator v1beta2 |

## Lịch Sử Thay Đổi

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| v1.0 | 2024-01 | Initial setup: E2E Init/Incremental pipelines |
| v1.1 | 2024-Q2 | MDM pipeline, DataHub publishing |
| v1.2 | 2024-Q3 | Backfill/Backdate DAGs, Dremio integration |
| v1.3 | 2024-Q4 | Maileroo email notifications, ad-hoc dbt ETL |
| v1.4 | 2025-Q1 | Unified publish TaskGroup, separate run/test artifacts |
