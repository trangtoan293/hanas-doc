# Quickstart — Bắt Đầu Với Hanas Data Platform

## Mục Tiêu

Sau khi hoàn thành quickstart, bạn sẽ:
- Có môi trường dev hoạt động đầy đủ các service
- Hiểu cách các service kết nối với nhau
- Chạy được luồng dữ liệu đầu tiên: File CSV → MinIO → Spark → Iceberg → Dremio

---

## 1. Yêu Cầu Môi Trường

### Phần cứng tối thiểu (dev/test)
- **CPU**: 8 cores
- **RAM**: 32 GB
- **Disk**: 100 GB SSD
- **OS**: Linux (Ubuntu 22.04+ khuyến nghị) hoặc macOS

### Phần mềm cần cài
```bash
# Docker & Docker Compose
docker --version        # >= 24.0
docker compose version  # >= 2.20

# kubectl (nếu dùng K8s)
kubectl version --client

# Python (cho Airflow DAGs, PySpark)
python3 --version  # >= 3.9

# Java (cho Spark)
java -version  # >= 11
```

---

## 2. Khởi Tạo Môi Trường

### 2.1 Cấu trúc thư mục dự án

```bash
mkdir -p hanas-platform/{config,data,logs,dags,dbt}
cd hanas-platform
```

```
hanas-platform/
├── docker-compose.yml      # Định nghĩa toàn bộ services
├── .env                    # Biến môi trường
├── config/
│   ├── minio/              # MinIO configuration
│   ├── spark/              # Spark configuration
│   ├── airflow/            # Airflow configuration
│   └── dremio/             # Dremio configuration
├── data/                   # Dữ liệu mẫu
├── dags/                   # Airflow DAGs
├── dbt/                    # dbt project
└── logs/                   # Log files
```

### 2.2 File `.env`

```env
# ===== MinIO =====
MINIO_ROOT_USER=<MINIO_ADMIN_USER>
MINIO_ROOT_PASSWORD=<STRONG_RANDOM_PASSWORD>
MINIO_ENDPOINT=http://minio:9000

# ===== Airflow =====
AIRFLOW__CORE__EXECUTOR=LocalExecutor
AIRFLOW_DB_USER=<AIRFLOW_DB_USER>
AIRFLOW_DB_PASSWORD=<STRONG_RANDOM_PASSWORD>
AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://${AIRFLOW_DB_USER}:${AIRFLOW_DB_PASSWORD}@postgres-airflow:5432/airflow
AIRFLOW__CORE__FERNET_KEY=<GENERATED_FERNET_KEY>
AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/dags
AIRFLOW__CORE__LOAD_EXAMPLES=false

# ===== Spark on K8s =====
# Spark chạy trên K8s qua Spark Operator, không cần config ở đây
# Xem docs/03-processing/apache-spark/installation.md

# ===== AWS/S3 (cho Spark Iceberg) =====
AWS_ACCESS_KEY_ID=<S3_ACCESS_KEY_FROM_SECRET_MANAGER>
AWS_SECRET_ACCESS_KEY=<S3_SECRET_KEY_FROM_SECRET_MANAGER>
AWS_REGION=us-east-1

# ===== PostgreSQL (shared) =====
POSTGRES_USER=<POSTGRES_ADMIN_USER>
POSTGRES_PASSWORD=<STRONG_RANDOM_PASSWORD>
```

> Các giá trị trong `.env` là placeholder. Tạo credential ngẫu nhiên, lưu trong Secret/Vault và URL-encode password khi đưa vào connection string; không commit file `.env`.

### 2.3 Docker Compose (Core Services)

```yaml
# docker-compose.yml
version: '3.8'

x-common-env: &common-env
  MINIO_ENDPOINT: http://minio:9000
  MINIO_ACCESS_KEY: ${MINIO_ROOT_USER}
  MINIO_SECRET_KEY: ${MINIO_ROOT_PASSWORD}

services:
  # ========== STORAGE LAYER ==========
  minio:
    image: quay.io/minio/minio:RELEASE.2025-04-22T22-12-26Z
    container_name: hanas-minio
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"   # API
      - "9001:9001"   # Console
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
    volumes:
      - minio_data:/data
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 10s
      timeout: 5s
      retries: 5

  # MinIO bucket initialization
  minio-init:
    image: quay.io/minio/mc:<PINNED_TAG>
    container_name: hanas-minio-init
    depends_on:
      minio:
        condition: service_healthy
    entrypoint: |
      /bin/sh -c "
      mc alias set myminio http://minio:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD};
      mc mb --ignore-existing myminio/landing;
      mc mb --ignore-existing myminio/raw-vault;
      mc mb --ignore-existing myminio/business-vault;
      mc mb --ignore-existing myminio/information-mart;
      mc mb --ignore-existing myminio/warehouse;
      echo 'Buckets created successfully';
      "

  # ========== DATABASE (shared) ==========
  postgres:
    image: postgres:15
    container_name: hanas-postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./config/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ========== PROCESSING LAYER ==========
  # Cảnh báo: Spark chạy trên Kubernetes qua Spark Operator
  # Không deploy Spark standalone trong Docker Compose
  # Xem: docs/03-processing/apache-spark/installation.md
  #
  # Quickstart flow dùng Hive Metastore để quản lý Iceberg catalog:
  hive-metastore:
    image: apache/hive:4.0.0
    container_name: hanas-hive-metastore
    ports:
      - "9083:9083"
    environment:
      SERVICE_NAME: metastore
    volumes:
      - hive_data:/opt/hive/data
    depends_on:
      postgres:
        condition: service_healthy

  # ========== ORCHESTRATION ==========
  airflow-webserver:
    image: apache/airflow:2.8.1
    container_name: hanas-airflow-webserver
    command: webserver
    environment:
      <<: *common-env
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://${AIRFLOW_DB_USER}:${AIRFLOW_DB_PASSWORD}@postgres:5432/airflow
      AIRFLOW__CORE__LOAD_EXAMPLES: 'false'
    ports:
      - "8081:8080"
    volumes:
      - ./dags:/opt/airflow/dags
      - ./logs/airflow:/opt/airflow/logs
    depends_on:
      postgres:
        condition: service_healthy

  airflow-scheduler:
    image: apache/airflow:2.8.1
    container_name: hanas-airflow-scheduler
    command: scheduler
    environment:
      <<: *common-env
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://${AIRFLOW_DB_USER}:${AIRFLOW_DB_PASSWORD}@postgres:5432/airflow
    volumes:
      - ./dags:/opt/airflow/dags
      - ./logs/airflow:/opt/airflow/logs
    depends_on:
      postgres:
        condition: service_healthy

  # ========== QUERY ENGINE ==========
  dremio:
    image: dremio/dremio-oss:<PINNED_TAG>
    container_name: hanas-dremio
    ports:
      - "9047:9047"   # UI
      - "31010:31010" # ODBC/JDBC
      - "32010:32010" # Arrow Flight
    volumes:
      - dremio_data:/opt/dremio/data

volumes:
  minio_data:
  postgres_data:
  dremio_data:
  hive_data:
```

### 2.4 Khởi động

```bash
# Khởi động toàn bộ services
docker compose up -d

# Kiểm tra trạng thái
docker compose ps

# Xem log nếu có lỗi
docker compose logs -f <service-name>
```

### 2.5 Kiểm tra các service

| Service | URL | Credentials |
|---|---|---|
| **MinIO Console** | http://localhost:9001 | Credential từ `.env`/Secret |
| **Hive Metastore** | thrift://localhost:9083 | — |
| **Airflow UI** | http://localhost:8081 | Credential bootstrap theo Secret |
| **Dremio UI** | http://localhost:9047 | (setup lần đầu) |

> **Spark**: Chạy trên K8s cluster riêng qua Spark Operator. Xem [Cài đặt Spark](../03-processing/apache-spark/installation.md).

---

## 3. Chạy Data Flow Đầu Tiên

### 3.1 Chuẩn bị dữ liệu mẫu

```bash
# Tạo file CSV mẫu
cat > data/customers.csv << 'EOF'
customer_id,name,email,phone,city,created_at
C001,Nguyen Van A,a@example.com,0901234567,Ha Noi,2025-01-15
C002,Tran Thi B,b@example.com,0912345678,Ho Chi Minh,2025-02-20
C003,Le Van C,c@example.com,0923456789,Da Nang,2025-03-10
C004,Pham Thi D,d@example.com,0934567890,Hai Phong,2025-04-05
C005,Hoang Van E,e@example.com,0945678901,Can Tho,2025-05-22
EOF
```

### 3.2 Upload vào MinIO (Landing Zone)

```bash
# Dùng mc (MinIO Client)
docker exec hanas-minio-init mc cp /data/customers.csv myminio/landing/customers/

# Hoặc dùng AWS CLI compatible
aws --endpoint-url http://localhost:9000 \
    s3 cp data/customers.csv s3://landing/customers/customers.csv
```

### 3.3 Xử lý bằng Spark → Ghi Iceberg

```python
# spark_quickstart.py — Chạy trong Spark on K8s (SparkApplication)
import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp, md5, concat_ws, lit

# SparkSession khi chạy trên K8s đã được cấu hình qua sparkConf trong manifest
# Credentials được inject qua K8s Secrets → environment variables
spark = (SparkSession.builder
    .appName("quickstart-landing-to-vault")
    # ── Iceberg Extensions ──
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
    # ── Iceberg Catalog: demo (Hive Metastore) ──
    .config("spark.sql.catalog.demo", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.demo.type", "hive")
    .config("spark.sql.catalog.demo.uri", "thrift://hive-metastore:9083")
    .config("spark.sql.catalog.demo.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
    .config("spark.sql.catalog.demo.s3.endpoint", "http://minio:9000")
    .config("spark.sql.catalog.demo.warehouse", "s3a://data/warehouse/")
    .config("spark.sql.defaultCatalog", "demo")
    # ── S3/MinIO (credentials qua env vars từ K8s Secrets) ──
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000")
    .config("spark.hadoop.fs.s3a.access.key", os.environ.get("AWS_ACCESS_KEY_ID"))
    .config("spark.hadoop.fs.s3a.secret.key", os.environ.get("AWS_SECRET_ACCESS_KEY"))
    .config("spark.hadoop.fs.s3a.path.style.access", "true")
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
    .getOrCreate())

# 1. Đọc từ Landing
df_landing = spark.read.option("header", True).csv("s3a://landing/customers/")

# 2. Tạo Hub Customer (Raw Vault)
df_hub = (df_landing
    .select("customer_id")
    .withColumn("hub_customer_hk", md5(concat_ws("||", "customer_id")))
    .withColumn("load_dts", current_timestamp())
    .withColumn("record_source", lit("CSV_CUSTOMERS"))
    .dropDuplicates(["customer_id"]))

# 3. Ghi vào Iceberg table (catalog demo)
df_hub.writeTo("demo.raw_vault.hub_customer").createOrReplace()

# 4. Tạo Satellite Customer (Raw Vault)
df_sat = (df_landing
    .withColumn("hub_customer_hk", md5(concat_ws("||", "customer_id")))
    .withColumn("load_dts", current_timestamp())
    .withColumn("record_source", lit("CSV_CUSTOMERS"))
    .withColumn("hash_diff", md5(concat_ws("||", "name", "email", "phone", "city"))))

df_sat.writeTo("demo.raw_vault.sat_customer_details").createOrReplace()

print("Raw Vault tables created successfully!")
spark.sql("SELECT * FROM demo.raw_vault.hub_customer").show()
spark.stop()
```

### 3.4 Kết nối Dremio → Truy vấn

1. Mở Dremio UI: http://localhost:9047
2. Add Source → **Amazon S3** (hoặc **NAS**)
   - Endpoint: `minio:9000`
   - Access Key: `<MINIO_ACCESS_KEY_FROM_SECRET>`
   - Secret Key: `<MINIO_SECRET_KEY_FROM_SECRET>`
   - Connection Properties: `fs.s3a.path.style.access = true`
3. Browse đến `warehouse/raw_vault/`
4. Truy vấn:

```sql
SELECT h.customer_id, s.name, s.email, s.city
FROM raw_vault.hub_customer h
JOIN raw_vault.sat_customer_details s
  ON h.hub_customer_hk = s.hub_customer_hk
ORDER BY h.customer_id;
```

---

## 4. Bước Tiếp Theo

Sau khi quickstart thành công, tiếp tục với:
1. [End-to-End Tutorial](end-to-end-tutorial.md) — Luồng hoàn chỉnh với Airflow orchestration
2. [Integration Guides](README.md) — Chi tiết tích hợp từng cặp service
3. [Code Examples](README.md) — Templates và mẫu code production-ready
