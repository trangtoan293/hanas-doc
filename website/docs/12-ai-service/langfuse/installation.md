# Cài Đặt & Triển Khai Langfuse

## Prerequisites

| Thành phần | Yêu cầu tối thiểu | Khuyến nghị |
|---|---|---|
| **CPU** | 2 cores | 4 cores |
| **RAM** | 2 GB | 4 GB |
| **Disk** | 10 GB SSD | 50+ GB SSD (cho traces data) |
| **Docker** | 20.10+ | Latest stable |
| **PostgreSQL** | 14+ | 16 (shared với Hanas) |

> [!NOTE]
> Langfuse không yêu cầu GPU. Nó là ứng dụng web thuần, chạy trên CPU.

## Cài Đặt Bằng Docker Compose

### 1. Tạo `docker-compose.yml`

```yaml
version: '3.8'

services:
  langfuse:
    image: langfuse/langfuse:latest
    container_name: langfuse
    ports:
      - "3000:3000"
    environment:
      # === Database ===
      DATABASE_URL: "postgresql://langfuse:secure-password@postgres:5432/langfuse"
      
      # === Authentication ===
      NEXTAUTH_SECRET: "your-nextauth-secret-key"
      NEXTAUTH_URL: "http://langfuse.your-domain.com"
      
      # === Salt for API key hashing ===
      SALT: "your-salt-value"
      
      # === Optional: Telemetry ===
      TELEMETRY_ENABLED: "false"
      
      # === Optional: Sign-up ===
      AUTH_DISABLE_SIGNUP: "false"  # Set true sau khi tạo admin
    depends_on:
      - postgres
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/public/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  postgres:
    image: postgres:16-alpine
    container_name: langfuse-db
    environment:
      POSTGRES_USER: langfuse
      POSTGRES_PASSWORD: secure-password
      POSTGRES_DB: langfuse
    volumes:
      - langfuse_pg_data:/var/lib/postgresql/data
    restart: always

volumes:
  langfuse_pg_data:
```

### 2. Khởi Động

```bash
docker compose up -d
```

### 3. Truy Cập

- **Dashboard**: `http://localhost:3000`
- Tạo tài khoản admin đầu tiên
- Tạo project và lấy API keys

### Sử Dụng PostgreSQL Từ Hanas

Nếu muốn sử dụng PostgreSQL cluster chung của Hanas:

```yaml
services:
  langfuse:
    image: langfuse/langfuse:latest
    environment:
      DATABASE_URL: "postgresql://langfuse:password@postgres.hanas-db:5432/langfuse"
      # ... các env vars khác
    # không cần service postgres riêng
```

## Cài Đặt Trên Kubernetes

### Helm Chart

```bash
helm repo add langfuse https://langfuse.github.io/langfuse-k8s
helm repo update

helm install langfuse langfuse/langfuse \
  --namespace langfuse \
  --create-namespace \
  --values values-production.yaml
```

### Ví Dụ `values-production.yaml`

```yaml
langfuse:
  replicas: 2
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "2Gi"
  env:
    NEXTAUTH_SECRET: "your-secret"
    NEXTAUTH_URL: "https://langfuse.your-domain.com"
    SALT: "your-salt"
    TELEMETRY_ENABLED: "false"
    AUTH_DISABLE_SIGNUP: "true"

# Sử dụng PostgreSQL external (Hanas)
postgresql:
  enabled: false
externalPostgresql:
  host: "postgres.hanas-db"
  port: 5432
  database: "langfuse"
  username: "langfuse"
  password: "secure-password"

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: langfuse.your-domain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: langfuse-tls
      hosts:
        - langfuse.your-domain.com
```

## Tích Hợp Với Hanas Infrastructure

| Hanas Service | Tích hợp Langfuse |
|---|---|
| **PostgreSQL** | Shared database cluster cho traces storage |
| **Kubernetes** (L8) | Container orchestration |
| **Vault** (L9) | Secrets management (API keys, DB credentials) |
| **OpenObserve** (L7) | Infrastructure monitoring (bổ sung cho AI observability) |

## Xác Nhận Cài Đặt

```bash
# 1. Health check
curl http://localhost:3000/api/public/health

# 2. Tạo project
# Truy cập http://localhost:3000 → New Project

# 3. Lấy API Keys
# Project Settings → API Keys → Create
# Ghi lại: Public Key (pk-lf-...) và Secret Key (sk-lf-...)

# 4. Test API
curl -X GET "http://localhost:3000/api/public/health" \
  -H "Authorization: Basic $(echo -n 'pk-lf-xxx:sk-lf-xxx' | base64)"
```

## Tiếp Theo

- [Cấu hình chi tiết](configuration.md) — Tích hợp Dify, SDK setup
- [Hướng dẫn sử dụng](user-guide.md) — Trace analysis, evaluation
