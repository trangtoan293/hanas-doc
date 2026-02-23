# Apache Spark - Cấu Hình

## Cấu Hình Cơ Bản (SparkConf)

Tất cả Spark configuration được khai báo trong `spec.sparkConf` của SparkApplication manifest.

### Cấu Hình Thiết Yếu

```yaml
sparkConf:
  # ── Performance ──
  "spark.sql.adaptive.enabled": "true"
  "spark.sql.adaptive.coalescePartitions.enabled": "true"
  "spark.serializer": "org.apache.spark.serializer.KryoSerializer"
  "spark.sql.execution.arrow.pyspark.enabled": "true"

  # ── Hive Metastore ──
  "spark.hadoop.hive.metastore.uris": "thrift://<HIVE_HOST>:9083"
  "spark.sql.warehouse.dir": "s3a://data/warehouse/"

  # ── S3/MinIO ──
  "spark.hadoop.fs.s3a.endpoint": "http://<MINIO_HOST>:9000"
  "spark.hadoop.fs.s3a.path.style.access": "true"
  "spark.hadoop.fs.s3a.ssl.enabled": "false"
  "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
  "spark.hadoop.fs.s3a.aws.credentials.provider": "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"

  # ── Iceberg Extensions ──
  "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"

  # ── Iceberg Catalog: spark_catalog (default Hive) ──
  "spark.sql.catalog.spark_catalog": "org.apache.iceberg.spark.SparkSessionCatalog"
  "spark.sql.catalog.spark_catalog.type": "hive"

  # ── Iceberg Catalog: demo (custom, S3FileIO) ──
  "spark.sql.catalog.demo": "org.apache.iceberg.spark.SparkCatalog"
  "spark.sql.catalog.demo.type": "hive"
  "spark.sql.catalog.demo.uri": "thrift://<HIVE_HOST>:9083"
  "spark.sql.catalog.demo.io-impl": "org.apache.iceberg.aws.s3.S3FileIO"
  "spark.sql.catalog.demo.s3.endpoint": "http://<MINIO_HOST>:9000"
  "spark.sql.catalog.demo.warehouse": "s3a://data/warehouse/"
  "spark.sql.defaultCatalog": "demo"

  # ── Kubernetes ──
  "spark.kubernetes.namespace": "spark-jobs"
  "spark.kubernetes.authenticate.driver.serviceAccountName": "spark"
  "spark.kubernetes.authenticate.executor.serviceAccountName": "spark"

  # ── SQL Settings ──
  "spark.sql.parser.quotedRegexColumnNames": "true"
  "spark.sql.caseSensitive": "false"
  "spark.sql.ansi.enabled": "false"
  "spark.sql.legacy.timeParserPolicy": "LEGACY"
```

---

## Cấu Hình dbt-spark (profiles.yml)

dbt-spark sử dụng method `session` để tận dụng SparkSession do Spark Operator cung cấp:

```yaml
ktl_dbt:
  target: dev
  outputs:
    dev:
      type: spark
      method: session
      schema: "{{ env_var('SCHEMA_NAME') }}"
      host: local[*]
      port: 7077
      threads: 8
      connect_timeout: 60
      connect_retries: 3
      retry_all: true
      conf:
        "spark.hadoop.hive.metastore.uris": "thrift://<HIVE_HOST>:9083"
        "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
        "spark.sql.catalog.demo": "org.apache.iceberg.spark.SparkCatalog"
        "spark.sql.catalog.demo.type": "hive"
        "spark.sql.catalog.demo.uri": "thrift://<HIVE_HOST>:9083"
        "spark.sql.catalog.demo.io-impl": "org.apache.iceberg.aws.s3.S3FileIO"
        "spark.sql.catalog.demo.s3.endpoint": "http://<MINIO_HOST>"
        "spark.sql.catalog.demo.warehouse": "s3a://data/warehouse/"
        "spark.sql.catalog.spark_catalog": "org.apache.iceberg.spark.SparkSessionCatalog"
        "spark.sql.catalog.spark_catalog.type": "hive"
        "spark.hadoop.fs.s3a.endpoint": "http://<MINIO_HOST>"
        "spark.hadoop.fs.s3a.path.style.access": "true"
        "spark.hadoop.fs.s3a.ssl.enabled": "false"
        "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
        "spark.sql.defaultCatalog": "demo"
```

> **Lưu ý**: `SCHEMA_NAME` được inject qua environment variable từ SparkApplication manifest.

### dbt_project.yml – Model Config

```yaml
models:
  ktl_dbt:
    integration:
      +materialized: table
      +file_format: iceberg
      +schema: integration
      +tblproperties:
        "hive.engine.enabled": "true"
        "read.parquet.vectorization.enabled": "true"
        "read.parquet.vectorization.batch-size": "10000"
    data_mart:
      +materialized: table
      +file_format: iceberg
      +schema: data_mart
```

---

## Cấu Hình Nâng Cao

### Adaptive Query Execution (AQE)

```yaml
sparkConf:
  "spark.sql.adaptive.enabled": "true"
  "spark.sql.adaptive.coalescePartitions.enabled": "true"
  "spark.sql.adaptive.advisoryPartitionSizeInBytes": "128MB"
  "spark.sql.adaptive.skewJoin.enabled": "true"
  "spark.sql.adaptive.skewJoin.skewedPartitionFactor": "5"
```

### Shuffle & Memory

```yaml
sparkConf:
  "spark.sql.shuffle.partitions": "200"
  "spark.memory.fraction": "0.6"
  "spark.memory.storageFraction": "0.5"
  "spark.memory.offHeap.enabled": "true"
  "spark.memory.offHeap.size": "2g"
```

### S3 Performance Tuning

```yaml
sparkConf:
  "spark.hadoop.fs.s3a.connection.maximum": "100"
  "spark.hadoop.fs.s3a.threads.max": "50"
  "spark.hadoop.fs.s3a.fast.upload": "true"
  "spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version": "2"
```

### Dynamic Allocation

```yaml
sparkConf:
  "spark.dynamicAllocation.enabled": "true"
  "spark.dynamicAllocation.shuffleTracking.enabled": "true"
  "spark.dynamicAllocation.minExecutors": "2"
  "spark.dynamicAllocation.maxExecutors": "10"
  "spark.dynamicAllocation.executorIdleTimeout": "60s"
```

---

## Cấu Hình Bảo Mật

> ⚠️ **KHÔNG** đặt credentials trong `sparkConf`. Sử dụng `envFrom` với Kubernetes Secrets.

```yaml
# ❌ SAI – Hardcode credentials
sparkConf:
  "spark.hadoop.fs.s3a.access.key": "AKIAIOSFODNN7EXAMPLE"

# ✅ ĐÚNG – Inject qua Secret
driver:
  envFrom:
    - secretRef:
        name: spark-k8s-aws-credentials
executor:
  envFrom:
    - secretRef:
        name: spark-k8s-aws-credentials
```

---

## Resource Sizing (Driver & Executor)

### Development / Test

```yaml
driver:
  cores: 1
  coreLimit: "1000m"
  memory: "1g"
  memoryOverhead: "200m"

executor:
  cores: 1
  coreLimit: "1000m"
  memory: "1g"
  memoryOverhead: "200m"
  instances: 2
```

### Production – Bảng Nhỏ (<1M rows)

```yaml
driver:
  cores: 2
  memory: "4g"
  memoryOverhead: "512m"

executor:
  cores: 2
  memory: "4g"
  memoryOverhead: "512m"
  instances: 5
```

### Production – Bảng Lớn (>10M rows)

```yaml
driver:
  cores: 4
  memory: "8g"
  memoryOverhead: "1g"

executor:
  cores: 4
  memory: "8g"
  memoryOverhead: "1g"
  instances: 10
```

**Công thức tính memoryOverhead:**

```
memoryOverhead = max(memory × 0.1, 384MB)
```

---

## Bảng Tham Số Quan Trọng

| Tham số | Giá trị mặc định | Mô tả |
|---|---|---|
| `spark.sql.adaptive.enabled` | `true` | Bật Adaptive Query Execution |
| `spark.serializer` | `KryoSerializer` | Serializer hiệu năng cao |
| `spark.sql.defaultCatalog` | `demo` | Iceberg catalog mặc định |
| `spark.hadoop.fs.s3a.path.style.access` | `true` | Bắt buộc cho MinIO |
| `spark.hadoop.fs.s3a.ssl.enabled` | `false` | Tắt SSL cho MinIO nội bộ |
| `spark.sql.extensions` | `IcebergSparkSessionExtensions` | Bật Iceberg SQL extensions |
| `spark.kubernetes.namespace` | `spark-jobs` | Namespace cho Spark pods |
| `spark.sql.shuffle.partitions` | `200` | Số partitions khi shuffle |
| `spark.sql.autoBroadcastJoinThreshold` | `10MB` | Threshold broadcast join |
