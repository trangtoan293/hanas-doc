# Integration Guide: NiFi → MinIO

## Tổng Quan

Hướng dẫn cấu hình Apache NiFi để thu thập dữ liệu từ các nguồn khác nhau và ghi vào MinIO (Landing Zone).

```
┌─────────────┐                    ┌──────────────┐                 ┌──────────────┐
│ Data Sources │───── NiFi Flow ──▶│    NiFi       │──── S3 API ──▶│    MinIO      │
│ (DB/File/API)│                   │  Processors   │                │ (Landing Zone)│
└─────────────┘                    └──────────────┘                 └──────────────┘
```

---

## 1. Cấu Hình NiFi Controller Services

### 1.1 S3 Credentials (cho MinIO)

```properties
# Controller Service: AWSCredentialsProviderControllerService
Service Name: MinIO-Credentials
Access Key ID: admin
Secret Access Key: minio_secret_2024
```

### 1.2 JDBC Connection Pool (cho Oracle)

```properties
# Controller Service: DBCPConnectionPool
Service Name: Oracle-JDBC-Pool
Database Connection URL: jdbc:oracle:thin:@//oracle-host:1521/ORCL
Database Driver Class Name: oracle.jdbc.OracleDriver
Database Driver Location(s): /opt/nifi/drivers/ojdbc11.jar
Database User: etl_user
Password: ********
Max Wait Time: 30 sec
Max Total Connections: 10
Validation Query: SELECT 1 FROM DUAL
```

---

## 2. Flow Patterns

### 2.1 Pattern: RDBMS → MinIO (Incremental)

```
QueryDatabaseTable → ConvertRecord → PutS3Object
```

#### QueryDatabaseTable

```properties
Database Connection Pooling Service: Oracle-JDBC-Pool
Database Type: Oracle
Table Name: ${table_name}                           # Dùng variable
Columns to Return:                                  # Để trống = tất cả
Maximum-value Columns: updated_at                   # Incremental column
Initial Max Value: 2024-01-01 00:00:00             # Lần chạy đầu
Max Rows Per Flow File: 50000                       # Batch size
Output Format: Avro
Use Avro Logical Types: true
```

> **Best Practice**: 
> - Dùng `Maximum-value Columns` = cột `updated_at` để chỉ lấy dữ liệu thay đổi
> - `Max Rows Per Flow File` = 50,000 là cân bằng tốt giữa throughput và memory
> - Bật `Avro Logical Types` để giữ đúng kiểu TIMESTAMP, DECIMAL

#### ConvertRecord (Avro → Parquet)

```properties
Record Reader: AvroReader
Record Writer: ParquetRecordSetWriter
```

> **Best Practice**: Chuyển sang Parquet trước khi ghi MinIO giúp tối ưu cho Spark/Dremio đọc.

#### PutS3Object

```properties
Object Key: landing/oracle/${table_name}/load_date=${now():format('yyyy-MM-dd')}/part_${UUID()}.parquet
Bucket: landing
Region: us-east-1
Access Key ID: admin
Secret Access Key: minio_secret_2024
Endpoint Override URL: http://minio:9000
Signer Override: AWSS3V4SignerType
Storage Class: Standard
Server Side Encryption: None
```

### 2.2 Pattern: File (CSV/Excel) → MinIO

```
GetFile / ListFile+FetchFile → ConvertRecord → PutS3Object
```

#### ListFile (watch folder)

```properties
Input Directory: /data/incoming/
File Filter: [^\.].*\.csv
Recurse Subdirectories: false
Minimum File Age: 5 sec            # Chờ file ghi xong
```

#### FetchFile

```properties
Completion Strategy: Move File
Move Destination Directory: /data/processed/
Conflict Resolution Strategy: Rename
```

> **Best Practice**: Luôn move file sau khi xử lý (không delete) để có thể recover nếu cần.

### 2.3 Pattern: REST API → MinIO

```
InvokeHTTP → SplitJSON → ConvertRecord → MergeContent → PutS3Object
```

#### InvokeHTTP

```properties
HTTP Method: GET
Remote URL: https://api.example.com/data?page=${page}&size=1000
HTTP Headers to send: Authorization: Bearer ${api_token}
Content-Type: application/json
```

---

## 3. Quy Ước Đường Dẫn Trên MinIO

```
s3://landing/
├── {source_system}/              # oracle, csv, api, kafka
│   └── {table_name}/            # src_customers, src_accounts
│       └── load_date=YYYY-MM-DD/ # Partition by load date
│           ├── part_uuid1.parquet
│           ├── part_uuid2.parquet
│           └── ...
```

| Quy tắc | Mô tả |
|---|---|
| Source system folder | Phân biệt nguồn dễ quản lý |
| Table name lowercase | Nhất quán, dễ reference |
| Partition by load_date | Airflow/Spark dễ filter |
| UUID in filename | Tránh overwrite khi NiFi retry |
| Parquet format | Tối ưu cho downstream processing |

---

## 4. Error Handling

### 4.1 Retry Strategy

```properties
# Processor Settings
Penalty Duration: 30 sec
Yield Duration: 1 sec
Bulletin Level: WARN

# Relationships
success → next processor
failure → LogAttribute → PutS3Object (error bucket)
retry → self (auto-retry)
```

### 4.2 Dead Letter Queue

```
failure → UpdateAttribute (add error info) → PutS3Object (s3://landing/errors/)
```

---

## 5. Monitoring

### 5.1 Metrics quan trọng

| Metric | Mô tả | Ngưỡng alert |
|---|---|---|
| **FlowFiles In** | Số file đã xử lý | < expected → alert |
| **Bytes Read/Written** | Lượng dữ liệu | Bất thường → alert |
| **Queue Size** | File đang chờ | > 10,000 → alert |
| **Bulletin Count** | Cảnh báo/lỗi | > 0 errors → alert |
| **Back Pressure** | Áp suất ngược | Active → investigate |

### 5.2 NiFi Reporting Task → OpenObserve

```properties
# Controller Service: PrometheusReportingTask
Port: 9092
Send JVM Metrics: true
Instance ID: hanas-nifi-01
```
