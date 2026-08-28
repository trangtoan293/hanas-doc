# dbt - Thông Tin Version

## Version Hiện Tại

| Thông tin | Giá trị |
|---|---|
| **Project name** | `ktl_dbt` |
| **Project version** | 1.0.0 |
| **dbt-spark** | 1.9.0 |
| **dbt-metricflow** | 0.10.1 |
| **Python** | >= 3.11 |
| **Môi trường** | Kubernetes (SparkOperator) |

## Dependencies

### dbt Packages

| Package | Version | Mô tả |
|---|---|---|
| `dbt-labs/dbt_utils` | 1.3.0 | Essential utility macros |
| `dbt-labs/spark_utils` | 0.3.0 | Spark-specific utility macros |
| `ktl_autovault` | local | AutoVault - tự sinh Data Vault models |

### Python Dependencies

```
dbt-spark==1.9.0
dbt-metricflow[dbt-databricks,dbt-spark]==0.10.1
```

## Tương Thích

### Compatibility Matrix

| Component | Version | Ghi chú |
|---|---|---|
| **Apache Spark** | 3.x | Engine xử lý dbt models |
| **Apache Iceberg** | Compatible với Spark 3.x | File format cho tất cả models |
| **Hive Metastore** | 3.x | Catalog management (`thrift://`) |
| **MinIO / S3** | Theo [baseline triển khai](../../00-overview/platform-baseline.md) | Object storage via `S3AFileSystem` |
| **Python** | >= 3.11 | Runtime requirement |
| **dbt config-version** | 2 | dbt project configuration version |

### Spark Extensions

```
org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
org.apache.iceberg.spark.SparkCatalog
org.apache.iceberg.spark.SparkSessionCatalog
org.apache.iceberg.aws.s3.S3FileIO
```

## Lịch Sử Thay Đổi

| Ngày | Version | Thay đổi |
|---|---|---|
| - | 1.0.0 | Initial release - Data Vault + MDM + Data Mart pipeline |
