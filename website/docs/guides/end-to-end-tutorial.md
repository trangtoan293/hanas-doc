# End-to-End Tutorial: Xây Dựng Luồng Dữ Liệu Hoàn Chỉnh

## Mục Tiêu

Hướng dẫn từng bước xây dựng luồng dữ liệu production-grade:

```
Oracle DB ──▶ NiFi ──▶ MinIO (Landing) ──▶ Airflow + Spark ──▶ Iceberg (Data Vault) ──▶ Dremio ──▶ BI
                                                  │
                                                  ▼
                                             dbt (Models)
```

Sau tutorial này, team sẽ nắm được cách:
- Thu thập dữ liệu từ RDBMS bằng NiFi
- Lưu trữ vào MinIO theo chuẩn landing zone
- Xử lý và transform bằng Airflow + Spark
- Build Data Vault models bằng dbt
- Phục vụ BI qua Dremio

---

## Phần 1: Chuẩn Bị Nguồn Dữ Liệu

### 1.1 Mô hình dữ liệu nguồn (Oracle mẫu)

```sql
-- Bảng khách hàng
CREATE TABLE src_customers (
    customer_id    VARCHAR2(20) PRIMARY KEY,
    full_name      VARCHAR2(100),
    email          VARCHAR2(100),
    phone          VARCHAR2(20),
    city           VARCHAR2(50),
    segment        VARCHAR2(30),
    created_at     TIMESTAMP DEFAULT SYSTIMESTAMP,
    updated_at     TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Bảng tài khoản
CREATE TABLE src_accounts (
    account_id     VARCHAR2(20) PRIMARY KEY,
    customer_id    VARCHAR2(20) REFERENCES src_customers(customer_id),
    account_type   VARCHAR2(30),
    currency       VARCHAR2(3) DEFAULT 'VND',
    balance        NUMBER(18,2),
    status         VARCHAR2(20),
    opened_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    updated_at     TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Bảng giao dịch
CREATE TABLE src_transactions (
    transaction_id VARCHAR2(30) PRIMARY KEY,
    account_id     VARCHAR2(20) REFERENCES src_accounts(account_id),
    txn_type       VARCHAR2(20),
    amount         NUMBER(18,2),
    description    VARCHAR2(200),
    txn_date       TIMESTAMP DEFAULT SYSTIMESTAMP
);
```

### 1.2 Quy hoạch vùng dữ liệu trên MinIO

```
MinIO Buckets:
├── landing/                    # Dữ liệu thô từ nguồn
│   ├── oracle/
│   │   ├── src_customers/      # Partitioned by load_date
│   │   ├── src_accounts/
│   │   └── src_transactions/
│   └── csv/                    # File uploads
│
├── warehouse/                  # Iceberg tables
│   ├── raw_vault/
│   │   ├── hub_customer/
│   │   ├── hub_account/
│   │   ├── lnk_customer_account/
│   │   ├── sat_customer_details/
│   │   ├── sat_account_details/
│   │   └── sat_transaction/
│   ├── business_vault/
│   │   ├── pit_customer/
│   │   └── brdg_customer_account/
│   └── information_mart/
│       ├── dim_customer/
│       ├── dim_account/
│       └── fct_transactions/
```

---

## Phần 2: Thu Thập Dữ Liệu Bằng NiFi

### 2.1 Thiết kế Flow NiFi

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────┐
│  QueryDatabase   │────▶│ ConvertAvroToJSON │────▶│ PutS3Object  │
│  Table           │     │ (hoặc giữ Avro)  │     │ (→ MinIO)    │
└─────────────────┘     └──────────────────┘     └──────────────┘
        │                                               │
        ▼                                               ▼
  Oracle JDBC                                   s3://landing/oracle/
  Connection Pool                               src_customers/
                                                load_date=2024-01-15/
```

### 2.2 Cấu hình JDBC Connection Pool

```properties
# Controller Service: DBCPConnectionPool
Database Connection URL: jdbc:oracle:thin:@//oracle-host:1521/ORCL
Database Driver Class Name: oracle.jdbc.OracleDriver
Database Driver Location(s): /opt/nifi/drivers/ojdbc11.jar
Database User: etl_user
Password: ********
Max Wait Time: 30 sec
Max Total Connections: 10
Validation Query: SELECT 1 FROM DUAL
```

### 2.3 Cấu hình QueryDatabaseTable Processor

```properties
# Processor: QueryDatabaseTable
Database Connection Pooling Service: Oracle-JDBC-Pool
Database Type: Oracle
Table Name: SRC_CUSTOMERS
Columns to Return: customer_id, full_name, email, phone, city, segment, created_at, updated_at
Maximum-value Columns: updated_at                    # ← Incremental load
Max Rows Per Flow File: 10000
Output Format: Avro
```

> **Best Practice**: Luôn dùng `Maximum-value Columns` (thường là `updated_at`) để chỉ lấy dữ liệu mới/thay đổi. Tránh full scan mỗi lần chạy.

### 2.4 Cấu hình PutS3Object (ghi vào MinIO)

```properties
# Processor: PutS3Object
Object Key: landing/oracle/src_customers/load_date=${now():format('yyyy-MM-dd')}/customers_${UUID()}.avro
Bucket: landing
Access Key ID: admin
Secret Access Key: minio_secret_2024
Endpoint Override URL: http://minio:9000
Signer Override: AWSS3V4SignerType
Region: us-east-1
```

> **Best Practice**: 
> - Partition theo `load_date` để dễ quản lý và truy vấn
> - Dùng UUID trong tên file để tránh overwrite
> - Dùng Avro format để giữ schema

### 2.5 Lặp lại cho các bảng khác

Duplicate flow cho `src_accounts` và `src_transactions`, chỉ thay đổi:
- Table Name
- Object Key (đường dẫn trên MinIO)
- Maximum-value Columns

### 2.6 Schedule

```properties
# NiFi Scheduling
Run Schedule: 0 */30 * * * ?    # Chạy mỗi 30 phút
# Hoặc: 0 0 1 * * ?             # Chạy lúc 1:00 AM hằng ngày (batch T+1)
```

---

## Phần 3: Xử Lý Dữ Liệu Bằng Airflow + Spark

### 3.1 Kiến trúc DAG

```
                    ┌─────────────────────┐
                    │  sensor_landing_data │  ← Chờ NiFi ghi xong
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   validate_landing   │  ← Kiểm tra chất lượng
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
    ┌─────────────┐  ┌─────────────┐  ┌──────────────┐
    │ load_hub_   │  │ load_hub_   │  │ load_lnk_    │
    │ customer    │  │ account     │  │ cust_account  │
    └──────┬──────┘  └──────┬──────┘  └──────┬───────┘
           │                │                │
    ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
    │ load_sat_   │  │ load_sat_   │  │ load_sat_   │
    │ customer    │  │ account     │  │ transaction │
    └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
           │                │                │
           └────────────────┼────────────────┘
                            │
                 ┌──────────▼──────────┐
                 │   run_dbt_models    │  ← Build Business Vault + Mart
                 └──────────┬──────────┘
                            │
                 ┌──────────▼──────────┐
                 │  quality_check_mart │  ← Kiểm tra sau xử lý
                 └──────────┬──────────┘
                            │
                 ┌──────────▼──────────┐
                 │  refresh_dremio     │  ← Refresh Dremio metadata
                 └─────────────────────┘
```

### 3.2 Airflow DAG hoàn chỉnh

```python
# dags/data_vault_pipeline.py
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import SparkKubernetesOperator
from airflow.operators.python import PythonOperator
from airflow.sensors.s3_key_sensor import S3KeySensor

# ── DAG Config ──
default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'email_on_failure': True,
    'email': ['data-team@company.com'],
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(hours=2),
}

# Spark on K8s — dùng SparkKubernetesOperator
# SparkConf, credentials, resources được khai báo trong K8s YAML templates

with DAG(
    dag_id='hanas_data_vault_pipeline',
    default_args=default_args,
    description='End-to-end Data Vault pipeline: Landing → Raw Vault → Biz Vault → Mart',
    schedule_interval='0 2 * * *',  # 2:00 AM daily
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['data-vault', 'production'],
    max_active_runs=1,
) as dag:

    # ── Step 1: Sensor — chờ dữ liệu landing ──
    wait_for_customers = S3KeySensor(
        task_id='wait_for_customer_data',
        bucket_name='landing',
        bucket_key='oracle/src_customers/load_date={{ ds }}/',
        aws_conn_id='minio_s3',
        poke_interval=60,
        timeout=3600,
        mode='poke',
    )

    # ── Step 2: Validate landing data ──
    validate = SparkKubernetesOperator(
        task_id='validate_landing_data',
        namespace='spark-jobs',
        application_file='k8s/spark-validate-landing.yaml',
        kubernetes_conn_id='kubernetes_default',
        params={'date': '{{ ds }}'},
    )

    # ── Step 3: Load Raw Vault (parallel) ──
    load_hub_customer = SparkKubernetesOperator(
        task_id='load_hub_customer',
        namespace='spark-jobs',
        application_file='k8s/spark-load-raw-vault.yaml',
        kubernetes_conn_id='kubernetes_default',
        params={'entity': 'hub_customer', 'date': '{{ ds }}'},
    )

    load_hub_account = SparkKubernetesOperator(
        task_id='load_hub_account',
        namespace='spark-jobs',
        application_file='k8s/spark-load-raw-vault.yaml',
        kubernetes_conn_id='kubernetes_default',
        params={'entity': 'hub_account', 'date': '{{ ds }}'},
    )

    load_lnk_cust_account = SparkKubernetesOperator(
        task_id='load_lnk_customer_account',
        namespace='spark-jobs',
        application_file='k8s/spark-load-raw-vault.yaml',
        kubernetes_conn_id='kubernetes_default',
        params={'entity': 'lnk_customer_account', 'date': '{{ ds }}'},
    )

    load_sat_customer = SparkKubernetesOperator(
        task_id='load_sat_customer_details',
        namespace='spark-jobs',
        application_file='k8s/spark-load-raw-vault.yaml',
        kubernetes_conn_id='kubernetes_default',
        params={'entity': 'sat_customer_details', 'date': '{{ ds }}'},
    )

    load_sat_account = SparkKubernetesOperator(
        task_id='load_sat_account_details',
        namespace='spark-jobs',
        application_file='k8s/spark-load-raw-vault.yaml',
        kubernetes_conn_id='kubernetes_default',
        params={'entity': 'sat_account_details', 'date': '{{ ds }}'},
    )

    load_sat_txn = SparkKubernetesOperator(
        task_id='load_sat_transaction',
        namespace='spark-jobs',
        application_file='k8s/spark-load-raw-vault.yaml',
        kubernetes_conn_id='kubernetes_default',
        params={'entity': 'sat_transaction', 'date': '{{ ds }}'},
    )

    # ── Step 4: Run dbt (Business Vault + Information Mart) ──
    # dbt chạy qua SparkApplication với git-sync sidecar pull dbt code từ Git
    run_dbt = SparkKubernetesOperator(
        task_id='run_dbt_models',
        namespace='spark-jobs',
        application_file='k8s/dbt-runner.yaml',
        kubernetes_conn_id='kubernetes_default',
        params={
            'dbt_select': 'data_mart',
            'full_refresh': False,
        },
    )

    # ── Step 5: Quality check ──
    quality_check = SparkKubernetesOperator(
        task_id='quality_check_mart',
        namespace='spark-jobs',
        application_file='k8s/spark-quality-check.yaml',
        kubernetes_conn_id='kubernetes_default',
        params={'date': '{{ ds }}'},
    )

    # ── Step 6: Refresh Dremio metadata ──
    refresh_dremio = PythonOperator(
        task_id='refresh_dremio_metadata',
        python_callable=lambda: __import__('requests').post(
            'http://dremio:9047/api/v3/catalog/by-path/warehouse/information_mart',
            headers={'Authorization': 'Bearer <dremio-token>'},
            json={'entityType': 'dataset', 'type': 'PHYSICAL_DATASET'}
        ),
    )

    # ── Dependencies ──
    wait_for_customers >> validate

    validate >> [load_hub_customer, load_hub_account, load_lnk_cust_account]

    load_hub_customer >> load_sat_customer
    load_hub_account >> load_sat_account
    load_lnk_cust_account >> load_sat_txn

    [load_sat_customer, load_sat_account, load_sat_txn] >> run_dbt
    run_dbt >> quality_check >> refresh_dremio
```

> **Best Practices — DAG Design:**
> - `max_active_runs=1` — ngăn chạy chồng chéo
> - Sensor timeout = 1h — không chờ vô hạn
> - Hub load trước Satellite (đảm bảo foreign key)
> - Hub/Link load song song (không phụ thuộc nhau)
> - dbt chạy qua SparkApplication (không dùng BashOperator)
> - Quality check sau dbt
> - Refresh Dremio cuối cùng

---

## Phần 4: Build Data Vault Models Bằng dbt

### 4.1 Cấu trúc dbt project

```
dbt/hanas_vault/
├── dbt_project.yml
├── profiles.yml
├── models/
│   ├── raw_vault/           # Không dùng dbt cho raw vault (Spark đã xử lý)
│   ├── business_vault/
│   │   ├── pit_customer.sql
│   │   └── brdg_customer_account.sql
│   └── information_mart/
│       ├── dim_customer.sql
│       ├── dim_account.sql
│       └── fct_transactions.sql
├── macros/
│   └── hash_functions.sql
└── tests/
    └── assert_hub_customer_unique.sql
```

### 4.2 dbt_project.yml

```yaml
name: 'hanas_vault'
version: '1.0.0'
profile: 'hanas_vault'

model-paths: ["models"]
test-paths: ["tests"]
macro-paths: ["macros"]

models:
  hanas_vault:
    business_vault:
      +materialized: incremental
      +tags: ['business_vault']
    information_mart:
      +materialized: table
      +tags: ['mart']
```

### 4.3 Ví dụ model: PIT Customer (Business Vault)

```sql
-- models/business_vault/pit_customer.sql
{{
    config(
        materialized='incremental',
        unique_key='pit_customer_hk',
        incremental_strategy='merge'
    )
}}

WITH latest_satellites AS (
    SELECT
        hub.hub_customer_hk,
        hub.customer_id,
        sat.load_dts AS sat_customer_load_dts,
        sat.name,
        sat.email,
        sat.phone,
        sat.city,
        ROW_NUMBER() OVER (
            PARTITION BY hub.hub_customer_hk
            ORDER BY sat.load_dts DESC
        ) AS rn
    FROM {{ source('raw_vault', 'hub_customer') }} hub
    LEFT JOIN {{ source('raw_vault', 'sat_customer_details') }} sat
        ON hub.hub_customer_hk = sat.hub_customer_hk
)

SELECT
    hub_customer_hk AS pit_customer_hk,
    customer_id,
    sat_customer_load_dts,
    name,
    email,
    phone,
    city,
    CURRENT_TIMESTAMP() AS pit_load_dts
FROM latest_satellites
WHERE rn = 1

{% if is_incremental() %}
    AND sat_customer_load_dts > (SELECT MAX(pit_load_dts) FROM {{ this }})
{% endif %}
```

### 4.4 Ví dụ model: Fact Transactions (Information Mart)

```sql
-- models/information_mart/fct_transactions.sql
{{
    config(
        materialized='table',
        tags=['mart', 'fact']
    )
}}

SELECT
    sat_txn.transaction_id,
    hub_acct.account_id,
    hub_cust.customer_id,
    sat_txn.txn_type,
    sat_txn.amount,
    sat_txn.description,
    sat_txn.txn_date,
    DATE(sat_txn.txn_date) AS txn_date_key,
    -- derived columns
    CASE
        WHEN sat_txn.txn_type IN ('DEPOSIT', 'CREDIT') THEN sat_txn.amount
        ELSE 0
    END AS credit_amount,
    CASE
        WHEN sat_txn.txn_type IN ('WITHDRAWAL', 'DEBIT') THEN sat_txn.amount
        ELSE 0
    END AS debit_amount,
    sat_txn.load_dts,
    sat_txn.record_source
FROM {{ source('raw_vault', 'sat_transaction') }} sat_txn
JOIN {{ source('raw_vault', 'lnk_customer_account') }} lnk
    ON sat_txn.lnk_customer_account_hk = lnk.lnk_customer_account_hk
JOIN {{ source('raw_vault', 'hub_account') }} hub_acct
    ON lnk.hub_account_hk = hub_acct.hub_account_hk
JOIN {{ source('raw_vault', 'hub_customer') }} hub_cust
    ON lnk.hub_customer_hk = hub_cust.hub_customer_hk
```

---

## Phần 5: Phục Vụ BI Qua Dremio

### 5.1 Cấu hình Sources trong Dremio

```
Sources:
├── lakehouse (S3/MinIO)
│   ├── warehouse/raw_vault/       → Iceberg tables
│   ├── warehouse/business_vault/  → Iceberg tables
│   └── warehouse/information_mart/ → Iceberg tables
│
├── oracle-source (RDBMS)          → Truy vấn trực tiếp nếu cần
│
└── Spaces:
    ├── Analytics/                 → Virtual Datasets cho BI
    └── Operations/                → Dashboard vận hành
```

### 5.2 Tạo Virtual Dataset (Semantic Layer)

```sql
-- Dremio Virtual Dataset: "Customer 360"
-- Space: Analytics / Customer360

SELECT
    dc.customer_id,
    dc.name AS customer_name,
    dc.email,
    dc.city,
    da.account_id,
    da.account_type,
    da.currency,
    da.balance AS current_balance,
    da.status AS account_status,
    COUNT(ft.transaction_id) AS total_transactions,
    SUM(ft.credit_amount) AS total_credit,
    SUM(ft.debit_amount) AS total_debit,
    MAX(ft.txn_date) AS last_transaction_date
FROM information_mart.dim_customer dc
LEFT JOIN information_mart.dim_account da
    ON dc.customer_id = da.customer_id
LEFT JOIN information_mart.fct_transactions ft
    ON da.account_id = ft.account_id
GROUP BY
    dc.customer_id, dc.name, dc.email, dc.city,
    da.account_id, da.account_type, da.currency,
    da.balance, da.status;
```

### 5.3 Tạo Reflection (Acceleration)

```sql
-- Tạo Aggregation Reflection cho Customer360
ALTER DATASET "Analytics"."Customer360"
  CREATE AGGREGATE REFLECTION "agg_customer_daily"
  USING
    DIMENSIONS (customer_id, city, account_type, txn_date_key)
    MEASURES (total_transactions SUM, total_credit SUM, total_debit SUM)
    PARTITION BY (txn_date_key);
```

### 5.4 Kết nối BI Tool

```
# JDBC Connection String (Superset, Tableau, PowerBI)
Driver: Dremio JDBC Driver
Host: dremio-host
Port: 31010
Schema: Analytics

# ODBC Connection
DSN: Hanas Dremio
Server: dremio-host:31010
Authentication: Username/Password

# Arrow Flight (high-performance)
Endpoint: grpc://dremio-host:32010
```

---

## Phần 6: Giám Sát & Vận Hành

### 6.1 Checklist vận hành hàng ngày

| Thời gian | Kiểm tra | Công cụ |
|---|---|---|
| 7:00 AM | NiFi flows có chạy đúng schedule? | NiFi UI |
| 7:30 AM | Airflow DAG `hanas_data_vault_pipeline` thành công? | Airflow UI |
| 8:00 AM | Dremio Reflections đã refresh? | Dremio UI |
| Liên tục | Metrics hệ thống (CPU, RAM, Disk) | OpenObserve |
| Liên tục | Log errors từ các services | OpenObserve |

### 6.2 Alerting Matrix

| Sự kiện | Mức | Hành động |
|---|---|---|
| NiFi flow stopped | 🔴 Critical | Kiểm tra connection pool, restart flow |
| Airflow DAG failed | 🔴 Critical | Kiểm tra Spark logs, retry task |
| MinIO disk > 80% | 🟡 Warning | Mở rộng storage hoặc archive old data |
| Spark job timeout | 🟡 Warning | Kiểm tra data volume, tune resources |
| dbt test failed | 🟡 Warning | Kiểm tra data quality, fix model |

---

## Tổng Kết Luồng

```
┌──────────┐   Schedule    ┌──────────┐   Avro     ┌──────────┐
│  Oracle  │──────────────▶│   NiFi   │──────────▶│  MinIO   │
│  (RDBMS) │  30min/daily  │  (ETL)   │  files    │ (Landing)│
└──────────┘               └──────────┘           └────┬─────┘
                                                       │
                                                       ▼
┌──────────┐   Submit      ┌──────────┐   Iceberg  ┌──────────┐
│ Airflow  │──────────────▶│  Spark   │──────────▶│  MinIO   │
│  (DAG)   │  SparkK8sOp  │(K8s Pods)│  tables   │(Raw Vault)│
└──────────┘               └──────────┘           └────┬─────┘
                                                       │
                                                       ▼
                           ┌──────────┐   Iceberg  ┌──────────┐
                           │   dbt    │──────────▶│  MinIO   │
                           │ (Models) │  tables   │(Biz+Mart)│
                           └──────────┘           └────┬─────┘
                                                       │
                                                       ▼
┌──────────┐   JDBC/ODBC   ┌──────────┐   S3      ┌──────────┐
│   BI     │◀──────────────│  Dremio  │◀─────────│  MinIO   │
│(Superset)│   SQL query   │ (Query)  │  Iceberg  │(Warehouse)│
└──────────┘               └──────────┘           └──────────┘
```
