# DBT - Thông Tin Version

## Version Hiện Tại

| Thông tin | Giá trị |
|---|---|
| **Project name** | `ktl_dbt` |
| **Project version** | 1.0.0 |
| **DBT-spark** | 1.9.0 |
| **DBT-metricflow** | 0.10.1 |
| **Python** | >= 3.11 |
| **Môi trường** | Kubernetes (SparkOperator) |

## Dependencies

### DBT Packages

| Package | Version | Mô tả |
|---|---|---|
| `DBT-labs/dbt_utils` | 1.3.0 | Essential utility macros |
| `DBT-labs/spark_utils` | 0.3.0 | Spark-specific utility macros |
| `ktl_autovault` | local | AutoVault - tự sinh Data Vault models |

### Python Dependencies

```
DBT-spark==1.9.0
DBT-metricflow[DBT-databricks,DBT-spark]==0.10.1
```

## Tương Thích

### Compatibility Matrix

| Component | Version | Ghi chú |
|---|---|---|
| **Apache Spark** | 3.x | Engine xử lý DBT models |
| **Apache Iceberg** | Compatible với Spark 3.x | File format cho tất cả models |
| **Hive Metastore** | 3.x | Catalog management (`thrift://`) |
| **MinIO / S3** | Latest | Object storage via `S3AFileSystem` |
| **Python** | >= 3.11 | Runtime requirement |
| **DBT config-version** | 2 | DBT project configuration version |

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
