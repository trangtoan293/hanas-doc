# MinIO - Hướng Dẫn Sử Dụng

## Truy Cập

### MinIO Console (Web UI)

| Môi trường | URL | Credentials |
|---|---|---|
| **Dev (Docker)** | http://localhost:9001 | admin / minio_secret_2025 |
| **Kubernetes** | http://minio-console.minio-tenant:9090 | Root credentials |
| **Production** | https://minio.hanas.local | Root hoặc IAM user |

Sau khi đăng nhập, Console cung cấp:
- **Object Browser**: Duyệt buckets/objects
- **Buckets**: Tạo, cấu hình buckets
- **IAM**: Quản lý users, groups, policies
- **Monitoring**: Xem metrics và dashboard

> **Lưu ý:** Từ MinIO Community Edition sau `RELEASE.2025-06-xx`, Console bị giới hạn chỉ còn Object Browser. Hanas Platform dùng version `RELEASE.2025-04-22T22-12-26Z` để giữ đầy đủ chức năng admin.

---

## Sử Dụng MinIO Client (`mc`)

### Cài Đặt

```bash
# macOS
brew install minio/stable/mc

# Linux
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/

# Verify
mc --version
```

### Thiết Lập Alias

```bash
# Dev environment
mc alias set hanas http://localhost:9000 admin minio_secret_2025

# Production
mc alias set hanas-prod https://minio.hanas.local admin '<SECRET>'

# Verify kết nối
mc admin info hanas
```

### Quản Lý Buckets

```bash
# Liệt kê buckets
mc ls hanas/

# Tạo bucket
mc mb hanas/new-bucket

# Xóa bucket (phải rỗng)
mc rb hanas/new-bucket

# Xóa bucket kèm toàn bộ objects
mc rb --force hanas/new-bucket
```

### Quản Lý Objects

```bash
# Upload file
mc cp local-file.csv hanas/landing/source/

# Upload thư mục (recursive)
mc cp --recursive ./data/ hanas/landing/batch-2025-01/

# Download
mc cp hanas/landing/source/file.csv ./local-dir/

# Xem nội dung file
mc cat hanas/landing/source/file.csv | head -5

# Liệt kê objects
mc ls hanas/landing/
mc ls --recursive hanas/landing/source/

# Xóa object
mc rm hanas/landing/source/old-file.csv

# Xóa recursive
mc rm --recursive --force hanas/landing/temp/

# Xem dung lượng
mc du hanas/landing/
mc du --depth 1 hanas/
```

### Tìm Kiếm & Lọc

```bash
# Tìm files theo pattern
mc find hanas/landing/ --name "*.csv"

# Tìm files lớn hơn 100MB
mc find hanas/landing/ --larger 100MB

# Tìm files cũ hơn 30 ngày
mc find hanas/landing/ --older-than 30d

# Tìm files mới trong 24h
mc find hanas/landing/ --newer-than 1d
```

---

## Sử Dụng AWS CLI (S3-Compatible)

```bash
# Cấu hình AWS CLI cho MinIO
aws configure --profile minio
# AWS Access Key ID: admin
# AWS Secret Access Key: minio_secret_2025
# Default region: us-east-1
# Default output format: json

# Sử dụng
aws --endpoint-url http://localhost:9000 --profile minio \
    s3 ls

aws --endpoint-url http://localhost:9000 --profile minio \
    s3 cp local-file.csv s3://landing/source/

aws --endpoint-url http://localhost:9000 --profile minio \
    s3 sync ./data/ s3://landing/batch/
```

---

## Tích Hợp Với Platform Services

### NiFi → MinIO (Ingestion)

Cấu hình processor `PutS3Object` trong NiFi:

| Property | Value |
|---|---|
| **Bucket** | `landing` |
| **Object Key** | `oracle/src_table/load_date=${now():format('yyyy-MM-dd')}/part_${UUID()}.parquet` |
| **Endpoint Override URL** | `http://minio:9000` |
| **Access Key ID** | `nifi-writer` (IAM user) |
| **Secret Access Key** | `<password>` |
| **Signer Override** | `AWSS3V4SignerType` |

### Spark → MinIO (Processing)

```python
# SparkSession configuration
spark = SparkSession.builder \
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
    .config("spark.hadoop.fs.s3a.access.key", os.environ["AWS_ACCESS_KEY_ID"]) \
    .config("spark.hadoop.fs.s3a.secret.key", os.environ["AWS_SECRET_ACCESS_KEY"]) \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .getOrCreate()

# Đọc từ landing
df = spark.read.parquet("s3a://landing/oracle/src_customers/")

# Ghi vào Iceberg (trên MinIO)
df.writeTo("demo.raw_vault.hub_customer").createOrReplace()
```

### Dremio → MinIO (Federation)

Cấu hình Source trong Dremio UI:
1. **Add Source** → **Amazon S3**
2. Điền thông tin:

| Field | Value |
|---|---|
| **Name** | `lakehouse` |
| **Access Key** | `dremio-reader` |
| **Secret Key** | `<password>` |
| **Encrypt connection** | Bỏ tick (nếu HTTP) |

3. **Advanced Options** → **Connection Properties**:

| Property | Value |
|---|---|
| `fs.s3a.endpoint` | `http://minio:9000` |
| `fs.s3a.path.style.access` | `true` |
| `dremio.s3.compat` | `true` |

4. **Root Path**: `/`

---

## Giám Sát (Monitoring)

### Prometheus Metrics

MinIO cung cấp nhiều endpoints metrics cho Prometheus:

```bash
# Lấy bearer token
mc admin prometheus generate hanas

# Hoặc disable auth
MINIO_PROMETHEUS_AUTH_TYPE=public
```

### Prometheus Scrape Config

```yaml
scrape_configs:
  # Cluster metrics
  - job_name: minio-cluster
    bearer_token: <TOKEN>
    metrics_path: /minio/v2/metrics/cluster
    scheme: http
    static_configs:
      - targets: ["minio:9000"]

  # Node metrics (per-node)
  - job_name: minio-node
    bearer_token: <TOKEN>
    metrics_path: /minio/v2/metrics/node
    scheme: http
    static_configs:
      - targets: ["minio-1:9000", "minio-2:9000"]

  # Bucket metrics
  - job_name: minio-bucket
    bearer_token: <TOKEN>
    metrics_path: /minio/v2/metrics/bucket
    scheme: http
    static_configs:
      - targets: ["minio:9000"]

  # Resource metrics
  - job_name: minio-resource
    bearer_token: <TOKEN>
    metrics_path: /minio/v2/metrics/resource
    scheme: http
    static_configs:
      - targets: ["minio:9000"]
```

### Metrics Quan Trọng

| Metric | Mô tả | Alert threshold |
|---|---|---|
| `minio_node_disk_free_bytes` | Disk trống per node | < 20% |
| `minio_node_disk_total_bytes` | Tổng disk per node | — |
| `minio_s3_requests_total` | Tổng S3 requests | — |
| `minio_s3_requests_errors_total` | S3 errors | > 1% total |
| `minio_s3_traffic_sent_bytes` | Outgoing traffic | — |
| `minio_s3_traffic_received_bytes` | Incoming traffic | — |
| `minio_node_process_cpu_total_seconds` | CPU usage | > 80% sustained |
| `minio_cluster_health_status` | Cluster health | != 1 |

---

## Troubleshooting

### Lỗi Thường Gặp

| Lỗi | Nguyên nhân | Giải pháp |
|---|---|---|
| `Access Denied` | Sai credentials hoặc thiếu policy | Kiểm tra access key, policy attachment |
| `Bucket does not exist` | Bucket chưa tạo | `mc mb hanas/<bucket>` |
| `Connection refused` | MinIO chưa start hoặc sai port | Kiểm tra container/pod status |
| `S3 operation failed: SignatureDoesNotMatch` | Sai secret key | Kiểm tra credentials |
| `path.style.access` errors | Thiếu config path style | Thêm `fs.s3a.path.style.access=true` |
| `SlowDown` | Quá nhiều requests | Tăng `MINIO_API_REQUESTS_MAX` hoặc scale nodes |
| `XMinioStorageFull` | Hết dung lượng | Mở rộng storage, cleanup old data |

### Debug Commands

```bash
# Xem server info
mc admin info hanas

# Xem real-time logs
mc admin trace hanas -v --all

# Chỉ xem S3 errors
mc admin trace hanas --errors

# Xem disk usage per bucket
mc du hanas/landing/
mc du hanas/raw-vault/

# Health check
mc admin healthcheck hanas
```
