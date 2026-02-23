# dbt - Cài Đặt & Triển Khai

## Yêu Cầu Hệ Thống

### Runtime Requirements

| Component | Yêu cầu |
|---|---|
| **Python** | >= 3.11 |
| **Apache Spark** | 3.x với Iceberg extensions |
| **Hive Metastore** | 3.x (Thrift protocol) |
| **S3/MinIO** | Object storage cho warehouse data |

### Infrastructure Dependencies

- **Hive Metastore**: `thrift://<host>:9083` - Quản lý metadata catalog
- **MinIO/S3**: `http://<host>` - Lưu trữ Iceberg data files
- **Spark Cluster**: Local mode hoặc Standalone cluster

## Cài Đặt Local Development

### Sử dụng uv (Recommended)

```bash
# Clone dbt project
git clone <repo-url> dbt-project
cd dbt-project

# Install dependencies với uv
uv sync

# Activate virtual environment
source .venv/bin/activate
```

### Sử dụng pip

```bash
# Install core dependencies
pip install dbt-spark==1.9.0
pip install dbt-metricflow[dbt-databricks,dbt-spark]==0.10.1

# Cài đặt dbt packages
export DBT_PROFILES_DIR=$(pwd)
dbt deps
```

### Cấu Hình Environment

```bash
# Bắt buộc: Schema name cho dbt target
export SCHEMA_NAME=integration_demo

# S3/MinIO credentials
export AWS_ACCESS_KEY_ID=<access_key>
export AWS_SECRET_ACCESS_KEY=<secret_key>

# Optional: Override target/log paths
export DBT_TARGET_PATH=/tmp/dbt_target
export DBT_LOG_PATH=/tmp/dbt_logs
```

## Triển Khai Trên Kubernetes

### Deployment Architecture

```
Kubernetes Cluster
├── SparkOperator
│   └── Spark Application (driver + executors)
│       ├── git-sync init container  → Pull dbt-project từ Git
│       ├── dbt_runner.py            → Entry point
│       └── Spark Session            → Execute dbt models
├── Hive Metastore Service
└── MinIO Service
```

### Deploy Flow

1. **Git-sync init container** pull latest dbt project code
2. **SparkOperator** khởi tạo Spark Application với dbt project
3. **dbt_runner.py** chạy dbt commands (deps → run/test → docs → upload artifacts)
4. **Artifacts** (manifest.json, run_results.json, catalog.json) upload lên S3

### Sử Dụng dbt_runner.py

```bash
# Chạy với subprocess mode (recommended cho Kubernetes)
python dbt_runner.py \
  --use-subprocess \
  --dbt-command ktl_dbt \
  run --target dev --select integration.*

# Chạy với artifact upload
python dbt_runner.py \
  --use-subprocess \
  --dbt-command ktl_dbt \
  --upload-artifacts \
  --s3-bucket data \
  --s3-prefix dbt/artifacts/$(date +%Y-%m-%d) \
  --s3-endpoint-url http://minio:9000 \
  run --target dev

# Chạy với Lakehouse logging
python dbt_runner.py \
  --use-subprocess \
  --dbt-command ktl_dbt \
  --log-to-lakehouse \
  --job-log-table LakeHouse.etladmin.job_run_logs \
  --sql-log-table LakeHouse.etladmin.job_sql_logs \
  --source-system dbt \
  --source-table integration.raw_vault \
  run --target dev
```

## Kiểm Tra Sau Cài Đặt

### Health Check

```bash
# Set profiles directory
export DBT_PROFILES_DIR=$(pwd)

# Kiểm tra connection
dbt debug

# Install packages
dbt deps

# Compile models (không chạy)
python dbt_compile.py --select hub_customer

# Test với seed data
python dbt_seed.py
```

### Kết Quả Mong Đợi

```
✅ dbt debug:
  - profiles.yml found
  - dbt_project.yml found
  - Connection test: OK (Spark session)

✅ dbt deps:
  - dbt-labs/dbt_utils@1.3.0
  - dbt-labs/spark_utils@0.3.0
  - ktl_autovault (local)

✅ dbt compile:
  - Compiled SQL cho selected models
  - manifest.json generated tại /tmp/dbt_target/
```
