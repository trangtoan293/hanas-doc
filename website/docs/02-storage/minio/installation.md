# MinIO - Cài Đặt & Triển Khai

## Yêu Cầu Hệ Thống

### Kiến Trúc Cluster (Production)

MinIO chạy ở **distributed mode** với erasure coding, yêu cầu tối thiểu 4 nodes × 4 drives:

| Component | Vai trò | Số lượng |
|---|---|---|
| **MinIO Server** | Object storage node | 4+ nodes (distributed) |
| **Drives per Node** | Erasure coding data/parity | 4+ drives/node |
| **Load Balancer** | Phân tải requests | 1 (Nginx/HAProxy) |

### Yêu Cầu Resources

| Resource | Dev/Test | Production | Ghi chú |
|---|---|---|---|
| **CPU** | 4 cores | 8–16 cores/node | Tối ưu cho throughput cao |
| **RAM** | 8 GB | 32–64 GB/node | Caching và concurrent requests |
| **Disk** | 50 GB SSD | 4× NVMe/SSD per node | Dedicated drives, KHÔNG dùng OS disk |
| **Network** | 1 GbE | 10–25 GbE | Quan trọng cho erasure coding healing |
| **OS** | Linux/macOS | Linux (Ubuntu 22.04+, RHEL 8+) | Kernel 5.x+ khuyến nghị |

### Prerequisites

| Yêu cầu | Chi tiết |
|---|---|
| **Kubernetes** | 1.25+ (EKS, GKE, OpenShift, Rancher) |
| **Helm 3** | >= 3.8 |
| **kubectl** | Configured trỏ vào target cluster |
| **Docker** | >= 24.0 (cho dev/test) |
| **mc (MinIO Client)** | Để quản lý buckets/objects |

---

## Cài Đặt Trên Kubernetes (Production)

### Option A: MinIO Operator (Khuyến nghị)

MinIO Operator quản lý lifecycle của MinIO Tenants trên Kubernetes.

#### Step 1: Cài Đặt MinIO Operator

```bash
# Tạo namespace
kubectl create namespace minio-operator

# Thêm Helm repo
helm repo add minio-operator https://operator.min.io
helm repo update

# Cài đặt Operator
helm install operator minio-operator/operator \
  --namespace minio-operator \
  --wait
```

#### Step 2: Tạo Namespace Cho Tenant

```bash
kubectl create namespace minio-tenant
```

#### Step 3: Tạo Secret Cho Credentials

```bash
kubectl create secret generic minio-creds \
  --namespace minio-tenant \
  --from-literal=accesskey='<MINIO_ADMIN_USER>' \
  --from-literal=secretkey='<MINIO_SECRET_KEY>'
```

> **Cảnh báo:** **KHÔNG** commit credentials vào Git. Sử dụng Kubernetes Secrets hoặc HashiCorp Vault.

#### Step 4: Deploy MinIO Tenant

Tạo file `tenant-values.yaml`:

```yaml
## MinIO Tenant Configuration — Hanas Platform
tenant:
  name: hanas-minio
  image:
    repository: quay.io/minio/minio
    tag: "RELEASE.2025-04-22T22-12-26Z"   # Version pinned ổn định
    pullPolicy: IfNotPresent

  ## Pools — Distributed Erasure Coding
  pools:
    - servers: 4                           # 4 MinIO server pods
      volumesPerServer: 4                  # 4 PVCs per server = 16 drives total
      size: 500Gi                          # Dung lượng mỗi PVC
      storageClassName: "local-path"       # Thay bằng StorageClass thực tế

  ## Resources
  resources:
    requests:
      cpu: "4"
      memory: "16Gi"
    limits:
      cpu: "8"
      memory: "32Gi"

  ## Tự động tạo Console
  console:
    image:
      repository: quay.io/minio/console
      tag: "v0.30.0"

  ## Prometheus
  prometheusOperator: true

  ## Environment Variables
  env:
    - name: MINIO_BROWSER
      value: "on"
```

```bash
# Deploy Tenant
helm install hanas-tenant minio-operator/tenant \
  -f tenant-values.yaml \
  --namespace minio-tenant \
  --wait
```

#### Step 5: Verify Deployment

```bash
# Kiểm tra pods
kubectl get pods -n minio-tenant
# Expected:
# hanas-minio-pool-0-0 1/1 Running
# hanas-minio-pool-0-1 1/1 Running
# hanas-minio-pool-0-2 1/1 Running
# hanas-minio-pool-0-3 1/1 Running
# hanas-minio-console-xxx 1/1 Running

# Kiểm tra services
kubectl get svc -n minio-tenant
# Expected:
# minio ClusterIP ... 9000/TCP
# minio-console ClusterIP ... 9090/TCP
```

### Option B: Standalone Pod (Dev/Staging)

Cho môi trường dev/staging đơn giản:

```yaml
# minio-standalone.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: minio
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: minio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: quay.io/minio/minio:RELEASE.2025-04-22T22-12-26Z
        command:
        - /bin/bash
        - -c
        args:
        - minio server /data --console-address :9001
        env:
        - name: MINIO_ROOT_USER
          valueFrom:
            secretKeyRef:
              name: minio-creds
              key: accesskey
        - name: MINIO_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: minio-creds
              key: secretkey
        ports:
        - containerPort: 9000
          name: api
        - containerPort: 9001
          name: console
        volumeMounts:
        - name: data
          mountPath: /data
        livenessProbe:
          httpGet:
            path: /minio/health/live
            port: 9000
          initialDelaySeconds: 10
          periodSeconds: 20
        readinessProbe:
          httpGet:
            path: /minio/health/ready
            port: 9000
          initialDelaySeconds: 10
          periodSeconds: 20
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: minio-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: minio
spec:
  selector:
    app: minio
  ports:
  - name: api
    port: 9000
    targetPort: 9000
  - name: console
    port: 9001
    targetPort: 9001
```

```bash
kubectl apply -f minio-standalone.yaml
kubectl port-forward svc/minio 9000:9000 9001:9001 -n minio
```

---

## Cài Đặt Docker Compose (Dev/Test)

```yaml
# docker-compose.yml
version: '3.8'
services:
  minio:
    image: quay.io/minio/minio:RELEASE.2025-04-22T22-12-26Z
    container_name: hanas-minio
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"   # S3 API
      - "9001:9001"   # Console UI
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER:?Set MINIO_ROOT_USER in .env}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:?Set MINIO_ROOT_PASSWORD in .env}
    volumes:
      - minio_data:/data
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Bucket initialization
  minio-init:
    image: quay.io/minio/mc:<PINNED_TAG>
    container_name: hanas-minio-init
    depends_on:
      minio:
        condition: service_healthy
    entrypoint: |
      /bin/sh -c "
      mc alias set myminio http://minio:9000 $${MINIO_ROOT_USER} $${MINIO_ROOT_PASSWORD};
      mc mb --ignore-existing myminio/landing;
      mc mb --ignore-existing myminio/raw-vault;
      mc mb --ignore-existing myminio/business-vault;
      mc mb --ignore-existing myminio/information-mart;
      mc mb --ignore-existing myminio/warehouse;
      echo 'All Hanas buckets created successfully';
      "
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER:?Set MINIO_ROOT_USER in .env}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:?Set MINIO_ROOT_PASSWORD in .env}

volumes:
  minio_data:
```

```bash
# Khởi động
docker compose up -d

# Kiểm tra
docker compose ps
docker compose logs minio-init
```

---

## Khởi Tạo Buckets Cho Platform

Sau khi MinIO chạy, tạo các buckets theo cấu trúc Hanas Platform:

```bash
# Cài mc (MinIO Client) nếu chưa có
brew install minio/stable/mc  # macOS
# hoặc: wget https://dl.min.io/client/mc/release/linux-amd64/mc

# Kết nối
mc alias set hanas http://<MINIO_HOST>:9000 admin '<MINIO_SECRET_KEY>'

# Tạo buckets
mc mb --ignore-existing hanas/landing
mc mb --ignore-existing hanas/raw-vault
mc mb --ignore-existing hanas/business-vault
mc mb --ignore-existing hanas/information-mart
mc mb --ignore-existing hanas/warehouse

# Verify
mc ls hanas/
# Expected:
# [2025-01-01 00:00:00 +07] 0B landing/
# [2025-01-01 00:00:00 +07] 0B raw-vault/
# [2025-01-01 00:00:00 +07] 0B business-vault/
# [2025-01-01 00:00:00 +07] 0B information-mart/
# [2025-01-01 00:00:00 +07] 0B warehouse/
```

---

## Kiểm Tra Sau Cài Đặt

### 1. Health Check API

```bash
# Liveness check
curl -s http://<MINIO_HOST>:9000/minio/health/live
# Expected: HTTP 200

# Readiness check
curl -s http://<MINIO_HOST>:9000/minio/health/ready
# Expected: HTTP 200

# Cluster check (distributed mode)
curl -s http://<MINIO_HOST>:9000/minio/health/cluster
# Expected: HTTP 200
```

### 2. Console UI

Truy cập `http://<MINIO_HOST>:9001` và verify:
- Login thành công với root credentials
- Tất cả buckets hiển thị (landing, raw-vault, business-vault, information-mart, warehouse)
- Server information hiển thị đúng version

### 3. Upload/Download Test

```bash
# Tạo file test
echo "Hello Hanas!" > /tmp/test.txt

# Upload
mc cp /tmp/test.txt hanas/landing/test/

# Download & verify
mc cat hanas/landing/test/test.txt
# Expected: Hello Hanas!

# Cleanup
mc rm hanas/landing/test/test.txt
```

### 4. S3 API Compatibility Test

```bash
# Dùng AWS CLI
aws --endpoint-url http://<MINIO_HOST>:9000 \
    s3 ls s3://landing/

# Upload via S3 API
aws --endpoint-url http://<MINIO_HOST>:9000 \
    s3 cp /tmp/test.txt s3://landing/test/
```

### 5. Kết Nối Từ Spark

```python
# Test Spark → MinIO connectivity
spark = SparkSession.builder \
    .config("spark.hadoop.fs.s3a.endpoint", "http://<MINIO_HOST>:9000") \
    .config("spark.hadoop.fs.s3a.access.key", "<ACCESS_KEY>") \
    .config("spark.hadoop.fs.s3a.secret.key", "<SECRET_KEY>") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .getOrCreate()

# Test read
spark.read.text("s3a://landing/test/test.txt").show()
```

---

## Upgrade MinIO

### Trên Kubernetes (Operator)

```bash
# Cập nhật image tag trong tenant-values.yaml
# tag: "RELEASE.2025-04-22T22-12-26Z" (giữ nguyên pin version)

# Apply upgrade
helm upgrade hanas-tenant minio-operator/tenant \
  -f tenant-values.yaml \
  --namespace minio-tenant \
  --wait

# Verify
kubectl get pods -n minio-tenant -w
```

### Trên Docker Compose

```bash
# Pull image mới (nếu cần)
docker compose pull minio

# Recreate container
docker compose up -d --force-recreate minio
```

> **Lưu ý khi upgrade:**
> - **Backup trước** khi upgrade (xem [Best Practices](best-practices.md))
> - MinIO hỗ trợ **rolling upgrade** trong distributed mode
> - Đọc release notes cho breaking changes
> - Test trên staging environment trước
> - **Không downgrade** — MinIO chỉ hỗ trợ upgrade lên version mới hơn
