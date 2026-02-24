# DataHub - Cài Đặt & Triển Khai

## Yêu Cầu Hệ Thống

### Kiến Trúc Components

DataHub gồm nhiều services chạy song song, yêu cầu tài nguyên đáng kể:

| Component | Vai trò | Số lượng |
|---|---|---|
| **DataHub GMS** | Metadata Store (API server) | 1–2 replicas |
| **DataHub Frontend** | React UI | 1–2 replicas |
| **MAE Consumer** | Metadata Audit Event processor | 1 replica |
| **MCE Consumer** | Metadata Change Event processor | 1 replica |
| **Kafka + ZooKeeper** | Internal message bus | 1 broker (dev), 3+ (prod) |
| **Elasticsearch** | Search index | 1 node (dev), 3+ (prod) |
| **MySQL/PostgreSQL** | Primary metadata store | 1 instance |

### Yêu Cầu Resources

| Resource | Dev/Test | Production | Ghi chú |
|---|---|---|---|
| **CPU** | 2 cores | 8–16 cores | Cho toàn bộ stack |
| **RAM** | 8 GB | 32–64 GB | Elasticsearch cần nhiều RAM nhất |
| **Disk** | 12 GB SSD | 100+ GB SSD | MySQL + Elasticsearch indices |
| **Network** | 1 GbE | 10 GbE | Internal service communication |
| **OS** | Linux/macOS | Linux (Ubuntu 22.04+) | Container runtime required |

### Prerequisites

| Yêu cầu | Chi tiết |
|---|---|
| **Kubernetes** | 1.19+ (EKS, GKE, Rancher, OpenShift) |
| **Helm 3** | >= 3.8 |
| **kubectl** | Configured trỏ vào target cluster |
| **Docker** | >= 24.0 (cho dev/test) |
| **Docker Compose** | v2 (cho quickstart) |
| **Python** | >= 3.10 (cho datahub CLI) |

---

## Cài Đặt Trên Kubernetes (Production)

### Step 1: Thêm Helm Repository

```bash
# Thêm DataHub Helm repo
helm repo add datahub https://helm.datahubproject.io/
helm repo update

# Verify
helm search repo datahub
```

### Step 2: Tạo Namespace

```bash
kubectl create namespace datahub
```

### Step 3: Tạo Secrets

```bash
# MySQL password
kubectl create secret generic mysql-secrets \
  --namespace datahub \
  --from-literal=mysql-root-password='<MYSQL_ROOT_PASSWORD>'

# DataHub credentials
kubectl create secret generic datahub-secrets \
  --namespace datahub \
  --from-literal=datahub-admin-password='<DATAHUB_ADMIN_PASSWORD>' \
  --from-literal=token-service-signing-key='<SIGNING_KEY_BASE64>'
```

> ⚠️ **KHÔNG** commit credentials vào Git. Sử dụng Kubernetes Secrets hoặc HashiCorp Vault.

### Step 4: Cài Đặt Dependencies (Prerequisites)

DataHub cần Kafka, Elasticsearch, MySQL chạy trước:

```yaml
# prerequisites-values.yaml
elasticsearch:
  replicas: 1                          # 3 cho production
  minimumMasterNodes: 1
  resources:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  volumeClaimTemplate:
    resources:
      requests:
        storage: 50Gi

kafka:
  replicaCount: 1                      # 3 cho production
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"

mysql:
  primary:
    resources:
      requests:
        cpu: "500m"
        memory: "1Gi"
    persistence:
      size: 20Gi
  auth:
    existingSecret: mysql-secrets

zookeeper:
  replicaCount: 1                      # 3 cho production
```

```bash
helm install prerequisites datahub/datahub-prerequisites \
  -f prerequisites-values.yaml \
  --namespace datahub \
  --wait --timeout 10m
```

### Step 5: Cài Đặt DataHub

```yaml
# datahub-values.yaml — Hanas Platform Configuration
datahub-gms:
  image:
    repository: acryldata/datahub-gms
    tag: "v0.14.1"                     # Pin version ổn định
  resources:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "4Gi"

datahub-frontend:
  image:
    repository: acryldata/datahub-frontend-react
    tag: "v0.14.1"
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
  extraEnvs:
    - name: AUTH_OIDC_ENABLED
      value: "false"                   # Bật khi có Identity Provider
    - name: REACT_APP_LOGO_URL
      value: "/custom/logo.png"        # Custom logo (optional)

datahub-mae-consumer:
  image:
    tag: "v0.14.1"

datahub-mce-consumer:
  image:
    tag: "v0.14.1"

global:
  elasticsearch:
    host: "elasticsearch-master"
    port: "9200"
  kafka:
    bootstrap:
      server: "prerequisites-kafka:9092"
  sql:
    datasource:
      host: "prerequisites-mysql:3306"
      hostForMysqlClient: "prerequisites-mysql"
      port: "3306"
      url: "jdbc:mysql://prerequisites-mysql:3306/datahub?verifyServerCertificate=false&useSSL=true"
      driver: "com.mysql.cj.jdbc.Driver"
      username: "root"
      password:
        secretRef: mysql-secrets
        secretKey: mysql-root-password
```

```bash
helm install datahub datahub/datahub \
  -f datahub-values.yaml \
  --namespace datahub \
  --wait --timeout 10m
```

### Step 6: Verify Deployment

```bash
# Kiểm tra pods
kubectl get pods -n datahub
# Expected:
# datahub-gms-xxx              1/1  Running
# datahub-frontend-xxx         1/1  Running
# datahub-mae-consumer-xxx     1/1  Running
# datahub-mce-consumer-xxx     1/1  Running
# elasticsearch-master-0       1/1  Running
# prerequisites-kafka-0        1/1  Running
# prerequisites-mysql-0        1/1  Running
# prerequisites-zookeeper-0    1/1  Running

# Kiểm tra services
kubectl get svc -n datahub
# Expected:
# datahub-gms          ClusterIP  ...  8080/TCP
# datahub-frontend     ClusterIP  ...  9002/TCP

# Port-forward để truy cập UI
kubectl port-forward svc/datahub-frontend 9002:9002 -n datahub
```

---

## Cài Đặt Docker Compose (Dev/Test)

### Option A: DataHub CLI Quickstart

Cách nhanh nhất cho dev/test:

```bash
# Cài datahub CLI
pip install datahub

# Khởi động toàn bộ stack
datahub docker quickstart

# Dừng
datahub docker quickstart --stop
```

> DataHub sẽ tự tải docker-compose file về `~/.datahub/quickstart/` và khởi động tất cả services.

### Option B: Docker Compose Thủ Công

Cho trường hợp cần customize:

```yaml
# docker-compose.yml
version: '3.8'

services:
  # --- Dependencies ---
  mysql:
    image: mysql:8.2
    container_name: datahub-mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-datahub}
      MYSQL_DATABASE: datahub
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  elasticsearch:
    image: elasticsearch:7.17.22
    container_name: datahub-elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200/_cluster/health | grep -q '\"status\":\"green\\|yellow\"'"]
      interval: 10s
      timeout: 5s
      retries: 10

  kafka:
    image: confluentinc/cp-kafka:7.6.0
    container_name: datahub-kafka
    depends_on:
      zookeeper:
        condition: service_healthy
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    ports:
      - "9092:9092"

  zookeeper:
    image: confluentinc/cp-zookeeper:7.6.0
    container_name: datahub-zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    healthcheck:
      test: ["CMD", "bash", "-c", "echo ruok | nc localhost 2181"]
      interval: 10s
      timeout: 5s
      retries: 5

  # --- DataHub Services ---
  datahub-gms:
    image: acryldata/datahub-gms:v0.14.1
    container_name: datahub-gms
    depends_on:
      mysql:
        condition: service_healthy
      elasticsearch:
        condition: service_healthy
      kafka:
        condition: service_started
    environment:
      EBEAN_DATASOURCE_URL: jdbc:mysql://mysql:3306/datahub?verifyServerCertificate=false&useSSL=true
      EBEAN_DATASOURCE_USERNAME: root
      EBEAN_DATASOURCE_PASSWORD: ${MYSQL_ROOT_PASSWORD:-datahub}
      KAFKA_BOOTSTRAP_SERVER: kafka:9092
      ELASTICSEARCH_HOST: elasticsearch
      ELASTICSEARCH_PORT: 9200
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:8080/health | grep -q UP"]
      interval: 15s
      timeout: 5s
      retries: 10

  datahub-frontend:
    image: acryldata/datahub-frontend-react:v0.14.1
    container_name: datahub-frontend
    depends_on:
      datahub-gms:
        condition: service_healthy
    environment:
      DATAHUB_GMS_HOST: datahub-gms
      DATAHUB_GMS_PORT: 8080
      DATAHUB_SECRET: YouKnowNothing
      DATAHUB_APP_VERSION: "1.0"
      DATAHUB_PLAY_MEM_BUFFER_SIZE: 10MB
    ports:
      - "9002:9002"
    restart: unless-stopped

  datahub-actions:
    image: acryldata/datahub-actions:v0.1.1
    container_name: datahub-actions
    depends_on:
      datahub-gms:
        condition: service_healthy
    environment:
      DATAHUB_GMS_URL: http://datahub-gms:8080
      KAFKA_BOOTSTRAP_SERVER: kafka:9092

volumes:
  mysql_data:
  es_data:
```

```bash
# Khởi động
docker compose up -d

# Kiểm tra
docker compose ps
docker compose logs datahub-gms --tail 20
```

---

## Kiểm Tra Sau Cài Đặt

### 1. Health Check API

```bash
# GMS health
curl -s http://<DATAHUB_HOST>:8080/health
# Expected: {"status":"UP"}

# GMS config
curl -s http://<DATAHUB_HOST>:8080/config
# Expected: JSON configuration object
```

### 2. Frontend UI

Truy cập `http://<DATAHUB_HOST>:9002` và verify:

- Login thành công với credentials mặc định (`datahub` / `datahub`)
- Trang Home hiển thị search bar và navigation
- Sidebar hiển thị Datasets, Dashboards, Pipelines, Glossary

### 3. Smoke Test — Ingestion

```bash
# Cài datahub CLI
pip install 'acryldata-datahub[datahub-rest]'

# Test kết nối GMS
datahub get --urn "urn:li:corpuser:datahub"
# Expected: Trả về entity metadata

# Tạo test dataset
datahub put --urn "urn:li:dataset:(urn:li:dataPlatform:hanas,test.smoke_test,PROD)" \
  -a datasetProperties \
  -d '{"description": "Smoke test dataset from Hanas Platform"}'

# Verify trên UI: search "smoke_test" → thấy dataset
```

### 4. Kết Nối Từ Airflow (Hanas Pipeline)

Verify DataHub publish TaskGroup hoạt động:

```bash
# Kiểm tra Airflow Variable
# DATAHUB_ASSET_TAG_NAME = "data platform demo"

# Trigger DAG test
# Chọn demo_data_pipeline_e2e_incremental → Trigger
# Kiểm tra task publish_datahub → logs phải show:
# "Successfully published dbt transformation metadata to DataHub"
# "Successfully published Iceberg metadata to DataHub"
# "Successfully published dbt test results to DataHub"
```

---

## Upgrade DataHub

### Trên Kubernetes

```bash
# Cập nhật image tag trong datahub-values.yaml
# tag: "v0.14.1" → "v0.15.0"

# Upgrade
helm upgrade datahub datahub/datahub \
  -f datahub-values.yaml \
  --namespace datahub \
  --wait

# Verify
kubectl get pods -n datahub -w
```

### Trên Docker Compose

```bash
# Cập nhật image tags trong docker-compose.yml
# Recreate containers
docker compose pull
docker compose up -d --force-recreate
```

> ⚠️ **Lưu ý khi upgrade:**
> - **Backup MySQL database** trước khi upgrade
> - Chạy DataHub upgrade CLI: `datahub docker quickstart --upgrade` (nếu dùng quickstart)
> - Đọc [release notes](https://github.com/datahub-project/datahub/releases) cho breaking changes
> - Test trên staging trước khi deploy production
> - Elasticsearch reindex có thể mất thời gian với dataset lớn
