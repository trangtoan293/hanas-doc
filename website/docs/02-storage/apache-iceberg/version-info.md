# Apache Iceberg - Thông Tin Version

## Version Hiện Tại

| Thông tin | Giá trị |
|---|---|
| **Iceberg Format Version** | 2 (row-level deletes) |
| **Iceberg Runtime** | 1.5.x |
| **Spark Version** | 3.5.1 |
| **Hive Metastore** | 3.x |
| **Môi trường** | Kubernetes (`spark-jobs` namespace) |

---

## Compatibility Matrix

### Compute Engines

| Engine | Iceberg Version | Read | Write | DDL | Maintenance |
|---|---|---|---|---|---|
| **Spark 3.5.x** | 1.5.x | ✅ | ✅ | ✅ | ✅ |
| **Dremio** | Built-in | ✅ | ✅ | ✅ | ⚠️ Limited |
| **Trino 4xx** | 1.4+ | ✅ | ✅ | ✅ | ✅ |
| **Flink 1.18+** | 1.5.x | ✅ | ✅ | ✅ | ❌ |
| **Hive 3.x** | 1.5.x | ✅ | ✅ | ✅ | ⚠️ Limited |

### Catalog Types

| Catalog | Được hỗ trợ | Sử dụng trong platform |
|---|---|---|
| **Hive Metastore** | ✅ | ✅ (`demo`, `LakeHouse`, `spark_catalog`) |
| **JDBC** | ✅ | ❌ |
| **REST** | ✅ | ❌ |
| **Hadoop** | ✅ | ❌ |
| **Nessie** | ✅ | ❌ |
| **Glue** | ✅ | ❌ |

### File Formats

| Format | Read | Write | Sử dụng trong platform |
|---|---|---|---|
| **Parquet** | ✅ | ✅ | ✅ (default) |
| **ORC** | ✅ | ✅ | ❌ |
| **Avro** | ✅ | ✅ | ❌ (chỉ metadata) |

### Compression Codecs (Parquet)

| Codec | Hỗ trợ | Sử dụng trong platform |
|---|---|---|
| **zstd** | ✅ | ✅ (khuyến nghị) |
| **snappy** | ✅ | ❌ |
| **gzip** | ✅ | ❌ |
| **lz4** | ✅ | ❌ |
| **uncompressed** | ✅ | ❌ |

---

## Iceberg Format V1 vs V2

| Feature | V1 | V2 |
|---|---|---|
| Append operations | ✅ | ✅ |
| Snapshot isolation | ✅ | ✅ |
| Schema evolution | ✅ | ✅ |
| Partition evolution | ✅ | ✅ |
| Time travel | ✅ | ✅ |
| **Row-level DELETE** | ❌ | ✅ |
| **Row-level UPDATE** | ❌ | ✅ |
| **MERGE INTO** | ❌ | ✅ |
| Position deletes | ❌ | ✅ |
| Equality deletes | ❌ | ✅ |

> **Platform standard:** Tất cả bảng mới phải sử dụng **Format V2**.

---

## Spark - Iceberg JAR Dependencies

| JAR | Mô tả |
|---|---|
| `iceberg-spark-runtime-3.5_2.12` | Iceberg runtime cho Spark 3.5 (Scala 2.12) |
| `iceberg-aws` | S3FileIO implementation |
| `aws-java-sdk-bundle` | AWS SDK cho S3 operations |

> Tất cả JARs đã được bao gồm trong Docker image `trangtoan293/dbt-spark-k8s-ktl:ktl-dbt`.

---

## Lịch Sử Thay Đổi

| Ngày | Thay đổi |
|---|---|
| 2024-01-01 | Initial deployment: Spark 3.5.1 + Iceberg 1.5.x |
| 2024-01-01 | Cấu hình catalogs: `demo`, `LakeHouse`, `spark_catalog` |
| 2024-01-01 | Deploy maintenance DAG: compaction, expire, orphan cleanup |

---

## Tham Khảo

- [Apache Iceberg Official Docs](https://iceberg.apache.org/docs/latest/)
- [Iceberg Spark Configuration](https://iceberg.apache.org/docs/latest/spark-configuration/)
- [Iceberg Spark Procedures](https://iceberg.apache.org/docs/latest/spark-procedures/)
- [Iceberg Table Maintenance](https://iceberg.apache.org/docs/latest/maintenance/)
