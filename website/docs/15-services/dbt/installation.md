# DBT - Cài Đặt & Triển Khai

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
# Clone DBT project
git clone <repo-url> DBT-project
cd DBT-project

# Install dependencies với uv
uv sync

# Activate virtual environment
source .venv/bin/activate
```

### Sử dụng pip

```bash
# Install core dependencies
pip install DBT-spark==1.9.0
pip install DBT-metricflow[DBT-databricks,DBT-spark]==0.10.1

# Cài đặt DBT packages
export DBT_PROFILES_DIR=$(pwd)
DBT deps
```

### Cấu Hình Environment

```bash
# Bắt buộc: Schema name cho DBT target
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
│       ├── git-sync init container  → Pull DBT-project từ Git
│       ├── dbt_runner.py            → Entry point
│       └── Spark Session            → Execute DBT models
├── Hive Metastore Service
└── MinIO Service
```

### Deploy Flow

1. **Git-sync init container** pull latest DBT project code
2. **SparkOperator** khởi tạo Spark Application với DBT project
3. **dbt_runner.py** chạy DBT commands (deps → run/test → docs → upload artifacts)
4. **Artifacts** (manifest.json, run_results.json, catalog.json) upload lên S3

### Sử Dụng dbt_runner.py

```bash
# Chạy với subprocess mode (recommended cho Kubernetes)
python dbt_runner.py \
  --use-subprocess \
  --DBT-command ktl_dbt \
  run --target dev --select integration.*

# Chạy với artifact upload
python dbt_runner.py \
  --use-subprocess \
  --DBT-command ktl_dbt \
  --upload-artifacts \
  --s3-bucket data \
  --s3-prefix DBT/artifacts/$(date +%Y-%m-%d) \
  --s3-endpoint-url http://minio:9000 \
  run --target dev

# Chạy với Lakehouse logging
python dbt_runner.py \
  --use-subprocess \
  --DBT-command ktl_dbt \
  --log-to-lakehouse \
  --job-log-table LakeHouse.etladmin.job_run_logs \
  --sql-log-table LakeHouse.etladmin.job_sql_logs \
  --source-system DBT \
  --source-table integration.raw_vault \
  run --target dev
```

## Kiểm Tra Sau Cài Đặt

### Health Check

```bash
# Set profiles directory
export DBT_PROFILES_DIR=$(pwd)

# Kiểm tra connection
DBT debug

# Install packages
DBT deps

# Compile models (không chạy)
python dbt_compile.py --select hub_customer

# Test với seed data
python dbt_seed.py
```

### Kết Quả Mong Đợi

```
✅ DBT debug:
  - profiles.yml found
  - dbt_project.yml found
  - Connection test: OK (Spark session)

✅ DBT deps:
  - DBT-labs/dbt_utils@1.3.0
  - DBT-labs/spark_utils@0.3.0
  - ktl_autovault (local)

✅ DBT compile:
  - Compiled SQL cho selected models
  - manifest.json generated tại /tmp/dbt_target/
```
