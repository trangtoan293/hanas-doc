# Integration Guide: Kafka Streaming Flow

## Tổng Quan

Hướng dẫn xây dựng luồng streaming real-time/near-real-time sử dụng Kafka + Spark Structured Streaming + Iceberg.

```
Source DB ──CDC──▶ Kafka ──▶ Spark Streaming ──▶ Iceberg (MinIO) ──▶ Dremio
  (Oracle)   Debezium   Topics     Micro-batch      Raw Vault         BI
```

---

## 1. Kiến Trúc Streaming

### 1.1 CDC với Kafka Connect (Debezium)

```json
// Debezium Oracle Connector Config
{
  "name": "oracle-cdc-connector",
  "config": {
    "connector.class": "io.debezium.connector.oracle.OracleConnector",
    "database.hostname": "oracle-host",
    "database.port": "1521",
    "database.user": "cdc_user",
    "database.password": "********",
    "database.dbname": "ORCL",
    "database.server.name": "oracle-prod",
    "schema.include.list": "ETL_SCHEMA",
    "table.include.list": "ETL_SCHEMA.SRC_CUSTOMERS,ETL_SCHEMA.SRC_ACCOUNTS,ETL_SCHEMA.SRC_TRANSACTIONS",
    "database.history.kafka.bootstrap.servers": "kafka:9092",
    "database.history.kafka.topic": "schema-changes",
    "transforms": "unwrap",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "true",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter"
  }
}
```

### 1.2 Kafka Topics

```
Topics:
├── oracle-prod.ETL_SCHEMA.SRC_CUSTOMERS      # CDC events
├── oracle-prod.ETL_SCHEMA.SRC_ACCOUNTS
├── oracle-prod.ETL_SCHEMA.SRC_TRANSACTIONS
├── hanas.streaming.errors                      # Dead letter queue
└── schema-changes                              # Schema evolution
```

---

## 2. Spark Structured Streaming → Iceberg

### 2.1 Consumer: Kafka → Iceberg Hub

```python
# streaming_hub_customer.py
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = (SparkSession.builder
    .appName("streaming-hub-customer")
    .config("spark.sql.catalog.hanas", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.hanas.type", "hadoop")
    .config("spark.sql.catalog.hanas.warehouse", "s3a://warehouse/")
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000")
    .config("spark.hadoop.fs.s3a.access.key", "admin")
    .config("spark.hadoop.fs.s3a.secret.key", "minio_secret_2024")
    .config("spark.hadoop.fs.s3a.path.style.access", "true")
    .config("spark.sql.streaming.checkpointLocation", "s3a://warehouse/checkpoints/")
    .getOrCreate())

# Schema cho Debezium CDC event
cdc_schema = StructType([
    StructField("customer_id", StringType()),
    StructField("full_name", StringType()),
    StructField("email", StringType()),
    StructField("phone", StringType()),
    StructField("city", StringType()),
    StructField("segment", StringType()),
    StructField("__op", StringType()),        # c=create, u=update, d=delete
    StructField("__source_ts_ms", LongType()),
])

# Đọc từ Kafka
df_stream = (spark.readStream
    .format("kafka")
    .option("kafka.bootstrap.servers", "kafka:9092")
    .option("subscribe", "oracle-prod.ETL_SCHEMA.SRC_CUSTOMERS")
    .option("startingOffsets", "latest")
    .option("maxOffsetsPerTrigger", "10000")   # Batch size
    .load()
    .select(
        from_json(col("value").cast("string"), cdc_schema).alias("data"),
        col("timestamp").alias("kafka_ts")
    )
    .select("data.*", "kafka_ts"))

# Transform → Hub (chỉ lấy key, deduplicate)
df_hub = (df_stream
    .filter(col("__op").isin("c", "u"))        # Skip deletes for Hub
    .select("customer_id")
    .withColumn("hub_customer_hk",
        md5(concat_ws("||", lit("CUSTOMER"), "customer_id")))
    .withColumn("load_dts", current_timestamp())
    .withColumn("record_source", lit("CDC.ORACLE.SRC_CUSTOMERS"))
    .dropDuplicates(["hub_customer_hk"]))

# Ghi vào Iceberg (micro-batch)
query = (df_hub.writeStream
    .format("iceberg")
    .outputMode("append")
    .option("checkpointLocation", "s3a://warehouse/checkpoints/hub_customer/")
    .trigger(processingTime="30 seconds")       # Micro-batch mỗi 30s
    .toTable("hanas.raw_vault.hub_customer"))

query.awaitTermination()
```

### 2.2 Consumer: Kafka → Iceberg Satellite (với change detection)

```python
# streaming_sat_customer.py

df_sat = (df_stream
    .filter(col("__op").isin("c", "u"))
    .withColumn("hub_customer_hk",
        md5(concat_ws("||", lit("CUSTOMER"), "customer_id")))
    .withColumn("hash_diff",
        md5(concat_ws("||", "full_name", "email", "phone", "city", "segment")))
    .withColumn("load_dts", current_timestamp())
    .withColumn("load_end_dts", lit(None).cast("timestamp"))
    .withColumn("record_source", lit("CDC.ORACLE.SRC_CUSTOMERS"))
    .select(
        "hub_customer_hk", "load_dts", "load_end_dts",
        "record_source", "hash_diff",
        "full_name", "email", "phone", "city", "segment"
    ))

# Ghi micro-batch
def process_batch(batch_df, batch_id):
    """Custom merge logic: chỉ ghi nếu hash thay đổi"""
    if batch_df.count() == 0:
        return
    
    batch_df.createOrReplaceTempView(f"updates_{batch_id}")
    
    spark.sql(f"""
        MERGE INTO hanas.raw_vault.sat_customer_details AS target
        USING updates_{batch_id} AS source
        ON target.hub_customer_hk = source.hub_customer_hk
           AND target.load_end_dts IS NULL
           AND target.hash_diff = source.hash_diff
        WHEN NOT MATCHED THEN INSERT *
    """)

query = (df_sat.writeStream
    .foreachBatch(process_batch)
    .option("checkpointLocation", "s3a://warehouse/checkpoints/sat_customer/")
    .trigger(processingTime="1 minute")
    .start())

query.awaitTermination()
```

---

## 3. Error Handling

### 3.1 Dead Letter Queue

```python
# Ghi lỗi vào topic riêng
def process_with_dlq(batch_df, batch_id):
    try:
        # Process logic...
        process_batch(batch_df, batch_id)
    except Exception as e:
        # Ghi vào DLQ topic
        error_df = batch_df.withColumn("error", lit(str(e)))
        (error_df.selectExpr("CAST(key AS STRING)", "to_json(struct(*)) AS value")
            .write.format("kafka")
            .option("kafka.bootstrap.servers", "kafka:9092")
            .option("topic", "hanas.streaming.errors")
            .save())
```

### 3.2 Checkpointing

```python
# Checkpoint location cho mỗi streaming query
# QUAN TRỌNG: mỗi query phải có checkpoint riêng
checkpoint_base = "s3a://warehouse/checkpoints/"

# Hub customer → checkpoint riêng
hub_query.option("checkpointLocation", f"{checkpoint_base}/hub_customer/")

# Sat customer → checkpoint riêng
sat_query.option("checkpointLocation", f"{checkpoint_base}/sat_customer/")
```

---

## 4. Monitoring Streaming

### 4.1 Kafka Lag Monitoring

```bash
# Kiểm tra consumer lag
kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
    --group spark-streaming-hub-customer \
    --describe

# Kết quả → lag > 10,000 → alert
```

### 4.2 Spark Streaming Metrics

| Metric | Mô tả | Alert khi |
|---|---|---|
| **Input Rate** | Events/second đọc từ Kafka | Drop đột ngột |
| **Processing Rate** | Events/second xử lý | < Input Rate kéo dài |
| **Batch Duration** | Thời gian micro-batch | > trigger interval |
| **Kafka Lag** | Offset chưa xử lý | > 10,000 |

---

## 5. Best Practices

| Practice | Mô tả |
|---|---|
| **Trigger interval = 30s-5m** | Cân bằng latency vs throughput |
| **maxOffsetsPerTrigger** | Giới hạn batch size, tránh OOM |
| **Checkpoint trên MinIO** | Persist, survive restart |
| **Dead Letter Queue** | Không mất event khi lỗi |
| **Separate queries per entity** | Hub, Sat chạy independent |
| **MERGE cho Sat** | Change detection bằng hash_diff |
| **Monitor Kafka lag** | Alert khi lag tăng |
| **Idempotent writes** | Iceberg MERGE đảm bảo no-duplicate |
