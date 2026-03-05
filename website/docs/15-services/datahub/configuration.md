# DataHub - Cấu Hình

## Cấu Hình Cơ Bản

### Environment Variables — GMS

| Biến | Mô tả | Giá trị mặc định | Khuyến nghị |
|---|---|---|---|
| `EBEAN_DATASOURCE_URL` | JDBC URL cho MySQL/PostgreSQL | — | `jdbc:mysql://mysql:3306/datahub` |
| `EBEAN_DATASOURCE_USERNAME` | Database username | `datahub` | Đổi cho production |
| `EBEAN_DATASOURCE_PASSWORD` | Database password | `datahub` | Dùng Kubernetes Secret |
| `KAFKA_BOOTSTRAP_SERVER` | Kafka broker address | `localhost:9092` | `kafka:9092` trong K8s |
| `ELASTICSEARCH_HOST` | Elasticsearch host | `localhost` | `elasticsearch-master` trong K8s |
| `ELASTICSEARCH_PORT` | Elasticsearch port | `9200` | Giữ nguyên |
| `ENTITY_SERVICE_IMPL` | Storage backend | `ebean` | `ebean` (MySQL) hoặc `cassandra` |

### Environment Variables — Frontend

| Biến | Mô tả | Giá trị mặc định | Khuyến nghị |
|---|---|---|---|
| `DATAHUB_GMS_HOST` | GMS hostname | `localhost` | `datahub-gms` trong K8s |
| `DATAHUB_GMS_PORT` | GMS port | `8080` | Giữ nguyên |
| `DATAHUB_SECRET` | Session signing secret | `YouKnowNothing` | **Đổi ngay** cho production |
| `DATAHUB_APP_VERSION` | Version hiển thị trên UI | `1.0` | Theo version deploy |
| `DATAHUB_PLAY_MEM_BUFFER_SIZE` | Max upload buffer | `10MB` | Tăng nếu cần upload lớn |

---

## Cấu Hình Ingestion — Hanas Platform

### Recipe: Apache Iceberg (S3/MinIO)

```yaml
# iceberg-ingestion.yaml
source:
  type: iceberg
  config:
    catalog:
      name: demo
      type: hive
      config:
        uri: thrift://hive-metastore:9083

    platform_instance: "hanas"
    env: "PROD"

    # Profiling (optional — tốn resources)
    profiling:
      enabled: false

sink:
  type: datahub-rest
  config:
    server: "http://datahub-gms:8080"
    # token: "<PERSONAL_ACCESS_TOKEN>"   # Bật khi có authentication
```

### Recipe: dbt Core

```yaml
# dbt-ingestion.yaml
source:
  type: dbt
  config:
    manifest_path: "s3://data/dbt-artifacts/latest/manifest.json"
    catalog_path: "s3://data/dbt-artifacts/latest/catalog.json"
    sources_path: "s3://data/dbt-artifacts/latest/sources.json"
    run_results_paths:
      - "s3://data/dbt-artifacts/latest/run_results.json"

    # Liên kết dataset platform
    target_platform: "iceberg"
    target_platform_instance: "hanas"

    # S3 credentials (qua env vars)
    aws_connection:
      aws_access_key_id: "${MINIO_ACCESS_KEY}"
      aws_secret_access_key: "${MINIO_SECRET_KEY}"
      aws_endpoint_url: "http://minio:9000"

sink:
  type: datahub-rest
  config:
    server: "http://datahub-gms:8080"
```

### Recipe: Apache Kafka

```yaml
# kafka-ingestion.yaml
source:
  type: kafka
  config:
    connection:
      bootstrap: "kafka:9092"
      schema_registry_url: "http://schema-registry:8081"  # Nếu có

    platform_instance: "hanas"
    env: "PROD"

    # Topic filter
    topic_patterns:
      allow:
        - ".*"
      deny:
        - "_.*"              # Bỏ internal topics
        - "__.*"

sink:
  type: datahub-rest
  config:
    server: "http://datahub-gms:8080"
```

### Recipe: Apache Airflow

```yaml
# airflow-ingestion.yaml
source:
  type: airflow
  config:
    base_url: "http://airflow-webserver:8080"
    connection:
      host: "http://airflow-webserver:8080"
      login: "${AIRFLOW_USERNAME}"
      password: "${AIRFLOW_PASSWORD}"

    platform_instance: "hanas"

sink:
  type: datahub-rest
  config:
    server: "http://datahub-gms:8080"
```

### Recipe: Dremio

```yaml
# dremio-ingestion.yaml
source:
  type: dremio
  config:
    hostname: "dremio:9047"
    port: 9047
    username: "${DREMIO_USERNAME}"
    password: "${DREMIO_PASSWORD}"
    tls: false

    platform_instance: "hanas"
    env: "PROD"

    # Source filter
    source_criteria:
      include_sources:
        - "hanas-lakehouse"       # MinIO source trên Dremio
      exclude_sources:
        - "Samples"               # Bỏ sample datasets

sink:
  type: datahub-rest
  config:
    server: "http://datahub-gms:8080"
```

### Chạy Ingestion

```bash
# Cài plugin cần thiết
pip install 'acryldata-datahub[datahub-rest,iceberg,dbt,kafka,airflow,dremio]'

# Chạy recipe
datahub ingest -c iceberg-ingestion.yaml
datahub ingest -c dbt-ingestion.yaml
datahub ingest -c kafka-ingestion.yaml
datahub ingest -c dremio-ingestion.yaml

# Xem trạng thái ingestion
datahub ingest list-runs
```

---

## Cấu Hình ktl_airflow_utils — Push-based Metadata

Hanas Platform sử dụng package **`ktl_airflow_utils`** để push metadata trực tiếp lên DataHub, thay vì pull-based ingestion.

### Airflow Variables — DataHub

| Variable | Default | Mô tả |
|---|---|---|
| `DATAHUB_GMS_HOST` | — (bắt buộc) | DataHub GMS URL (`http://datahub-gms:8080`) |
| `DATAHUB_TOKEN` | `""` | DataHub bearer token (PAT) |
| `DATAHUB_ENV` | `PROD` | Environment cho URNs (`PROD`, `DEV`, `STAGING`) |
| `DATAHUB_PLATFORM_INSTANCE` | `demo` | dbt platform instance name |
| `DATAHUB_ICEBERG_PLATFORM_INSTANCE` | `LakeHouse` | Iceberg platform instance name |
| `DATAHUB_ASSET_TAG_NAME` | `data platform demo` | Tag mặc định cho ingested assets |
| `DATAHUB_INCLUDE_DATABASE_IN_NAME` | `false` | Include database trong Iceberg dataset name |
| `DATAHUB_EMIT_BOTH_NAME_VARIANTS` | `false` | Emit cả 2 variant (có/không database name) |
| `DBT_ARTIFACTS_BUCKET` | `data` | S3 bucket chứa dbt artifacts |
| `DBT_ARTIFACTS_PREFIX` | `dbt-artifacts/{{ dag_run.run_id }}` | S3 prefix cho artifacts |

### Airflow Variables — AWS/S3

| Variable | Mô tả |
|---|---|
| `AWS_ENDPOINT_URL` | S3-compatible endpoint (MinIO: `http://minio:9000`) |
| `AWS_DEFAULT_REGION` | AWS region |
| `AWS_ACCESS_KEY_ID` | S3 access key |
| `AWS_SECRET_ACCESS_KEY` | S3 secret key |
| `AWS_SESSION_TOKEN` | AWS session token (optional) |
| `S3_INSECURE_SKIP_VERIFY` | Skip SSL verify cho MinIO (default: `false`) |

### Cấu Hình TaskGroup Trong DAG

```python
from package.ktl_airflow_utils.taskgroups import (
    create_unified_publish_to_datahub_taskgroup,
)

with DAG(...) as dag:
    # ETL taskgroup (dbt run + test)
    etl = create_dbt_etl_taskgroup("raw_vault_etl", dag=dag, ...)

    # Publish metadata lên DataHub (4 bước tuần tự)
    publish_datahub = create_unified_publish_to_datahub_taskgroup(
        group_id="publish_datahub",
        run_prefix_value="dbt-artifacts/run",        # S3 prefix cho dbt run artifacts
        test_prefix_value="dbt-artifacts/test",       # S3 prefix cho dbt test artifacts
        run_artifacts_suffix="raw_vault/run",         # Suffix cho run folder
        test_artifacts_suffix="raw_vault/test",       # Suffix cho test folder
        dag=dag,
    )

    etl >> publish_datahub
```

> **S3 Artifacts Structure**: TaskGroup tìm artifacts tại `s3://$DBT_ARTIFACTS_BUCKET/$prefix/manifest.json`, `run_results.json`, và `catalog.json`.

### Cấu Hình BI Lineage DAG

Ngoài ETL metadata, package hỗ trợ emit lineage cho lớp BI (Federation → Consumption):

```python
from package.ktl_airflow_utils.datahub.emit_lineage import (
    emit_dremio_lineage,
    emit_superset_dataset_lineage,
)

# Task 1: Dremio View → Iceberg Table (table + column level)
emit_dremio = PythonVirtualenvOperator(
    task_id="emit_dremio_lineage",
    python_callable=emit_dremio_lineage,
    op_kwargs={
        "datahub_gms_host": get_var("DATAHUB_GMS_HOST"),
        "datahub_token": get_var("DATAHUB_TOKEN", ""),
        "dremio_schema_pattern_allow": "^DATA_MART.*,^MDM.*,^ETLADMIN.*",
        "source_to_iceberg_platform_instance": '{"LakeHouse": "demo"}',
        "dremio_hostname": get_var("DREMIO_HOST"),
        "dremio_port": get_var("DREMIO_PORT", "9047"),
        "dremio_user": get_var("DREMIO_USER"),
        "dremio_password": get_var("DREMIO_PASSWORD"),
        "dremio_platform_urn_prefix": "dremio",
    },
    requirements=["requests"],
)

# Task 2: Superset Dataset → Dremio View (column level)
emit_superset = PythonVirtualenvOperator(
    task_id="emit_superset_lineage",
    python_callable=emit_superset_dataset_lineage,
    op_kwargs={
        "datahub_gms_host": get_var("DATAHUB_GMS_HOST"),
        "datahub_token": get_var("DATAHUB_TOKEN", ""),
        "superset_host": get_var("SUPERSET_HOST"),
        "superset_user": get_var("SUPERSET_USER"),
        "superset_password": get_var("SUPERSET_PASSWORD"),
        "dremio_platform_urn_prefix": "dremio",
    },
    requirements=["requests"],
)

emit_dremio >> emit_superset
```

### Airflow Variables — BI Lineage

| Variable | Mô tả |
|---|---|
| `DREMIO_HOST` | Dremio server hostname |
| `DREMIO_PORT` | Dremio port (default: `9047`) |
| `DREMIO_USER` | Dremio username |
| `DREMIO_PASSWORD` | Dremio password |
| `SUPERSET_HOST` | Superset API URL |
| `SUPERSET_USER` | Superset username |
| `SUPERSET_PASSWORD` | Superset password |

---

## Cấu Hình Authentication

### Native Authentication (Default)

Mặc định DataHub sử dụng native credentials:

- **Username**: `datahub`
- **Password**: `datahub`

> ⚠️ **Đổi ngay** cho production! Vào Settings → Users & Groups → Edit User.

### OIDC Single Sign-On (Khuyến Nghị Cho Production)

```bash
# Environment variables cho datahub-frontend
AUTH_OIDC_ENABLED=true
AUTH_OIDC_CLIENT_ID=<your-client-id>
AUTH_OIDC_CLIENT_SECRET=<your-client-secret>
AUTH_OIDC_DISCOVERY_URI=https://<your-idp>/.well-known/openid-configuration
AUTH_OIDC_BASE_URL=https://<your-datahub-url>

# Optional
AUTH_OIDC_USER_NAME_CLAIM=preferred_username     # Claim cho username
AUTH_OIDC_USER_NAME_CLAIM_REGEX=(.*)             # Regex extract
AUTH_OIDC_SCOPE="openid profile email"           # Scopes requested
```

Kubernetes values.yaml:

```yaml
datahub-frontend:
  extraEnvs:
    - name: AUTH_OIDC_ENABLED
      value: "true"
    - name: AUTH_OIDC_CLIENT_ID
      value: "<your-client-id>"
    - name: AUTH_OIDC_CLIENT_SECRET
      valueFrom:
        secretKeyRef:
          name: datahub-oidc-secret
          key: client-secret
    - name: AUTH_OIDC_DISCOVERY_URI
      value: "https://<your-idp>/.well-known/openid-configuration"
    - name: AUTH_OIDC_BASE_URL
      value: "https://datahub.hanas.local"
```

### Personal Access Tokens (API)

Dùng cho programmatic access (CLI, SDK, Airflow):

1. Login DataHub UI → **Settings** → **Access Tokens**
2. Click **Generate New Token**
3. Chọn expiration, scope
4. Copy token và lưu vào Kubernetes Secret / Vault

```bash
# Sử dụng token
datahub --token "<PAT_TOKEN>" get --urn "urn:li:dataset:..."

# Hoặc qua env var
export DATAHUB_GMS_TOKEN="<PAT_TOKEN>"
datahub get --urn "urn:li:dataset:..."
```

---

## Cấu Hình Nâng Cao

### Elasticsearch Tuning

```yaml
# Trong prerequisites-values.yaml
elasticsearch:
  esJavaOpts: "-Xms2g -Xmx2g"              # Heap size = 50% RAM
  resources:
    requests:
      memory: "4Gi"
    limits:
      memory: "4Gi"

  esConfig:
    elasticsearch.yml: |
      indices.query.bool.max_clause_count: 4096
      search.max_buckets: 65535
```

### Kafka Tuning

```yaml
# Tăng retention cho MCE/MCL topics
kafka:
  config:
    log.retention.hours: 168                # 7 ngày
    log.retention.bytes: 5368709120         # 5 GB per partition
    num.partitions: 3                       # Default partitions
```

### GMS Performance

```yaml
datahub-gms:
  extraEnvs:
    - name: JAVA_OPTS
      value: "-Xms2g -Xmx4g"
    - name: METADATA_SERVICE_AUTH_ENABLED
      value: "true"                        # Bật API authentication
    - name: UI_INGESTION_ENABLED
      value: "true"                        # Cho phép tạo ingestion từ UI
```

---

## Tham Số Quan Trọng

| Biến / Config | Mô tả | Default | Khuyến nghị |
|---|---|---|---|
| `DATAHUB_SECRET` | Session signing key | `YouKnowNothing` | **Đổi ngay**, random string ≥ 32 chars |
| `METADATA_SERVICE_AUTH_ENABLED` | Bật auth cho GMS API | `false` | `true` cho production |
| `UI_INGESTION_ENABLED` | Cho phép manage ingestion từ UI | `true` | `true` |
| `ELASTICSEARCH_HEAP` | ES JVM heap | `512m` | `2g`–`4g` cho production |
| `KAFKA_BOOTSTRAP_SERVER` | Kafka broker | `localhost:9092` | Internal K8s service name |
| `AUTH_OIDC_ENABLED` | Bật OIDC SSO | `false` | `true` khi có IdP |
| `DATAHUB_ANALYTICS_ENABLED` | Thu thập usage analytics | `true` | `true` (cho recommendations) |
