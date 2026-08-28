---
sidebar_position: 4
---

# HashiCorp Vault — Hướng Dẫn Sử Dụng

## 1. Truy Cập Vault

### 1.1 Vault Web UI

```
URL: https://vault.vault.svc.cluster.local:8200/ui
```

Truy cập qua port-forward (development):

```bash
kubectl port-forward -n vault svc/vault-ui 8200:8200

# Mở browser: https://localhost:8200
```

**Đăng nhập:**
- **Method**: LDAP (admin users) hoặc Token
- **Username/Password**: LDAP credentials của tổ chức

### 1.2 Vault CLI

```bash
# Cài đặt Vault CLI
# macOS
brew install vault

# Linux
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vault

# Cấu hình endpoint
export VAULT_ADDR="https://vault.vault.svc.cluster.local:8200"

# Login
vault login -method=ldap username=<YOUR_USERNAME>
```

### 1.3 Vault API

```bash
# Health check
curl -sk https://vault.vault.svc.cluster.local:8200/v1/sys/health | jq

# Login và lấy token
curl -sk --request POST \
  --data '{"password": "<PASSWORD>"}' \
  https://vault.vault.svc.cluster.local:8200/v1/auth/ldap/login/<USERNAME> | jq

# Đọc secret với token
curl -sk --header "X-Vault-Token: <TOKEN>" \
  https://vault.vault.svc.cluster.local:8200/v1/secret/data/hanas/airflow/connections/postgres | jq
```

## 2. Tích Hợp Từng Service

### 2.1 Apache Airflow — VaultBackend

Airflow tự động đọc connections và variables từ Vault thay vì lưu trong metadata DB.

**Cấu hình `airflow.cfg` hoặc Helm values:**

```yaml
# airflow-values.yaml (Helm)
config:
  secrets:
    backend: "airflow.providers.hashicorp.secrets.vault.VaultBackend"
    backend_kwargs: >
      {
        "connections_path": "hanas/airflow/connections",
        "variables_path": "hanas/airflow/variables",
        "mount_point": "secret",
        "url": "https://vault.vault.svc.cluster.local:8200",
        "auth_type": "kubernetes",
        "kubernetes_role": "airflow",
        "kubernetes_jwt_path": "/var/run/secrets/kubernetes.io/serviceaccount/token"
      }
```

**Lưu connection trong Vault theo format Airflow URI:**

```bash
# PostgreSQL connection
vault kv put secret/hanas/airflow/connections/postgres_default \
  conn_uri="postgresql://airflow:password@postgres.database.svc:5432/airflow"

# MinIO / S3 connection
vault kv put secret/hanas/airflow/connections/minio_default \
  conn_uri="aws://ACCESS_KEY:SECRET_KEY@?endpoint_url=http://minio.minio.svc:9000&region_name=us-east-1"

# Variables
vault kv put secret/hanas/airflow/variables/dbt_target \
  value="production"
```

### 2.2 Apache NiFi — Parameter Provider

NiFi 1.14+ hỗ trợ native HashiCorp Vault integration.

**Cấu hình `nifi.properties`:**

```properties
# Vault Parameter Provider
nifi.parameter.provider.vault.class=org.apache.nifi.vault.hashicorp.HashiCorpVaultParameterProvider
nifi.parameter.provider.vault.url=https://vault.vault.svc.cluster.local:8200
nifi.parameter.provider.vault.authentication=KUBERNETES
nifi.parameter.provider.vault.kubernetes.service.account.token.path=/var/run/secrets/kubernetes.io/serviceaccount/token
nifi.parameter.provider.vault.kubernetes.role=nifi
```

**NiFi Transit Engine cho sensitive properties:**

```properties
# Sử dụng Vault Transit Engine để mã hóa NiFi sensitive properties
nifi.sensitive.props.provider=hashicorp-vault-transit
nifi.sensitive.props.provider.vault.url=https://vault.vault.svc.cluster.local:8200
nifi.sensitive.props.provider.vault.transit.path=transit
nifi.sensitive.props.provider.vault.transit.key=nifi-encryption
```

**Tham chiếu secret trong NiFi Parameter Context:**

```
# Trong Parameter Context, tham chiếu KV secret:
Parameter Name: db.password
Parameter Value: #{vault:secret/hanas/nifi/credentials/database#password}
```

### 2.3 Apache Kafka — Dynamic Credentials

**Vault Agent Injector annotations cho Kafka clients:**

```yaml
# kafka-consumer-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka-consumer
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "kafka-role"
        vault.hashicorp.com/agent-inject-secret-kafka.properties: "secret/hanas/kafka/client"
        vault.hashicorp.com/agent-inject-template-kafka.properties: |
          {{- with secret "secret/data/hanas/kafka/client" -}}
          sasl.mechanism=SCRAM-SHA-512
          security.protocol=SASL_SSL
          sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required \
            username="{{ .Data.data.username }}" \
            password="{{ .Data.data.password }}";
          {{- end }}
    spec:
      serviceAccountName: kafka-client
      containers:
        - name: consumer
          # ...
```

### 2.4 MinIO — KES + Vault KMS

MinIO sử dụng Key Encryption Service (KES) kết nối với Vault cho Server-Side Encryption.

**Cấu hình KES (`kes-config.yaml`):**

```yaml
# kes-config.yaml
address: 0.0.0.0:7373
admin:
  identity: ${KES_ADMIN_IDENTITY}

tls:
  key: /certs/kes-server.key
  cert: /certs/kes-server.crt

keystore:
  vault:
    endpoint: https://vault.vault.svc.cluster.local:8200
    engine: "kv-v2"
    prefix: "minio-kes"
    approle:
      id: "${VAULT_APPROLE_ID}"
      secret: "${VAULT_APPROLE_SECRET}"
    tls:
      ca: /certs/vault-ca.crt
    status:
      ping: 10s
```

**Lưu encryption key trong Vault:**

```bash
vault kv put secret/minio-kes/my-minio-key \
  key="$(openssl rand -hex 32)"
```

**Cấu hình MinIO sử dụng KES:**

```bash
# MinIO environment variables
MINIO_KMS_KES_ENDPOINT=https://kes.minio.svc:7373
MINIO_KMS_KES_KEY_NAME=my-minio-key
MINIO_KMS_KES_CERT_FILE=/certs/minio-kes.crt
MINIO_KMS_KES_KEY_FILE=/certs/minio-kes.key
MINIO_KMS_KES_CAPATH=/certs/kes-ca.crt
```

### 2.5 Dremio / Spark — Dynamic JDBC Credentials

**Vault Secrets Operator (VSO) cho Dremio:**

```yaml
# dremio-vault-secret.yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultDynamicSecret
metadata:
  name: dremio-db-creds
  namespace: dremio
spec:
  vaultAuthRef: vault-auth
  mount: database
  path: creds/dremio-role
  destination:
    name: dremio-db-credentials  # K8s Secret sẽ được tạo tự động
    create: true
  renewalPercent: 67  # Renew khi đã dùng 67% TTL
```

**Spark — Vault Agent sidecar:**

```yaml
# spark-driver-template.yaml
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "spark-role"
        vault.hashicorp.com/agent-inject-secret-db-creds: "database/creds/dremio-role"
        vault.hashicorp.com/agent-inject-template-db-creds: |
          {{- with secret "database/creds/dremio-role" -}}
          JDBC_URL=jdbc:postgresql://postgres.database.svc:5432/hanas
          JDBC_USER={{ .Data.username }}
          JDBC_PASS={{ .Data.password }}
          {{- end }}
```

### 2.6 AI Services (Dify, vLLM, Langfuse)

**VaultStaticSecret cho Dify API keys:**

```yaml
# dify-vault-secret.yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: dify-secrets
  namespace: ai
spec:
  vaultAuthRef: vault-auth
  mount: secret
  type: kv-v2
  path: hanas/ai/dify
  destination:
    name: dify-env-secrets
    create: true
  refreshAfter: 60s
```

**Lưu secrets cho AI services trong Vault:**

```bash
# Dify secrets
vault kv put secret/hanas/ai/dify \
  OPENAI_API_KEY="<OPENAI_API_KEY_FROM_SECRET>" \
  SECRET_KEY="<RANDOM_SECRET>" \
  DB_PASSWORD="<DIFY_DB_PASSWORD>" \
  REDIS_PASSWORD="<REDIS_PASSWORD>"

# vLLM model tokens
vault kv put secret/hanas/ai/vllm \
  HUGGING_FACE_HUB_TOKEN="<HUGGING_FACE_TOKEN_FROM_SECRET>" \
  MODEL_NAME="meta-llama/Llama-3-8B-Instruct"

# Langfuse
vault kv put secret/hanas/ai/langfuse \
  DATABASE_URL="postgresql://<LANGFUSE_DB_USER>:<LANGFUSE_DB_PASSWORD>@postgres.database.svc:5432/langfuse" \
  NEXTAUTH_SECRET="<RANDOM_SECRET>" \
  ENCRYPTION_KEY="<RANDOM_KEY>" \
  SALT="<RANDOM_SALT>"
```

## 3. Quản Lý Secrets Hàng Ngày

### 3.1 Xoay Vòng (Rotation) Static Secrets

```bash
# Cập nhật secret (tự tạo version mới)
vault kv put secret/hanas/ai/dify \
  OPENAI_API_KEY="<NEW_OPENAI_API_KEY_FROM_SECRET>" \
  SECRET_KEY="<NEW_SECRET>" \
  DB_PASSWORD="<NEW_PASSWORD>" \
  REDIS_PASSWORD="<NEW_REDIS_PASSWORD>"

# Kiểm tra version history
vault kv metadata get secret/hanas/ai/dify

# Rollback về version trước
vault kv rollback -version=2 secret/hanas/ai/dify
```

### 3.2 Quản Lý Lease (Dynamic Secrets)

```bash
# Liệt kê active leases
vault list sys/leases/lookup/database/creds/airflow-role

# Xem chi tiết lease
vault lease lookup <LEASE_ID>

# Gia hạn lease
vault lease renew <LEASE_ID>

# Thu hồi lease cụ thể
vault lease revoke <LEASE_ID>

# Thu hồi TẤT CẢ leases của 1 role (emergency)
vault lease revoke -prefix database/creds/airflow-role
```

### 3.3 Token Management

```bash
# Tạo token với policy cụ thể (cho automation)
vault token create \
  -policy="airflow-policy" \
  -ttl="8h" \
  -display-name="airflow-batch-job"

# Tạo orphan token (không bị revoke theo parent)
vault token create -orphan \
  -policy="admin-policy" \
  -ttl="4h"

# Kiểm tra token hiện tại
vault token lookup

# Revoke token
vault token revoke <TOKEN>
```

## 4. Giám Sát & Monitoring

### 4.1 Prometheus Metrics

Vault expose metrics tại `/v1/sys/metrics?format=prometheus`.

```yaml
# ServiceMonitor cho Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vault-metrics
  namespace: vault
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: vault
  endpoints:
    - port: http
      path: /v1/sys/metrics
      params:
        format: ["prometheus"]
      interval: 30s
      scheme: https
      tlsConfig:
        insecureSkipVerify: true
      bearerTokenSecret:
        name: vault-prometheus-token
        key: token
```

### 4.2 Metrics Quan Trọng

| Metric | Mô Tả | Ngưỡng Cảnh Báo |
|--------|--------|-----------------|
| `vault.core.unsealed` | Vault sealed status | `= 0` → **CRITICAL** |
| `vault.expire.num_leases` | Số active leases | `> 10000` → Warning |
| `vault.runtime.num_goroutines` | Go goroutines | `> 1000` → Warning |
| `vault.audit.log_response` | Audit log latency | `> 500ms` → Warning |
| `vault.barrier.get.count` | Storage reads/sec | Baseline + 50% → Warning |
| `vault.core.handle_request.count` | API requests/sec | Baseline + 100% → Warning |
| `vault.token.count` | Total active tokens | `> 50000` → Warning |
| `vault.raft.leader.lastContact` | Raft leader heartbeat | `> 500ms` → Warning |

### 4.3 Tích Hợp OpenObserve

```bash
# Forward Vault audit logs tới OpenObserve qua syslog
vault audit enable syslog \
  tag="vault-audit" \
  facility="LOCAL0"

# Hoặc sử dụng fluent-bit sidecar đọc audit file
# → Forward tới OpenObserve HTTP API
```

### 4.4 Alert Rules

```yaml
# Vault Sealed Alert
- alert: VaultSealed
  expr: vault_core_unsealed == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Vault instance sealed"
    description: "Vault pod {{ $labels.pod }} is sealed. Immediate unseal required."

# High Lease Count
- alert: VaultHighLeaseCount
  expr: vault_expire_num_leases > 10000
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "High number of active Vault leases"

# Raft Leader Loss
- alert: VaultNoLeader
  expr: vault_raft_leader_lastContact > 500
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "Vault Raft cluster has no stable leader"
```

## 5. Troubleshooting

### 5.1 Các Lỗi Thường Gặp

| # | Lỗi | Nguyên Nhân | Giải Pháp |
|---|-----|-------------|-----------|
| 1 | **Vault is sealed** | Vault restart, node failure | Unseal bằng 3/5 unseal keys: `vault operator unseal <KEY>` |
| 2 | **Permission denied** | Policy không cho phép | Kiểm tra policy: `vault token capabilities <TOKEN> <PATH>` |
| 3 | **Lease not found** | Lease đã hết hạn | Tạo credentials mới: `vault read database/creds/<ROLE>` |
| 4 | **Connection refused** | Vault service không chạy | Kiểm tra Pod: `kubectl get pods -n vault` |
| 5 | **503 Service Unavailable** | Vault sealed hoặc standby | Kiểm tra: `vault status`, unseal nếu cần |
| 6 | **Authentication failed** | SA token invalid, role sai | Kiểm tra ServiceAccount và Kubernetes auth role |
| 7 | **x509 certificate error** | TLS cert expired hoặc sai CA | Kiểm tra cert: `openssl s_client -connect vault:8200` |

### 5.2 Debug Commands

```bash
# Kiểm tra Vault status toàn diện
kubectl exec -n vault vault-0 -- vault status -format=json | jq

# Kiểm tra audit logs
kubectl exec -n vault vault-0 -- tail -50 /vault/audit/vault-audit.log | jq

# Kiểm tra Raft cluster health
kubectl exec -n vault vault-0 -- vault operator raft list-peers

# Kiểm tra secrets engine list
kubectl exec -n vault vault-0 -- vault secrets list -format=table

# Kiểm tra auth methods
kubectl exec -n vault vault-0 -- vault auth list -format=table

# Kiểm tra policy cho token
kubectl exec -n vault vault-0 -- vault token capabilities <TOKEN> secret/data/hanas/airflow/*

# Xem Vault server logs
kubectl logs -n vault vault-0 --tail=100

# Debug Vault Agent Injector
kubectl logs -n vault -l component=webhook --tail=100
```

### 5.3 Emergency Procedures

**Vault bị sealed sau restart:**

```bash
# 1. Kiểm tra trạng thái sealed
kubectl exec -n vault vault-0 -- vault status

# 2. Unseal từng node (cần 3/5 keys)
for i in 0 1 2; do
  kubectl exec -n vault vault-$i -- vault operator unseal <KEY_1>
  kubectl exec -n vault vault-$i -- vault operator unseal <KEY_2>
  kubectl exec -n vault vault-$i -- vault operator unseal <KEY_3>
done

# 3. Verify cluster healthy
kubectl exec -n vault vault-0 -- vault operator raft list-peers
```

**Tái tạo Root Token (khi cần):**

```bash
# Bắt đầu quá trình generate root token
vault operator generate-root -init

# Mỗi key holder cung cấp unseal key
vault operator generate-root \
  -nonce=<NONCE_FROM_INIT> \
  <UNSEAL_KEY>

# Sau khi đủ threshold → nhận encoded root token
# Decode token
vault operator generate-root -decode=<ENCODED_TOKEN> -otp=<OTP>
```

## 6. Backup & Disaster Recovery

### 6.1 Raft Snapshot (Backup)

```bash
# Tạo Raft snapshot
kubectl exec -n vault vault-0 -- vault operator raft snapshot save /tmp/vault-backup.snap

# Copy snapshot ra ngoài cluster
kubectl cp vault/vault-0:/tmp/vault-backup.snap ./vault-backup-$(date +%Y%m%d).snap
```

### 6.2 Automated Backup (CronJob)

```yaml
# vault-backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: vault-backup
  namespace: vault
spec:
  schedule: "0 2 * * *"  # 2:00 AM hàng ngày
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: vault-backup
          containers:
            - name: backup
              image: hashicorp/vault:1.18.1
              env:
                - name: VAULT_ADDR
                  value: "https://vault.vault.svc:8200"
                - name: VAULT_TOKEN
                  valueFrom:
                    secretKeyRef:
                      name: vault-backup-token
                      key: token
              command:
                - /bin/sh
                - -c
                - |
                  DATE=$(date +%Y%m%d-%H%M%S)
                  vault operator raft snapshot save /backup/vault-${DATE}.snap
                  echo "Backup completed: vault-${DATE}.snap"
                  # Upload to MinIO (S3)
                  # aws s3 cp /backup/vault-${DATE}.snap s3://backups/vault/
              volumeMounts:
                - name: backup-volume
                  mountPath: /backup
          volumes:
            - name: backup-volume
              persistentVolumeClaim:
                claimName: vault-backup-pvc
          restartPolicy: OnFailure
```

### 6.3 Disaster Recovery — Restore

```bash
# Restore từ snapshot (trên Vault cluster mới hoặc đã init)
kubectl cp ./vault-backup-20260302.snap vault/vault-0:/tmp/vault-restore.snap

kubectl exec -n vault vault-0 -- vault operator raft snapshot restore \
  -force /tmp/vault-restore.snap

# Verify sau restore
kubectl exec -n vault vault-0 -- vault status
kubectl exec -n vault vault-0 -- vault secrets list
kubectl exec -n vault vault-0 -- vault auth list
```

## 7. Best Practices

### 7.1 Security Hardening

| # | Practice | Mô Tả |
|---|----------|--------|
| 1 | **Revoke Root Token** | Xóa root token ngay sau initial setup |
| 2 | **Enable TLS** | Luôn sử dụng HTTPS, kể cả internal traffic |
| 3 | **Audit Logging** | Enable ít nhất 2 audit devices (file + syslog) |
| 4 | **Short TTLs** | Dynamic secrets: 1-4h TTL, tokens: 8h max |
| 5 | **Least Privilege** | Mỗi service chỉ có quyền trên path cần thiết |
| 6 | **Disable Swap** | Tránh sensitive data leak ra disk |
| 7 | **Network Policies** | Chỉ cho phép authorized namespaces truy cập Vault |

### 7.2 Naming Convention

```
# Secrets path convention
secret/hanas/<service>/<category>/<name>

# Ví dụ:
secret/hanas/airflow/connections/postgres_default
secret/hanas/kafka/connect/oracle-cdc-credentials
secret/hanas/ai/dify/llm-api-keys
secret/hanas/infra/openobserve/admin-credentials

# Database roles
database/creds/<service>-role

# PKI roles
pki_int/issue/<service>-mtls
```

### 7.3 Rotation Schedule

| Secret Type | TTL / Rotation | Phương Pháp |
|-------------|----------------|-------------|
| **Database creds** | 1-4h (dynamic) | Tự động qua Database Engine |
| **API keys** | 90 ngày | Manual rotation, KV versioning |
| **TLS certificates** | 7-30 ngày | Tự động qua PKI Engine |
| **Encryption keys** | 30 ngày | Tự động `auto_rotate_period` |
| **Service tokens** | 1-8h | Tự động qua K8s auth |
| **Root credentials** | Ngay sau init | `vault operator generate-root` khi cần |
