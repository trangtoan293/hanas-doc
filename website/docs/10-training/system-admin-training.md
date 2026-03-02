# Đào Tạo Quản Trị Hệ Thống & Hạ Tầng

## Tổng Quan

| Thông tin | Chi tiết |
|-----------|---------|
| **Đối tượng** | IT Admin, DevOps Engineer, System Engineer |
| **Thời lượng** | 2 tuần (full-time) |
| **Lịch học** | Mỗi ngày 8 giờ: 4 giờ theory + 4 giờ hands-on |
| **Điều kiện** | Kiến thức Linux, Docker, networking cơ bản |

## Kết Quả Sau Đào Tạo

Sau 2 tuần, học viên có khả năng:

- Quản trị cụm Kubernetes và toàn bộ services của Hanas
- Triển khai namespace mới cho khách hàng (deploy core services, monitoring, alerts)
- Giám sát hệ thống thông qua OpenObserve
- Thực hiện backup/restore với Velero và MinIO Site Replication
- Quản lý bảo mật: RBAC, network policies, secrets management
- Xử lý sự cố hạ tầng cơ bản

---

## Tuần 1: Quản Trị Hạ Tầng

### Ngày 1-2: Kubernetes & Container (16 giờ)

#### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| K8s Architecture | Control plane, worker nodes, etcd | 2 giờ |
| Core Objects | Pod, Deployment, StatefulSet, Service, Ingress | 3 giờ |
| Namespace Management | Tạo namespace per customer, resource quotas, limit ranges | 2 giờ |
| Storage | PersistentVolume, PVC, StorageClass | 1 giờ |

#### Hands-on

```bash
# Tạo namespace cho customer
kubectl create namespace hanas-customer-demo
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: resource-quota
  namespace: hanas-customer-demo
spec:
  hard:
    cpu: "16"
    memory: 32Gi
    pods: "50"
EOF

# Verify
kubectl describe namespace hanas-customer-demo
kubectl top nodes
kubectl describe nodes | grep "Allocated resources"
```

📖 Tài liệu: [Hạ tầng — Kubernetes](../08-infrastructure/README.md)

---

### Ngày 3-4: Quản Trị Data Platform Services (16 giờ)

#### Nội dung

Quản trị toàn bộ services trong kiến trúc Hanas:

| Lớp | Service | Quản trị |
|-----|---------|----------|
| 1 - Ingestion | Apache NiFi | Processor groups, controller services, backpressure |
| 1 - Ingestion | Apache Kafka | Brokers, topics, consumer groups, CDC connectors (Oracle CDC Source, Iceberg Sink), Schema Registry, AKHQ/Control Center |
| 2 - Storage | MinIO | Buckets, policies, erasure coding, site replication |
| 2 - Storage | Apache Iceberg | Table maintenance, compaction, snapshot management |
| 3 - Processing | Apache Airflow | Connections, variables, pools, DAG deployment |
| 3 - Processing | Apache Spark | Spark Operator, resource allocation, job monitoring |
| 5 - Governance | DataHub | Ingestion sources, metadata sync |
| 6 - Federation | Dremio | Sources, reflections, user management |
| AI Service | Dify, vLLM, Langfuse | Model deployment, API keys, tracing config |

#### Hands-on: Deploy Core Services cho Customer Mới

```bash
# Deploy MinIO
kubectl apply -k customers/demo/overlays/production/minio/
kubectl get pods -n hanas-customer-demo -l app=minio

# Deploy Airflow
kubectl apply -k customers/demo/overlays/production/airflow/
kubectl wait --for=condition=ready pod -l app=airflow-webserver \
  -n hanas-customer-demo --timeout=300s

# Deploy Spark Operator
kubectl apply -f components/spark-operator/
kubectl get pods -n hanas-customer-demo -l app.kubernetes.io/name=spark-operator

# Tạo MinIO buckets
mc alias set demo-minio http://minio.hanas-customer-demo.svc:9000 ACCESS SECRET
mc mb demo-minio/landing
mc mb demo-minio/raw-vault
mc mb demo-minio/business-vault
mc mb demo-minio/information-mart
```

📖 Tài liệu tham khảo:
- [MinIO](../02-storage/minio/README.md)
- [Airflow](../03-processing/apache-airflow/README.md)
- [Spark](../03-processing/apache-spark/README.md)
- [AI Service](../12-ai-service/README.md)

---

### Ngày 5: Smoke Tests & Validation (8 giờ)

#### Nội dung

Sau khi deploy services, chạy smoke tests để xác nhận hoạt động:

```bash
# Test MinIO
./tests/smoke/minio.sh customer-demo

# Test Airflow
./tests/smoke/airflow.sh customer-demo

# Test Spark
./tests/smoke/spark.sh customer-demo

# Test Dremio
./tests/smoke/dremio.sh customer-demo

# Test Kafka & Connectors
kafka-topics.sh --bootstrap-server kafka:9092 --list
curl -s http://connect:8083/connectors | jq .
curl -s http://connect:8083/connectors/DEMO_GROUP3/status | jq '.connector.state'
```

#### End-to-End Pipeline Test

```bash
# Upload test data → Trigger DAG → Monitor → Query
mc cp test-data/customers.csv demo-minio/landing/

kubectl exec -n hanas-customer-demo deployment/airflow-webserver -- \
  airflow dags trigger test_pipeline

# Verify
# SELECT * FROM raw_vault.hub_customer LIMIT 10;
```

---

## Tuần 2: Monitoring, Security & DR

### Ngày 6-7: Monitoring & Alerting (16 giờ)

#### Nội dung

| Chủ đề | Nội dung |
|--------|---------|
| OpenObserve | Log collection, metrics dashboards, traces |
| Golden Signals | Latency, Traffic, Errors, Saturation |
| Dashboard Design | Executive, technical, customer-specific dashboards |
| Alert Configuration | Classification (P1/P2/P3), routing, escalation |

#### Hands-on

```bash
# Tạo dashboards cho customer
./scripts/create-dashboard.sh customer-demo

# Cấu hình alerts
kubectl apply -f customers/demo/monitoring/alerts.yaml

# Test alert
./scripts/test-alert.sh customer-demo DataFreshnessSLABreach
```

📖 Tài liệu: [OpenObserve Documentation](../07-system-management/openobserve/README.md)

---

### Ngày 8-9: Security & Access Control (16 giờ)

#### Nội dung

| Chủ đề | Nội dung |
|--------|---------|
| Kubernetes RBAC | Roles, RoleBindings, ServiceAccounts |
| Network Policies | Ingress/Egress rules, namespace isolation |
| Apache Ranger | Data access policies, column-level security |
| HashiCorp Vault | Secrets management, dynamic credentials |
| Encryption | TLS 1.3, encryption at rest, customer-managed keys |
| Scanning | Trivy (images), Snyk (dependencies) |

#### Hands-on

```bash
# Check RBAC
kubectl auth can-i --list --namespace hanas-customer-demo

# Network policies
kubectl get networkpolicies -n hanas-customer-demo

# Secrets management
kubectl get secrets -n hanas-customer-demo

# Security scanning
trivy image hanas/spark:latest
```

📖 Tài liệu: [An toàn thông tin](../09-security/README.md)

---

### Ngày 10: Backup, DR & Tổng Kết (8 giờ)

#### Nội dung

| Chủ đề | Nội dung |
|--------|---------|
| Velero Backup | Cluster backup/restore, schedule automation |
| MinIO Replication | Site replication, failover procedures |
| DR Planning | RTO, RPO, business impact analysis |
| DR Drill | Quarterly testing, documentation, lessons learned |

#### Hands-on

```bash
# Backup
velero backup create daily-backup --include-namespaces hanas-customer-demo --ttl 720h

# Restore test
velero restore create --from-backup daily-backup \
  --namespace-mappings hanas-customer-demo:hanas-restore-test

# Verify
kubectl get pods -n hanas-restore-test
```

📖 Tài liệu: [Hạ tầng — Velero](../08-infrastructure/README.md)

---

## Kiểm Tra & Đánh Giá

| Phần | Nội dung | Tiêu chí |
|------|----------|---------|
| Lý thuyết | 30 câu hỏi (K8s, services, security, monitoring) | ≥ 80% |
| Thực hành | Deploy namespace + services + monitoring cho customer mới | Hoàn thành trong 2 giờ |
| Xử lý sự cố | Troubleshoot simulated infrastructure issue | MTTR < 1 giờ |

## Tài Liệu Tham Khảo

- [Kiến trúc tổng thể](../00-overview/architecture.md)
- [Apache Kafka (CDC & Streaming)](../01-ingestion/apache-kafka/README.md)
- [Hạ tầng](../08-infrastructure/README.md)
- [An toàn thông tin](../09-security/README.md)
- [Giám sát hệ thống](../07-system-management/README.md)
- [Quy trình bảo trì](../11-maintenance/maintenance-process.md)
- [SLA & Cam kết](../11-maintenance/sla.md)
- [Quy trình Onboarding Khách Hàng](customer-onboarding-guide.md)
