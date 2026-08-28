# Apache Kafka - Thông Tin Version

## Version Hiện Tại

### V1 — Confluent Kafka

| Thành Phần | Version | Ghi Chú |
|------------|---------|---------|
| **Confluent Platform** | 7.7.x | Enterprise distribution |
| **Kafka Broker** | 3.7.x | Bundled với Confluent 7.7 |
| **Schema Registry** | 7.7.x | Avro, Protobuf, JSON Schema |
| **Control Center** | 7.7.x | GUI management |
| **Kafka Connect** | 7.7.x | Connector framework |
| **Confluent for Kubernetes** | 2.9.x | K8s operator |

### V2 — Apache Kafka + Debezium + AKHQ

| Thành Phần | Version | Ghi Chú |
|------------|---------|---------|
| **Apache Kafka** | 3.8.x | KRaft mode (không ZooKeeper) |
| **Strimzi Operator** | 0.43.x | K8s operator cho Kafka |
| **Debezium** | 2.7.x | CDC connectors |
| **AKHQ** | 0.25.x | Web GUI management |
| **Java Runtime** | JDK 17+ | Recommended |

### Thông Tin Triển Khai

| Thông tin | Giá trị |
|-----------|---------|
| **Môi trường** | Kubernetes |
| **Namespace** | `confluent` (V1) / `kafka` (V2) |
| **Mode** | KRaft (không ZooKeeper) |
| **Replicas** | 3 brokers |

---

## Lịch Sử Thay Đổi

| Ngày | Version | Thay Đổi |
|------|---------|----------|
| 2026-03 | Initial | Viết tài liệu đầy đủ cho 2 phiên bản |

---

## Tương Thích (Compatibility Matrix)

### Với Hanas Platform Components

| Component | Tương Thích | Ghi Chú |
|-----------|-------------|---------|
| **MinIO** | Có | Kafka Connect S3 Sink → MinIO |
| **Apache Iceberg** | Có | Kafka → Spark Structured Streaming → Iceberg |
| **Apache Spark** | Có | Spark Streaming consumer, batch consumer |
| **Apache Airflow** | Có | KafkaSensor, KafkaTrigger, DAG scheduling |
| **Apache NiFi** | Có | ConsumeKafka processor, PublishKafka processor |
| **DataHub** | Có | Kafka metadata ingestion, lineage tracking |
| **Dremio** | Hạn chế | Dremio đọc Iceberg tables (không đọc Kafka trực tiếp) |
| **OpenObserve** | Có | JMX metrics → Prometheus → OpenObserve |

### Debezium Connector Compatibility

| Database | Connector | Version | Ghi Chú |
|----------|-----------|---------|---------|
| **PostgreSQL** | `debezium-connector-postgres` | 2.7.x | Yêu cầu `wal_level=logical` |
| **MySQL** | `debezium-connector-mysql` | 2.7.x | Yêu cầu binlog enabled |
| **Oracle** | `debezium-connector-oracle` | 2.7.x | Yêu cầu LogMiner hoặc XStream |
| **SQL Server** | `debezium-connector-sqlserver` | 2.7.x | Yêu cầu CDC enabled |
| **MongoDB** | `debezium-connector-mongodb` | 2.7.x | Change streams |

### Protocol & Format Support

| Protocol/Format | Kafka | Confluent | Debezium |
|-----------------|-------|-----------|----------|
| **Avro** | Có | Có (Schema Registry) | Có |
| **Protobuf** | Có | Có (Schema Registry) | Có |
| **JSON** | Có | Có | Có (default) |
| **JSON Schema** | Có | Có (Schema Registry) | Có |
| **TLS/SSL** | Có | Có | Có |
| **SASL/SCRAM** | Có | Có | Có |
| **mTLS** | Có | Có | Có |
| **ACL** | Có | Có (+ RBAC) | N/A |

---

## Upgrade Path

### Apache Kafka

```
Kafka 3.6 → 3.7 → 3.8 (minor version rolling upgrade)
- Rolling restart, không cần downtime
- Upgrade từng broker, chờ ISR sync
- Upgrade inter.broker.protocol.version sau khi tất cả broker lên version mới
```

### Debezium

```
Debezium 2.5 → 2.6 → 2.7 (minor version upgrade)
- Stop connector → Update image → Restart connector
- Kiểm tra connector status sau restart
- Snapshot vẫn resume từ last offset
```

### AKHQ

```
AKHQ 0.24 → 0.25 (update Docker image)
- Stateless application, chỉ cần restart
- Config không thay đổi giữa minor versions
```

---

## Tài Liệu Tham Khảo

| Tài liệu | Link |
|-----------|------|
| Apache Kafka Documentation | [kafka.apache.org/documentation](https://kafka.apache.org/documentation/) |
| Confluent Platform Documentation | [docs.confluent.io](https://docs.confluent.io/) |
| Debezium Documentation | [debezium.io/documentation](https://debezium.io/documentation/) |
| AKHQ Documentation | [akhq.io/docs](https://akhq.io/docs/) |
| Strimzi Documentation | [strimzi.io/documentation](https://strimzi.io/documentation/) |
| Kafka KRaft Guide | [kafka.apache.org/documentation/#kraft](https://kafka.apache.org/documentation/#kraft) |
