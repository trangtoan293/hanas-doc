---
sidebar_position: 3
---

# HashiCorp Vault — Cấu Hình

## 1. Tổng Quan Cấu Hình

Sau khi [cài đặt](installation.md), cần cấu hình các thành phần sau cho Hanas Platform:

```mermaid
flowchart LR
    subgraph Config["Cấu Hình Vault"]
        SE["Secrets Engines"]
        AM["Auth Methods"]
        PO["Policies"]
        AU["Audit Devices"]
    end

    SE --> KV["KV v2"]
    SE --> DB["Database"]
    SE --> TR["Transit"]
    SE --> PKI_E["PKI"]

    AM --> K8S["Kubernetes"]
    AM --> AR["AppRole"]
    AM --> LDAP_E["LDAP"]

    PO --> SP["Service Policies"]
    PO --> AP["Admin Policies"]

    AU --> File["File Audit"]
    AU --> Syslog["Syslog"]

    style Config fill:#7c4dff,stroke:#4a148c,color:#fff
```

## 2. KV Secrets Engine v2

Lưu trữ secrets dạng key-value với versioning, phù hợp cho API keys, static passwords, config values.

### 2.1 Enable & Cấu Hình

```bash
# Enable KV v2 tại path "secret/"
vault secrets enable -path=secret -version=2 kv

# Cấu hình — giữ tối đa 10 versions
vault kv metadata put -max-versions=10 secret/
```

### 2.2 Tổ Chức Secrets Theo Service

```
secret/
├── hanas/
│   ├── airflow/
│   │   ├── connections/    # DB connections, API endpoints
│   │   └── variables/      # DAG config variables
│   ├── nifi/
│   │   ├── credentials/    # DB passwords, API keys
│   │   └── config/         # Sensitive NiFi properties
│   ├── kafka/
│   │   ├── schema-registry/
│   │   └── connect/
│   ├── minio/
│   │   ├── root-credentials/
│   │   └── service-accounts/
│   ├── datahub/
│   │   ├── mysql/
│   │   └── elasticsearch/
│   ├── dremio/
│   │   └── sources/        # Source connection credentials
│   ├── ai/
│   │   ├── dify/           # LLM API keys, Redis password
│   │   ├── vllm/           # Model tokens
│   │   └── langfuse/       # DB creds, encryption key
│   └── infra/
│       ├── openobserve/
│       └── velero/
```

### 2.3 CRUD Operations

```bash
# Ghi secret
vault kv put secret/hanas/airflow/connections/postgres \
  host="postgres.database.svc" \
  port="5432" \
  username="airflow" \
  password="<STRONG_PASSWORD>" \
  database="airflow"

# Đọc secret
vault kv get secret/hanas/airflow/connections/postgres

# Đọc field cụ thể
vault kv get -field=password secret/hanas/airflow/connections/postgres

# Đọc version cụ thể
vault kv get -version=2 secret/hanas/airflow/connections/postgres

# Cập nhật (tạo version mới)
vault kv put secret/hanas/airflow/connections/postgres \
  host="postgres.database.svc" \
  port="5432" \
  username="airflow" \
  password="<NEW_PASSWORD>" \
  database="airflow"

# Xóa version hiện tại (soft delete, có thể recover)
vault kv delete secret/hanas/airflow/connections/postgres

# Xóa vĩnh viễn
vault kv destroy -versions=1,2 secret/hanas/airflow/connections/postgres
```

## 3. Database Secrets Engine

Tạo database credentials **động** với TTL tự động xoay vòng — loại bỏ static passwords.

### 3.1 Enable

```bash
vault secrets enable -path=database database
```

### 3.2 PostgreSQL Dynamic Credentials

```bash
# Cấu hình connection tới PostgreSQL
vault write database/config/hanas-postgres \
  plugin_name="postgresql-database-plugin" \
  allowed_roles="airflow-role,dremio-role,langfuse-role,datahub-role" \
  connection_url="postgresql://{{username}}:{{password}}@postgres.database.svc:5432/hanas?sslmode=require" \
  username="vault_admin" \
  password="<VAULT_ADMIN_PASSWORD>"

# Xoay root password (Vault quản lý, không ai biết)
vault write -force database/rotate-root/hanas-postgres
```

### 3.3 Tạo Database Roles

```bash
# Role cho Airflow — read/write access
vault write database/roles/airflow-role \
  db_name="hanas-postgres" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}'
      VALID UNTIL '{{expiration}}';
    GRANT CONNECT ON DATABASE airflow TO \"{{name}}\";
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";
  " \
  revocation_statements="
    REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";
    REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM \"{{name}}\";
    DROP ROLE IF EXISTS \"{{name}}\";
  " \
  default_ttl="1h" \
  max_ttl="24h"

# Role cho Dremio — read-only access
vault write database/roles/dremio-role \
  db_name="hanas-postgres" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}'
      VALID UNTIL '{{expiration}}';
    GRANT CONNECT ON DATABASE hanas TO \"{{name}}\";
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
  " \
  default_ttl="1h" \
  max_ttl="12h"

# Role cho Langfuse
vault write database/roles/langfuse-role \
  db_name="hanas-postgres" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}'
      VALID UNTIL '{{expiration}}';
    GRANT CONNECT ON DATABASE langfuse TO \"{{name}}\";
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";
  " \
  default_ttl="1h" \
  max_ttl="24h"
```

### 3.4 Generate Dynamic Credentials

```bash
# Lấy credentials động cho Airflow
vault read database/creds/airflow-role

# Output:
# Key Value
# --- -----
# lease_id database/creds/airflow-role/xxxxx
# lease_duration 1h
# username v-k8s-airflow-xxxxx
# password A1b2C3d4-xxxxx
```

## 4. Transit Secrets Engine (Encryption-as-a-Service)

Mã hóa/giải mã dữ liệu mà không lộ encryption key — key **không bao giờ rời khỏi Vault**.

### 4.1 Enable & Tạo Key

```bash
# Enable Transit engine
vault secrets enable transit

# Tạo encryption key cho NiFi sensitive properties
vault write -f transit/keys/nifi-encryption \
  type="aes256-gcm96"

# Tạo key cho PII data encryption
vault write -f transit/keys/pii-encryption \
  type="aes256-gcm96" \
  auto_rotate_period="720h"   # Tự xoay key mỗi 30 ngày
```

### 4.2 Encrypt / Decrypt

```bash
# Mã hóa (plaintext phải encode base64)
vault write transit/encrypt/pii-encryption \
  plaintext=$(echo -n "SỐ CMND: 012345678" | base64)

# Output: ciphertext = vault:v1:xxxxxxxxxx

# Giải mã
vault write transit/decrypt/pii-encryption \
  ciphertext="vault:v1:xxxxxxxxxx"

# Output: plaintext (base64) → decode để đọc
```

### 4.3 Key Rotation

```bash
# Xoay key thủ công (data cũ vẫn đọc được)
vault write -f transit/keys/pii-encryption/rotate

# Rewrap ciphertext với key version mới
vault write transit/rewrap/pii-encryption \
  ciphertext="vault:v1:xxxxxxxxxx"
# Output: vault:v2:yyyyyyyyyy
```

## 5. PKI Secrets Engine (Internal CA)

Cấp phát certificates TLS/mTLS động cho inter-service communication.

### 5.1 Thiết Lập Root CA

```bash
# Enable PKI engine
vault secrets enable -path=pki pki

# Tăng max TTL lên 10 năm
vault secrets tune -max-lease-ttl=87600h pki

# Generate Root CA
vault write pki/root/generate/internal \
  common_name="Hanas Platform Root CA" \
  ttl="87600h" \
  key_bits=4096

# Cấu hình CRL và issuing URLs
vault write pki/config/urls \
  issuing_certificates="https://vault.vault.svc:8200/v1/pki/ca" \
  crl_distribution_points="https://vault.vault.svc:8200/v1/pki/crl"
```

### 5.2 Thiết Lập Intermediate CA

```bash
# Enable Intermediate CA
vault secrets enable -path=pki_int pki

vault secrets tune -max-lease-ttl=43800h pki_int

# Generate CSR
vault write pki_int/intermediate/generate/internal \
  common_name="Hanas Platform Intermediate CA" \
  key_bits=4096 \
  -format=json | jq -r '.data.csr' > pki_int.csr

# Sign CSR bằng Root CA
vault write pki/root/sign-intermediate \
  csr=@pki_int.csr \
  format=pem_bundle \
  ttl="43800h" \
  -format=json | jq -r '.data.certificate' > intermediate.cert.pem

# Import signed certificate
vault write pki_int/intermediate/set-signed \
  certificate=@intermediate.cert.pem
```

### 5.3 Tạo Role & Issue Certificate

```bash
# Role cho Kafka mTLS certificates
vault write pki_int/roles/kafka-mtls \
  allowed_domains="kafka.confluent.svc.cluster.local,kafka-internal.confluent.svc.cluster.local" \
  allow_subdomains=true \
  max_ttl="720h" \
  key_bits=2048

# Issue certificate
vault write pki_int/issue/kafka-mtls \
  common_name="kafka-0.kafka-internal.confluent.svc.cluster.local" \
  ttl="168h"
```

## 6. Authentication Methods

### 6.1 Kubernetes Auth (Chính)

```bash
# Enable (đã làm trong installation)
vault auth enable kubernetes

# Cấu hình
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

# Tạo role cho Airflow namespace
vault write auth/kubernetes/role/airflow \
  bound_service_account_names="airflow-worker,airflow-webserver,airflow-scheduler" \
  bound_service_account_namespaces="airflow" \
  policies="airflow-policy" \
  ttl="1h"

# Tạo role cho NiFi namespace
vault write auth/kubernetes/role/nifi \
  bound_service_account_names="nifi" \
  bound_service_account_namespaces="nifi" \
  policies="nifi-policy" \
  ttl="1h"

# Tạo role cho AI services
vault write auth/kubernetes/role/ai-services \
  bound_service_account_names="dify,vllm,langfuse" \
  bound_service_account_namespaces="ai" \
  policies="ai-policy" \
  ttl="1h"
```

### 6.2 AppRole (CI/CD)

```bash
# Enable AppRole
vault auth enable approle

# Tạo role cho CI/CD pipeline
vault write auth/approle/role/cicd-role \
  token_policies="cicd-policy" \
  token_ttl="10m" \
  token_max_ttl="30m" \
  secret_id_ttl="24h" \
  secret_id_num_uses=0

# Lấy RoleID (lưu trong CI/CD config)
vault read auth/approle/role/cicd-role/role-id

# Generate SecretID (inject vào CI/CD runtime)
vault write -f auth/approle/role/cicd-role/secret-id
```

### 6.3 LDAP Auth (Admin Users)

```bash
# Enable LDAP
vault auth enable ldap

# Cấu hình LDAP server
vault write auth/ldap/config \
  url="ldaps://ldap.company.local:636" \
  userdn="ou=Users,dc=company,dc=local" \
  groupdn="ou=Groups,dc=company,dc=local" \
  userattr="uid" \
  groupattr="cn" \
  groupfilter="(member={{.UserDN}})" \
  insecure_tls=false \
  certificate=@ldap-ca.pem
```

## 7. Policies

### 7.1 Airflow Policy

```hcl
# airflow-policy.hcl
# KV secrets cho Airflow connections & variables
path "secret/data/hanas/airflow/*" {
  capabilities = ["read", "list"]
}

# Database dynamic credentials
path "database/creds/airflow-role" {
  capabilities = ["read"]
}

# Transit encryption cho sensitive data
path "transit/encrypt/pii-encryption" {
  capabilities = ["update"]
}

path "transit/decrypt/pii-encryption" {
  capabilities = ["update"]
}
```

### 7.2 NiFi Policy

```hcl
# nifi-policy.hcl
path "secret/data/hanas/nifi/*" {
  capabilities = ["read", "list"]
}

path "transit/encrypt/nifi-encryption" {
  capabilities = ["update"]
}

path "transit/decrypt/nifi-encryption" {
  capabilities = ["update"]
}
```

### 7.3 AI Services Policy

```hcl
# ai-policy.hcl
path "secret/data/hanas/ai/*" {
  capabilities = ["read", "list"]
}

path "database/creds/langfuse-role" {
  capabilities = ["read"]
}
```

### 7.4 Admin Policy

```hcl
# admin-policy.hcl
# Toàn quyền trên hanas secrets
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Quản lý database engine
path "database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Quản lý auth methods
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# System operations
path "sys/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
```

### 7.5 Apply Policies

```bash
# Tạo policies
vault policy write airflow-policy airflow-policy.hcl
vault policy write nifi-policy nifi-policy.hcl
vault policy write ai-policy ai-policy.hcl
vault policy write admin-policy admin-policy.hcl

# Gán policy cho LDAP group
vault write auth/ldap/groups/platform-admins \
  policies="admin-policy"

# Kiểm tra policy
vault policy read airflow-policy
```

## 8. Audit Devices

```bash
# Enable file audit (ghi vào persistent volume)
vault audit enable file \
  file_path=/vault/audit/vault-audit.log

# Enable syslog audit (gửi tới OpenObserve/SIEM)
vault audit enable syslog \
  tag="vault" \
  facility="AUTH"

# Kiểm tra audit devices
vault audit list
```

## 9. Bảng Tham Số Quan Trọng

### 9.1 Server Configuration

| Tham Số | Giá Trị | Mô Tả |
|---------|---------|--------|
| `listener.tcp.address` | `[::]:8200` | Vault API listener address |
| `listener.tcp.tls_disable` | `0` | **Luôn enable TLS** trong production |
| `storage.raft.path` | `/vault/data` | Raft data directory |
| `api_addr` | `https://vault.vault.svc:8200` | Client-facing API address |
| `cluster_addr` | `https://vault-internal:8201` | Cluster communication address |
| `ui` | `true` | Enable Vault Web UI |
| `default_lease_ttl` | `1h` | Default secret lease TTL |
| `max_lease_ttl` | `24h` | Maximum allowed TTL |
| `disable_mlock` | `true` | Required khi chạy trên container |

### 9.2 Telemetry Configuration

| Tham Số | Giá Trị | Mô Tả |
|---------|---------|--------|
| `telemetry.prometheus_retention_time` | `24h` | Prometheus metrics retention |
| `telemetry.disable_hostname` | `true` | Tránh high-cardinality metrics |
| `telemetry.statsite_address` | — | StatsD/Statsite endpoint |

> **Bước tiếp theo**: Xem [Hướng dẫn sử dụng](user-guide.md) để tìm hiểu cách tích hợp Vault với từng service cụ thể và quy trình vận hành hàng ngày.
