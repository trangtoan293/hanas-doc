# Apache Iceberg - Hướng Dẫn Sử Dụng

## 1. Truy Cập Iceberg Tables

### 1.1 Qua Spark SQL (spark-shell / spark-sql)

```bash
# Port-forward Spark driver pod (nếu cần)
kubectl port-forward <spark-driver-pod> 4040:4040 -n spark-jobs
```

```sql
-- Sử dụng catalog demo (default)
USE demo;

-- Liệt kê schemas
SHOW DATABASES;

-- Liệt kê tables trong schema
SHOW TABLES IN integration;
```

### 1.2 Qua Airflow (SparkKubernetesOperator)

Spark jobs được submit qua Airflow với catalog đã cấu hình sẵn trong manifest YAML (xem [configuration.md](configuration.md)).

### 1.3 Qua Dremio

Dremio có thể đọc Iceberg tables trực tiếp từ Hive Metastore hoặc MinIO path.

---

## 2. DDL — Quản Lý Bảng

### 2.1 Tạo Bảng

```sql
-- Bảng cơ bản
CREATE TABLE demo.integration.hub_customer (
    hub_customer_hashkey STRING,
    load_date            TIMESTAMP,
    record_source        STRING,
    customer_id          STRING
)
USING iceberg;

-- Bảng với partitioning
CREATE TABLE demo.integration.sat_customer (
    hub_customer_hashkey STRING,
    load_date            TIMESTAMP,
    load_end_date        TIMESTAMP,
    record_source        STRING,
    customer_name        STRING,
    customer_email       STRING
)
USING iceberg
PARTITIONED BY (days(load_date))    -- Hidden partition by day
TBLPROPERTIES (
    'format-version' = '2',
    'write.parquet.compression-codec' = 'zstd'
);

-- Tạo từ SELECT (CTAS)
CREATE TABLE demo.data_mart.dim_customer
USING iceberg
AS SELECT * FROM demo.integration.hub_customer;
```

### 2.2 Thay Đổi Bảng (ALTER)

```sql
-- Thêm cột
ALTER TABLE demo.integration.hub_customer ADD COLUMNS (
    phone STRING COMMENT 'Số điện thoại',
    address STRING COMMENT 'Địa chỉ'
);

-- Đổi tên cột
ALTER TABLE demo.integration.hub_customer RENAME COLUMN phone TO phone_number;

-- Thay đổi type (chỉ widening: int → bigint, float → double)
ALTER TABLE demo.integration.hub_customer ALTER COLUMN customer_id TYPE BIGINT;

-- Xóa cột
ALTER TABLE demo.integration.hub_customer DROP COLUMN address;

-- Thêm comment
ALTER TABLE demo.integration.hub_customer ALTER COLUMN customer_id COMMENT 'Mã khách hàng';
```

### 2.3 Xóa Bảng

```sql
-- Xóa table (giữ data files)
DROP TABLE demo.integration.hub_customer;

-- Xóa table + data files
DROP TABLE demo.integration.hub_customer PURGE;
```

> ⚠️ `PURGE` xóa vĩnh viễn data trên MinIO. Không dùng trong production nếu chưa backup.

---

## 3. DML — Thao Tác Dữ Liệu

### 3.1 INSERT

```sql
-- Insert values
INSERT INTO demo.integration.hub_customer VALUES
('abc123', current_timestamp(), 'oracle_crm', '1001'),
('def456', current_timestamp(), 'oracle_crm', '1002');

-- Insert from SELECT
INSERT INTO demo.data_mart.dim_customer
SELECT * FROM demo.integration.hub_customer
WHERE load_date >= '2024-01-01';

-- INSERT OVERWRITE (replace partition data)
INSERT OVERWRITE demo.integration.sat_customer
SELECT * FROM staging_data
WHERE load_date = '2024-01-15';
```

### 3.2 MERGE INTO (Upsert)

```sql
-- Upsert pattern: insert new, update existing
MERGE INTO demo.integration.hub_customer AS target
USING staging.new_customers AS source
ON target.customer_id = source.customer_id
WHEN MATCHED THEN
    UPDATE SET
        load_date = source.load_date,
        record_source = source.record_source
WHEN NOT MATCHED THEN
    INSERT (hub_customer_hashkey, load_date, record_source, customer_id)
    VALUES (source.hashkey, source.load_date, source.record_source, source.customer_id);
```

> **Yêu cầu:** Bảng phải có `format-version = 2` để sử dụng MERGE INTO.

### 3.3 UPDATE & DELETE

```sql
-- Update
UPDATE demo.integration.hub_customer
SET record_source = 'salesforce'
WHERE customer_id = '1001';

-- Delete
DELETE FROM demo.integration.hub_customer
WHERE load_date < '2023-01-01';
```

> **Yêu cầu:** Format version 2. Row-level operations tạo delete files, cần compaction định kỳ.

---

## 4. Time Travel

### 4.1 Xem Snapshots

```sql
-- Liệt kê tất cả snapshots
SELECT
    snapshot_id,
    committed_at,
    operation,
    summary['added-records'] AS added_records,
    summary['deleted-records'] AS deleted_records
FROM demo.integration.hub_customer.snapshots
ORDER BY committed_at DESC;
```

### 4.2 Truy Vấn Snapshot Cũ

```sql
-- Query theo snapshot ID
SELECT * FROM demo.integration.hub_customer VERSION AS OF 123456789;

-- Query theo timestamp
SELECT * FROM demo.integration.hub_customer TIMESTAMP AS OF '2024-06-15 10:00:00';
```

### 4.3 Rollback

```sql
-- Rollback về snapshot cụ thể
CALL demo.system.rollback_to_snapshot('integration.hub_customer', 123456789);

-- Rollback về thời điểm cụ thể
CALL demo.system.rollback_to_timestamp('integration.hub_customer', TIMESTAMP '2024-06-15 10:00:00');
```

> **Lưu ý:** Rollback tạo snapshot mới trỏ về state cũ. Snapshots cũ vẫn tồn tại cho đến khi expire.

---

## 5. Schema Evolution

Iceberg hỗ trợ thay đổi schema mà **không cần rewrite dữ liệu**. Mỗi cột được theo dõi bằng unique ID, không phải tên.

### 5.1 Các Thao Tác Schema Được Hỗ Trợ

| Thao tác | SQL | Có cần rewrite? |
|---|---|---|
| Thêm cột | `ADD COLUMNS` | ❌ Không |
| Xóa cột | `DROP COLUMN` | ❌ Không |
| Đổi tên cột | `RENAME COLUMN` | ❌ Không |
| Thay đổi type | `ALTER COLUMN ... TYPE` | ❌ Không (chỉ widening) |
| Thay đổi thứ tự | `ALTER COLUMN ... AFTER` | ❌ Không |
| Thêm comment | `ALTER COLUMN ... COMMENT` | ❌ Không |

### 5.2 Auto Schema Merge

Khi write data có schema khác với bảng hiện tại:

```sql
-- Bật auto merge trên bảng
ALTER TABLE demo.integration.hub_customer SET TBLPROPERTIES (
    'write.spark.accept-any-schema' = 'true'
);
```

```scala
// Scala/PySpark — enable merge khi write
data.writeTo("demo.integration.hub_customer")
    .option("mergeSchema", "true")
    .append()
```

---

## 6. Partition Evolution

Iceberg cho phép thay đổi partition scheme **mà không cần rewrite dữ liệu cũ**. Dữ liệu cũ giữ nguyên layout, dữ liệu mới sử dụng layout mới.

### 6.1 Partition Transforms

| Transform | Ví dụ | Mô tả |
|---|---|---|
| `identity` | `PARTITIONED BY (country)` | Partition theo giá trị gốc |
| `year` | `PARTITIONED BY (year(created_at))` | Partition theo năm |
| `month` | `PARTITIONED BY (month(created_at))` | Partition theo tháng |
| `day` | `PARTITIONED BY (days(created_at))` | Partition theo ngày |
| `hour` | `PARTITIONED BY (hours(created_at))` | Partition theo giờ |
| `bucket(N)` | `PARTITIONED BY (bucket(16, customer_id))` | Hash bucketing |
| `truncate(N)` | `PARTITIONED BY (truncate(10, name))` | Truncate string/number |

### 6.2 Thay Đổi Partition

```sql
-- Thêm partition field
ALTER TABLE demo.integration.sat_customer
ADD PARTITION FIELD months(load_date);

-- Thay thế partition field
ALTER TABLE demo.integration.sat_customer
REPLACE PARTITION FIELD days(load_date) WITH months(load_date);

-- Xóa partition field
ALTER TABLE demo.integration.sat_customer
DROP PARTITION FIELD months(load_date);
```

> **Hidden partitioning:** User query không cần biết partition layout. Iceberg tự động pruning dựa trên filter conditions.

---

## 7. Metadata Tables

Iceberg cung cấp các metadata tables để kiểm tra trạng thái bảng:

### 7.1 Các Metadata Tables

```sql
-- Snapshots: lịch sử commit
SELECT * FROM demo.integration.hub_customer.snapshots;

-- History: lịch sử thay đổi
SELECT * FROM demo.integration.hub_customer.history;

-- Files: data files trong snapshot hiện tại
SELECT file_path, file_format, record_count, file_size_in_bytes
FROM demo.integration.hub_customer.files;

-- Manifests: manifest files
SELECT path, length, added_files_count, deleted_files_count
FROM demo.integration.hub_customer.manifests;

-- Partitions: partition statistics
SELECT partition, record_count, file_count
FROM demo.integration.hub_customer.partitions;

-- All data files (across all snapshots)
SELECT * FROM demo.integration.hub_customer.all_data_files;
```

### 7.2 Kiểm Tra Sức Khỏe Bảng

```sql
-- Số lượng small files (< 100MB)
SELECT
    COUNT(*) AS total_files,
    COUNT(CASE WHEN file_size_in_bytes < 104857600 THEN 1 END) AS small_files,
    SUM(file_size_in_bytes) / 1024 / 1024 / 1024 AS total_size_gb,
    AVG(file_size_in_bytes) / 1024 / 1024 AS avg_file_size_mb
FROM demo.integration.hub_customer.files;

-- Số snapshots (quá nhiều → cần expire)
SELECT COUNT(*) AS snapshot_count,
       MIN(committed_at) AS oldest_snapshot,
       MAX(committed_at) AS newest_snapshot
FROM demo.integration.hub_customer.snapshots;
```

---

## 8. Quản Lý & Giám Sát

### 8.1 Kiểm Tra Table Properties

```sql
SHOW TBLPROPERTIES demo.integration.hub_customer;
```

### 8.2 Spark UI

Theo dõi Spark jobs qua port-forward:

```bash
kubectl port-forward <driver-pod> 4040:4040 -n spark-jobs
open http://localhost:4040
```

### 8.3 Iceberg Metrics

Nếu đã cấu hình `LoggingMetricsReporter`:

```yaml
"spark.sql.catalog.demo.metrics-reporter-impl": "org.apache.iceberg.metrics.LoggingMetricsReporter"
```

Metrics sẽ được log trong Spark driver logs:

```bash
kubectl logs <driver-pod> -n spark-jobs | grep "IcebergMetrics"
```
