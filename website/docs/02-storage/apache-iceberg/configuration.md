# Apache Iceberg - Cấu Hình

## 1. Cấu Hình Spark Catalog

Iceberg sử dụng Spark catalogs để quản lý bảng. Cấu hình được khai báo trong `sparkConf` của SparkApplication manifest.

### 1.1 Iceberg Spark Extensions (Bắt buộc)

```yaml
sparkConf:
  "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
```

> **Tại sao:** Extension này bật các SQL commands đặc biệt của Iceberg: `CALL` procedures, `MERGE INTO`, `ALTER TABLE ... ADD PARTITION FIELD`, time travel syntax, v.v.

### 1.2 Custom Iceberg Catalog (`demo`)

Catalog chính cho Data Vault và Data Mart:

```yaml
sparkConf:
  # Catalog class
  "spark.sql.catalog.demo": "org.apache.iceberg.spark.SparkCatalog"
  "spark.sql.catalog.demo.type": "hive"
  "spark.sql.catalog.demo.uri": "thrift://<HIVE_HOST>:9083"

  # S3FileIO — đọc/ghi file qua S3 API (MinIO)
  "spark.sql.catalog.demo.io-impl": "org.apache.iceberg.aws.s3.S3FileIO"
  "spark.sql.catalog.demo.s3.endpoint": "http://<MINIO_HOST>"
  "spark.sql.catalog.demo.warehouse": "s3a://data/warehouse/"

  # Metrics & Lock
  "spark.sql.catalog.demo.metrics-reporter-impl": "org.apache.iceberg.metrics.LoggingMetricsReporter"
  "spark.sql.catalog.demo.lock-enabled": "false"
  "spark.sql.catalog.demo.lock-impl": "org.apache.iceberg.util.NoLockManager"

  # Set làm default catalog
  "spark.sql.defaultCatalog": "demo"
```

### 1.3 ETL Admin Catalog (`LakeHouse`)

Catalog cho bảng ETL logging:

```yaml
sparkConf:
  "spark.sql.catalog.LakeHouse": "org.apache.iceberg.spark.SparkCatalog"
  "spark.sql.catalog.LakeHouse.type": "hive"
  "spark.sql.catalog.LakeHouse.uri": "thrift://<HIVE_HOST>:9083"
  "spark.sql.catalog.LakeHouse.io-impl": "org.apache.iceberg.aws.s3.S3FileIO"
  "spark.sql.catalog.LakeHouse.s3.endpoint": "http://<MINIO_HOST>"
  "spark.sql.catalog.LakeHouse.warehouse": "s3a://data/warehouse/"
  "spark.sql.catalog.LakeHouse.lock-enabled": "false"
  "spark.sql.catalog.LakeHouse.lock-impl": "org.apache.iceberg.util.NoLockManager"
```

### 1.4 Default Spark Catalog (`spark_catalog`)

Cho tables không phải Iceberg (Hive tables truyền thống):

```yaml
sparkConf:
  "spark.sql.catalog.spark_catalog": "org.apache.iceberg.spark.SparkSessionCatalog"
  "spark.sql.catalog.spark_catalog.type": "hive"
  "spark.sql.catalog.spark_catalog.lock-enabled": "false"
  "spark.sql.catalog.spark_catalog.lock-impl": "org.apache.iceberg.util.NoLockManager"
```

> **Khác biệt:** `SparkSessionCatalog` (cho `spark_catalog`) quản lý cả Iceberg và non-Iceberg tables. `SparkCatalog` (cho `demo`, `LakeHouse`) chỉ quản lý Iceberg tables.

---

## 2. Cấu Hình S3/MinIO

```yaml
sparkConf:
  "spark.hadoop.fs.s3a.endpoint": "http://<MINIO_HOST>"
  "spark.hadoop.fs.s3a.path.style.access": "true"        # Bắt buộc cho MinIO
  "spark.hadoop.fs.s3a.ssl.enabled": "false"              # Tắt SSL cho MinIO nội bộ
  "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
  "spark.hadoop.fs.s3a.aws.credentials.provider": "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"
```

> **Cảnh báo:** **KHÔNG** đặt `access.key` / `secret.key` trong `sparkConf`. Sử dụng `envFrom` với K8s Secrets:
>
> ```yaml
> driver:
>   envFrom:
>     - secretRef:
>         name: spark-k8s-aws-credentials
> executor:
>   envFrom:
>     - secretRef:
>         name: spark-k8s-aws-credentials
> ```

---

## 3. Table Properties Quan Trọng

### 3.1 Khi tạo bảng

```sql
CREATE TABLE demo.integration.hub_customer (
    hub_customer_hashkey STRING,
    load_date TIMESTAMP,
    record_source STRING,
    customer_id STRING
)
USING iceberg
TBLPROPERTIES (
    'format-version' = '2',                         -- Bật row-level deletes
    'write.format.default' = 'parquet',              -- File format (parquet/orc/avro)
    'write.parquet.compression-codec' = 'zstd',      -- Compression (zstd/snappy/gzip)
    'write.target-file-size-bytes' = '536870912',    -- 512MB target file size
    'read.parquet.vectorization.enabled' = 'true',   -- Vectorized reads
    'read.parquet.vectorization.batch-size' = '10000'
);
```

### 3.2 Table Properties Reference

| Property | Default | Mô tả |
|---|---|---|
| `format-version` | `1` | `2` để bật row-level deletes (MERGE/UPDATE/DELETE) |
| `write.format.default` | `parquet` | File format cho data files |
| `write.parquet.compression-codec` | `gzip` | `zstd` recommended cho balance size/speed |
| `write.target-file-size-bytes` | `536870912` | Target file size (512MB) |
| `write.metadata.delete-after-commit.enabled` | `false` | Tự xóa metadata files cũ |
| `write.metadata.previous-versions-max` | `100` | Số metadata files giữ lại |
| `read.parquet.vectorization.enabled` | `true` | Bật vectorized Parquet reads |
| `commit.retry.num-retries` | `4` | Số lần retry khi commit conflict |
| `commit.retry.min-wait-ms` | `100` | Wait time giữa các retry |
| `write.spark.accept-any-schema` | `false` | `true` để bật auto schema merge |

---

## 4. Cấu Hình dbt-spark với Iceberg

Trong `dbt_project.yml`, các model sử dụng Iceberg format:

```yaml
models:
  ktl_dbt:
    integration:
      +materialized: table
      +file_format: iceberg
      +schema: integration
      +tblproperties:
        "hive.engine.enabled": "true"
        "read.parquet.vectorization.enabled": "true"
        "read.parquet.vectorization.batch-size": "10000"
    data_mart:
      +materialized: table
      +file_format: iceberg
      +schema: data_mart
```

> **Lưu ý:** `+file_format: iceberg` quyết định dbt tạo Iceberg tables thay vì Hive tables thông thường.

---

## 5. Cấu Hình Maintenance

Các tham số maintenance được quản lý qua Airflow Variables:

| Variable | Default | Mô tả |
|---|---|---|
| `iceberg_default_catalog` | _(bắt buộc)_ | Catalog mặc định khi không chỉ định `targets` |
| `iceberg_snapshot_retention_days` | `7` | Số ngày giữ snapshot |
| `iceberg_target_file_size_mb` | `512` | Target file size cho compaction (MB) |
| `iceberg_orphan_retention_days` | `3` | Chỉ xóa orphan files cũ hơn N ngày |

> Chi tiết về maintenance operations: xem [Best Practices — Vận Hành Production](best-practices.md#5-vận-hành-production--maintenance).
