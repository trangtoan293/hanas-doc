# Apache Iceberg - Thông Tin Version

## Version Hiện Tại

| Thông tin | Giá trị |
|---|---|
| **Iceberg Format Version** | 2 (row-level deletes) |
| **Iceberg Runtime** | 1.8.1 theo runtime Spark chuẩn của platform |
| **Spark Version** | 3.5.1 |
| **Catalog** | Hive Metastore cho quickstart; Apache Polaris REST Catalog cho production nếu profile này được phê duyệt |
| **Môi trường** | Kubernetes (`spark-jobs` namespace) |

---

## Compatibility Matrix

### Compute Engines

| Engine | Iceberg Version | Read | Write | DDL | Maintenance |
|---|---|---|---|---|---|
| **Spark 3.5.x** | 1.8.1 | Có | Có | Có | Có |
| **Dremio** | Built-in | Có | Có | Có | Limited |
| **Trino 4xx** | 1.4+ | Có | Có | Có | Có |
| **Flink 1.18+** | 1.5.x | Có | Có | Có | Không |
| **Hive 3.x** | Theo runtime được đóng gói | Có | Có | Có | Limited |

### Catalog Types

| Catalog | Được hỗ trợ | Sử dụng trong platform |
|---|---|---|
| **Hive Metastore** | Có | Có (`demo`, `LakeHouse`, `spark_catalog`) |
| **JDBC** | Có | Không |
| **REST** | Có | Không |
| **Hadoop** | Có | Không |
| **Nessie** | Có | Không |
| **Glue** | Có | Không |

### File Formats

| Format | Read | Write | Sử dụng trong platform |
|---|---|---|---|
| **Parquet** | Có | Có | Có (default) |
| **ORC** | Có | Có | Không |
| **Avro** | Có | Có | Không (chỉ metadata) |

### Compression Codecs (Parquet)

| Codec | Hỗ trợ | Sử dụng trong platform |
|---|---|---|
| **zstd** | Có | Có (khuyến nghị) |
| **snappy** | Có | Không |
| **gzip** | Có | Không |
| **lz4** | Có | Không |
| **uncompressed** | Có | Không |

---

## Iceberg Format V1 vs V2

| Feature | V1 | V2 |
|---|---|---|
| Append operations | Có | Có |
| Snapshot isolation | Có | Có |
| Schema evolution | Có | Có |
| Partition evolution | Có | Có |
| Time travel | Có | Có |
| **Row-level DELETE** | Không | Có |
| **Row-level UPDATE** | Không | Có |
| **MERGE INTO** | Không | Có |
| Position deletes | Không | Có |
| Equality deletes | Không | Có |

> **Platform standard:** Tất cả bảng mới phải sử dụng **Format V2**.

---

## Spark - Iceberg JAR Dependencies

| JAR | Mô tả |
|---|---|
| `iceberg-spark-runtime-3.5_2.12` | Iceberg runtime cho Spark 3.5 (Scala 2.12) |
| `iceberg-aws` | S3FileIO implementation |
| `aws-java-sdk-bundle` | AWS SDK cho S3 operations |

> Tất cả JARs phải được kiểm tra trong Docker image Spark đã phê duyệt: `<REGISTRY>/<NAMESPACE>/dbt-spark-k8s-ktl:<PINNED_TAG>`.

---

## Lịch Sử Thay Đổi

| Ngày | Thay đổi |
|---|---|
| 2024-01-01 | Initial deployment: Spark 3.5.1 + Iceberg runtime theo image |
| 2024-01-01 | Cấu hình catalogs: `demo`, `LakeHouse`, `spark_catalog` |
| 2024-01-01 | Deploy maintenance DAG: compaction, expire, orphan cleanup |

---

## Tham Khảo

- [Apache Iceberg Official Docs](https://iceberg.apache.org/docs/latest/)
- [Iceberg Spark Configuration](https://iceberg.apache.org/docs/latest/spark-configuration/)
- [Iceberg Spark Procedures](https://iceberg.apache.org/docs/latest/spark-procedures/)
- [Iceberg Table Maintenance](https://iceberg.apache.org/docs/latest/maintenance/)
