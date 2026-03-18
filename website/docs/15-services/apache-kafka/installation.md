# Apache Kafka - Cài Đặt & Triển Khai

## Yêu Cầu Hệ Thống

### Phần Cứng Tối Thiểu (Per Broker)

| Tài Nguyên | Development | Production |
|------------|-------------|------------|
| **CPU** | 2 cores | 8+ cores |
| **RAM** | 4 GB | 16–32 GB |
| **Disk** | 50 GB SSD | 500 GB+ SSD/NVMe |
| **Network** | 1 Gbps | 10 Gbps |

> **Lưu ý**: Kafka sử dụng OS page cache nên cần nhiều RAM. Tối thiểu 50% RAM dành cho page cache, JVM heap chỉ cần 6–8 GB.

### Phần Mềm

| Phần mềm | Version |
|-----------|---------|
| **Java** | JDK 17+ (recommended) |
| **Kubernetes** | 1.25+ |
| **Helm** | 3.x |
| **Docker** | 24+ (cho dev/test) |

---

## V1 — Confluent Kafka

### Cài Đặt Trên Kubernetes (Confluent for Kubernetes)

#### Bước 1: Thêm Helm Repository

```bash
# Thêm Confluent Helm repo
helm repo add confluentinc https://packages.confluent.io/helm
helm repo update
```

#### Bước 2: Cài Đặt Confluent Operator

```bash
# Tạo namespace
kubectl create namespace confluent

# Cài Confluent for Kubernetes operator
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes \
  --namespace confluent \
  --set namespaced=false
```

#### Bước 3: Triển Khai Kafka Cluster

```yaml
# confluent-platform.yaml
apiVersion: platform.confluent.io/v1beta1
kind: Kafka
metadata:
  name: kafka
  namespace: confluent
spec:
  replicas: 3
  image:
    application: confluentinc/cp-server:7.7.0
    init: confluentinc/confluent-init-container:2.9.0
  dataVolumeCapacity: 100Gi
  configOverrides:
    server:
      - "log.retention.hours=168"
      - "num.partitions=6"
      - "default.replication.factor=3"
      - "min.insync.replicas=2"
      - "auto.create.topics.enable=false"
  metrics:
    prometheus:
      whitelist:
        - "kafka.server:type=BrokerTopicMetrics,*"
        - "kafka.server:type=ReplicaManager,*"
---
apiVersion: platform.confluent.io/v1beta1
kind: SchemaRegistry
metadata:
  name: schemaregistry
  namespace: confluent
spec:
  replicas: 2
  image:
    application: confluentinc/cp-schema-registry:7.7.0
    init: confluentinc/confluent-init-container:2.9.0
---
apiVersion: platform.confluent.io/v1beta1
kind: ControlCenter
metadata:
  name: controlcenter
  namespace: confluent
spec:
  replicas: 1
  image:
    application: confluentinc/cp-enterprise-control-center:7.7.0
    init: confluentinc/confluent-init-container:2.9.0
  dataVolumeCapacity: 10Gi
---
apiVersion: platform.confluent.io/v1beta1
kind: Connect
metadata:
  name: connect
  namespace: confluent
spec:
  replicas: 2
  image:
    application: confluentinc/cp-server-connect:7.7.0
    init: confluentinc/confluent-init-container:2.9.0
  build:
    type: onDemand
    onDemand:
      plugins:
        locationType: confluentHub
        confluentHub:
          - owner: debezium
            name: debezium-connector-postgresql
            version: "2.5.4"
          - owner: confluentinc
            name: kafka-connect-s3
            version: "10.5.7"
```

```bash
# Apply manifest
kubectl apply -f confluent-platform.yaml
```

#### Bước 4: Kiểm Tra Triển Khai

```bash
# Kiểm tra pods
kubectl get pods -n confluent

# Expected output:
# kafka-0                    1/1     Running   
# kafka-1                    1/1     Running   
# kafka-2                    1/1     Running   
# schemaregistry-0           1/1     Running   
# controlcenter-0            1/1     Running   
# connect-0                  1/1     Running   
```

### Cài Đặt Docker Compose (Dev/Test)

```yaml
# docker-compose-confluent.yml
version: "3.8"
services:
  kafka-1:
    image: confluentinc/cp-server:7.7.0
    hostname: kafka-1
    ports:
      - "9092:9092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_QUORUM_VOTERS: "1@kafka-1:9093,2@kafka-2:9093,3@kafka-3:9093"
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-1:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_LOG_DIRS: /var/lib/kafka/data
      KAFKA_NUM_PARTITIONS: 3
      KAFKA_DEFAULT_REPLICATION_FACTOR: 3
      KAFKA_MIN_INSYNC_REPLICAS: 2
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "false"
      CLUSTER_ID: "MkU3OEVBNTcwNTJENDM2Qk"
    volumes:
      - kafka-1-data:/var/lib/kafka/data

  kafka-2:
    image: confluentinc/cp-server:7.7.0
    hostname: kafka-2
    ports:
      - "9093:9092"
    environment:
      KAFKA_NODE_ID: 2
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_QUORUM_VOTERS: "1@kafka-1:9093,2@kafka-2:9093,3@kafka-3:9093"
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-2:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_LOG_DIRS: /var/lib/kafka/data
      CLUSTER_ID: "MkU3OEVBNTcwNTJENDM2Qk"
    volumes:
      - kafka-2-data:/var/lib/kafka/data

  kafka-3:
    image: confluentinc/cp-server:7.7.0
    hostname: kafka-3
    ports:
      - "9094:9092"
    environment:
      KAFKA_NODE_ID: 3
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_QUORUM_VOTERS: "1@kafka-1:9093,2@kafka-2:9093,3@kafka-3:9093"
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-3:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_LOG_DIRS: /var/lib/kafka/data
      CLUSTER_ID: "MkU3OEVBNTcwNTJENDM2Qk"
    volumes:
      - kafka-3-data:/var/lib/kafka/data

  schema-registry:
    image: confluentinc/cp-schema-registry:7.7.0
    hostname: schema-registry
    depends_on:
      - kafka-1
      - kafka-2
      - kafka-3
    ports:
      - "8081:8081"
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: kafka-1:9092,kafka-2:9092,kafka-3:9092
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081

  control-center:
    image: confluentinc/cp-enterprise-control-center:7.7.0
    hostname: control-center
    depends_on:
      - kafka-1
      - schema-registry
    ports:
      - "9021:9021"
    environment:
      CONTROL_CENTER_BOOTSTRAP_SERVERS: kafka-1:9092,kafka-2:9092,kafka-3:9092
      CONTROL_CENTER_SCHEMA_REGISTRY_URL: http://schema-registry:8081
      CONTROL_CENTER_REPLICATION_FACTOR: 3

volumes:
  kafka-1-data:
  kafka-2-data:
  kafka-3-data:
```

```bash
# Khởi chạy
docker compose -f docker-compose-confluent.yml up -d

# Kiểm tra
docker compose -f docker-compose-confluent.yml ps
```

---

## V2 — Apache Kafka + Debezium + AKHQ

### Cài Đặt Trên Kubernetes (Strimzi Operator)

#### Bước 1: Cài Đặt Strimzi Operator

```bash
# Tạo namespace
kubectl create namespace kafka

# Cài Strimzi operator
helm repo add strimzi https://strimzi.io/charts/
helm repo update

helm upgrade --install strimzi-operator strimzi/strimzi-kafka-operator \
  --namespace kafka \
  --set watchNamespaces="{kafka}"
```

#### Bước 2: Triển Khai Kafka Cluster (KRaft)

```yaml
# kafka-cluster.yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaNodePool
metadata:
  name: controller
  namespace: kafka
  labels:
    strimzi.io/cluster: hanas-kafka
spec:
  replicas: 3
  roles:
    - controller
  storage:
    type: persistent-claim
    size: 10Gi
    class: standard
---
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaNodePool
metadata:
  name: broker
  namespace: kafka
  labels:
    strimzi.io/cluster: hanas-kafka
spec:
  replicas: 3
  roles:
    - broker
  storage:
    type: persistent-claim
    size: 100Gi
    class: standard
---
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: hanas-kafka
  namespace: kafka
  annotations:
    strimzi.io/kraft: enabled
    strimzi.io/node-pools: enabled
spec:
  kafka:
    version: 3.8.0
    metadataVersion: "3.8"
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    config:
      num.partitions: 6
      default.replication.factor: 3
      min.insync.replicas: 2
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      log.retention.hours: 168
      log.segment.bytes: 1073741824
      auto.create.topics.enable: false
    metricsConfig:
      type: jmxPrometheusExporter
      valueFrom:
        configMapKeyRef:
          name: kafka-metrics
          key: kafka-metrics-config.yml
  entityOperator:
    topicOperator: {}
    userOperator: {}
```

```bash
kubectl apply -f kafka-cluster.yaml
```

#### Bước 3: Triển Khai Kafka Connect + Debezium

```yaml
# kafka-connect-debezium.yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaConnect
metadata:
  name: debezium-connect
  namespace: kafka
  annotations:
    strimzi.io/use-connector-resources: "true"
spec:
  version: 3.8.0
  replicas: 2
  bootstrapServers: hanas-kafka-kafka-bootstrap:9092
  config:
    group.id: debezium-connect-cluster
    offset.storage.topic: debezium-connect-offsets
    config.storage.topic: debezium-connect-configs
    status.storage.topic: debezium-connect-status
    config.storage.replication.factor: 3
    offset.storage.replication.factor: 3
    status.storage.replication.factor: 3
    key.converter: org.apache.kafka.connect.json.JsonConverter
    value.converter: org.apache.kafka.connect.json.JsonConverter
    key.converter.schemas.enable: true
    value.converter.schemas.enable: true
    config.providers: secrets
    config.providers.secrets.class: io.strimzi.kafka.KubernetesSecretConfigProvider
  build:
    output:
      type: docker
      image: registry.local/debezium-connect:latest
    plugins:
      - name: debezium-postgresql
        artifacts:
          - type: tgz
            url: https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.7.3.Final/debezium-connector-postgres-2.7.3.Final-plugin.tar.gz
      - name: debezium-mysql
        artifacts:
          - type: tgz
            url: https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/2.7.3.Final/debezium-connector-mysql-2.7.3.Final-plugin.tar.gz
      - name: debezium-oracle
        artifacts:
          - type: tgz
            url: https://repo1.maven.org/maven2/io/debezium/debezium-connector-oracle/2.7.3.Final/debezium-connector-oracle-2.7.3.Final-plugin.tar.gz
```

```bash
kubectl apply -f kafka-connect-debezium.yaml
```

#### Bước 4: Triển Khai AKHQ

```yaml
# akhq.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: akhq
  namespace: kafka
spec:
  replicas: 1
  selector:
    matchLabels:
      app: akhq
  template:
    metadata:
      labels:
        app: akhq
    spec:
      containers:
        - name: akhq
          image: tchiotludo/akhq:latest
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: config
              mountPath: /app/application.yml
              subPath: application.yml
      volumes:
        - name: config
          configMap:
            name: akhq-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: akhq-config
  namespace: kafka
data:
  application.yml: |
    akhq:
      connections:
        hanas-kafka:
          properties:
            bootstrap.servers: "hanas-kafka-kafka-bootstrap:9092"
          connect:
            - name: "debezium"
              url: "http://debezium-connect-connect-api:8083"
      security:
        default-group: reader
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
---
apiVersion: v1
kind: Service
metadata:
  name: akhq
  namespace: kafka
spec:
  selector:
    app: akhq
  ports:
    - port: 8080
      targetPort: 8080
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: akhq
  namespace: kafka
spec:
  rules:
    - host: akhq.hanas.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: akhq
                port:
                  number: 8080
```

```bash
kubectl apply -f akhq.yaml
```

### Cài Đặt Docker Compose (Dev/Test)

```yaml
# docker-compose-kafka-cdc.yml
version: "3.8"
services:
  kafka:
    image: apache/kafka:3.8.0
    hostname: kafka
    ports:
      - "9092:9092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_QUORUM_VOTERS: "1@kafka:9093"
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093,EXTERNAL://0.0.0.0:29092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,EXTERNAL://localhost:29092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_LOG_DIRS: /var/lib/kafka/data
      KAFKA_NUM_PARTITIONS: 3
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "false"
      CLUSTER_ID: "MkU3OEVBNTcwNTJENDM2Qk"
    volumes:
      - kafka-data:/var/lib/kafka/data

  debezium-connect:
    image: debezium/connect:2.7
    hostname: debezium-connect
    depends_on:
      - kafka
    ports:
      - "8083:8083"
    environment:
      BOOTSTRAP_SERVERS: kafka:9092
      GROUP_ID: debezium-connect
      CONFIG_STORAGE_TOPIC: debezium-configs
      OFFSET_STORAGE_TOPIC: debezium-offsets
      STATUS_STORAGE_TOPIC: debezium-status
      KEY_CONVERTER_SCHEMAS_ENABLE: "true"
      VALUE_CONVERTER_SCHEMAS_ENABLE: "true"

  akhq:
    image: tchiotludo/akhq:latest
    hostname: akhq
    depends_on:
      - kafka
    ports:
      - "8080:8080"
    environment:
      AKHQ_CONFIGURATION: |
        akhq:
          connections:
            local-kafka:
              properties:
                bootstrap.servers: "kafka:9092"
              connect:
                - name: "debezium"
                  url: "http://debezium-connect:8083"

volumes:
  kafka-data:
```

```bash
# Khởi chạy
docker compose -f docker-compose-kafka-cdc.yml up -d

# Kiểm tra
docker compose -f docker-compose-kafka-cdc.yml ps
```

---

## Kiểm Tra Sau Cài Đặt

### 1. Kiểm Tra Kafka Cluster

```bash
# V1 — Confluent
docker exec -it kafka-1 kafka-metadata --snapshot /var/lib/kafka/data/__cluster_metadata-0/00000000000000000000.log --cluster-id

# V2 — Apache Kafka (Strimzi trên K8s)
kubectl exec -it hanas-kafka-broker-0 -n kafka -- bin/kafka-metadata.sh --snapshot /var/lib/kafka/data/__cluster_metadata-0/00000000000000000000.log --cluster-id
```

### 2. Tạo Topic Test

```bash
# Tạo topic
kafka-topics.sh --bootstrap-server localhost:9092 \
  --create --topic test-ingestion \
  --partitions 3 \
  --replication-factor 3

# Liệt kê topics
kafka-topics.sh --bootstrap-server localhost:9092 --list

# Mô tả topic
kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic test-ingestion
```

### 3. Test Produce/Consume

```bash
# Gửi message
echo "Hello Hanas Platform" | kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-ingestion

# Đọc message
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-ingestion \
  --from-beginning
```

### 4. Kiểm Tra Debezium Connect (V2)

```bash
# Kiểm tra Kafka Connect status
curl -s http://localhost:8083/ | jq .

# Liệt kê connector plugins
curl -s http://localhost:8083/connector-plugins | jq '.[].class'

# Expected output:
# "io.debezium.connector.postgresql.PostgresConnector"
# "io.debezium.connector.mysql.MySqlConnector"
```

### 5. Kiểm Tra AKHQ (V2)

```bash
# Mở browser
open http://localhost:8080

# Hoặc trên K8s
open http://akhq.hanas.local
```

Truy cập AKHQ GUI sẽ hiển thị:
- Danh sách topics
- Consumer groups
- Kafka Connect connectors
- Cluster nodes status

### 6. Kiểm Tra Control Center (V1)

```bash
# Mở browser
open http://localhost:9021
```

Control Center hiển thị:
- Cluster overview (brokers, topics, consumers)
- Broker metrics (throughput, latency)
- Topic inspection
- Consumer lag monitoring
- Schema Registry integration
