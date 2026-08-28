# Cài Đặt & Triển Khai Dify

## Prerequisites

| Thành phần | Yêu cầu tối thiểu | Khuyến nghị |
|---|---|---|
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 4 GB | 8+ GB |
| **Disk** | 20 GB SSD | 50+ GB SSD |
| **Docker** | 20.10+ | Theo baseline/manifest đã phê duyệt |
| **Docker Compose** | v2.0+ | Theo baseline/manifest đã phê duyệt |
| **PostgreSQL** | 15+ | 16 |
| **Redis** | 6+ | 7 |

> [!NOTE]
> Dify không yêu cầu GPU. GPU chỉ cần cho vLLM inference server — xem [vLLM Installation](../vllm/installation.md).

## Cài Đặt Bằng Docker Compose

### 1. Clone Source Code

```bash
git clone https://github.com/langgenius/dify.git
cd dify/docker
```

### 2. Cấu Hình Environment

```bash
cp .env.example .env
```

Chỉnh sửa `.env` với các giá trị:

```bash
# === Core Settings ===
SECRET_KEY=<DIFY_SECRET_KEY_FROM_SECRET>
CONSOLE_WEB_URL=https://dify.your-domain.com
APP_WEB_URL=https://dify-app.your-domain.com

# === Database ===
DB_USERNAME=dify
DB_PASSWORD=<DIFY_DB_PASSWORD_FROM_SECRET>
DB_HOST=db
DB_PORT=5432
DB_DATABASE=dify

# === Redis ===
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=<REDIS_PASSWORD_FROM_SECRET>

# === Object Storage (MinIO — tích hợp Hanas) ===
STORAGE_TYPE=s3
S3_ENDPOINT=https://minio.your-domain.com
S3_BUCKET_NAME=dify-storage
S3_ACCESS_KEY=<MINIO_ACCESS_KEY_FROM_SECRET>
S3_SECRET_KEY=<MINIO_SECRET_KEY_FROM_SECRET>
S3_REGION=us-east-1

# === Vector Database ===
VECTOR_STORE=weaviate
WEAVIATE_ENDPOINT=http://weaviate:8080
```

### 3. Khởi Động Services

```bash
docker compose up -d
```

### 4. Kiểm Tra Health

```bash
# Kiểm tra tất cả containers
docker compose ps

# Kiểm tra API health
curl http://localhost/v1/health
```

### 5. Truy Cập Giao Diện

- **Console (Admin)**: `http://localhost` — Quản lý workspace, workflows, knowledge bases
- **App**: `http://localhost/app` — Giao diện ứng dụng AI cho end-user

## Cài Đặt Trên Kubernetes

### Helm Chart

```bash
# Thêm Helm repo
helm repo add dify https://langgenius.github.io/dify-helm
helm repo update

# Cài đặt
helm install dify dify/dify \
  --namespace dify \
  --create-namespace \
  --values values-production.yaml
```

### Ví Dụ `values-production.yaml`

```yaml
# Dify Kubernetes Configuration
global:
  image:
    tag: "1.0.0"

api:
  replicas: 2
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  env:
    SECRET_KEY: "<DIFY_SECRET_KEY_FROM_SECRET>"
    # Tích hợp MinIO từ Hanas Platform
    STORAGE_TYPE: "s3"
    S3_ENDPOINT: "http://minio.hanas-storage:9000"
    S3_ACCESS_KEY: "<MINIO_ACCESS_KEY_FROM_SECRET>"
    S3_SECRET_KEY: "<MINIO_SECRET_KEY_FROM_SECRET>"
    S3_BUCKET_NAME: "dify-storage"

worker:
  replicas: 2
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"

web:
  replicas: 2

# Sử dụng PostgreSQL external (từ Hanas)
postgresql:
  enabled: false
externalPostgresql:
  host: "postgres.hanas-db"
  port: 5432
  database: "dify"
  username: "dify"
  password: "<DIFY_DB_PASSWORD_FROM_SECRET>"

# Sử dụng Redis external
redis:
  enabled: false
externalRedis:
  host: "redis.hanas-cache"
  port: 6379
  password: "<REDIS_PASSWORD_FROM_SECRET>"

# Vector Database
vectorStore:
  type: "weaviate"
  weaviate:
    endpoint: "http://weaviate.hanas-ai:8080"

# Ingress
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: dify.your-domain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: dify-tls
      hosts:
        - dify.your-domain.com
```

## Tích Hợp Với Hanas Infrastructure

| Hanas Service | Tích hợp Dify |
|---|---|
| **MinIO** (L2) | Object storage cho uploaded files, Knowledge Base documents |
| **PostgreSQL** | Shared database cluster cho application data |
| **Redis** | Shared Redis cho caching và Celery task queue |
| **Kubernetes** (L8) | Container orchestration, auto-scaling |
| **Vault** (L9) | Secrets management cho API keys, credentials |

## Xác Nhận Cài Đặt

```bash
# 1. Kiểm tra services
docker compose ps
# Tất cả services phải ở trạng thái "Up (healthy)"

# 2. Tạo admin account
# Truy cập http://localhost và tạo tài khoản admin đầu tiên

# 3. Kiểm tra model provider
# Settings → Model Providers → Thêm vLLM (OpenAI-compatible)

# 4. Test nhanh
# Tạo một Chatbot đơn giản và gửi tin nhắn test
```

## Tiếp Theo

- [Cấu hình chi tiết](configuration.md) — Thiết lập model provider, Knowledge Base, Langfuse
- [Hướng dẫn sử dụng](user-guide.md) — Tạo workflow đầu tiên
