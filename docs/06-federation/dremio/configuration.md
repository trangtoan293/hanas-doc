# Dremio - Cấu Hình

## 1. Cấu Hình Data Sources

### 1.1 MinIO (S3-Compatible)

Kết nối Dremio với MinIO để đọc Iceberg data files:

**Qua UI:** Sources → Add Source → Amazon S3

```
General:
  Name:               minio_lakehouse
  AWS Access Key:     <MINIO_ACCESS_KEY>
  AWS Access Secret:  <MINIO_SECRET_KEY>
  Encrypt Connection: false

Advanced Options:
  Enable compatibility mode:               true
  Root Path:                                /
  Connection Properties:
    fs.s3a.endpoint:                        http://<MINIO_HOST>:9000
    fs.s3a.path.style.access:              true
  Default CTAS Format:                      ICEBERG
  Enable local caching:                     true
```

**Qua API:**

```bash
curl -X POST "http://<DREMIO_HOST>:9047/api/v3/catalog" \
  -H "Authorization: _dremio<TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "entityType": "source",
    "name": "minio_lakehouse",
    "type": "S3",
    "config": {
      "credentialType": "ACCESS_KEY",
      "accessKey": "<MINIO_ACCESS_KEY>",
      "accessSecret": "data:<MINIO_SECRET_KEY>",
      "secure": false,
      "compatibilityMode": true,
      "rootPath": "/",
      "propertyList": [
        {"name": "fs.s3a.endpoint", "value": "http://<MINIO_HOST>:9000"},
        {"name": "fs.s3a.path.style.access", "value": "true"}
      ],
      "defaultCtasFormat": "ICEBERG",
      "isCachingEnabled": true,
      "maxCacheSpacePct": 100
    }
  }'
```

### 1.2 Hive Metastore

Kết nối Dremio với Hive Metastore để đọc Iceberg table metadata:

**Qua UI:** Sources → Add Source → Hive 2.x/3.x

```
General:
  Name:         hive_catalog
  Hostname:     <HIVE_HOST>
  Port:         9083
  Enable SASL:  false

Storage:
  Default CTAS Format:  ICEBERG
  Enable S3/Azure caching: true

Connection Properties:
  fs.s3a.endpoint:                  http://<MINIO_HOST>:9000
  fs.s3a.path.style.access:        true
  fs.s3a.access.key:               <MINIO_ACCESS_KEY>
  fs.s3a.secret.key:               <MINIO_SECRET_KEY>
```

> **Lưu ý:** Khi sử dụng Hive source, Dremio đọc metadata từ Hive Metastore và data files từ MinIO. S3 credentials cần được cấu hình trong connection properties của Hive source.

---

## 2. Cấu Hình Spaces & Folders

### 2.1 Tạo Spaces

Spaces tổ chức Virtual Datasets (views) theo chủ đề/phòng ban:

| Space | Mục đích |
|---|---|
| `DATA_MART` | Views phục vụ BI/reporting — điểm truy cập chính cho business users |
| `INTEGRATION` | Views cho lớp integration/business vault (internal) |

**Qua UI:** Spaces → Add Space

**Qua API:**

```bash
curl -X POST "http://<DREMIO_HOST>:9047/api/v3/catalog" \
  -H "Authorization: _dremio<TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "entityType": "space",
    "name": "DATA_MART"
  }'
```

### 2.2 Tổ Chức Folders

```
DATA_MART/
├── PL/                         # Profit & Loss
│   ├── FACT_PL_DETAIL
│   └── FACT_PL_SUMMARY
├── DP/                         # Deposits
│   ├── FACT_DP_DETAIL
│   └── FACT_DP_SUMMARY
├── LN/                         # Loans
│   ├── FACT_LN_DETAIL
│   └── FACT_LN_SUMMARY
└── BACKDATE/                   # Backdate views
    ├── FACT_PL_DETAIL_BACKDATE
    ├── FACT_PL_SUMMARY_BACKDATE
    ├── FACT_DP_DETAIL_BACKDATE
    ├── FACT_DP_SUMMARY_BACKDATE
    ├── FACT_LN_DETAIL_BACKDATE
    └── FACT_LN_SUMMARY_BACKDATE
```

---

## 3. Cấu Hình Virtual Datasets (Views)

### 3.1 Tạo View Qua UI

1. Truy cập SQL Runner
2. Viết SQL query trên Iceberg tables
3. Click "Save View As..." → chọn Space và đặt tên

### 3.2 Tạo View Qua API

```bash
curl -X POST "http://<DREMIO_HOST>:9047/api/v3/catalog" \
  -H "Authorization: _dremio<TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "entityType": "dataset",
    "type": "VIRTUAL_DATASET",
    "path": ["DATA_MART", "FACT_PL_DETAIL"],
    "sql": "SELECT * FROM hive_catalog.data_mart.fact_pl_detail",
    "sqlContext": ["DATA_MART"]
  }'
```

### 3.3 Tạo View Qua Airflow DremioClient

Platform sử dụng `DremioClient` trong Airflow DAGs để tự động tạo views:

```python
from utils.dremio_client import DremioClient

client = DremioClient(
    base_url='http://192.168.1.193:9047',
    username='vaultadmin',
    password=Variable.get('dremio_password'),
    ssl_verify=False
)

client.login()
result = client.create_vds(
    space='DATA_MART',
    view_name='FACT_PL_DETAIL_BACKDATE',
    sql='SELECT * FROM hive_catalog.data_mart.fact_pl_detail_backdate'
)
client.close()
```

---

## 4. Cấu Hình Reflections

### 4.1 Tổng Quan Reflections

Reflections là pre-computed materialized views mà Dremio tự động sử dụng để tăng tốc queries:

| Loại | Mục đích | Use case |
|---|---|---|
| **Raw Reflection** | Cache toàn bộ hoặc subset columns ở định dạng tối ưu | Dashboard queries cần full data |
| **Aggregation Reflection** | Pre-compute aggregations (SUM, COUNT, AVG...) | KPI dashboards, summary reports |

### 4.2 Tạo Raw Reflection

**Qua UI:** Dataset → Reflections tab → Raw Reflections → Enable → chọn columns

**Qua API:**

```bash
curl -X POST "http://<DREMIO_HOST>:9047/api/v3/reflection" \
  -H "Authorization: _dremio<TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "RAW",
    "datasetId": "<DATASET_ID>",
    "enabled": true,
    "name": "Raw Reflection",
    "displayFields": [
      {"name": "col1"},
      {"name": "col2"}
    ],
    "partitionDistributionStrategy": "CONSOLIDATED"
  }'
```

### 4.3 Tạo Aggregation Reflection

```bash
curl -X POST "http://<DREMIO_HOST>:9047/api/v3/reflection" \
  -H "Authorization: _dremio<TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "AGGREGATION",
    "datasetId": "<DATASET_ID>",
    "enabled": true,
    "name": "Agg Reflection",
    "dimensionFields": [
      {"name": "region"},
      {"name": "product_type"}
    ],
    "measureFields": [
      {"name": "total_amount"},
      {"name": "transaction_count"}
    ],
    "partitionDistributionStrategy": "CONSOLIDATED"
  }'
```

### 4.4 Reflection Refresh Policy

```
Settings → Reflections:
  Refresh Method:     Full update
  Refresh Period:     3 hours (cho production)
  Grace Period:       1 hour
  Never Expire:       false
```

> **Trong platform:** Backdate DAG sử dụng `DremioClient.create_raw_reflection()` để tự động tạo reflections cho views mới.

---

## 5. Cấu Hình Kết Nối BI Tools

### 5.1 Arrow Flight (Khuyến nghị)

Protocol hiệu năng cao, tránh serialization overhead:

```
Driver:     org.apache.arrow.driver.jdbc.ArrowFlightJdbcDriver
URL:        jdbc:arrow-flight-sql://<DREMIO_HOST>:32010/?useEncryption=false
Username:   <username>
Password:   <password>
```

> **Yêu cầu Java 16+:**
> ```
> --add-opens=java.base/java.nio=org.apache.arrow.memory.core,ALL-UNNAMED
> ```

### 5.2 JDBC chuẩn

```
Driver:     com.dremio.jdbc.Driver
URL:        jdbc:dremio:direct=<DREMIO_HOST>:31010
Username:   <username>
Password:   <password>
```

### 5.3 ODBC

```
Driver:     Dremio ODBC Driver
Host:       <DREMIO_HOST>
Port:       31010
Auth Type:  Plain
Username:   <username>
Password:   <password>
SSL:        false (nội bộ)
```

### 5.4 Bảng Tổng Hợp Ports

| Giao thức | Port | Sử dụng |
|---|---|---|
| **HTTP/REST API** | `9047` | UI, REST API, login |
| **JDBC** | `31010` | BI tools kết nối JDBC |
| **Arrow Flight** | `32010` | High-performance connections |
| **Inter-node** | `45678` | Communication giữa coordinator/executor |

---

## 6. Cấu Hình Bảo Mật

### 6.1 Users & Roles

Tạo users qua UI: Settings → Users → Add User

| User | Vai trò | Mục đích |
|---|---|---|
| `vaultadmin` | Admin | Quản trị Dremio, tạo sources/spaces |
| `bi_user` | User | Truy vấn DATA_MART, kết nối BI tools |
| `airflow_svc` | User | Service account cho Airflow DremioClient |

### 6.2 Access Control

```
Space Permissions:
  DATA_MART:      All users → SELECT
  INTEGRATION:    Admin only

Source Permissions:
  minio_lakehouse: Admin only (users truy cập qua views)
  hive_catalog:    Admin only
```

---

## 7. Airflow Variables cho Dremio

Các Airflow Variables cần cấu hình để Dremio integration hoạt động:

| Variable | Default | Mô tả |
|---|---|---|
| `dremio_host` | `http://192.168.1.193` | Dremio base URL (không kèm port) |
| `dremio_username` | `vaultadmin` | Tài khoản Dremio cho API |
| `dremio_password` | _(bắt buộc)_ | Password — lưu trong Airflow Variables |
| `dremio_ssl_verify` | `false` | Verify SSL certificate |
| `dremio_space` | `DATA_MART` | Default space cho views |

> **Lưu ý:** `dremio_host` trong Airflow **không** kèm port. Port `9047` được append trong code `DremioClient`:
> ```python
> 'base_url': Variable.get('dremio_host') + ':9047'
> ```

---

## 8. Tham Số Quan Trọng

### Dremio Server (`dremio.conf`)

| Parameter | Default | Mô tả |
|---|---|---|
| `services.coordinator.enabled` | `true` | Bật coordinator role |
| `services.executor.enabled` | `true` | Bật executor role |
| `paths.dist` | _(configurable)_ | Distributed storage path (MinIO) |
| `paths.local` | `/opt/dremio/data` | Local data directory |
| `registration.publish-host` | auto | Hostname cho cluster registration |

### Query Engine

| Parameter | Default | Khuyến nghị |
|---|---|---|
| `exec.queue.timeout` | `300s` | Timeout cho queued queries |
| `planner.memory.max_query_memory_per_node` | `4096m` | Max memory per query per node |
| `store.parquet.block-size` | `268435456` | Parquet block size (256MB) |
