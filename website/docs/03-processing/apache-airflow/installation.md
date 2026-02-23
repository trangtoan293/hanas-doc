# Apache Airflow - Cài Đặt & Triển Khai

## 1. Yêu Cầu Hệ Thống

### 1.1 Kubernetes Cluster

| Component | Minimum | Recommended |
|---|---|---|
| Airflow Scheduler | 2 CPU, 4GB RAM | 4 CPU, 8GB RAM |
| Airflow Webserver | 1 CPU, 2GB RAM | 2 CPU, 4GB RAM |
| Metadata DB (PostgreSQL) | 1 CPU, 2GB RAM | 2 CPU, 4GB RAM |
| Spark Driver (per job) | 3 CPU, 5GB RAM | 3 CPU, 5GB RAM |
| Spark Executor (per instance) | 3 CPU, 4GB RAM | 3 CPU, 4GB RAM |

### 1.2 External Services

| Service | Vai trò |
|---|---|
| **MinIO** | Object storage (S3-compatible) cho Iceberg warehouse và dbt artifacts |
| **Hive Metastore** | Iceberg catalog management |
| **DataHub** | Metadata platform (nhận dbt lineage, Iceberg schemas) |
| **Spark Operator** | K8s operator để quản lý SparkApplication CRDs |

---

## 2. Cài Đặt Trên Kubernetes

### 2.1 Prerequisites

```bash
# Spark Operator (quản lý SparkApplication CRDs)
helm install spark-operator spark-operator/spark-operator \
  --namespace spark-operator \
  --set webhook.enable=true

# Namespace cho Spark jobs
kubectl create namespace spark-jobs

# Service Account cho Spark
kubectl create serviceaccount spark -n spark-jobs
kubectl create clusterrolebinding spark-role \
  --clusterrole=edit \
  --serviceaccount=spark-jobs:spark \
  --namespace=spark-jobs
```

### 2.2 K8s Secrets & ConfigMaps

```bash
# AWS/MinIO credentials cho Spark
kubectl create secret generic spark-k8s-aws-credentials \
  -n spark-jobs \
  --from-literal=AWS_ACCESS_KEY_ID=<access_key> \
  --from-literal=AWS_SECRET_ACCESS_KEY=<secret_key>

# Oracle credentials
kubectl create secret generic spark-k8s-oracle-credentials \
  -n spark-jobs \
  --from-literal=ORACLE_USER=<user> \
  --from-literal=ORACLE_PASSWORD=<password> \
  --from-literal=ORACLE_HOST=<host>

# MSSQL credentials
kubectl create secret generic spark-k8s-mssql-credentials \
  -n spark-jobs \
  --from-literal=MSSQL_USER=<user> \
  --from-literal=MSSQL_PASSWORD=<password>

# Git-sync config (cho dbt project sync)
kubectl create configmap git-sync-config \
  -n spark-jobs \
  --from-literal=GITSYNC_REPO=<dbt-git-repo-url> \
  --from-literal=GITSYNC_ROOT=/opt/spark/work-dir \
  --from-literal=GITSYNC_ONE_TIME=true

# Spark general config
kubectl create configmap spark-k8s-config \
  -n spark-jobs \
  --from-literal=SCHEMA_NAME=integration
```

### 2.3 Airflow Deployment

```bash
# Helm chart (Community hoặc Official)
helm repo add apache-airflow https://airflow.apache.org
helm install airflow apache-airflow/airflow \
  --namespace airflow \
  --set executor=KubernetesExecutor \
  --set config.core.dags_folder=/opt/airflow/dags \
  --values custom-values.yaml
```

---

## 3. Cấu Trúc DAGs Repository

```
airfow/dags/
├── .airflowignore                  # Exclude patterns
├── airflow_team_best_practice_guide.md
│
├── raw_vault/                      # E2E data pipelines
│   ├── demo_data_pipeline_e2e_init.py
│   ├── demo_data_pipeline_e2e_incremental.py
│   ├── demo_data_pipeline_e2e_test_incremental.py
│   ├── demo_mdm_pipeline_e2e_init.py
│   ├── demo_mdm_pipeline_e2e_incremental.py
│   ├── dbt_adhoc_etl.py
│   ├── k8s/                        # K8s YAML templates
│   │   ├── dbt-runner.yaml
│   │   ├── dbt-runner-eod-vars.yaml
│   │   ├── dbt-test.yaml
│   │   ├── dbt-logger.yaml
│   │   └── mdm-iceberg-to-oracle.yaml
│   └── taskgroups/                 # Reusable TaskGroup modules
│       ├── dbt_etl_jobs_taskgroup.py
│       ├── dbt_etl_test_jobs_taskgroup.py
│       └── publish_to_datahub_taskgroup.py
│
├── backfill/                       # Data correction DAGs
│   ├── backfill_etl_dag.py
│   ├── backfill_merge_dag.py
│   ├── backfill_rebuild_dag.py
│   ├── config/backfill_config.yaml
│   ├── k8s/                        # Backfill-specific YAML templates
│   ├── sql/                        # SQL scripts
│   └── utils/
│
├── backdate/                       # Backdate processing DAGs
│   ├── backdate_etl_dag.py
│   ├── config/backdate_config.yaml
│   ├── k8s/
│   ├── sql/
│   └── utils/dremio_client.py
│
├── maintenance/                    # Maintenance DAGs
│   └── iceberg_maintenance.py
│
├── datahub_ingestion/              # DataHub metadata
│   └── emit_bi_lineage_dag.py
│
├── utils/                          # Shared utility modules
│   ├── callbacks.py                # Task lifecycle callbacks
│   ├── datahub_publisher.py        # DataHub API client
│   ├── dbt_catalog.py              # dbt catalog processing
│   ├── dbt_setup.py                # dbt project setup
│   ├── email_utils.py              # Email helpers
│   ├── iceberg_table_manager.py    # Iceberg operations
│   ├── maileroo_utils.py           # Maileroo API client
│   ├── column_lineage_publisher.py # Column-level lineage
│   └── logging_config.py
│
├── taskgroups/                     # Shared TaskGroups
│   └── maileroo_groups.py          # Email notification TaskGroup
│
└── package/                        # Published utility package
    └── ktl_airflow_utils/
        ├── airflow_vars.py
        ├── maileroo.py
        ├── spark/
        ├── taskgroups/
        └── datahub/
```

---

## 4. Kiểm Tra Sau Cài Đặt

### 4.1 Verify Airflow

```bash
# Kiểm tra Airflow services
kubectl get pods -n airflow

# Kiểm tra DAGs loaded
kubectl exec -n airflow <scheduler-pod> -- airflow dags list

# Kiểm tra connections
kubectl exec -n airflow <scheduler-pod> -- airflow connections list
```

### 4.2 Verify Spark Operator

```bash
# Kiểm tra Spark Operator
kubectl get pods -n spark-operator

# Test submit một SparkApplication
kubectl apply -f test-spark-app.yaml -n spark-jobs
kubectl get sparkapplication -n spark-jobs
```

### 4.3 Verify Connectivity

```bash
# Kiểm tra kết nối Hive Metastore
kubectl exec -n spark-jobs <test-pod> -- \
  python -c "from pyhive import hive; conn = hive.connect('<metastore-host>', 10000)"

# Kiểm tra kết nối MinIO
kubectl exec -n spark-jobs <test-pod> -- \
  aws s3 ls --endpoint-url http://<minio-host> s3://data/
```
