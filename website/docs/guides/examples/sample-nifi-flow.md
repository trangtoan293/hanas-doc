# Code Example: NiFi Flow Mẫu — RDBMS → MinIO Landing

---

## 1. Flow: Oracle → MinIO (Incremental Load)

```
┌──────────────────┐     ┌───────────────────┐     ┌──────────────┐
│ QueryDatabase    │────▶│ ConvertAvroTo     │────▶│ PutS3Object  │
│ Table            │     │ Parquet           │     │ (→ MinIO)    │
└──────────────────┘     └───────────────────┘     └──────────────┘
       │                                                  │
  Oracle JDBC Pool                                  s3://landing/
  (incremental via                                  oracle/src_xxx/
   updated_at column)                               load_date=YYYY-MM-DD/
```

### Processor Config

| Processor | Property | Value |
|---|---|---|
| **QueryDatabaseTable** | Table Name | `SRC_CUSTOMERS` |
| | Maximum-value Columns | `updated_at` |
| | Max Rows Per Flow File | `50000` |
| | Output Format | Avro |
| **ConvertRecord** | Record Reader | AvroReader |
| | Record Writer | ParquetRecordSetWriter |
| **PutS3Object** | Bucket | `landing` |
| | Object Key | `oracle/src_customers/load_date=${now():format('yyyy-MM-dd')}/part_${UUID()}.parquet` |
| | Endpoint Override URL | `http://minio:9000` |

---

## 2. Flow: CSV File Upload → MinIO

```
ListFile → FetchFile → ConvertRecord → PutS3Object
```

| Property | Value |
|---|---|
| Input Directory | `/data/incoming/` |
| File Filter | `[^\.].*\.csv` |
| Completion Strategy | Move File |
| Move Destination | `/data/processed/` |

---

## 3. Error Handling Flow

```
Main flow ── failure ──▶ UpdateAttribute ──▶ PutS3Object
                          (add error info)    (s3://landing/errors/)
```

---

## 4. Schedule Patterns

| Pattern | Cron | Mô tả |
|---|---|---|
| **Daily T+1** | `0 0 1 * * ?` | Chạy 1:00 AM hằng ngày |
| **Every 30 min** | `0 */30 * * * ?` | Near real-time |
| **Business hours** | `0 0 8-17 * * MON-FRI` | Chỉ giờ làm việc |
