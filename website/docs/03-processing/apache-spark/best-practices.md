# Apache Spark - Best Practices

## Thiết Kế & Kiến Trúc

### Mô Hình Đóng Gói

- **Image chứa runtime**: JARs, Python deps, system packages → ít thay đổi, build infrequently
- **Code logic qua git-sync**: dbt models, ETL scripts → thay đổi thường xuyên, không cần rebuild image
- **Tách biệt config khỏi code**: Dùng ConfigMap/Secret cho endpoints, credentials → deploy cùng manifest cho nhiều môi trường

### Version Control

- Dùng **image tags cố định** (ví dụ: `v1.0.0`), tránh `latest` trên production
- Lock Python dependencies trong `requirements.txt` với version cụ thể
- Pin git-sync branch trong ConfigMap (ví dụ: `main`, `release/v1`)

---

## Bảo Mật

### Quản Lý Credentials

```yaml
# KHÔNG hardcode credentials
sparkConf:
  "spark.hadoop.fs.s3a.access.key": "AKIAEXAMPLE"

# Dùng Kubernetes Secrets
driver:
  envFrom:
    - secretRef:
        name: spark-k8s-aws-credentials
```

**Checklist bảo mật:**

- [ ] Tất cả credentials nằm trong K8s Secrets, không trong manifest/image
- [ ] File `.env`, secrets YAML không được commit vào Git (thêm `.gitignore`)
- [ ] Dùng template files (`secrets.template.yaml`) làm reference
- [ ] Rotate credentials định kỳ

### RBAC

- Tạo **ServiceAccount riêng** cho Spark (`spark` SA)
- Giới hạn quyền tối thiểu cần thiết (create/delete pods, get configmaps)
- Dùng **namespace riêng** (`spark-jobs`) để isolate

### Container Security

- Chạy container với **non-root user** (UID `1001` trong Bitnami image)
- Dùng `imagePullPolicy: IfNotPresent` với versioned tags
- Scan image định kỳ cho vulnerabilities

---

## Hiệu Năng

### Adaptive Query Execution (AQE)

Luôn bật AQE cho workload production:

```yaml
sparkConf:
  "spark.sql.adaptive.enabled": "true"
  "spark.sql.adaptive.coalescePartitions.enabled": "true"
  "spark.sql.adaptive.skewJoin.enabled": "true"
```

### Shuffle Partitions

Điều chỉnh dựa trên kích thước dữ liệu:

| Data size | `spark.sql.shuffle.partitions` |
|---|---|
| < 1 GB | 50–100 |
| 1–10 GB | 200–500 |
| > 10 GB | 500–2000 |

> **Tip**: Nếu bật AQE, Spark sẽ tự động coalesce partitions. Có thể để giá trị mặc định `200`.

### Resource Sizing

- **Bắt đầu nhỏ**, scale up dựa trên monitoring
- Đặt `memoryOverhead` = 10–20% của `memory` (tối thiểu 384MB)
- `coreLimit` = `cores × 1000` (millicores)
- Monitor qua Spark UI → Executor tab → GC time, task duration

### Broadcast Join

Cho bảng nhỏ (< 10MB):

```yaml
sparkConf:
  "spark.sql.autoBroadcastJoinThreshold": "10485760"  # 10MB
```

### Caching

- Dùng `df.cache()` cho DataFrame sử dụng nhiều lần
- Gọi `df.unpersist()` sau khi hoàn tất để giải phóng bộ nhớ

---

## Vận Hành Production

### Restart Policy

```yaml
restartPolicy:
  type: OnFailure
  onFailureRetries: 2              # Retry tối đa 2 lần
  onFailureRetryInterval: 10       # Chờ 10s giữa các retry
  onSubmissionFailureRetries: 3    # Retry nếu submit thất bại
  onSubmissionFailureRetryInterval: 20
```

### Resource Quotas

Giới hạn tài nguyên per namespace:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: spark-jobs-quota
  namespace: spark-jobs
spec:
  hard:
    requests.cpu: "50"
    requests.memory: 100Gi
    limits.cpu: "100"
    limits.memory: 200Gi
```

### Network Policies

Giới hạn network access cho Spark pods:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: spark-network-policy
  namespace: spark-jobs
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to: [{ podSelector: {} }]       # Pod-to-pod trong namespace
    - ports:
        - { protocol: TCP, port: 9083 }   # Hive Metastore
        - { protocol: TCP, port: 9000 }   # MinIO
        - { protocol: TCP, port: 1521 }   # Oracle
        - { protocol: TCP, port: 3306 }   # MySQL
        - { protocol: TCP, port: 1433 }   # MSSQL
```

### Monitoring Checklist

- [ ] Spark UI accessible qua port-forward
- [ ] Event logging enabled (nếu dùng Spark History Server)
- [ ] Resource usage tracked qua `kubectl top pods`
- [ ] Alert cho FAILED SparkApplications
