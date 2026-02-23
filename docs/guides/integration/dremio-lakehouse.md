# Integration Guide: Dremio + Lakehouse

## Tổng Quan

Hướng dẫn cấu hình Dremio như query engine thống nhất, kết nối Iceberg tables trên MinIO và phục vụ BI tools.

```
MinIO (Iceberg)  ──▶  Dremio  ──▶  BI Tools (Superset/Tableau/PowerBI)
RDBMS (Oracle)   ──▶  (Query  ──▶  Applications (REST API)
                       Engine)
```

---

## 1. Cấu Hình Data Sources

### 1.1 Kết nối MinIO (Lakehouse)

```
Dremio UI → Sources → Add Source → Amazon S3

Name: lakehouse
Authentication: Access Key
Access Key: admin
Secret Key: minio_secret_2024

Connection Properties:
  fs.s3a.endpoint         = http://minio:9000
  fs.s3a.path.style.access = true
  dremio.s3.compat        = true

Root Path: /
```

### 1.2 Kết nối Oracle (RDBMS trực tiếp)

```
Dremio UI → Sources → Add Source → Oracle

Name: oracle-prod
Host: oracle-host
Port: 1521
Service Name: ORCL
Username: readonly_user
Password: ********
```

### 1.3 Setup Iceberg Tables

Sau khi kết nối MinIO, promote Iceberg tables:

```
lakehouse → warehouse → raw_vault → hub_customer
  → Click "Format Iceberg" 
  → Save
```

Lặp lại cho tất cả tables trong `raw_vault`, `business_vault`, `information_mart`.

---

## 2. Tạo Spaces & Virtual Datasets

### 2.1 Tổ chức Spaces

```
Dremio Spaces:
├── Analytics/              # Virtual datasets cho BI
│   ├── Customer360
│   ├── TransactionSummary
│   └── AccountOverview
│
├── Operations/             # Dashboard vận hành
│   ├── DailyLoadStatus
│   └── DataQualityMetrics
│
└── Sandbox/               # Phân tích ad-hoc
```

### 2.2 Virtual Dataset: Customer 360

```sql
-- Space: Analytics / Customer360
SELECT
    dc.customer_id,
    dc.full_name AS customer_name,
    dc.email,
    dc.city,
    dc.segment,
    dc.segment_label,
    da.account_id,
    da.account_type,
    da.currency,
    da.balance AS current_balance,
    da.status AS account_status,
    -- Aggregated metrics
    txn_summary.total_transactions,
    txn_summary.total_credit,
    txn_summary.total_debit,
    txn_summary.net_amount,
    txn_summary.last_transaction_date
FROM lakehouse.warehouse.information_mart.dim_customer dc
LEFT JOIN lakehouse.warehouse.information_mart.dim_account da
    ON dc.customer_id = da.customer_id
LEFT JOIN (
    SELECT
        account_id,
        COUNT(*) AS total_transactions,
        SUM(credit_amount) AS total_credit,
        SUM(debit_amount) AS total_debit,
        SUM(credit_amount) - SUM(debit_amount) AS net_amount,
        MAX(txn_date) AS last_transaction_date
    FROM lakehouse.warehouse.information_mart.fct_transactions
    GROUP BY account_id
) txn_summary ON da.account_id = txn_summary.account_id
```

### 2.3 Virtual Dataset: Daily Transaction Summary

```sql
-- Space: Analytics / TransactionSummary
SELECT
    txn_date_key,
    dc.city,
    dc.segment,
    da.account_type,
    ft.txn_type,
    COUNT(*) AS transaction_count,
    SUM(ft.amount) AS total_amount,
    AVG(ft.amount) AS avg_amount,
    MIN(ft.amount) AS min_amount,
    MAX(ft.amount) AS max_amount
FROM lakehouse.warehouse.information_mart.fct_transactions ft
JOIN lakehouse.warehouse.information_mart.dim_customer dc
    ON ft.customer_sk = dc.customer_sk
JOIN lakehouse.warehouse.information_mart.dim_account da
    ON ft.account_id = da.account_id
GROUP BY txn_date_key, dc.city, dc.segment, da.account_type, ft.txn_type
```

---

## 3. Reflections (Acceleration)

### 3.1 Raw Reflection (caching toàn bảng)

```sql
-- Raw Reflection cho dim_customer (luôn đọc nhanh)
ALTER DATASET "Analytics"."Customer360"
  CREATE RAW REFLECTION "raw_customer360"
  USING DISPLAY (customer_id, customer_name, email, city, segment,
                 account_id, account_type, current_balance,
                 total_transactions, total_credit, total_debit);
```

### 3.2 Aggregation Reflection (pre-aggregated)

```sql
-- Aggregation Reflection cho Transaction Summary
ALTER DATASET "Analytics"."TransactionSummary"
  CREATE AGGREGATE REFLECTION "agg_txn_daily"
  USING
    DIMENSIONS (txn_date_key, city, segment, account_type, txn_type)
    MEASURES (transaction_count SUM, total_amount SUM, avg_amount AVG)
    PARTITION BY (txn_date_key);
```

### 3.3 Best Practices cho Reflections

| Practice | Mô tả |
|---|---|
| Raw Reflection cho dim tables nhỏ | Cache toàn bộ, truy vấn instant |
| Aggregation cho fact tables | Pre-compute SUM/COUNT/AVG |
| Partition reflection theo date | Refresh từng phần thay vì toàn bộ |
| Refresh schedule phù hợp | Sau Airflow DAG hoàn tất |
| Monitor reflection hit rate | Dremio → Acceleration → Status |

---

## 4. Row-Level Security

```sql
-- Tạo UDF cho row-level security
CREATE FUNCTION is_allowed_city(user_city VARCHAR)
RETURNS BOOLEAN
RETURN SELECT CASE
    WHEN query_user() = 'admin' THEN TRUE
    WHEN query_user() = 'hn_user' AND user_city = 'Ha Noi' THEN TRUE
    WHEN query_user() = 'hcm_user' AND user_city = 'Ho Chi Minh' THEN TRUE
    ELSE FALSE
END;

-- Áp dụng
ALTER DATASET "Analytics"."Customer360"
  ADD ROW ACCESS POLICY filter_by_city
  ON (city);
```

---

## 5. Kết Nối BI Tools

### 5.1 Apache Superset

```python
# superset_config.py — Database connection
SQLALCHEMY_DATABASE_URI = "dremio+flight://user:pass@dremio-host:32010/dremio"

# Hoặc qua JDBC
# dremio://user:pass@dremio-host:31010
```

### 5.2 Tableau

```
Driver: Dremio ODBC Driver
Server: dremio-host
Port: 31010
Authentication: Username/Password
Schema: Analytics
```

### 5.3 PowerBI

```
Get Data → ODBC → DSN: Dremio
Hoặc: DirectQuery → Server: dremio-host:31010
```

### 5.4 Python / Pandas

```python
import pyarrow.flight as flight

# Arrow Flight (high performance)
client = flight.FlightClient("grpc://dremio-host:32010")
token = client.authenticate_basic_token("user", "password")
options = flight.FlightCallOptions(headers=[token])

# Query
ticket = flight.Ticket(b'SELECT * FROM "Analytics"."Customer360" LIMIT 100')
reader = client.do_get(ticket, options)
df = reader.read_pandas()
```

---

## 6. Best Practices

| Practice | Mô tả |
|---|---|
| Virtual Datasets thay vì copy data | Không nhân bản, dễ quản trị |
| Semantic layer tập trung | 1 định nghĩa "doanh thu" dùng chung |
| Reflections cho dashboard nặng | Giảm load trên Lakehouse |
| Row-level security | Phân quyền dữ liệu theo role |
| Workspace per team | Sandbox cho phân tích ad-hoc |
| Arrow Flight cho big data | 10x nhanh hơn JDBC |
