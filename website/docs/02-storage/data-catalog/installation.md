# Apache Polaris - Cài Đặt & Triển Khai

## Yêu Cầu Hệ Thống

Apache Polaris là một **service chạy độc lập** (khác với Iceberg là library). Polaris server cần các thành phần sau:

### Components Bắt Buộc

| Component | Version | Vai trò |
|---|---|---|
| **Apache Polaris** | 1.3.x | REST Catalog server (Quarkus-based) |
| **PostgreSQL** | 14+ | Persistence backend cho catalog metadata |
| **MinIO** | Latest | Object Storage (lưu Iceberg data + metadata files) |
| **Kubernetes** | 1.28+ | Container orchestration (production) |
| **Helm** | 3.x+ | Package manager cho K8s deployment |

### Components Tùy Chọn

| Component | Vai trò |
|---|---|
| **Apache Spark** | Compute engine, kết nối qua REST Catalog |
| **Dremio** | Query engine, kết nối qua Iceberg REST source |
| **HashiCorp Vault** | Quản lý secrets (PostgreSQL password, Polaris credentials) |
| **OpenObserve** | Monitoring (logs, metrics) |

### Network Requirements

| Port | Protocol | Service |
|---|---|---|
| **8181** | HTTP | Polaris REST API (Iceberg + Management) |
| **8182** | HTTP | Polaris Management API (metrics, health) |
| **5432** | TCP | PostgreSQL |
| **9000** | HTTP | MinIO S3 API |

---

## Cài Đặt Trên Kubernetes (Production)

### Step 1: Tạo PostgreSQL Database

Polaris yêu cầu PostgreSQL làm persistence backend. Tạo database trước khi deploy:

```sql
-- Tạo database và user cho Polaris
CREATE USER polaris WITH PASSWORD '<POLARIS_DB_PASSWORD>';
CREATE DATABASE polaris OWNER polaris;
GRANT ALL PRIVILEGES ON DATABASE polaris TO polaris;
```

### Step 2: Tạo Kubernetes Secrets

```bash
# Secret cho PostgreSQL credentials
kubectl create secret generic polaris-db-credentials \
  --namespace polaris \
  --from-literal=username=polaris \
  --from-literal=password='<POLARIS_DB_PASSWORD>'

# Secret cho Polaris bootstrap credentials
kubectl create secret generic polaris-bootstrap-credentials \
  --namespace polaris \
  --from-literal=client-id=root \
  --from-literal=client-secret='<POLARIS_CLIENT_SECRET>'

# Secret cho MinIO credentials (nếu dùng credential vending)
kubectl create secret generic polaris-s3-credentials \
  --namespace polaris \
  --from-literal=access-key='<MINIO_ACCESS_KEY>' \
  --from-literal=secret-key='<MINIO_SECRET_KEY>'
```

### Step 3: Thêm Helm Repository

```bash
# Thêm Apache Polaris Helm repo
helm repo add apache-polaris https://polaris.apache.org/helm
helm repo update

# Xem các versions có sẵn
helm search repo apache-polaris/polaris --versions
```

### Step 4: Tạo Custom Values File

Tạo file `polaris-values.yaml`:

```yaml
# polaris-values.yaml - Production configuration cho Hanas Platform

replicaCount: 2

image:
  repository: apache/polaris
  tag: "1.3.0"
  pullPolicy: IfNotPresent

# Server configuration
polaris:
  # Persistence - PostgreSQL
  persistence:
    type: jdbc
    jdbc:
      url: "jdbc:postgresql://<POSTGRES_HOST>:5432/polaris"
      user:
        secretName: polaris-db-credentials
        secretKey: username
      password:
        secretName: polaris-db-credentials
        secretKey: password

  # Bootstrap credentials
  bootstrap:
    credentials:
      secretName: polaris-bootstrap-credentials
      clientIdKey: client-id
      clientSecretKey: client-secret

  # Storage - MinIO S3
  storage:
    type: s3
    s3:
      endpoint: "http://<MINIO_HOST>:9000"
      region: "us-east-1"
      pathStyleAccess: true

  # CORS (cho phép Dremio UI access)
  cors:
    allowedOrigins:
      - "*"
    allowedMethods:
      - "GET"
      - "POST"
      - "PUT"
      - "DELETE"
      - "HEAD"

# Resources
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 4Gi

# Service
service:
  type: ClusterIP
  port: 8181
  managementPort: 8182

# Health checks
livenessProbe:
  httpGet:
    path: /q/health/live
    port: 8182
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /q/health/ready
    port: 8182
  initialDelaySeconds: 15
  periodSeconds: 5

# Ingress (tùy chọn)
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: polaris.hanas.local
      paths:
        - path: /
          pathType: Prefix

# Pod disruption budget cho HA
podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

### Step 5: Deploy Polaris

```bash
# Tạo namespace
kubectl create namespace polaris

# Deploy bằng Helm
helm install polaris apache-polaris/polaris \
  --namespace polaris \
  --values polaris-values.yaml \
  --wait --timeout 5m

# Verify deployment
kubectl get pods -n polaris
kubectl get svc -n polaris
```

### Step 6: Bootstrap Polaris

Sau khi deploy, Polaris tự động bootstrap realm và root principal. Verify:

```bash
# Port-forward để test
kubectl port-forward svc/polaris 8181:8181 -n polaris &

# Test health
curl -s http://localhost:8181/q/health | jq .

# Lấy access token
curl -s -X POST http://localhost:8181/api/catalog/v1/oauth/tokens \
  -d "grant_type=client_credentials" \
  -d "client_id=root" \
  -d "client_secret=<POLARIS_CLIENT_SECRET>" \
  -d "scope=PRINCIPAL_ROLE:ALL" | jq .
```

---

## Cài Đặt Docker Compose (Dev/Test)

Cho môi trường phát triển, sử dụng Docker Compose:

```yaml
# docker-compose.yml
version: '3.8'

services:
  polaris-postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: polaris
      POSTGRES_PASSWORD: polaris123
      POSTGRES_DB: polaris
    ports:
      - "5432:5432"
    volumes:
      - polaris_pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U polaris"]
      interval: 5s
      timeout: 3s
      retries: 10

  polaris:
    image: apache/polaris:1.3.0
    depends_on:
      polaris-postgres:
        condition: service_healthy
      minio:
        condition: service_started
    ports:
      - "8181:8181"
      - "8182:8182"
    environment:
      # Persistence
      POLARIS_PERSISTENCE_TYPE: jdbc
      QUARKUS_DATASOURCE_JDBC_URL: "jdbc:postgresql://polaris-postgres:5432/polaris"
      QUARKUS_DATASOURCE_USERNAME: polaris
      QUARKUS_DATASOURCE_PASSWORD: polaris123
      # Bootstrap
      POLARIS_BOOTSTRAP_CREDENTIALS: "POLARIS,root,s3cr3t"
      # Storage defaults
      AWS_REGION: us-east-1
      AWS_ACCESS_KEY_ID: minioadmin
      AWS_SECRET_ACCESS_KEY: minioadmin
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8182/q/health/ready"]
      interval: 10s
      timeout: 5s
      retries: 10

  minio:
    image: minio/minio
    ports:
      - "9000:9000"
      - "9001:9001"
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - minio_data:/data

  minio-init:
    image: minio/mc
    depends_on:
      - minio
    entrypoint: >
      /bin/sh -c "
      sleep 5;
      mc alias set minio http://minio:9000 minioadmin minioadmin;
      mc mb minio/data --ignore-existing;
      mc mb minio/data/warehouse --ignore-existing;
      exit 0;
      "

volumes:
  polaris_pgdata:
  minio_data:
```

Khởi chạy:

```bash
# Start tất cả services
docker compose up -d

# Verify
docker compose ps
curl -s http://localhost:8181/q/health | jq .
```

---

## Kiểm Tra Sau Cài Đặt

### 1. Verify Health Check

```bash
# Health endpoint
curl -s http://localhost:8181/q/health | jq .
# Expected: {"status":"UP","checks":[...]}

# Readiness
curl -s http://localhost:8182/q/health/ready | jq .
```

### 2. Verify Authentication

```bash
# Lấy access token
TOKEN=$(curl -s -X POST http://localhost:8181/api/catalog/v1/oauth/tokens \
  -d "grant_type=client_credentials" \
  -d "client_id=root" \
  -d "client_secret=s3cr3t" \
  -d "scope=PRINCIPAL_ROLE:ALL" | jq -r '.access_token')

echo $TOKEN
```

### 3. Tạo Catalog Test

```bash
# Tạo internal catalog
curl -s -X POST http://localhost:8181/api/management/v1/catalogs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "catalog": {
      "name": "test_catalog",
      "type": "INTERNAL",
      "properties": {
        "default-base-location": "s3://data/warehouse/test_catalog"
      },
      "storageConfigInfo": {
        "storageType": "S3",
        "allowedLocations": ["s3://data/warehouse/test_catalog"],
        "s3": {
          "endpoint": "http://minio:9000",
          "region": "us-east-1",
          "pathStyleAccess": true
        }
      }
    }
  }' | jq .

# List catalogs
curl -s http://localhost:8181/api/management/v1/catalogs \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### 4. Verify Spark Connectivity

```bash
# Kết nối Spark SQL với Polaris
bin/spark-sql \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.9.0,org.apache.iceberg:iceberg-aws-bundle:1.9.0 \
  --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
  --conf spark.sql.catalog.polaris=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.polaris.catalog-impl=org.apache.iceberg.rest.RESTCatalog \
  --conf spark.sql.catalog.polaris.uri=http://localhost:8181/api/catalog \
  --conf spark.sql.catalog.polaris.credential='root:s3cr3t' \
  --conf spark.sql.catalog.polaris.warehouse=test_catalog \
  --conf spark.sql.catalog.polaris.scope='PRINCIPAL_ROLE:ALL' \
  --conf spark.sql.catalog.polaris.token-refresh-enabled=true \
  --conf spark.sql.catalog.polaris.header.X-Iceberg-Access-Delegation=vended-credentials
```

```sql
-- Test trong Spark SQL
CREATE NAMESPACE polaris.test_ns;
SHOW NAMESPACES IN polaris;

CREATE TABLE polaris.test_ns.test_table (
    id INT,
    name STRING,
    created_at TIMESTAMP
) USING iceberg;

INSERT INTO polaris.test_ns.test_table VALUES (1, 'hello polaris', current_timestamp());
SELECT * FROM polaris.test_ns.test_table;
```

### 5. Cleanup Test

```bash
# Xóa catalog test
curl -s -X DELETE http://localhost:8181/api/management/v1/catalogs/test_catalog \
  -H "Authorization: Bearer $TOKEN"
```

> **Lưu ý:** Trong production, sử dụng HashiCorp Vault để quản lý tất cả credentials (PostgreSQL password, Polaris client secret, MinIO access keys) thay vì hardcode.
