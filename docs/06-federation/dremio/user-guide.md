# Dremio - Hướng Dẫn Sử Dụng

## 1. Truy Cập Dremio

### 1.1 Web UI

| Thông tin | Giá trị |
|---|---|
| **URL** | `http://dremio.hanas.local/` hoặc `http://<DREMIO_HOST>:9047` |
| **Admin Account** | `vaultadmin` / `<password>` |
| **BI Account** | `bi_user` / `<password>` |

### 1.2 Giao Diện Chính

```
┌──────────────────────────────────────────────────┐
│  Dremio UI                                        │
├──────────┬───────────────────────────────────────┤
│          │                                         │
│  Sources │   Main Content Area                    │
│  Spaces  │   (Dataset browser / SQL Runner /       │
│  Home    │    Job History / Reflections)           │
│          │                                         │
├──────────┴───────────────────────────────────────┤
│  Navigation: Datasets │ SQL Runner │ Jobs          │
└──────────────────────────────────────────────────┘
```

- **Datasets**: Browse sources, spaces, datasets
- **SQL Runner**: Viết và chạy SQL queries
- **Jobs**: Xem lịch sử queries và trạng thái

---

## 2. Khám Phá Data Sources

### 2.1 Browse Iceberg Tables

Sau khi cấu hình MinIO / Hive source (xem [configuration.md](configuration.md)):

1. Mở **Datasets** → click vào source (e.g., `hive_catalog` hoặc `minio_lakehouse`)
2. Navigate qua các schema: `integration`, `data_mart`, `landing`
3. Click vào table để xem schema, preview data

### 2.2 Cấu Trúc Dữ Liệu Trong Platform

```
hive_catalog/
├── integration/              # Raw Vault + Business Vault (Iceberg)
│   ├── hub_customer
│   ├── sat_customer
│   ├── link_customer_account
│   └── ...
├── data_mart/                # Data Mart (Iceberg)
│   ├── fact_pl_detail
│   ├── fact_pl_summary
│   ├── dim_customer
│   └── ...
└── landing/                  # Landing zone (Iceberg)
    ├── gl_poc_streaming
    └── gl_poc_backdate
```

### 2.3 Iceberg Time Travel Qua Dremio

```sql
-- Query dữ liệu tại thời điểm trước
SELECT * FROM hive_catalog.data_mart.fact_pl_detail
AT TIMESTAMP '2025-02-10 00:00:00';

-- Query theo snapshot ID
SELECT * FROM hive_catalog.data_mart.fact_pl_detail
AT SNAPSHOT '1234567890';
```

---

## 3. Virtual Datasets (Views)

### 3.1 Tạo View Qua SQL Runner

```sql
-- Tạo view đơn giản trên Iceberg table
CREATE VDS DATA_MART.FACT_PL_DETAIL AS
SELECT
    transaction_id,
    account_number,
    transaction_date,
    amount,
    currency,
    branch_code,
    description
FROM hive_catalog.data_mart.fact_pl_detail;
```

Hoặc: Chạy SQL → click **Save View As...** → chọn Space `DATA_MART` → đặt tên

### 3.2 View Phức Tạp — Join Nhiều Tables

```sql
-- Join Hub + Satellite + Data Mart
SELECT
    h.customer_id,
    s.customer_name,
    s.customer_email,
    f.total_balance,
    f.last_transaction_date
FROM hive_catalog.integration.hub_customer h
JOIN hive_catalog.integration.sat_customer s
    ON h.hub_customer_hashkey = s.hub_customer_hashkey
    AND s.load_end_date IS NULL  -- Current record
JOIN hive_catalog.data_mart.dim_customer_balance f
    ON h.customer_id = f.customer_id;
```

### 3.3 View Pattern Trong Platform

| View | SQL Pattern | Space |
|---|---|---|
| Direct mapping | `SELECT * FROM source_table` | `DATA_MART` |
| Filtered | `SELECT ... WHERE condition` | `DATA_MART` |
| Aggregated | `SELECT ... GROUP BY ...` | `DATA_MART` |
| Joined | `SELECT ... JOIN ...` | `DATA_MART` |
| Backdate | `SELECT ... FROM backdate_table` | `DATA_MART` |

---

## 4. Reflections

### 4.1 Tạo Raw Reflection

1. Mở dataset → tab **Reflections**
2. Bật **Raw Reflections**
3. Chọn columns cần cache
4. Click **Save**

> **Khi nào dùng Raw:** Dashboard queries cần nhiều columns, filter khác nhau trên cùng dataset.

### 4.2 Tạo Aggregation Reflection

1. Mở dataset → tab **Reflections**
2. Bật **Aggregation Reflections**
3. Cấu hình:
   - **Dimension Fields**: Columns dùng GROUP BY (e.g., `region`, `product_type`, `transaction_date`)
   - **Measure Fields**: Columns dùng aggregate (e.g., `SUM(amount)`, `COUNT(*)`)
4. Click **Save**

> **Khi nào dùng Aggregation:** KPI dashboards chỉ cần summary/totals, ít thay đổi filter dimensions.

### 4.3 Kiểm Tra Trạng Thái Reflections

1. **Reflections Page:** Settings → Reflections → xem danh sách toàn bộ reflections
2. **Dataset Level:** Mở dataset → Reflections tab → xem status (ACTIVE, REFRESHING, FAILED)
3. **Job History:** Jobs → filter "Reflection" → xem refresh history

### 4.4 Reflection Lifecycle

```
Create → First Refresh → ACTIVE → Auto Refresh (periodic) → ...
                                  │
                                  ├── Manual Refresh (khi data thay đổi)
                                  │
                                  └── Disable / Delete (khi không cần)
```

---

## 5. SQL Queries

### 5.1 SQL Runner

Truy cập **SQL Runner** từ navigation bar → viết SQL → click **Run**

### 5.2 Query Iceberg Tables Trực Tiếp

```sql
-- Đọc từ Hive catalog
SELECT * FROM hive_catalog.data_mart.fact_pl_detail
WHERE transaction_date >= '2025-01-01'
LIMIT 100;

-- Đọc từ MinIO source path
SELECT * FROM minio_lakehouse.data.warehouse.data_mart.fact_pl_detail
LIMIT 100;
```

### 5.3 Query Virtual Datasets

```sql
-- Query views trong Space
SELECT *
FROM DATA_MART.FACT_PL_DETAIL_BACKDATE
WHERE transaction_date BETWEEN '2025-02-10' AND '2025-02-15';
```

### 5.4 DML Trên Iceberg Tables

```sql
-- INSERT INTO
INSERT INTO hive_catalog.data_mart.dim_reference
VALUES ('REF001', 'Category A', current_timestamp());

-- MERGE INTO (upsert)
MERGE INTO hive_catalog.data_mart.dim_customer AS target
USING staging.new_customers AS source
ON target.customer_id = source.customer_id
WHEN MATCHED THEN UPDATE SET customer_name = source.customer_name
WHEN NOT MATCHED THEN INSERT *;

-- CREATE TABLE AS SELECT
CREATE TABLE hive_catalog.data_mart.report_monthly
AS SELECT
    DATE_TRUNC('MONTH', transaction_date) AS month,
    SUM(amount) AS total_amount
FROM hive_catalog.data_mart.fact_pl_detail
GROUP BY DATE_TRUNC('MONTH', transaction_date);
```

---

## 6. Kết Nối BI Tools

### 6.1 Apache Superset

```
Database Connection:
  Type:         Dremio
  SQLAlchemy URI: dremio+flight://<username>:<password>@<DREMIO_HOST>:32010/dremio?UseEncryption=false
```

### 6.2 Tableau

```
Connection:
  Server:      <DREMIO_HOST>
  Port:        31010
  Database:    DREMIO
  Username:    <username>
  Password:    <password>
  Driver:      Dremio JDBC Driver (download từ Dremio website)
```

### 6.3 PowerBI

```
Connection:
  Server:      <DREMIO_HOST>:31010
  Database:    DREMIO
  Protocol:    JDBC hoặc ODBC
  Auth:        Username/Password
```

### 6.4 Python (pyarrow / dremio-simple-query)

```python
from pyarrow import flight

# Connect via Arrow Flight
client = flight.FlightClient(f"grpc://<DREMIO_HOST>:32010")

# Authenticate
token_pair = client.authenticate_basic_token(b"<username>", b"<password>")
options = flight.FlightCallOptions(headers=[token_pair])

# Execute query
flight_info = client.get_flight_info(
    flight.FlightDescriptor.for_command(
        b"SELECT * FROM DATA_MART.FACT_PL_DETAIL LIMIT 10"
    ),
    options
)

reader = client.do_get(flight_info.endpoints[0].ticket, options)
table = reader.read_all()
df = table.to_pandas()
print(df)
```

---

## 7. API Integration (Airflow)

### 7.1 DremioClient Overview

Platform sử dụng `DremioClient` utility class trong Airflow DAGs:

| Method | Mô tả |
|---|---|
| `login()` | Authenticate, lấy token |
| `create_vds(space, view_name, sql)` | Tạo/thay thế Virtual Dataset |
| `create_raw_reflection(dataset_id)` | Tạo raw reflection cho dataset |
| `get_catalog_id(path)` | Lấy catalog ID theo path |
| `close()` | Đóng session |

### 7.2 Luồng Tự Động Trong Backdate DAG

```
Airflow DAG
    │
    ├── 1. SparkKubernetesOperator → Create Iceberg table
    │
    ├── 2. SparkKubernetesOperator → Run dbt models
    │
    ├── 3. PythonOperator (DremioClient)
    │       → Login to Dremio API
    │       → Create 6 views in DATA_MART space
    │       → Push dataset IDs to XCom
    │
    └── 4. PythonOperator (DremioClient)
            → Login to Dremio API
            → Create raw reflections cho 6 views
```

### 7.3 API Endpoints Thường Dùng

| Endpoint | Method | Mô tả |
|---|---|---|
| `/apiv2/login` | POST | Login, lấy token |
| `/api/v3/catalog` | POST | Tạo space, source, VDS |
| `/api/v3/catalog/{id}` | GET | Lấy chi tiết entity |
| `/api/v3/catalog/{id}` | PUT | Cập nhật entity |
| `/api/v3/catalog/{id}?tag={tag}` | DELETE | Xóa entity |
| `/api/v3/catalog/by-path/{path}` | GET | Tìm entity theo path |
| `/api/v3/reflection` | GET/POST | Quản lý reflections |
| `/api/v3/reflection/{id}` | DELETE | Xóa reflection |
| `/api/v3/sql` | POST | Submit SQL query |

---

## 8. Quản Lý & Giám Sát

### 8.1 Jobs Page

Truy cập **Jobs** để xem:
- Trạng thái queries (Running, Completed, Failed, Canceled)
- Thời gian thực thi
- Query profile (execution plan)
- Rows scanned/returned

### 8.2 Query Profiling

1. Vào **Jobs** → click vào job cụ thể
2. Xem **Query Profile** → execution plan tree
3. Kiểm tra:
   - **Reflection used**: Có dùng reflection hay full scan?
   - **Rows scanned**: Bao nhiêu rows được đọc?
   - **Duration**: Planning time vs execution time?

### 8.3 Reflection Monitoring

```bash
# Via API: Liệt kê tất cả reflections
curl -X GET "http://<DREMIO_HOST>:9047/api/v3/reflection" \
  -H "Authorization: _dremio<TOKEN>"
```

### 8.4 Cluster Health

```bash
# Health check
curl -s http://<DREMIO_HOST>:9047/apiv2/server_status

# Cluster info (coordinator only)
curl -s http://<DREMIO_HOST>:9047/api/v3/cluster/stats \
  -H "Authorization: _dremio<TOKEN>"
```
