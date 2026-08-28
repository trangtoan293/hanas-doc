---
sidebar_position: 2
---

# HashiCorp Vault — Cài Đặt & Triển Khai

## 1. Yêu Cầu Hệ Thống

### 1.1 Phần Cứng

| Thành Phần | Development | Staging | Production (HA) |
|------------|:-----------:|:-------:|:----------------:|
| **CPU** | 2 cores | 4 cores | 4-8 cores × 3 nodes |
| **RAM** | 2 GB | 4 GB | 8 GB × 3 nodes |
| **Disk** | 10 GB | 25 GB SSD | 50-100 GB SSD × 3 nodes |
| **Network** | — | Low latency | Low latency, 10Gbps recommended |

### 1.2 Phần Mềm

| Yêu Cầu | Phiên Bản |
|----------|-----------|
| **Kubernetes** | ≥ 1.29 |
| **Helm** | ≥ 3.6 |
| **kubectl** | Tương thích K8s cluster version |
| **Vault CLI** (tùy chọn) | Cùng version với Vault server |

## 2. Triển Khai Trên Kubernetes (Helm Chart)

### 2.1 Thêm Helm Repository

```bash
# Thêm HashiCorp Helm repo
helm repo add hashicorp https://helm.releases.hashicorp.com

# Cập nhật repo
helm repo update

# Kiểm tra phiên bản chart có sẵn
helm search repo hashicorp/vault --versions | head -10
```

### 2.2 Chế Độ Triển Khai

| Chế Độ | Mô Tả | Phù Hợp |
|--------|--------|---------|
| **Dev** | Single server, in-memory, tự unseal, root token sinh riêng cho lab | Testing, học tập |
| **Standalone** | Single server, persistent volume | Dev, staging |
| **HA (High Availability)** | 3+ replicas, Raft Integrated Storage, leader election | **Production ← Khuyến nghị** |
| **External** | Chỉ deploy Agent Injector, kết nối Vault server bên ngoài | Hybrid setup |

### 2.3 Production Values (HA Mode)

Tạo file `vault-values.yaml`:

```yaml
# vault-values.yaml — Hanas Platform Production
global:
  enabled: true

server:
  # Vault image
  image:
    repository: hashicorp/vault
    tag: "1.18.1"  # Phiên bản OSS ổn định

  # HA Mode với Raft Integrated Storage
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      config: |
        ui = true

        listener "tcp" {
          tls_disable     = 0
          address         = "[::]:8200"
          cluster_address = "[::]:8201"
          tls_cert_file   = "/vault/userconfig/vault-tls/tls.crt"
          tls_key_file    = "/vault/userconfig/vault-tls/tls.key"
        }

        storage "raft" {
          path = "/vault/data"

          retry_join {
            leader_api_addr = "https://vault-0.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-tls/ca.crt"
          }
          retry_join {
            leader_api_addr = "https://vault-1.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-tls/ca.crt"
          }
          retry_join {
            leader_api_addr = "https://vault-2.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-tls/ca.crt"
          }
        }

        telemetry {
          prometheus_retention_time = "24h"
          disable_hostname          = true
        }

        service_registration "kubernetes" {}

  # Resources
  resources:
    requests:
      memory: "4Gi"
      cpu: "2000m"
    limits:
      memory: "8Gi"
      cpu: "4000m"

  # Persistent storage
  dataStorage:
    enabled: true
    size: 50Gi
    storageClass: "fast-ssd"  # Thay đổi theo cluster

  # Audit log storage
  auditStorage:
    enabled: true
    size: 20Gi
    storageClass: "fast-ssd"

  # Extra volumes cho TLS certificates
  extraVolumes:
    - type: secret
      name: vault-tls

  # Standalone mode (tắt khi dùng HA)
  standalone:
    enabled: false

# Vault Agent Injector
injector:
  enabled: true
  replicas: 2
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"

# Vault UI
ui:
  enabled: true
  serviceType: "ClusterIP"

# CSI Provider (tùy chọn)
csi:
  enabled: false
```

### 2.4 Cài Đặt Vault

```bash
# Tạo namespace
kubectl create namespace vault

# (Tùy chọn) Tạo TLS secret trước — sử dụng cert-manager hoặc tự generate
kubectl create secret generic vault-tls \
  --namespace vault \
  --from-file=tls.crt=vault.crt \
  --from-file=tls.key=vault.key \
  --from-file=ca.crt=ca.crt

# Cài đặt Vault
helm install vault hashicorp/vault \
  --namespace vault \
  --values vault-values.yaml

# Theo dõi quá trình deploy
kubectl get pods -n vault -w
```

**Kết quả mong đợi:**

```
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 0/1     Running   0          30s
vault-1                                 0/1     Running   0          30s
vault-2                                 0/1     Running   0          30s
vault-agent-injector-xxxxx-xxxxx        1/1     Running   0          30s
```

> **Cảnh báo:** Vault pods sẽ ở trạng thái `0/1 Running` cho đến khi được **khởi tạo (init)** và **mở khóa (unseal)**.

## 3. Khởi Tạo & Unseal

### 3.1 Khởi Tạo Vault (Chỉ Lần Đầu)

```bash
# Khởi tạo Vault trên node đầu tiên
kubectl exec -n vault vault-0 -- vault operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > vault-init.json

# Xem kết quả
cat vault-init.json | jq
```

**Output chứa:**
- `unseal_keys_b64`: **5 Unseal Keys** (cần 3/5 để unseal)
- `root_token`: **Root Token** (dùng cho initial setup)

> **QUAN TRỌNG**: Lưu trữ unseal keys và root token **an toàn** — phân phối cho các quản trị viên khác nhau theo nguyên tắc Shamir's Secret Sharing. **Không lưu trên cùng hệ thống** với Vault.

### 3.2 Unseal Vault

```bash
# Unseal vault-0 (cần 3 keys khác nhau)
kubectl exec -n vault vault-0 -- vault operator unseal <UNSEAL_KEY_1>
kubectl exec -n vault vault-0 -- vault operator unseal <UNSEAL_KEY_2>
kubectl exec -n vault vault-0 -- vault operator unseal <UNSEAL_KEY_3>

# Unseal vault-1
kubectl exec -n vault vault-1 -- vault operator unseal <UNSEAL_KEY_1>
kubectl exec -n vault vault-1 -- vault operator unseal <UNSEAL_KEY_2>
kubectl exec -n vault vault-1 -- vault operator unseal <UNSEAL_KEY_3>

# Unseal vault-2
kubectl exec -n vault vault-2 -- vault operator unseal <UNSEAL_KEY_1>
kubectl exec -n vault vault-2 -- vault operator unseal <UNSEAL_KEY_2>
kubectl exec -n vault vault-2 -- vault operator unseal <UNSEAL_KEY_3>
```

### 3.3 Join Raft Cluster

```bash
# vault-1 và vault-2 join cluster qua vault-0
kubectl exec -n vault vault-1 -- vault operator raft join \
  https://vault-0.vault-internal:8200

kubectl exec -n vault vault-2 -- vault operator raft join \
  https://vault-0.vault-internal:8200
```

### 3.4 Kiểm Tra Cluster Status

```bash
# Login với root token
kubectl exec -n vault vault-0 -- vault login <ROOT_TOKEN>

# Kiểm tra trạng thái
kubectl exec -n vault vault-0 -- vault status

# Kiểm tra Raft peers
kubectl exec -n vault vault-0 -- vault operator raft list-peers
```

**Output mong đợi:**

```
Node       Address                        State       Voter
----       -------                        -----       -----
vault-0    vault-0.vault-internal:8201    leader      true
vault-1    vault-1.vault-internal:8201    follower    true
vault-2    vault-2.vault-internal:8201    follower    true
```

## 4. Cài Đặt Vault Secrets Operator (VSO)

VSO tự động đồng bộ secrets từ Vault → Kubernetes Secrets, phù hợp cho các service đọc secrets qua environment variables.

```bash
# Cài đặt VSO
helm install vault-secrets-operator hashicorp/vault-secrets-operator \
  --namespace vault-secrets-operator-system \
  --create-namespace

# Kiểm tra
kubectl get pods -n vault-secrets-operator-system
```

### 4.1 VaultConnection & VaultAuth CRDs

```yaml
# vault-connection.yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultConnection
metadata:
  name: vault-connection
  namespace: default
spec:
  address: https://vault.vault.svc.cluster.local:8200
  skipTLSVerify: false
  caCertSecretRef: vault-tls

---
# vault-auth.yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: vault-auth
  namespace: default
spec:
  vaultConnectionRef: vault-connection
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: default-role
    serviceAccount: default
```

## 5. Cấu Hình Kubernetes Auth Method

Cho phép Pods xác thực với Vault qua ServiceAccount token:

```bash
# Enable Kubernetes auth
kubectl exec -n vault vault-0 -- vault auth enable kubernetes

# Cấu hình Kubernetes auth
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
```

## 6. Kubernetes Services & Endpoints

| Service | Namespace | Port | URL Nội Bộ |
|---------|-----------|------|-----------|
| **Vault Server** | `vault` | 8200 | `https://vault.vault.svc.cluster.local:8200` |
| **Vault Cluster** | `vault` | 8201 | `https://vault-internal.vault.svc.cluster.local:8201` |
| **Vault UI** | `vault` | 8200 | `https://vault-ui.vault.svc.cluster.local:8200` |
| **Agent Injector** | `vault` | 443 | `https://vault-agent-injector-svc.vault.svc.cluster.local:443` |

## 7. Kiểm Tra Sau Cài Đặt

### 7.1 Health Check

```bash
# Vault status
kubectl exec -n vault vault-0 -- vault status

# Health endpoint
kubectl exec -n vault vault-0 -- \
  curl -sk https://localhost:8200/v1/sys/health | jq

# Kết quả mong đợi
# {
# "initialized": true,
# "sealed": false,
# "standby": false,
# "performance_standby": false,
# "cluster_name": "vault-cluster-xxxxx",
# "cluster_id": "xxxxx-xxxxx-xxxxx"
# }
```

### 7.2 Smoke Test — Đọc/Ghi Secret

```bash
# Enable KV v2 secrets engine
kubectl exec -n vault vault-0 -- vault secrets enable -path=secret kv-v2

# Ghi secret test
kubectl exec -n vault vault-0 -- vault kv put secret/test \
  username="<TEST_USER>" password="<TEST_PASSWORD_FROM_SECRET>"

# Đọc secret
kubectl exec -n vault vault-0 -- vault kv get secret/test

# Xóa secret test
kubectl exec -n vault vault-0 -- vault kv delete secret/test
```

### 7.3 Checklist Sau Cài Đặt

| # | Mục | Lệnh Kiểm Tra | Kết Quả Mong Đợi |
|---|-----|---------------|-------------------|
| 1 | Vault initialized | `vault status` | `Initialized: true` |
| 2 | Vault unsealed | `vault status` | `Sealed: false` |
| 3 | HA cluster healthy | `vault operator raft list-peers` | 3 nodes, 1 leader + 2 followers |
| 4 | Agent Injector running | `kubectl get pods -n vault` | `vault-agent-injector` = Running |
| 5 | KV engine enabled | `vault secrets list` | `secret/` xuất hiện |
| 6 | K8s auth enabled | `vault auth list` | `kubernetes/` xuất hiện |
| 7 | Root token revoked | `vault token revoke <root_token>` | Token revoked |
| 8 | Audit enabled | `vault audit list` | Audit device active |

> **Bước tiếp theo**: Sau khi cài đặt thành công, tiến hành [Cấu hình](configuration.md) secrets engines, auth methods và policies cho từng service.
