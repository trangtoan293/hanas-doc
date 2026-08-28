# Apache Iceberg - Best Practices

## 1. Thiết Kế & Kiến Trúc

### 1.1 Chọn Format Version

```sql
-- Luôn sử dụng format version 2 cho bảng mới
CREATE TABLE demo.integration.my_table (...)
USING iceberg
TBLPROPERTIES ('format-version' = '2');
```

| Version | Tính năng |
|---|---|
| V1 | Append-only, snapshot isolation |
| **V2 (khuyến nghị)** | Row-level deletes (MERGE/UPDATE/DELETE), equality deletes |

### 1.2 Partition Strategy

```
STEP 1: QUERY PATTERNS — Xác định filter columns phổ biến nhất
STEP 2: CARDINALITY   — Cardinality quá cao? → dùng bucket/truncate
STEP 3: GRANULARITY   — Chọn đúng mức: year > month > day > hour
STEP 4: FILE COUNT    — Mỗi partition nên có ít file, mỗi file ~512MB
```

```sql
-- ĐÚNG — Partition theo tháng cho batch T+1
CREATE TABLE demo.integration.sat_transaction (...)
USING iceberg
PARTITIONED BY (months(transaction_date));

-- ĐÚNG — Bucket cho high-cardinality column
CREATE TABLE demo.integration.link_customer_account (...)
USING iceberg
PARTITIONED BY (bucket(16, customer_id));

-- SAI — Partition theo ngày cho bảng nhỏ → quá nhiều partitions rỗng
CREATE TABLE demo.integration.hub_small_ref (...)
USING iceberg
PARTITIONED BY (days(load_date));  -- Chỉ vài records/ngày → small files
```

> **Rule of thumb:** Mỗi partition nên chứa ít nhất 100MB data. Nếu ít hơn, tăng granularity (day → month) hoặc bỏ partition.

### 1.3 Sort Order

```sql
-- Sort order giúp cải thiện query pruning
ALTER TABLE demo.integration.sat_customer
WRITE ORDERED BY load_date, hub_customer_hashkey;
```

### 1.4 File Format & Compression

```sql
-- Khuyến nghị cho platform
ALTER TABLE demo.integration.hub_customer SET TBLPROPERTIES (
    'write.format.default' = 'parquet',          -- Parquet cho analytics
    'write.parquet.compression-codec' = 'zstd'   -- zstd: balance tốt size/speed
);
```

| Codec | Compression Ratio | Speed | Khuyến nghị |
|---|---|---|---|
| `zstd` | Cao | Nhanh | Production default |
| `snappy` | Trung bình | Rất nhanh | Khi cần tốc độ đọc tối đa |
| `gzip` | Rất cao | Chậm | Archival / cold storage |

---

## 2. Hiệu Năng

### 2.1 Target File Size

```sql
ALTER TABLE demo.integration.hub_customer SET TBLPROPERTIES (
    'write.target-file-size-bytes' = '536870912'  -- 512MB (recommended)
);
```

| Workload | Target Size | Lý do |
|---|---|---|
| Analytics (scan-heavy) | 512MB | Ít files, giảm planning overhead |
| Mixed (read/write) | 256MB | Balance giữa write latency và read perf |
| Streaming | 128MB | Commit nhanh, compaction bù sau |

### 2.2 Tránh Small File Problem

Small files là **nguyên nhân #1** gây chậm query trên Iceberg. Nguyên nhân:
- Nhiều INSERT nhỏ liên tục
- Partition quá granular (day cho table nhỏ)
- Streaming writes không compaction

**Giải pháp:**

```sql
-- Kiểm tra small files
SELECT
    COUNT(*) AS total_files,
    COUNT(CASE WHEN file_size_in_bytes < 104857600 THEN 1 END) AS small_files,
    AVG(file_size_in_bytes) / 1024 / 1024 AS avg_size_mb
FROM demo.integration.hub_customer.files;

-- Compaction nếu > 20% small files
CALL demo.system.rewrite_data_files(
    table => 'integration.hub_customer',
    options => map('target-file-size-bytes', '536870912')
);
```

### 2.3 Metadata Tuning

```sql
-- Giới hạn số metadata files cũ
ALTER TABLE demo.integration.hub_customer SET TBLPROPERTIES (
    'write.metadata.delete-after-commit.enabled' = 'true',
    'write.metadata.previous-versions-max' = '10'
);
```

### 2.4 Vectorized Reads

```sql
ALTER TABLE demo.integration.hub_customer SET TBLPROPERTIES (
    'read.parquet.vectorization.enabled' = 'true',
    'read.parquet.vectorization.batch-size' = '10000'
);
```

---

## 3. Bảo Mật

### 3.1 Credentials qua K8s Secrets

```yaml
# ĐÚNG — Inject credentials từ Kubernetes Secrets
driver:
  envFrom:
    - secretRef:
        name: spark-k8s-aws-credentials
executor:
  envFrom:
    - secretRef:
        name: spark-k8s-aws-credentials
```

```yaml
# SAI — Hardcode credentials trong sparkConf
sparkConf:
  "spark.hadoop.fs.s3a.access.key": "AKIAIOSFODNN7EXAMPLE"
  "spark.hadoop.fs.s3a.secret.key": "wJalrXUtnFEMI/..."
```

### 3.2 Lock Manager

Trong môi trường single-writer hoặc Hive Metastore đã serialize commits:

```yaml
sparkConf:
  "spark.sql.catalog.demo.lock-enabled": "false"
  "spark.sql.catalog.demo.lock-impl": "org.apache.iceberg.util.NoLockManager"
```

> **Khi nào bật lock:** Nhiều writers concurrent (multi-pipeline) mà Hive Metastore không serialize commits → bật lock-enabled để tránh commit conflicts.

---

## 4. Data Modeling với Iceberg

### 4.1 Data Vault trên Iceberg

Pattern chuẩn trong platform cho Raw Vault:

```sql
-- Hub: Business key + metadata
CREATE TABLE demo.integration.hub_customer (
    hub_customer_hashkey STRING,
    load_date            TIMESTAMP,
    record_source        STRING,
    customer_id          STRING
) USING iceberg
TBLPROPERTIES ('format-version' = '2');

-- Satellite: Descriptive attributes + historization
CREATE TABLE demo.integration.sat_customer (
    hub_customer_hashkey STRING,
    load_date            TIMESTAMP,
    load_end_date        TIMESTAMP,
    record_source        STRING,
    hashdiff             STRING,
    customer_name        STRING,
    customer_email       STRING,
    customer_phone       STRING
) USING iceberg
PARTITIONED BY (months(load_date))
TBLPROPERTIES ('format-version' = '2');

-- Link: Relationship
CREATE TABLE demo.integration.link_customer_account (
    link_customer_account_hashkey STRING,
    hub_customer_hashkey          STRING,
    hub_account_hashkey           STRING,
    load_date                     TIMESTAMP,
    record_source                 STRING
) USING iceberg
TBLPROPERTIES ('format-version' = '2');
```

### 4.2 dbt Model Config

```yaml
# dbt_project.yml
models:
  ktl_dbt:
    integration:
      +materialized: table
      +file_format: iceberg
      +schema: integration
      +tblproperties:
        "hive.engine.enabled": "true"
        "read.parquet.vectorization.enabled": "true"
```

---

## 5. Vận Hành Production — Maintenance

### 5.1 Tổng Quan Maintenance Operations

Iceberg tables cần bảo trì định kỳ. Platform sử dụng Airflow DAG `iceberg_maintenance` chạy hàng ngày lúc 4:00 AM UTC.

**Thứ tự thực hiện (rất quan trọng):**

```
Compaction → Expire Snapshots → Remove Orphans → Rewrite Manifests
```

Lý do thứ tự:
1. **Compaction** trước: gom small files thành files lớn
2. **Expire snapshots**: xóa snapshots cũ (có thể reference small files cũ)
3. **Remove orphans**: xóa files không được reference bởi snapshot nào
4. **Rewrite manifests**: gom manifest files sau khi cleanup

### 5.2 Compaction (`rewrite_data_files`)

Gom các small files thành files lớn hơn:

```sql
-- Compaction cơ bản
CALL demo.system.rewrite_data_files('integration.hub_customer');

-- Với target file size
CALL demo.system.rewrite_data_files(
    table => 'integration.hub_customer',
    options => map('target-file-size-bytes', '536870912')  -- 512MB
);

-- Chỉ compaction partition cụ thể
CALL demo.system.rewrite_data_files(
    table => 'integration.sat_customer',
    where => 'load_date >= "2025-01-01" AND load_date < "2025-02-01"'
);

-- Sort compaction (sắp xếp lại data để tối ưu reads)
CALL demo.system.rewrite_data_files(
    table => 'integration.hub_customer',
    strategy => 'sort',
    sort_order => 'customer_id ASC'
);

-- Z-order compaction (tối ưu multi-column filter)
CALL demo.system.rewrite_data_files(
    table => 'integration.hub_customer',
    strategy => 'sort',
    sort_order => 'zorder(customer_id, load_date)'
);
```

**Cấu hình trong platform:** Target file size = **512MB** (từ Airflow Variable `iceberg_target_file_size_mb`).

### 5.3 Expire Snapshots (`expire_snapshots`)

Xóa snapshots cũ để thu hồi storage:

```sql
-- Expire snapshots cũ hơn 7 ngày
CALL demo.system.expire_snapshots(
    table => 'integration.hub_customer',
    older_than => TIMESTAMP '2025-06-08 00:00:00',
    retain_last => 2  -- Luôn giữ ít nhất 2 snapshots
);
```

> **Cảnh báo:** **Sau khi expire snapshots, time travel về các snapshot đã xóa sẽ không còn hoạt động.**

**Cấu hình trong platform:** Retention = **7 ngày** (từ Airflow Variable `iceberg_snapshot_retention_days`).

### 5.4 Remove Orphan Files (`remove_orphan_files`)

Xóa data files không được reference bởi bất kỳ snapshot nào:

```sql
-- Xóa orphan files cũ hơn 3 ngày
CALL demo.system.remove_orphan_files(
    table => 'integration.hub_customer',
    older_than => TIMESTAMP '2025-06-12 00:00:00'
);
```

**Khi nào có orphan files:**
- Job ghi dữ liệu bị fail giữa chừng → files đã ghi nhưng chưa commit
- Manual operations (xóa snapshot nhưng chưa cleanup files)

**Cấu hình trong platform:** Retention = **3 ngày** (từ Airflow Variable `iceberg_orphan_retention_days`).

### 5.5 Rewrite Manifests (`rewrite_manifests`)

Gom/tối ưu manifest files sau cleanup:

```sql
CALL demo.system.rewrite_manifests('integration.hub_customer');

-- Rewrite cho partition spec cụ thể
CALL demo.system.rewrite_manifests(
    table => 'integration.hub_customer',
    spec_id => 1
);
```

### 5.6 Airflow DAG Configuration

| Parameter | Type | Default | Mô tả |
|---|---|---|---|
| `targets` | string | _(all tables in default catalog)_ | Patterns: `catalog.*`, `catalog.schema.*`, `catalog.schema.table` |
| `target_file_size_mb` | integer | 512 | Target compacted file size |
| `snapshot_retention_days` | integer | 7 | Days to retain snapshots |
| `orphan_retention_days` | integer | 3 | Days to retain orphan files |
| `skip_compaction` | boolean | false | Skip compaction step |
| `skip_expire_snapshots` | boolean | false | Skip snapshot expiration |
| `skip_orphan_cleanup` | boolean | false | Skip orphan file cleanup |
| `skip_rewrite_manifests` | boolean | false | Skip manifest rewrite |
| `enable_tuning` | boolean | false | Enable Spark performance monitoring |

### 5.7 Lịch Trình Maintenance Khuyến Nghị

| Operation | Frequency | Lý do |
|---|---|---|
| Compaction | Daily (4 AM) | Gom small files từ ETL hàng ngày |
| Expire Snapshots | Daily (4 AM) | Giữ storage cost ổn định |
| Orphan Cleanup | Daily (4 AM) | Dọn dẹp files từ failed jobs |
| Rewrite Manifests | Daily (4 AM) | Tối ưu planning sau cleanup |
| Full Table Sort | Weekly/Monthly | Sắp xếp lại data cho optimal reads |

---

## 6. Troubleshooting

### 6.1 Compaction Fails with OOM

```
java.lang.OutOfMemoryError: Java heap space
```

**Giải pháp:**
- Tăng executor memory trong SparkApplication manifest
- Hoặc compaction từng partition thay vì cả table
- Hoặc giảm `target-file-size-bytes`

### 6.2 Query Chậm — Small File Problem

```sql
-- Kiểm tra
SELECT COUNT(*), AVG(file_size_in_bytes)/1024/1024 AS avg_mb
FROM demo.integration.hub_customer.files;
-- Nếu avg_mb < 100 → cần compaction
```

**Giải pháp:** Chạy compaction procedure hoặc trigger manual Airflow DAG `iceberg_maintenance`.

### 6.3 Commit Conflict

```
org.apache.iceberg.exceptions.CommitFailedException
```

**Giải pháp:**
- Kiểm tra có multiple writers đang ghi cùng table
- Tăng `commit.retry.num-retries`
- Đảm bảo chỉ 1 pipeline ghi vào 1 table tại 1 thời điểm

### 6.4 Expire Snapshots Fails

**Giải pháp:**
- Verify Hive Metastore connectivity
- Kiểm tra table exists: `SHOW TABLES IN <schema>`
- Kiểm tra Spark logs: `kubectl logs <driver-pod> -n spark-jobs`

### 6.5 Orphan Cleanup Takes Too Long

**Giải pháp:**
- Bình thường cho bảng lớn với nhiều files
- Chạy ít thường xuyên hơn (weekly thay vì daily)
- Hoặc chạy từng schema: `CALL demo.system.remove_orphan_files('integration.hub_customer')`

---

## 7. Code Review Checklist

### Trước khi tạo bảng mới:

- [ ] **Format Version**: Đã set `format-version = 2`?
- [ ] **Partition**: Partition strategy phù hợp với query patterns?
- [ ] **Compression**: Sử dụng `zstd` compression?
- [ ] **File Size**: Target file size phù hợp workload?
- [ ] **Naming**: Tên bảng theo convention `schema.table_name`?

### Trước khi deploy pipeline ghi dữ liệu:

- [ ] **Single Writer**: Chỉ 1 pipeline ghi vào 1 table tại 1 thời điểm?
- [ ] **Maintenance**: Table đã được thêm vào `iceberg_maintenance` DAG?
- [ ] **Credentials**: Sử dụng K8s Secrets, không hardcode?
- [ ] **Monitor**: Có monitoring cho small files và snapshot count?
