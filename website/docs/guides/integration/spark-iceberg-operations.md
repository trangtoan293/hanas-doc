# Integration Guide: Spark + Iceberg Operations

## Tổng Quan

Hướng dẫn cách Spark đọc/ghi dữ liệu dưới dạng Iceberg tables trên MinIO — thao tác cốt lõi trong Hanas Data Platform.

---

## 1. Cấu Hình SparkSession Cho Iceberg + MinIO

```python
import os
from pyspark.sql import SparkSession

spark = (SparkSession.builder
    .appName("hanas-iceberg-operations")
    # ── Iceberg Extensions ──
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
    # ── Iceberg Catalog: demo (Hive Metastore) ──
    .config("spark.sql.catalog.demo", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.demo.type", "hive")
    .config("spark.sql.catalog.demo.uri", "thrift://<HIVE_HOST>:9083")
    .config("spark.sql.catalog.demo.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
    .config("spark.sql.catalog.demo.s3.endpoint", "http://<MINIO_HOST>:9000")
    .config("spark.sql.catalog.demo.warehouse", "s3a://data/warehouse/")
    .config("spark.sql.defaultCatalog", "demo")
    # ── S3/MinIO (credentials qua K8s Secrets → env vars) ──
    .config("spark.hadoop.fs.s3a.endpoint", "http://<MINIO_HOST>:9000")
    .config("spark.hadoop.fs.s3a.access.key", os.environ.get("AWS_ACCESS_KEY_ID"))
    .config("spark.hadoop.fs.s3a.secret.key", os.environ.get("AWS_SECRET_ACCESS_KEY"))
    .config("spark.hadoop.fs.s3a.path.style.access", "true")
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
    .config("spark.hadoop.fs.s3a.connection.maximum", "100")
    # ── Performance ──
    .config("spark.sql.adaptive.enabled", "true")
    .config("spark.sql.adaptive.coalescePartitions.enabled", "true")
    .getOrCreate())
```

> **Lưu ý**: Khi chạy trên K8s, cấu hình này đã được khai báo trong `sparkConf` của SparkApplication manifest. Credentials được inject qua `envFrom` + K8s Secrets.

---

## 2. Tạo Bảng Iceberg

### 2.1 Tạo Database (Namespace)

```python
spark.sql("CREATE DATABASE IF NOT EXISTS demo.raw_vault")
spark.sql("CREATE DATABASE IF NOT EXISTS demo.business_vault")
spark.sql("CREATE DATABASE IF NOT EXISTS demo.information_mart")
```

### 2.2 Tạo Hub Table

```python
spark.sql("""
    CREATE TABLE IF NOT EXISTS demo.raw_vault.hub_customer (
        hub_customer_hk   STRING    COMMENT 'Hash key (MD5 of business key)',
        customer_id       STRING    COMMENT 'Business key',
        load_dts          TIMESTAMP COMMENT 'Load datetime',
        record_source     STRING    COMMENT 'Source system identifier'
    )
    USING iceberg
    PARTITIONED BY (days(load_dts))
    TBLPROPERTIES (
        'write.format.default' = 'parquet',
        'write.parquet.compression-codec' = 'zstd',
        'write.metadata.delete-after-commit.enabled' = 'true',
        'write.metadata.previous-versions-max' = '10'
    )
""")
```

### 2.3 Tạo Link Table

```python
spark.sql("""
    CREATE TABLE IF NOT EXISTS demo.raw_vault.lnk_customer_account (
        lnk_customer_account_hk  STRING    COMMENT 'Hash of combined keys',
        hub_customer_hk           STRING    COMMENT 'FK to hub_customer',
        hub_account_hk            STRING    COMMENT 'FK to hub_account',
        load_dts                  TIMESTAMP,
        record_source             STRING
    )
    USING iceberg
    PARTITIONED BY (days(load_dts))
""")
```

### 2.4 Tạo Satellite Table

```python
spark.sql("""
    CREATE TABLE IF NOT EXISTS demo.raw_vault.sat_customer_details (
        hub_customer_hk  STRING    COMMENT 'FK to hub_customer',
        load_dts         TIMESTAMP COMMENT 'Load datetime',
        load_end_dts     TIMESTAMP COMMENT 'End datetime (NULL = current)',
        record_source    STRING,
        hash_diff        STRING    COMMENT 'Hash of all descriptive columns',
        -- Descriptive columns
        full_name        STRING,
        email            STRING,
        phone            STRING,
        city             STRING,
        segment          STRING
    )
    USING iceberg
    PARTITIONED BY (days(load_dts))
""")
```

---

## 3. Ghi Dữ Liệu (Write Operations)

### 3.1 INSERT — Append dữ liệu mới

```python
from pyspark.sql.functions import md5, concat_ws, lit, current_timestamp

# Đọc từ landing
df_landing = (spark.read
    .parquet("s3a://landing/oracle/src_customers/load_date=2024-01-15/"))

# Transform → Hub
df_hub = (df_landing
    .select("customer_id")
    .distinct()
    .withColumn("hub_customer_hk", md5(concat_ws("||", lit("CUSTOMER"), "customer_id")))
    .withColumn("load_dts", current_timestamp())
    .withColumn("record_source", lit("ORACLE.SRC_CUSTOMERS")))

# Ghi append mode
df_hub.writeTo("demo.raw_vault.hub_customer").append()
```

### 3.2 MERGE — Upsert (chỉ insert nếu chưa có)

```python
# Merge Hub: chỉ insert key mới, skip existing
df_hub.createOrReplaceTempView("staging_hub_customer")

spark.sql("""
    MERGE INTO demo.raw_vault.hub_customer AS target
    USING staging_hub_customer AS source
    ON target.hub_customer_hk = source.hub_customer_hk
    WHEN NOT MATCHED THEN INSERT *
""")
```

### 3.3 Satellite — Change Detection

```python
from pyspark.sql.functions import col

# Hash descriptive columns
df_sat_new = (df_landing
    .withColumn("hub_customer_hk",
        md5(concat_ws("||", lit("CUSTOMER"), "customer_id")))
    .withColumn("hash_diff",
        md5(concat_ws("||", "full_name", "email", "phone", "city", "segment")))
    .withColumn("load_dts", current_timestamp())
    .withColumn("load_end_dts", lit(None).cast("timestamp"))
    .withColumn("record_source", lit("ORACLE.SRC_CUSTOMERS")))

# So sánh hash: chỉ ghi nếu dữ liệu thay đổi
df_existing = spark.table("demo.raw_vault.sat_customer_details") \
    .filter(col("load_end_dts").isNull()) \
    .select("hub_customer_hk", col("hash_diff").alias("existing_hash"))

df_changed = (df_sat_new
    .join(df_existing, "hub_customer_hk", "left")
    .filter(
        col("existing_hash").isNull() |  # Mới hoàn toàn
        (col("hash_diff") != col("existing_hash"))  # Đã thay đổi
    )
    .drop("existing_hash"))

# Append chỉ các bản ghi mới/thay đổi
df_changed.writeTo("demo.raw_vault.sat_customer_details").append()

print(f"Inserted {df_changed.count()} changed/new records")
```

> **Best Practice**: Dùng `hash_diff` để so sánh thay đổi thay vì so từng cột. MD5 hash nhanh và chính xác.

---

## 4. Đọc Dữ Liệu (Read Operations)

### 4.1 Đọc toàn bộ bảng

```python
df = spark.table("demo.raw_vault.hub_customer")
df.show()
```

### 4.2 Time Travel — Đọc tại thời điểm quá khứ

```python
# Đọc snapshot tại thời điểm cụ thể
df_past = (spark.read
    .option("as-of-timestamp", "2024-01-15T00:00:00+07:00")
    .table("demo.raw_vault.sat_customer_details"))

# Đọc snapshot cụ thể
df_snapshot = (spark.read
    .table("demo.raw_vault.sat_customer_details"))
```

### 4.3 Incremental Read — Chỉ đọc thay đổi

```python
# Đọc thay đổi giữa 2 snapshot
df_changes = (spark.read
    .option("start-snapshot-id", "11111")
    .option("end-snapshot-id", "22222")
    .table("demo.raw_vault.sat_customer_details"))
```

---

## 5. Table Maintenance

### 5.1 Compact Small Files

```python
# Gom file nhỏ → file lớn hơn (128MB target)
spark.sql("""
    CALL demo.system.rewrite_data_files(
        table => 'raw_vault.hub_customer',
        options => map('target-file-size-bytes', '134217728')
    )
""")
```

### 5.2 Expire Old Snapshots

```python
# Giữ lại snapshot 7 ngày gần nhất
spark.sql("""
    CALL demo.system.expire_snapshots(
        table => 'raw_vault.hub_customer',
        older_than => TIMESTAMP '2024-01-08 00:00:00',
        retain_last => 5
    )
""")
```

### 5.3 Remove Orphan Files

```python
spark.sql("""
    CALL demo.system.remove_orphan_files(
        table => 'raw_vault.hub_customer',
        older_than => TIMESTAMP '2024-01-01 00:00:00'
    )
""")
```

> **Best Practice**: Chạy maintenance jobs hàng tuần qua Airflow DAG riêng:
> ```python
> # dags/iceberg_maintenance.py — Schedule: weekly
> compact >> expire_snapshots >> remove_orphans
> ```

---

## 6. Best Practices

| Practice | Mô tả |
|---|---|
| **Partition by `days(load_dts)`** | Tối ưu query và maintenance |
| **Parquet + ZSTD compression** | Cân bằng size và speed |
| **MERGE cho Hub/Link** | Đảm bảo idempotent |
| **APPEND cho Satellite** | Giữ full history |
| **Hash diff cho change detection** | Tránh so từng cột |
| **Compact weekly** | Tránh small files |
| **Expire snapshots** | Kiểm soát metadata size |
| **Adaptive query execution** | Tối ưu shuffle tự động |
