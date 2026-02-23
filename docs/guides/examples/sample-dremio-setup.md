# Code Example: Dremio Setup Mẫu — Lakehouse Query Engine

---

## 1. Sources Setup

### 1.1 MinIO / Lakehouse

```
Name: lakehouse
Type: Amazon S3
Auth: Access Key (admin / minio_secret_2024)
Properties:
  fs.s3a.endpoint = http://minio:9000
  fs.s3a.path.style.access = true
  dremio.s3.compat = true
Root Path: /
```

### 1.2 Oracle (Direct Query)

```
Name: oracle-prod
Type: Oracle
Host: oracle-host:1521
Service Name: ORCL
Auth: readonly_user / ********
```

---

## 2. Space Organization

```
Spaces:
├── Analytics/               # Virtual datasets cho BI
│   ├── Customer360          # Khách hàng 360°
│   ├── DepositSummary       # Tổng hợp tiền gửi
│   ├── LoanSummary          # Tổng hợp cho vay
│   └── PLSummary            # Tổng hợp lợi nhuận
│
├── Operations/              # Dashboard vận hành
│   ├── ETLStatus            # Trạng thái pipeline
│   └── DataQuality          # Chất lượng dữ liệu
│
└── Sandbox/                 # Ad-hoc analysis
    └── (per-user folders)
```

---

## 3. Virtual Dataset Examples

### Customer 360

```sql
SELECT
    dc.customer_id,
    dc.full_name,
    dc.segment,
    dc.city,
    da.account_type,
    da.balance,
    COUNT(ft.transaction_id) AS total_txn,
    SUM(ft.credit_amount) AS total_credit,
    SUM(ft.debit_amount) AS total_debit
FROM lakehouse.warehouse.data_mart.dim_customer dc
LEFT JOIN lakehouse.warehouse.data_mart.dim_account da
    ON dc.customer_id = da.customer_id
LEFT JOIN lakehouse.warehouse.data_mart.fct_transactions ft
    ON da.account_id = ft.account_id
GROUP BY 1,2,3,4,5,6
```

---

## 4. Reflections (Acceleration)

```sql
-- Raw Reflection cho dim tables nhỏ
ALTER DATASET "Analytics"."Customer360"
  CREATE RAW REFLECTION "raw_cust360"
  USING DISPLAY (customer_id, full_name, segment, city,
                 account_type, balance, total_txn);

-- Aggregation Reflection cho fact tables
ALTER DATASET "Analytics"."DepositSummary"
  CREATE AGGREGATE REFLECTION "agg_deposit_daily"
  USING
    DIMENSIONS (branch_code, currency, report_date)
    MEASURES (total_balance SUM, total_accounts SUM)
    PARTITION BY (report_date);
```

---

## 5. BI Connection Strings

| Tool | Connection |
|---|---|
| **Superset** | `dremio+flight://user:pass@dremio:32010/dremio` |
| **Tableau** | ODBC → `dremio:31010`, Schema: `Analytics` |
| **PowerBI** | DirectQuery → `dremio:31010` |
| **Python** | `pyarrow.flight.FlightClient("grpc://dremio:32010")` |
| **DBeaver** | JDBC → `jdbc:dremio:direct=dremio:31010` |
