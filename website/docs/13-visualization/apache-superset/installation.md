# Apache Superset - Cài Đặt & Triển Khai

## Yêu Cầu Hệ Thống

### Kiến Trúc Components

Apache Superset bao gồm các components chính:

| Component | Vai trò | Bắt buộc |
|---|---|---|
| **Superset App** | Flask backend + React frontend, xử lý API, render UI | ✅ Có |
| **Metadata DB** | Lưu chart/dashboard definitions, users, permissions | ✅ Có (PostgreSQL) |
| **Redis** | Cache query results, session store, Celery message broker | ✅ Có |
| **Celery Worker** | Xử lý async queries, Alerts & Reports | ⚠️ Khuyến nghị |
| **Celery Beat** | Scheduler cho Alerts & Reports, cache warmup | ⚠️ Khuyến nghị |

### Yêu Cầu Resources

#### Superset App (Web Server)

| Resource | Khuyến nghị | Ghi chú |
|---|---|---|
| **CPU** | 4–8 cores | Gunicorn workers = 2 × CPU + 1 |
| **RAM** | 8–16 GB | Tùy số concurrent users và query complexity |
| **Disk** | 10 GB | Application code, logs |

#### Celery Worker

| Resource | Khuyến nghị | Ghi chú |
|---|---|---|
| **CPU** | 4–8 cores | Mỗi worker xử lý 1 async query |
| **RAM** | 8–16 GB | Tùy kích thước result sets |
| **Disk** | 10 GB | Temporary files, logs |

#### Metadata Database (PostgreSQL)

| Resource | Khuyến nghị | Ghi chú |
|---|---|---|
| **CPU** | 2–4 cores | Workload nhẹ (metadata only) |
| **RAM** | 4–8 GB | Connection pooling |
| **Disk** | 20–50 GB SSD | Metadata, query logs, saved queries |

#### Redis

| Resource | Khuyến nghị | Ghi chú |
|---|---|---|
| **CPU** | 1–2 cores | In-memory operations |
| **RAM** | 4–8 GB | Cache size, session store, message queue |
| **Disk** | 10 GB | AOF/RDB persistence (optional) |

### Prerequisites

| Yêu cầu | Chi tiết |
|---|---|
| **Kubernetes** | EKS, AKS, GKE, OpenShift hoặc tương đương |
| **Helm 3** | Để deploy Superset Helm chart |
| **kubectl** | Configured trỏ vào target cluster |
| **Dremio** | Đang chạy, accessible qua Arrow Flight port 32010 |
| **Python** | 3.9+ (bundled trong Docker image) |
| **Node.js** | 18+ (bundled trong Docker image, cho frontend build) |

---

## Cài Đặt Trên Kubernetes (Production)

### Step 1: Thêm Helm Repository

```bash
# Thêm Apache Superset Helm repository
helm repo add superset https://apache.github.io/superset
helm repo update

# Kiểm tra chart versions
helm search repo superset/superset --versions
```

### Step 2: Chuẩn Bị Namespace

```bash
kubectl create namespace superset
```

### Step 3: Tạo Kubernetes Secrets

```bash
# Secret Key cho Flask (BẮT BUỘC - phải unique và bảo mật)
kubectl create secret generic superset-secret \
  --namespace superset \
  --from-literal=SUPERSET_SECRET_KEY="$(openssl rand -base64 42)"

# Database credentials cho Dremio
kubectl create secret generic superset-dremio-creds \
  --namespace superset \
  --from-literal=DREMIO_USER="<DREMIO_USERNAME>" \
  --from-literal=DREMIO_PASS="<DREMIO_PASSWORD>"
```

> ⚠️ **KHÔNG** hardcode credentials trong `values.yaml` hoặc commit vào Git. Sử dụng Kubernetes Secrets hoặc HashiCorp Vault.

### Step 4: Cấu Hình `values.yaml`

Tạo file `superset-values.yaml` cho Hanas Platform:

```yaml
# ==============================================
# Apache Superset Helm Values - Hanas Platform
# ==============================================

# --- Image ---
image:
  repository: apachesuperset.docker.scarf.sh/apache/superset
  tag: "4.1.1"
  pullPolicy: IfNotPresent

# --- Superset Web Server ---
supersetNode:
  replicaCount: 2
  connections:
    db_host: "superset-postgresql"
    db_port: "5432"
    db_user: "superset"
    db_pass: "superset"
    db_name: "superset"
    redis_host: "superset-redis-master"
    redis_port: "6379"
  resources:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "4"
      memory: "8Gi"

# --- Celery Workers ---
supersetWorker:
  replicaCount: 2
  resources:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "4"
      memory: "8Gi"

# --- Celery Beat (Scheduler) ---
supersetCeleryBeat:
  enabled: true
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "1Gi"

# --- Celery Flower (Monitoring, Optional) ---
supersetCeleryFlower:
  enabled: false

# --- Init Container (Bootstrap) ---
init:
  adminUser:
    enabled: true
    username: admin
    firstname: Admin
    lastname: Hanas
    email: admin@hanas.vn
    password: "<CHANGE_ME>"
  initscript: |-
    #!/bin/bash
    echo "Installing database drivers..."
    pip install sqlalchemy-dremio
    echo "Superset init complete."

# --- SECRET KEY (từ Kubernetes Secret) ---
extraSecretEnv:
  SUPERSET_SECRET_KEY:
    valueFrom:
      secretKeyRef:
        name: superset-secret
        key: SUPERSET_SECRET_KEY

# --- Config Overrides ---
configOverrides:
  superset_config: |
    import os

    # Feature Flags
    FEATURE_FLAGS = {
        "DASHBOARD_NATIVE_FILTERS": True,
        "DASHBOARD_CROSS_FILTERS": True,
        "EMBEDDED_SUPERSET": True,
        "ALERT_REPORTS": True,
        "DASHBOARD_RBAC": True,
        "ENABLE_TEMPLATE_PROCESSING": True,
        "THUMBNAILS": True,
    }

    # Row Level Security
    ROW_LEVEL_SECURITY_ENABLED = True

    # SQL Lab
    SQLLAB_TIMEOUT = 300
    SQL_MAX_ROW = 100000

    # Proxy fix (cho Ingress / Load Balancer)
    ENABLE_PROXY_FIX = True

# --- PostgreSQL (Sub-chart) ---
postgresql:
  enabled: true
  auth:
    username: superset
    password: superset
    database: superset
  primary:
    persistence:
      enabled: true
      size: 20Gi

# --- Redis (Sub-chart) ---
redis:
  enabled: true
  architecture: standalone
  auth:
    enabled: false
  master:
    persistence:
      enabled: true
      size: 8Gi

# --- Ingress ---
ingress:
  enabled: true
  ingressClassName: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
  hosts:
    - host: superset.hanas.local
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: superset-tls
      hosts:
        - superset.hanas.local

# --- Service ---
service:
  type: ClusterIP
  port: 8088
```

### Step 5: Deploy Helm Chart

```bash
helm upgrade --install superset superset/superset \
  -f superset-values.yaml \
  --namespace superset \
  --wait \
  --timeout 10m
```

### Step 6: Verify Deployment

```bash
# Kiểm tra pods
kubectl get pods -n superset
# Expected:
# superset-0                          1/1  Running
# superset-1                          1/1  Running
# superset-worker-0                   1/1  Running
# superset-worker-1                   1/1  Running
# superset-celerybeat-0               1/1  Running
# superset-postgresql-0               1/1  Running
# superset-redis-master-0             1/1  Running

# Kiểm tra services
kubectl get svc -n superset
# Expected:
# superset          ClusterIP   ...   8088/TCP

# Kiểm tra ingress
kubectl get ingress -n superset
```

### Step 7: Truy Cập UI

```bash
# Port-forward nếu chưa có Ingress
kubectl port-forward svc/superset 8088:8088 -n superset

# Mở browser
open http://localhost:8088
# Hoặc: http://superset.hanas.local (nếu đã cấu hình Ingress)
```

**Đăng nhập:** Sử dụng admin credentials đã cấu hình trong `init.adminUser`.

---

## Cài Đặt Docker Compose (Dev/Test)

```yaml
version: "3.8"
services:
  superset:
    image: apachesuperset.docker.scarf.sh/apache/superset:4.1.1
    container_name: superset
    ports:
      - "8088:8088"
    environment:
      - SUPERSET_SECRET_KEY=hanas-dev-secret-key-change-in-production
      - DATABASE_URL=postgresql://superset:superset@postgres:5432/superset
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    volumes:
      - superset-home:/app/superset_home
    restart: unless-stopped
    command: >
      bash -c "
        pip install sqlalchemy-dremio &&
        superset db upgrade &&
        superset fab create-admin --username admin --firstname Admin --lastname Hanas --email admin@hanas.vn --password admin123 &&
        superset init &&
        superset run -h 0.0.0.0 -p 8088
      "

  postgres:
    image: postgres:15-alpine
    container_name: superset-postgres
    environment:
      - POSTGRES_USER=superset
      - POSTGRES_PASSWORD=superset
      - POSTGRES_DB=superset
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: superset-redis
    volumes:
      - redis-data:/data
    restart: unless-stopped

  celery-worker:
    image: apachesuperset.docker.scarf.sh/apache/superset:4.1.1
    container_name: superset-worker
    environment:
      - SUPERSET_SECRET_KEY=hanas-dev-secret-key-change-in-production
      - DATABASE_URL=postgresql://superset:superset@postgres:5432/superset
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    command: celery --app=superset.tasks.celery_app:app worker --loglevel=INFO
    restart: unless-stopped

  celery-beat:
    image: apachesuperset.docker.scarf.sh/apache/superset:4.1.1
    container_name: superset-beat
    environment:
      - SUPERSET_SECRET_KEY=hanas-dev-secret-key-change-in-production
      - DATABASE_URL=postgresql://superset:superset@postgres:5432/superset
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    command: celery --app=superset.tasks.celery_app:app beat --loglevel=INFO
    restart: unless-stopped

volumes:
  superset-home:
  postgres-data:
  redis-data:
```

```bash
# Khởi động
docker compose up -d

# Verify
curl -s http://localhost:8088/health | jq
# Expected: {"status": "OK"}
```

> **Dev/Test:** Docker Compose phù hợp cho development và testing. Không khuyến nghị cho production.

---

## Kiểm Tra Sau Cài Đặt

### 1. Health Check API

```bash
# Health endpoint
curl -s http://<SUPERSET_HOST>:8088/health
# Expected: {"status": "OK"}

# Login API
curl -X POST http://<SUPERSET_HOST>:8088/api/v1/security/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "<PASSWORD>", "provider": "db"}'
# Expected: {"access_token": "eyJ...", "refresh_token": "eyJ..."}
```

### 2. Verify Dremio Connection

Sau khi login vào UI:

1. Vào **Settings → Database Connections → + Database**
2. Chọn **Other** (hoặc Dremio nếu có trong danh sách)
3. Nhập SQLAlchemy URI:

```
dremio+flight://dremio_user:dremio_password@dremio-client.dremio.svc:32010/dremio
```

4. Click **Test Connection** → phải thấy "Connection looks good!"

### 3. Test Query Trên SQL Lab

```sql
-- Mở SQL Lab, chọn database Dremio
-- Chạy test query
SELECT * FROM "DATA_MART".dim_customer LIMIT 10;
```

### 4. Verify Celery Workers

```bash
# Kubernetes
kubectl logs -n superset -l app=superset-worker --tail=20
# Expected: celery@... ready, pool: prefork

# Docker Compose
docker logs superset-worker --tail=20
```

---

## Upgrade Superset

### Trên Kubernetes

```bash
# 1. Cập nhật image tag trong superset-values.yaml
# image:
#   tag: "4.1.2"

# 2. Apply upgrade
helm upgrade superset superset/superset \
  -f superset-values.yaml \
  --namespace superset \
  --wait

# 3. Verify
kubectl get pods -n superset -w
```

### Trên Docker Compose

```bash
# 1. Cập nhật image tag trong docker-compose.yml
# image: apachesuperset.docker.scarf.sh/apache/superset:4.1.2

# 2. Pull và restart
docker compose pull
docker compose up -d

# 3. Run DB migration
docker exec -it superset superset db upgrade
docker exec -it superset superset init
```

> ⚠️ **Lưu ý khi upgrade:**
> - **Backup metadata database** (PostgreSQL) trước khi upgrade
> - Đọc [UPDATING.md](https://github.com/apache/superset/blob/master/UPDATING.md) cho breaking changes
> - Test trên staging environment trước
> - Major version upgrade (3.x → 4.x) có thể yêu cầu migration steps bổ sung
