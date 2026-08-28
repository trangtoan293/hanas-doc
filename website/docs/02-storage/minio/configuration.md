# MinIO - Cấu Hình

## Cấu Hình Cơ Bản

### Environment Variables

MinIO server được cấu hình chủ yếu qua environment variables:

```bash
# Credentials (bắt buộc)
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=<strong_password>

# Server endpoint
MINIO_VOLUMES=/data                       # Đường dẫn lưu trữ
MINIO_SERVER_URL=http://minio:9000        # S3 API URL
MINIO_BROWSER_REDIRECT_URL=http://minio:9001  # Console redirect

# Console
MINIO_BROWSER=on                          # Bật/tắt Console UI
```

### Endpoint Configuration Cho Platform Services

| Service | Config Key | Giá trị | Ghi chú |
|---|---|---|---|
| **Spark** | `spark.hadoop.fs.s3a.endpoint` | `http://minio:9000` | S3A connector |
| **Spark** | `spark.hadoop.fs.s3a.path.style.access` | `true` | Bắt buộc cho MinIO |
| **Spark** | `spark.hadoop.fs.s3a.impl` | `org.apache.hadoop.fs.s3a.S3AFileSystem` | Hadoop S3A |
| **Iceberg** | `spark.sql.catalog.demo.s3.endpoint` | `http://minio:9000` | S3FileIO |
| **Dremio** | `fs.s3a.endpoint` | `http://minio:9000` | Source property |
| **Dremio** | `fs.s3a.path.style.access` | `true` | Bắt buộc |
| **Dremio** | `dremio.s3.compat` | `true` | S3-compatible flag |
| **NiFi** | Endpoint Override URL | `http://minio:9000` | PutS3Object processor |
| **AWS CLI** | `--endpoint-url` | `http://minio:9000` | CLI flag |

---

## Cấu Hình Erasure Coding

Erasure coding được **tự động bật** khi MinIO chạy distributed mode (≥ 4 drives). Không cần cấu hình manual.

### Cơ Chế Hoạt Động

```
16 drives (4 nodes × 4 drives) → EC:8 (default)
├── 8 data shards
└── 8 parity shards
→ Chịu lỗi tối đa 8 drives mà không mất dữ liệu
```

### Storage Class Configuration

```bash
# Standard parity (default: N/2)
MINIO_STORAGE_CLASS_STANDARD=EC:4    # 4 parity shards

# Reduced Redundancy (cho landing zone)
MINIO_STORAGE_CLASS_RRS=EC:2         # 2 parity shards, tiết kiệm dung lượng
```

| Storage Class | Parity | Fault Tolerance | Use Case |
|---|---|---|---|
| **STANDARD** | EC:4 | Mất 4 drives | raw-vault, business-vault, information-mart |
| **REDUCED_REDUNDANCY** | EC:2 | Mất 2 drives | landing (dữ liệu có thể re-ingest) |

---

## Cấu Hình Bucket Policies

### Policy Mẫu: Read-Only Cho Dremio

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["arn:aws:iam:::user/dremio-reader"]},
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::raw-vault/*",
        "arn:aws:s3:::business-vault/*",
        "arn:aws:s3:::information-mart/*",
        "arn:aws:s3:::warehouse/*"
      ]
    }
  ]
}
```

### Policy Mẫu: Write Cho NiFi (Landing Only)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["arn:aws:iam:::user/nifi-writer"]},
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::landing",
        "arn:aws:s3:::landing/*"
      ]
    }
  ]
}
```

### Áp Dụng Policy

```bash
# Tạo user cho dịch vụ
mc admin user add hanas dremio-reader '<PASSWORD>'
mc admin user add hanas nifi-writer '<PASSWORD>'

# Tạo policy từ file JSON
mc admin policy create hanas dremio-readonly dremio-readonly.json
mc admin policy create hanas nifi-landing nifi-landing.json

# Gán policy cho user
mc admin policy attach hanas dremio-readonly --user dremio-reader
mc admin policy attach hanas nifi-landing --user nifi-writer
```

---

## Cấu Hình Site Replication (DC-DR)

Site Replication cho phép đồng bộ active-active giữa Data Center và Disaster Recovery:

```bash
# Thiết lập alias cho 2 sites
mc alias set dc http://minio-dc:9000 admin '<PASSWORD>'
mc alias set dr http://minio-dr:9000 admin '<PASSWORD>'

# Bật Site Replication
mc admin replicate add dc dr

# Verify
mc admin replicate status dc
mc admin replicate info dc
```

### Những gì được replicate:

| Item | Replicated |
|---|---|
| Buckets | Có |
| Objects | Có |
| IAM users & policies | Có |
| Bucket policies | Có |
| Bucket lifecycle | Có |
| Bucket versioning | Có |
| Object lock | Có |

---

## Cấu Hình Bảo Mật

### TLS/HTTPS

```bash
# Đặt certificate files vào thư mục certs
# ${HOME}/.minio/certs/ (trên host)
# /root/.minio/certs/ (trong container)
mkdir -p ~/.minio/certs

# Copy certificates
cp public.crt ~/.minio/certs/
cp private.key ~/.minio/certs/

# MinIO tự động detect và bật HTTPS
```

### Encryption At Rest (Server-Side Encryption)

```bash
# Bật SSE-S3 (auto encryption)
MINIO_KMS_SECRET_KEY="<MINIO_KMS_SECRET_KEY_FROM_SECRET_MANAGER>"

# Hoặc dùng KMS (Vault)
MINIO_KMS_KES_ENDPOINT=https://kes:7373
MINIO_KMS_KES_KEY_FILE=/certs/kes-client.key
MINIO_KMS_KES_CERT_FILE=/certs/kes-client.crt
MINIO_KMS_KES_CAPATH=/certs/ca.crt
MINIO_KMS_KES_KEY_NAME=<MINIO_KMS_KEY_NAME>
```

### Bucket Versioning (Bắt Buộc Cho Site Replication)

```bash
# Bật versioning trên tất cả buckets
mc version enable hanas/landing
mc version enable hanas/raw-vault
mc version enable hanas/business-vault
mc version enable hanas/information-mart
mc version enable hanas/warehouse
```

---

## Tham Số Quan Trọng

| Biến môi trường | Mô tả | Giá trị mặc định | Khuyến nghị |
|---|---|---|---|
| `MINIO_ROOT_USER` | Admin username | `minioadmin` | Đổi ngay |
| `MINIO_ROOT_PASSWORD` | Admin password | `minioadmin` | Đổi ngay, ≥ 12 ký tự |
| `MINIO_VOLUMES` | Data directories | — | `/data` hoặc `/mnt/drive-{1...N}` |
| `MINIO_BROWSER` | Bật Console UI | `on` | `on` (dev), `off` (production nếu không cần) |
| `MINIO_STORAGE_CLASS_STANDARD` | Default parity | `EC:N/2` | Tùy fault tolerance cần |
| `MINIO_PROMETHEUS_AUTH_TYPE` | Auth cho metrics | `jwt` | `public` nếu dùng internal scrape |
| `MINIO_API_REQUESTS_MAX` | Max concurrent requests | `0` (unlimited) | Set limit nếu cần throttle |
| `MINIO_API_REQUESTS_DEADLINE` | Request timeout | `10s` | Tăng lên `30s` nếu có large objects |
| `MINIO_SCANNER_SPEED` | Disk scanner speed | `default` | `slow` cho production để giảm I/O |
