# Dremio - Cài Đặt & Triển Khai

## Yêu Cầu Hệ Thống

### Kiến Trúc Cluster

Dremio cluster bao gồm 2 loại nodes chính:

| Node Type | Vai trò | Số lượng |
|---|---|---|
| **Coordinator** | Query planning, UI/API, metadata management | 1 (+ secondary cho HA) |
| **Executor** | Query execution, caching, reflections | 3+ (scale theo workload) |
| **Zookeeper** | Cluster coordination giữa các nodes | 3 (quorum) |

### Yêu Cầu Resources

#### Coordinator Node

| Resource | Khuyến nghị | Ghi chú |
|---|---|---|
| **CPU** | 16–32 cores | Quan trọng cho high-throughput query planning |
| **RAM** | 32–64 GB | Heap + Direct memory cho metadata |
| **Disk (KV Store)** | 128–512 GB SSD | Metadata, KV store — cần IOPS cao |
| **Disk (Logs)** | 16 GB | Persistent logs, heap dumps |

#### Executor Node

| Resource | Khuyến nghị | Ghi chú |
|---|---|---|
| **CPU** | 16–32 cores | Dành cho query execution |
| **RAM** | 64–128 GB | Heap + Direct memory cho queries |
| **Disk (Spilling)** | 128–512 GB SSD/NVMe | Intermediate data, spilling |
| **Disk (C3 Cache)** | 128–512 GB NVMe | Cloud Columnar Cache — dùng local NVMe |
| **Disk (Logs)** | 16 GB | Persistent logs |

### Prerequisites

| Yêu cầu | Chi tiết |
|---|---|
| **Kubernetes** | EKS, AKS, GKE, OpenShift hoặc tương đương |
| **Helm 3** | Để deploy Dremio Helm chart |
| **kubectl** | Configured trỏ vào target cluster |
| **Object Storage** | MinIO (S3-compatible) đã sẵn sàng |
| **Hive Metastore** | Đang chạy, accessible từ Dremio pods |
| **Java** | OpenJDK 11/17/21 (bundled trong image) |
| **Network** | 10 GbE khuyến nghị cho large datasets |

---

## Cài Đặt Trên Kubernetes (Production)

### Step 1: Chuẩn Bị Namespace

```bash
kubectl create namespace dremio
```

### Step 2: Tải Helm Chart

```bash
# Clone Dremio Helm chart
git clone https://github.com/dremio/dremio-cloud-tools.git
cd dremio-cloud-tools/charts/dremio_v2
```

### Step 3: Cấu Hình `values.yaml`

Tạo file `values-overrides.yaml` cho Hanas Platform:

```yaml
# Dremio Image
image: dremio/dremio-oss
imageTag: "25.1.0"

# Coordinator Configuration
coordinator:
  memory: 32768          # 32 GB RAM
  cpu: 16                # 16 cores
  count: 1               # 1 main coordinator
  volumeSize: "200Gi"    # KV store
  web:
    port: 9047           # UI/API port
  client:
    port: 31010          # JDBC port
  flight:
    port: 32010          # Arrow Flight port

# Executor Configuration
executor:
  memory: 65536          # 64 GB RAM
  cpu: 16                # 16 cores
  count: 3               # 3 executor pods
  volumeSize: "200Gi"    # Spilling + C3 cache
  cloudCache:
    enabled: true

# Zookeeper
zookeeper:
  memory: 1024           # 1 GB
  cpu: 0.5
  count: 3               # Quorum
  volumeSize: "10Gi"

# Distributed Storage — MinIO
distStorage:
  type: "aws"            # S3-compatible
  aws:
    bucketName: "dremio"
    path: "/"
    authentication: "accessKeySecret"
    credentials:
      accessKey: "<MINIO_ACCESS_KEY>"
      secret: "<MINIO_SECRET_KEY>"
    extraProperties: |
      <property>
        <name>fs.s3a.endpoint</name>
        <value>http://<MINIO_HOST>:9000</value>
      </property>
      <property>
        <name>fs.s3a.path.style.access</name>
        <value>true</value>
      </property>
      <property>
        <name>dremio.s3.compat</name>
        <value>true</value>
      </property>

# Service Type
service:
  type: LoadBalancer      # Hoặc NodePort cho on-premise
  sessionAffinity: ClientIP
```

> ⚠️ **KHÔNG** commit credentials vào Git. Sử dụng Kubernetes Secrets hoặc Vault:
>
> ```bash
> kubectl create secret generic dremio-minio-creds \
>   --namespace dremio \
>   --from-literal=accessKey=<MINIO_ACCESS_KEY> \
>   --from-literal=secret=<MINIO_SECRET_KEY>
> ```

### Step 4: Deploy Helm Chart

```bash
helm install dremio dremio_v2 \
  -f values-overrides.yaml \
  --namespace dremio \
  --wait
```

### Step 5: Verify Deployment

```bash
# Kiểm tra pods
kubectl get pods -n dremio
# Expected:
# dremio-coordinator-0       1/1  Running
# dremio-executor-0          1/1  Running
# dremio-executor-1          1/1  Running
# dremio-executor-2          1/1  Running
# zk-0                       1/1  Running
# zk-1                       1/1  Running
# zk-2                       1/1  Running

# Kiểm tra services
kubectl get svc -n dremio
# Expected:
# dremio-client   LoadBalancer   ...   9047:xxxxx/TCP,31010:xxxxx/TCP,32010:xxxxx/TCP
```

### Step 6: Truy Cập UI

```bash
# Port-forward nếu dùng NodePort
kubectl port-forward svc/dremio-client 9047:9047 -n dremio

# Mở browser
open http://localhost:9047
# Hoặc: http://dremio.hanas.local/ (nếu đã cấu hình DNS/Ingress)
```

**Đăng nhập lần đầu:** Tạo admin account (username/password) khi truy cập UI lần đầu tiên.

---

## Cài Đặt Docker Compose (Dev/Test)

```yaml
version: "3.8"
services:
  dremio:
    image: dremio/dremio-oss:25.1.0
    container_name: dremio
    ports:
      - "9047:9047"    # UI / REST API
      - "31010:31010"  # JDBC
      - "32010:32010"  # Arrow Flight
      - "45678:45678"  # Inter-node communication
    volumes:
      - dremio-data:/opt/dremio/data
      - dremio-conf:/opt/dremio/conf
    environment:
      - DREMIO_JAVA_SERVER_EXTRA_OPTS=-Dpaths.dist=file:///opt/dremio/data/dist
    restart: unless-stopped

volumes:
  dremio-data:
  dremio-conf:
```

```bash
# Khởi động
docker compose up -d

# Verify
curl -s http://localhost:9047 | head -5
```

> **Dev/Test:** Docker Compose chạy single-node (coordinator + executor trên cùng 1 container). Không phù hợp production.

---

## Kiểm Tra Sau Cài Đặt

### 1. Health Check UI

Truy cập `http://<DREMIO_HOST>:9047` và verify:
- Login thành công với admin credentials
- Navigation panel hiển thị Sources, Spaces, SQL Runner

### 2. Health Check API

```bash
# Login API
curl -X POST http://<DREMIO_HOST>:9047/apiv2/login \
  -H "Content-Type: application/json" \
  -d '{"userName": "vaultadmin", "password": "<PASSWORD>"}'

# Expected: {"token": "..."}
```

### 3. Test SQL Query

Truy cập SQL Runner trên UI và chạy:

```sql
-- Kiểm tra version
SELECT version();

-- Nếu đã cấu hình MinIO source, test query
SELECT * FROM <minio_source>.data_mart.dim_customer LIMIT 10;
```

### 4. Verify Arrow Flight Connectivity

```bash
# Test Arrow Flight port
nc -zv <DREMIO_HOST> 32010
# Expected: Connection to <host> 32010 port [tcp/*] succeeded!
```

### 5. Verify JDBC Connectivity

```bash
# Test JDBC port
nc -zv <DREMIO_HOST> 31010
# Expected: Connection to <host> 31010 port [tcp/*] succeeded!
```

---

## Upgrade Dremio

### Trên Kubernetes

```bash
# Cập nhật imageTag trong values-overrides.yaml
# imageTag: "25.2.0"

# Apply upgrade
helm upgrade dremio dremio_v2 \
  -f values-overrides.yaml \
  --namespace dremio \
  --wait

# Verify
kubectl get pods -n dremio -w
```

> ⚠️ **Lưu ý khi upgrade:**
> - Backup KV store trước khi upgrade (persistent volume trên coordinator)
> - Đọc release notes cho breaking changes
> - Test trên staging environment trước
> - Dremio không hỗ trợ downgrade — chỉ upgrade lên version mới hơn
