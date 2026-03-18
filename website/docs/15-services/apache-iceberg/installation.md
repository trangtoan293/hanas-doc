# Apache Iceberg - Cài Đặt & Triển Khai

## Yêu Cầu Hệ Thống

Apache Iceberg không phải là một service chạy độc lập — nó là một **table format library** được tích hợp vào các compute engines. Yêu cầu hệ thống phụ thuộc vào engine sử dụng.

### Components Bắt Buộc

| Component | Version | Vai trò |
|---|---|---|
| **Apache Spark** | 3.5.1 | Compute engine chính |
| **Hive Metastore** | 3.x | Catalog backend (lưu metadata pointer) |
| **MinIO** | Latest | Object storage (lưu data + metadata files) |
| **Iceberg Runtime JAR** | 1.5.x | Library tích hợp vào Spark |

### Components Tùy Chọn

| Component | Vai trò |
|---|---|
| **Dremio** | Query engine cho BI/analytics |
| **Trino** | Distributed SQL engine |
| **Apache Flink** | Stream processing |

---

## Cài Đặt Trên Kubernetes (Production)

Iceberg được tích hợp sẵn trong Docker image của Spark. Không cần cài đặt riêng.

### Step 1: Docker Image

Sử dụng image đã bao gồm Iceberg runtime:

```
trangtoan293/dbt-spark-k8s-ktl:ktl-dbt
```

Image này bao gồm:
- Apache Spark 3.5.1
- Iceberg Spark Runtime JAR
- AWS SDK (cho S3FileIO)
- dbt-spark adapter

### Step 2: Hive Metastore

Hive Metastore phải đang chạy và accessible từ Spark pods:

```bash
# Verify Hive Metastore connectivity
kubectl run test-hive --rm -it --image=busybox -- \
  nc -zv <HIVE_HOST> 9083
```

### Step 3: MinIO

MinIO phải có bucket `data` với cấu trúc warehouse:

```bash
# Verify MinIO bucket
mc ls minio/data/warehouse/
```

### Step 4: Spark Configuration

Thêm cấu hình Iceberg vào SparkApplication manifest (xem [configuration.md](configuration.md) để biết chi tiết):

```yaml
sparkConf:
  # Iceberg Extensions (bắt buộc)
  "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"

  # Catalog (bắt buộc ít nhất 1)
  "spark.sql.catalog.demo": "org.apache.iceberg.spark.SparkCatalog"
  "spark.sql.catalog.demo.type": "hive"
  "spark.sql.catalog.demo.uri": "thrift://<HIVE_HOST>:9083"
  "spark.sql.catalog.demo.io-impl": "org.apache.iceberg.aws.s3.S3FileIO"
  "spark.sql.catalog.demo.s3.endpoint": "http://<MINIO_HOST>"
  "spark.sql.catalog.demo.warehouse": "s3a://data/warehouse/"
  "spark.sql.defaultCatalog": "demo"
```

---

## Cài Đặt Docker Compose (Dev/Test)

Cho môi trường phát triển, sử dụng Docker Compose với các services:

```yaml
services:
  hive-metastore:
    image: apache/hive:3.1.3
    ports:
      - "9083:9083"
    environment:
      - SERVICE_NAME=metastore

  minio:
    image: minio/minio
    ports:
      - "9000:9000"
      - "9001:9001"
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin

  spark-iceberg:
    image: trangtoan293/dbt-spark-k8s-ktl:ktl-dbt
    depends_on:
      - hive-metastore
      - minio
    environment:
      - SPARK_CONF_spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
      - SPARK_CONF_spark.sql.catalog.demo=org.apache.iceberg.spark.SparkCatalog
      - SPARK_CONF_spark.sql.catalog.demo.type=hive
      - SPARK_CONF_spark.sql.catalog.demo.uri=thrift://hive-metastore:9083
```

---

## Kiểm Tra Sau Cài Đặt

### 1. Verify Iceberg Extensions

```sql
-- Tạo bảng test trong Spark SQL
CREATE TABLE demo.default.test_iceberg (
    id INT,
    name STRING,
    created_at TIMESTAMP
) USING iceberg;

-- Insert dữ liệu
INSERT INTO demo.default.test_iceberg VALUES
(1, 'test', current_timestamp());

-- Verify
SELECT * FROM demo.default.test_iceberg;
```

### 2. Verify Time Travel

```sql
-- Xem snapshots
SELECT * FROM demo.default.test_iceberg.snapshots;

-- Insert thêm dữ liệu
INSERT INTO demo.default.test_iceberg VALUES
(2, 'test2', current_timestamp());

-- Time travel về snapshot trước
SELECT * FROM demo.default.test_iceberg VERSION AS OF <snapshot_id>;
```

### 3. Verify Metadata trên MinIO

```bash
# Kiểm tra file structure trên MinIO
mc ls minio/data/warehouse/default/test_iceberg/
# Expected:
# ├── metadata/
# │   ├── v1.metadata.json
# │   ├── v2.metadata.json
# │   └── snap-*.avro
# └── data/
#     └── *.parquet
```

### 4. Verify Maintenance Procedures

```sql
-- Test compaction procedure
CALL demo.system.rewrite_data_files('default.test_iceberg');

-- Test expire snapshots
CALL demo.system.expire_snapshots('default.test_iceberg', TIMESTAMP '2024-01-01 00:00:00.000');
```

### 5. Cleanup

```sql
DROP TABLE demo.default.test_iceberg PURGE;
```

> **Lưu ý:** `PURGE` xóa cả data files trên MinIO. Không dùng `PURGE` nếu muốn giữ data để recover.
