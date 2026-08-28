# Apache Kafka - Cấu Hình

## 1. Cấu Hình Broker (KRaft Mode)

### 1.1 Tham Số Server Chính

```properties
# === KRaft Mode (thay thế ZooKeeper) ===
process.roles=broker,controller
node.id=1
controller.quorum.bootstrap.servers=kafka-0:9093,kafka-1:9093,kafka-2:9093

# === Network Listeners ===
listeners=PLAINTEXT://:9092,CONTROLLER://:9093
advertised.listeners=PLAINTEXT://kafka-0.kafka.confluent.svc.cluster.local:9092
inter.broker.listener.name=PLAINTEXT
controller.listener.names=CONTROLLER

# === Threading ===
num.network.threads=8
num.io.threads=16
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600

# === Log Storage ===
log.dirs=/var/lib/kafka/data
num.partitions=6
num.recovery.threads.per.data.dir=2

# === Replication ===
default.replication.factor=3
min.insync.replicas=2
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2

# === Log Retention ===
log.retention.hours=168
log.retention.bytes=-1
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000

# === Quan trọng ===
auto.create.topics.enable=false
compression.type=producer
```

### 1.2 Bảng Tham Số Quan Trọng

| Tham Số | Giá Trị | Mô Tả |
|---------|---------|--------|
| `process.roles` | `broker,controller` | KRaft combined mode |
| `num.partitions` | `6` | Default partitions cho topic mới |
| `default.replication.factor` | `3` | Số bản sao mặc định |
| `min.insync.replicas` | `2` | Số replica tối thiểu phải sync |
| `log.retention.hours` | `168` | Giữ data 7 ngày |
| `auto.create.topics.enable` | `false` | **Bắt buộc** tạo topic thủ công |

---

## 2. Cấu Hình Topic

### 2.1 Naming Convention

```
ĐÚNG:
ORACLE.<schema>.<table>              # CDC: ORACLE.DEMO_LAKE.TBL_TRANSACTION
cdc.<db>.<schema>.<table>            # Debezium: cdc.postgres.public.customers
REDO_<GROUP>                         # Redo log: REDO_GROUP3
HEARTBEAT_TOPIC_<GROUP>              # Heartbeat: HEARTBEAT_TOPIC_GROUP3

SAI:
my_topic                             # Không rõ nguồn
test123                              # Không theo convention
```

### 2.2 Tạo Topic

```bash
# CDC Topic — log compaction để giữ latest state
kafka-topics.sh --bootstrap-server kafka:9092 \
  --create --topic ORACLE.DEMO_LAKE.TBL_TRANSACTION \
  --partitions 6 \
  --replication-factor 3 \
  --config cleanup.policy=compact \
  --config min.compaction.lag.ms=86400000 \
  --config retention.ms=604800000

# Event Topic — delete policy
kafka-topics.sh --bootstrap-server kafka:9092 \
  --create --topic events.order.created \
  --partitions 12 \
  --replication-factor 3 \
  --config cleanup.policy=delete \
  --config retention.ms=259200000
```

### 2.3 Config Theo Loại Topic

| Config | CDC Topic | Event Topic | Redo Log Topic |
|--------|-----------|-------------|----------------|
| `cleanup.policy` | `compact` | `delete` | `delete` |
| `retention.ms` | `604800000` (7d) | `259200000` (3d) | `86400000` (1d) |
| `partitions` | 6 | 12 | 1 |
| `replication.factor` | 3 | 3 | 3 |
| `compression.type` | `lz4` | `lz4` | `producer` |

---

## 3. Cấu Hình Oracle CDC Source Connector (V1)

Dưới đây là cấu hình thực tế đang dùng trong platform:

```json
{
  "name": "DEMO_GROUP3",
  "config": {
    "connector.class": "io.confluent.connect.oracle.cdc.OracleCdcSourceConnector",
    "tasks.max": "1",

    "key.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "key.converter.schema.registry.url": "http://schemaregistry.confluent.svc.cluster.local:8081",
    "value.converter.schema.registry.url": "http://schemaregistry.confluent.svc.cluster.local:8081",

    "oracle.server": "<ORACLE_HOST>",
    "oracle.port": "1521",
    "oracle.sid": "ORACLAB",
    "oracle.pdb.name": "DATALAKE",
    "oracle.username": "C##GGADMIN",
    "oracle.password": "********",

    "start.from": "snapshot",
    "db.timezone": "UTC",
    "db.timezone.date": "UTC",
    "oracle.dictionary.mode": "auto",
    "numeric.mapping": "none",
    "oracle.date.mapping": "date",

    "redo.log.topic.name": "REDO_GROUP3",
    "redo.log.row.fetch.size": "1",
    "redo.log.consumer.bootstrap.servers": "kafka.confluent.svc.cluster.local:9071",

    "table.inclusion.regex": "DATALAKE[.]DEMO_LAKE[.](TBL_TRANSACTION)",
    "table.topic.name.template": "ORACLE.${schemaName}.${tableName}",

    "lob.topic.name.template": "${databaseName}.${schemaName}.${tableName}.${columnName}",
    "enable.large.lob.object.support": "true",

    "heartbeat.interval.ms": "30000",
    "heartbeat.topic.name": "HEARTBEAT_TOPIC_GROUP3",

    "connection.pool.max.size": "20",

    "errors.log.enable": "true",
    "errors.log.include.messages": "true"
  }
}
```

### 3.1 Giải Thích Tham Số Oracle CDC

| Tham Số | Giá Trị | Mô Tả |
|---------|---------|--------|
| `oracle.sid` | `ORACLAB` | Oracle SID (non-CDB) hoặc CDB name |
| `oracle.pdb.name` | `DATALAKE` | Pluggable Database name |
| `start.from` | `snapshot` | Snapshot toàn bộ trước, sau đó streaming |
| `oracle.dictionary.mode` | `auto` | Tự động chọn dictionary mode |
| `redo.log.topic.name` | `REDO_GROUP3` | Topic lưu redo log entries |
| `redo.log.consumer.bootstrap.servers` | `kafka...svc:9071` | Kafka bootstrap cho redo log consumer |
| `table.inclusion.regex` | `DATALAKE[.]DEMO_LAKE[.](TBL_TRANSACTION)` | Regex chọn tables cần capture |
| `table.topic.name.template` | `ORACLE.${schemaName}.${tableName}` | Template tên topic — ví dụ: `ORACLE.DEMO_LAKE.TBL_TRANSACTION` |
| `heartbeat.interval.ms` | `30000` | Heartbeat mỗi 30s giữ connector active |
| `enable.large.lob.object.support` | `true` | Hỗ trợ CLOB/BLOB columns |
| `connection.pool.max.size` | `20` | Pool connections tới Oracle |
| `errors.log.enable` | `true` | Log lỗi chi tiết |

> **Lưu ý:** User `C##GGADMIN` cần quyền `SELECT ANY TRANSACTION`, `LOGMINING`, `SELECT_CATALOG_ROLE` trên Oracle.

---

## 4. Cấu Hình Iceberg Sink Connector (V1)

Connector ghi dữ liệu trực tiếp từ Kafka topic vào Iceberg table trên MinIO:

```json
{
  "name": "DEMO_SINK_GROUP2",
  "config": {
    "connector.class": "io.tabular.iceberg.connect.IcebergSinkConnector",
    "tasks.max": "6",

    "key.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "key.converter.schema.registry.url": "http://schemaregistry.confluent.svc.cluster.local:8081",
    "value.converter.schema.registry.url": "http://schemaregistry.confluent.svc.cluster.local:8081",
    "value.converter.schemas.enable": "true",
    "schemas.enable": "true",

    "topics": "ORACLE.DEMO_LAKE.TBL_TRANSACTION",

    "transforms": "offset, cast, Timestamp, cast_opts, op_ts, partitions, insert_timestamp",
    "transforms.offset.type": "org.apache.kafka.connect.transforms.InsertField$Value",
    "transforms.offset.offset.field": "offset",
    "transforms.cast.type": "org.apache.kafka.connect.transforms.Cast$Value",
    "transforms.cast.spec": "current_ts:int64",
    "transforms.Timestamp.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.Timestamp.target.type": "Timestamp",
    "transforms.Timestamp.field": "current_ts",
    "transforms.Timestamp.format": "yyyy-MM-dd HH:mm:ss",
    "transforms.cast_opts.type": "org.apache.kafka.connect.transforms.Cast$Value",
    "transforms.cast_opts.spec": "op_ts:int64",
    "transforms.op_ts.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.op_ts.target.type": "Timestamp",
    "transforms.op_ts.field": "op_ts",
    "transforms.op_ts.format": "yyyy-MM-dd HH:mm:ss",
    "transforms.partitions.type": "org.apache.kafka.connect.transforms.InsertField$Value",
    "transforms.partitions.partition.field": "k_partition",
    "transforms.insert_timestamp.type": "org.apache.kafka.connect.transforms.InsertField$Value",
    "transforms.insert_timestamp.timestamp.field": "k_timestamp",

    "iceberg.tables": "landing.corebank_tbl_transaction",
    "iceberg.tables.auto-create-enabled": "true",
    "iceberg.tables.schema-force-optional": "true",
    "iceberg.tables.evolve-schema-enabled": "true",

    "iceberg.control.topic": "sink_demo_group2",
    "iceberg.control.group-id": "consum_sink_demo_group2",
    "iceberg.control.commit.interval-ms": "0",
    "iceberg.control.commit.timeout-ms": "0",

    "iceberg.catalog.type": "hive",
    "iceberg.catalog.uri": "thrift://<HIVE_METASTORE_HOST>:9083",
    "iceberg.catalog.warehouse": "s3a://data/warehouse",
    "iceberg.catalog.io-impl": "org.apache.iceberg.aws.s3.S3FileIO",
    "iceberg.catalog.s3.endpoint": "http://<MINIO_HOST>:9000",
    "iceberg.catalog.s3.path.style.access": "true",
    "iceberg.catalog.s3.access-key-id": "********",
    "iceberg.catalog.s3.secret-access-key": "********",
    "iceberg.catalog.client.region": "us-east-1",

    "iceberg.hadoop-conf-dir": "/tmp/ext",
    "iceberg.s3a.connection.ssl.enabled": "false"
  }
}
```

### 4.1 Giải Thích SMT Transforms

Pipeline transforms chạy theo thứ tự:

| # | Transform | Chức Năng |
|---|-----------|-----------|
| 1 | `offset` | Thêm Kafka offset vào message value (truy vết nguồn) |
| 2 | `cast` | Cast `current_ts` sang `int64` (chuẩn bị cho timestamp convert) |
| 3 | `Timestamp` | Convert `current_ts` → Timestamp format `yyyy-MM-dd HH:mm:ss` |
| 4 | `cast_opts` | Cast `op_ts` sang `int64` |
| 5 | `op_ts` | Convert `op_ts` (operation timestamp) → Timestamp |
| 6 | `partitions` | Thêm Kafka partition ID vào message (`k_partition`) |
| 7 | `insert_timestamp` | Thêm Kafka timestamp vào message (`k_timestamp`) |

> **Mục đích:** Các metadata fields (`offset`, `k_partition`, `k_timestamp`) giúp truy vết và debug dữ liệu từ Kafka topic đến Iceberg table.

### 4.2 Giải Thích Iceberg Sink Config

| Tham Số | Giá Trị | Mô Tả |
|---------|---------|--------|
| `iceberg.tables` | `landing.corebank_tbl_transaction` | Iceberg table đích (`schema.table`) |
| `iceberg.tables.auto-create-enabled` | `true` | Tự tạo table nếu chưa tồn tại |
| `iceberg.tables.evolve-schema-enabled` | `true` | Tự thêm column mới khi source schema thay đổi |
| `iceberg.tables.schema-force-optional` | `true` | Tất cả columns đều nullable |
| `iceberg.catalog.type` | `hive` | Dùng Hive Metastore làm catalog |
| `iceberg.catalog.uri` | `thrift://<HMS_HOST>:9083` | Hive Metastore endpoint |
| `iceberg.catalog.warehouse` | `s3a://data/warehouse` | Warehouse location trên MinIO |
| `iceberg.catalog.io-impl` | `S3FileIO` | Dùng S3FileIO để ghi file lên MinIO |
| `iceberg.control.topic` | `sink_demo_group2` | Internal control topic cho coordinator |

---

## 5. Cấu Hình Debezium Connector (V2)

### 5.1 PostgreSQL CDC

```json
{
  "name": "hanas-postgres-cdc",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",

    "database.hostname": "postgres.hanas.local",
    "database.port": "5432",
    "database.user": "debezium",
    "database.password": "********",
    "database.dbname": "hanas_prod",

    "topic.prefix": "cdc.postgres",
    "table.include.list": "public.customers,public.orders",
    "plugin.name": "pgoutput",
    "slot.name": "debezium_hanas",

    "snapshot.mode": "initial",
    "tombstones.on.delete": true,
    "heartbeat.interval.ms": "10000",
    "decimal.handling.mode": "double",

    "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
    "schema.history.internal.kafka.topic": "schema-changes.postgres"
  }
}
```

### 5.2 MySQL CDC

```json
{
  "name": "hanas-mysql-cdc",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",

    "database.hostname": "mysql.hanas.local",
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "********",
    "database.server.id": "184054",

    "topic.prefix": "cdc.mysql",
    "database.include.list": "hanas_erp",

    "snapshot.mode": "initial",
    "include.schema.changes": true,
    "tombstones.on.delete": true,

    "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
    "schema.history.internal.kafka.topic": "schema-changes.mysql"
  }
}
```

---

## 6. Cấu Hình Schema Registry (V1)

```properties
SCHEMA_REGISTRY_HOST_NAME=schema-registry
SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS=kafka.confluent.svc.cluster.local:9071
SCHEMA_REGISTRY_LISTENERS=http://0.0.0.0:8081
SCHEMA_REGISTRY_SCHEMA_COMPATIBILITY_LEVEL=BACKWARD
```

**Sử dụng:**

```bash
# Đăng ký Avro schema
curl -X POST http://schemaregistry.confluent.svc.cluster.local:8081/subjects/ORACLE.DEMO_LAKE.TBL_TRANSACTION-value/versions \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{"schema": "{\"type\":\"record\",\"name\":\"TblTransaction\",\"fields\":[...]}"}'

# Liệt kê subjects
curl http://schemaregistry.confluent.svc.cluster.local:8081/subjects

# Lấy schema mới nhất
curl http://schemaregistry.confluent.svc.cluster.local:8081/subjects/ORACLE.DEMO_LAKE.TBL_TRANSACTION-value/versions/latest
```

---

## 7. Cấu Hình AKHQ (V2)

```yaml
akhq:
  connections:
    hanas-kafka:
      properties:
        bootstrap.servers: "hanas-kafka-kafka-bootstrap:9092"
      connect:
        - name: "debezium"
          url: "http://debezium-connect-connect-api:8083"

  pagination:
    page-size: 25

  topic:
    replication: 3
    partition: 6
    internal-regexps:
      - "^_.*$"
      - "^.*\\.internal$"
      - "^connect-.*$"

  topic-data:
    size: 50
    poll-timeout: 1000

  ui-options:
    topic:
      default-view: HIDE_INTERNAL
    topic-data:
      sort: NEWEST

  security:
    default-group: reader
```

---

## 8. Cấu Hình Producer/Consumer

### 8.1 Producer

```properties
acks=all
enable.idempotence=true
retries=2147483647
max.in.flight.requests.per.connection=5
batch.size=16384
linger.ms=5
compression.type=lz4
```

### 8.2 Consumer

```properties
group.id=hanas-consumer-group
auto.offset.reset=earliest
enable.auto.commit=false
max.poll.records=500
session.timeout.ms=45000
heartbeat.interval.ms=15000
```

---

## 9. Cấu Hình Bảo Mật

### 9.1 Credentials

```
ĐÚNG — Sử dụng Kubernetes Secrets
   config.providers: secrets
   config.providers.secrets.class: io.strimzi.kafka.KubernetesSecretConfigProvider
   oracle.password: ${secrets:confluent/oracle-secret:password}

SAI — Hardcode trong config
   oracle.password: <HARDCODED_PASSWORD_EXAMPLE>
   iceberg.catalog.s3.access-key-id: <HARDCODED_ACCESS_KEY_EXAMPLE>
```

> **Quan trọng:** Trong production, tất cả passwords và credentials phải được quản lý qua K8s Secrets hoặc HashiCorp Vault. Không commit credentials vào Git.

### 9.2 TLS & ACL

```bash
# Cấp quyền read cho consumer
kafka-acls.sh --bootstrap-server kafka:9092 \
  --add --allow-principal User:iceberg-sink \
  --consumer --topic 'ORACLE.*' \
  --group sink-consumer-group

# Cấp quyền write cho CDC connector
kafka-acls.sh --bootstrap-server kafka:9092 \
  --add --allow-principal User:oracle-cdc \
  --producer --topic 'ORACLE.*'
```

---

## 10. Service Endpoints Trong Platform

| Service | Endpoint | Namespace |
|---------|----------|-----------|
| **Kafka Broker** | `kafka.confluent.svc.cluster.local:9071` | `confluent` |
| **Schema Registry** | `schemaregistry.confluent.svc.cluster.local:8081` | `confluent` |
| **Kafka Connect** | `connect.confluent.svc.cluster.local:8083` | `confluent` |
| **Hive Metastore** | `thrift://<HMS_HOST>:9083` | — |
| **MinIO** | `http://<MINIO_HOST>` | `minio-tenant` |
| **AKHQ** (V2) | `akhq.kafka.svc.cluster.local:8080` | `kafka` |
