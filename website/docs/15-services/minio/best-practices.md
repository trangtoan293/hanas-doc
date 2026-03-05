# MinIO - Best Practices

## Thiết Kế & Kiến Trúc

### Bucket Naming Convention

| Pattern | Ví dụ | Mục đích |
|---|---|---|
| **Zone-based** | `landing`, `raw-vault`, `business-vault` | Data Vault zones |
| **Object path** | `<source>/<table>/load_date=YYYY-MM-DD/` | Partition-like organization |
| **Tránh** | `data-2025`, `backup-old-123` | Không rõ ràng, khó quản lý |

### Quy Tắc Thiết Kế Object Key

```
s3://<bucket>/<source_system>/<table_name>/load_date=<YYYY-MM-DD>/part_<UUID>.parquet
```

Ví dụ thực tế trong platform:

```
s3://landing/oracle/src_customers/load_date=2025-01-15/part_abc123.parquet
s3://warehouse/raw_vault/hub_customer/data/00001.parquet
s3://warehouse/raw_vault/hub_customer/metadata/v1.metadata.json
```

- **Sử dụng prefix rõ ràng**: source system, table name, date
- **Tránh tên quá dài**: Giữ key path ≤ 1024 ký tự
- **Không dùng ký tự đặc biệt**: Chỉ dùng `a-z`, `0-9`, `-`, `_`, `/`, `.`
- **Hive-style partition**: `key=value/` cho tương thích với Spark/Iceberg partition pruning

### Tách Biệt Buckets Theo Zone

```
✅ Tốt: Mỗi zone 1 bucket → landing/, raw-vault/, business-vault/, information-mart/
❌ Xấu: 1 bucket chứa tất cả → data/landing/, data/raw-vault/, data/business/
```

**Lý do:**
- Phân quyền dễ hơn (policy per bucket)
- Lifecycle rules riêng biệt  
- Monitoring/quota rõ ràng per zone
- Site Replication linh hoạt (chọn bucket nào replicate)

---

## Hiệu Năng

### Disk I/O

- **Dùng NVMe/SSD** cho production — HDD chỉ cho archival
- **Dedicated drives**: Không chia sẻ disk với OS hoặc services khác
- **Cùng loại, cùng dung lượng**: Tất cả drives trong pool phải đồng nhất
- **XFS filesystem**: Khuyến nghị XFS cho MinIO data drives

```bash
# Format drives cho MinIO
mkfs.xfs /dev/sdb
mkfs.xfs /dev/sdc
mkfs.xfs /dev/sdd
mkfs.xfs /dev/sde
```

### Network

- **10–25 GbE** cho production distributed mode
- MinIO cần bandwidth cao cho:
  - Erasure coding healing (rebuild parity shards)
  - Site Replication (cross-DC sync)
  - Large object multipart uploads
- **Đặt MinIO cùng network segment** với Spark/Dremio để giảm latency

### Object Size Optimization

| Object Size | Khuyến nghị |
|---|---|
| < 1 KB | Gom nhiều objects nhỏ lại (batch) |
| 1 KB – 64 MB | Tối ưu cho MinIO |
| 64 MB – 5 GB | Tự động multipart upload |
| > 5 GB | mc sử dụng multipart, cần cấu hình part size |

### Concurrent Access

```bash
# Tăng concurrent uploads
mc cp --parallel 8 ./large-dir/ hanas/landing/

# Cấu hình multipart threshold (mc)
mc cp --part-size 64MiB large-file.parquet hanas/landing/
```

---

## Bảo Mật

### Credentials Management

- ❌ **KHÔNG** dùng root credentials cho applications
- ✅ Tạo IAM users riêng cho mỗi service (NiFi, Spark, Dremio)
- ✅ Sử dụng Kubernetes Secrets cho credentials
- ✅ Rotate credentials định kỳ (90 ngày)

```bash
# Tạo service accounts
mc admin user add hanas spark-user '<STRONG_PASSWORD>'
mc admin user add hanas nifi-writer '<STRONG_PASSWORD>'
mc admin user add hanas dremio-reader '<STRONG_PASSWORD>'

# Gán policies phù hợp (principle of least privilege)
mc admin policy attach hanas readwrite --user spark-user
mc admin policy attach hanas writeonly --user nifi-writer
mc admin policy attach hanas readonly --user dremio-reader
```

### Network Security

- **Network Policies** trên Kubernetes: Chỉ cho phép services cần thiết truy cập MinIO
- **TLS**: Bật HTTPS cho production (xem [configuration.md](configuration.md))
- **Firewall**: Lock port 9000 và 9001 trên public interface

```yaml
# Kubernetes NetworkPolicy cho MinIO
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: minio-allow
  namespace: minio-tenant
spec:
  podSelector:
    matchLabels:
      app: minio
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: spark-jobs       # Cho phép Spark
    - namespaceSelector:
        matchLabels:
          name: dremio           # Cho phép Dremio
    - namespaceSelector:
        matchLabels:
          name: nifi             # Cho phép NiFi
    ports:
    - protocol: TCP
      port: 9000
```

### Encryption

- **In-transit**: TLS (HTTPS)
- **At-rest**: Server-Side Encryption (SSE-S3 hoặc SSE-KMS)
- **Never** disable encryption cho production

---

## Backup & Disaster Recovery

### Site Replication (Khuyến nghị)

Active-active replication giữa DC và DR:

```bash
# Setup (chỉ cần 1 lần)
mc admin replicate add dc dr

# Monitor
mc admin replicate status dc
```

**Ưu điểm:**
- Tự động, real-time sync
- Active-active: cả 2 site đều read/write
- Bao gồm cả IAM, policies, configs

### Velero Backup (Cho K8s Resources)

MinIO đóng vai trò backup backend cho Velero (Kubernetes backup):

```bash
# Velero dùng MinIO S3 endpoint
velero install \
  --provider aws \
  --bucket velero-backup \
  --secret-file ./credentials-velero \
  --backup-location-config \
    region=us-east-1,s3ForcePathStyle=true,s3Url=http://minio:9000
```

### Lifecycle Rules (Dọn Dẹp Tự Động)

```bash
# Xóa objects trong landing sau 90 ngày (đã xử lý)
mc ilm rule add hanas/landing \
  --expire-days 90 \
  --prefix "oracle/"

# Xóa incomplete multipart uploads sau 7 ngày
mc ilm rule add hanas/landing \
  --expire-delete-marker \
  --noncurrent-expire-days 7
```

---

## Vận Hành Production

### Monitoring Checklist

| Item | Tần suất | Tool |
|---|---|---|
| Disk usage per bucket | Daily | `mc du`, Prometheus |
| S3 error rate | Real-time | Prometheus alerts |
| Node health | Real-time | Health endpoints |
| Replication lag | Real-time | `mc admin replicate status` |
| Capacity planning | Monthly | Grafana dashboard |

### Alerting Rules (Prometheus)

```yaml
groups:
  - name: minio
    rules:
    - alert: MinIODiskSpaceLow
      expr: minio_node_disk_free_bytes / minio_node_disk_total_bytes < 0.2
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "MinIO disk space < 20%"

    - alert: MinIONodeDown
      expr: up{job="minio-cluster"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "MinIO node is down"

    - alert: MinIOHighErrorRate
      expr: rate(minio_s3_requests_errors_total[5m]) / rate(minio_s3_requests_total[5m]) > 0.01
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "MinIO S3 error rate > 1%"
```

### Capacity Planning

| Vùng | Growth rate (estimated) | Retention |
|---|---|---|
| **landing** | ~10 GB/day | 90 ngày (lifecycle rule) |
| **raw-vault** | ~5 GB/day | Vĩnh viễn |
| **business-vault** | ~2 GB/day | Vĩnh viễn |
| **information-mart** | ~1 GB/day | Vĩnh viễn |
| **warehouse** (metadata) | ~100 MB/day | Vĩnh viễn |

> **Quy tắc**: Provision ít nhất **2× dung lượng cần thiết** cho erasure coding overhead và growth headroom.
