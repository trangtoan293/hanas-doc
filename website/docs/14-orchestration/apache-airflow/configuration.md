# Apache Airflow - Cấu Hình

## 1. Airflow Connections

### 1.1 Kubernetes Connection

Dùng cho `SparkKubernetesOperator` để submit Spark jobs lên K8s cluster.

```
Connection Id: k8s_conn_id
Connection Type: Kubernetes
In-cluster: True (khi Airflow chạy trong K8s)
```

> **Lưu ý:** Khi Airflow chạy trong cùng K8s cluster với Spark, connection sử dụng in-cluster config. Không cần cấu hình `kubeconfig` riêng.

### 1.2 Dremio Connection (cho Backdate DAG)

```
Airflow Variables:
  dremio_host:         http://<DREMIO_HOST>
  dremio_username:     <DREMIO_SERVICE_USER>
  dremio_password:     <stored_securely>
  dremio_ssl_verify:   false
  dremio_space:        DATA_MART
```

---

## 2. Airflow Variables

### 2.1 Variables Bắt Buộc

| Variable | Default | Mô tả |
|---|---|---|
| `MAILEROO_API_KEY` | _(bắt buộc)_ | API key cho Maileroo email service |
| `SENDER_EMAIL` | _(bắt buộc)_ | Email sender đã verified trên Maileroo |

### 2.2 Variables Tùy Chọn

| Variable | Default | Mô tả |
|---|---|---|
| `DBT_ARTIFACTS_PREFIX` | `dbt-artifacts/<run_id>` | S3 prefix cho dbt artifacts |
| `DBT_ARTIFACTS_BUCKET` | `data` | S3 bucket chứa artifacts |
| `DATAHUB_ASSET_TAG_NAME` | `data platform demo` | Tag name cho assets trên DataHub |
| `AIRFLOW_BASE_URL` | `http://localhost:8080` | URL của Airflow UI (dùng cho email links) |
| `DEFAULT_NOTIFICATION_EMAIL` | _(trống)_ | Email mặc định nhận notifications |
| `DEMO_DATA_PIPELINE_E2E_INCREMENTAL_GROUPS` | _(JSON)_ | Override ETL groups: `[{"group_id": "...", "dbt_select": "..."}]` |

### 2.3 Variables cho Alerting

| Variable | Default | Mô tả |
|---|---|---|
| `IMMEDIATE_ALERT_CHANNELS` | `["slack"]` | Channels cho failure alerts |
| `RETRY_ALERT_CHANNELS` | `["slack"]` | Channels cho retry alerts |
| `NOTIFY_ON_TASK_SUCCESS` | `false` | Enable per-task success notifications |
| `ENABLE_PROGRESS_TRACKING` | `false` | Enable progress tracking |

---

## 3. Kubernetes YAML Templates

Tất cả DAGs sử dụng K8s YAML templates để định nghĩa `SparkApplication` CRDs. Templates nằm trong thư mục `k8s/` của mỗi DAG module.

### 3.1 `dbt-runner.yaml` — Chạy dbt models

```yaml
# Key configurations:
spec:
  type: Python
  mode: cluster
  image: "<REGISTRY>/<NAMESPACE>/dbt-spark-k8s-ktl:<PINNED_TAG>"
  mainApplicationFile: "local:///opt/spark/work-dir/dbt-project/dbt-project/dbt_runner.py"
  arguments:
    - "--use-subprocess"
    - "--dbt-command"
    - "ktl_dbt"           # Custom dbt command (Data Vault)
    - "--upload-artifacts" # Upload artifacts lên S3
    - "--s3-bucket"
    - "data"
    - "run"
    - "--target"
    - "dev"
    # Template variables:
    # {{ params.dbt_select }}   → --select argument
    # {{ params.full_refresh }} → --full-refresh flag
    # {{ params.artifacts_suffix }} → S3 prefix suffix
```

### 3.2 `dbt-test.yaml` — Chạy dbt tests

Tương tự `dbt-runner.yaml` nhưng sử dụng lệnh `dbt test` thay vì `dbt run`. Artifacts được lưu vào thư mục `/test` riêng biệt.

### 3.3 `dbt-logger.yaml` — Logging ETL metadata

Ghi ETL execution logs và SQL metrics vào bảng `LakeHouse.etladmin`. Sử dụng dbt run artifacts từ thư mục `/run`.

### 3.4 Cấu trúc Artifacts trên S3

```
s3://data/
└── dbt-artifacts/
    └── <dag_run.run_id>/
        ├── <group_id>/
        │   ├── run/           ← dbt run artifacts (manifest.json, run_results.json, catalog.json)
        │   └── test/          ← dbt test artifacts (manifest.json, run_results.json)
        └── vw_ref_eod/        ← EOD reference view artifacts
```

---

## 4. Spark Configuration

Cấu hình Spark được định nghĩa trong YAML templates. Các thiết lập chính:

### 4.1 Iceberg Catalogs

| Catalog | Type | Dùng cho |
|---|---|---|
| `demo` (default) | Hive | Raw Vault, Data Mart tables |
| `LakeHouse` | Hive | ETL admin logging tables (`etladmin`) |
| `spark_catalog` | Hive | Default Spark catalog |

### 4.2 Cấu hình Spark chính

```yaml
sparkConf:
  # Optimizations
  spark.sql.adaptive.enabled: "true"
  spark.sql.adaptive.coalescePartitions.enabled: "true"
  spark.serializer: "org.apache.spark.serializer.KryoSerializer"

  # Hive Metastore
  spark.hadoop.hive.metastore.uris: "thrift://<hive-metastore-host>:9083"
  spark.sql.warehouse.dir: "s3a://data/warehouse/"

  # S3/MinIO
  spark.hadoop.fs.s3a.endpoint: "http://<minio-host>"
  spark.hadoop.fs.s3a.path.style.access: "true"
  spark.hadoop.fs.s3a.impl: "org.apache.hadoop.fs.s3a.S3AFileSystem"

  # Iceberg Extensions
  spark.sql.extensions: "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"

  # Default catalog
  spark.sql.defaultCatalog: "demo"
```

### 4.3 Tài Nguyên Spark (Defaults)

| Resource | Driver | Executor |
|---|---|---|
| **Cores** | 3 | 3 |
| **Memory** | 5g | 4g |
| **Instances** | 1 | 2 |

> **Lưu ý:** Backfill/Backdate DAGs cho phép override Spark resources qua DAG params.

---

## 5. K8s Resources Required

### 5.1 ConfigMaps

| ConfigMap | Mục đích |
|---|---|
| `git-sync-config` | Cấu hình git-sync sidecar cho dbt project |
| `spark-k8s-config` | Cấu hình chung cho Spark jobs |

### 5.2 Secrets

| Secret | Mục đích |
|---|---|
| `spark-k8s-aws-credentials` | MinIO/S3 access keys |
| `spark-k8s-oracle-credentials` | Oracle DB credentials |
| `spark-k8s-mssql-credentials` | MSSQL DB credentials |

### 5.3 Git-Sync Sidecar

Mỗi Spark driver pod sử dụng `git-sync` init container để pull dbt project từ Git repository:

```yaml
initContainers:
  - name: git-sync
    image: registry.k8s.io/git-sync/git-sync:v4.1.0
    envFrom:
      - configMapRef:
          name: git-sync-config
    volumeMounts:
      - name: dbt-project
        mountPath: /opt/spark/work-dir
```
