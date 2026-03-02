---
sidebar_position: 6
---

# HashiCorp Vault — Thông Tin Version

## 1. Phiên Bản Hiện Tại

| Thông Tin | Chi Tiết |
|-----------|---------|
| **Phiên bản sử dụng** | HashiCorp Vault 1.18.x (OSS) |
| **License** | Business Source License 1.1 (BSL) — miễn phí cho production use |
| **Source Code** | [github.com/hashicorp/vault](https://github.com/hashicorp/vault) |
| **Official Docs** | [developer.hashicorp.com/vault](https://developer.hashicorp.com/vault/docs) |
| **Helm Chart** | [github.com/hashicorp/vault-helm](https://github.com/hashicorp/vault-helm) |
| **Vault Secrets Operator** | [github.com/hashicorp/vault-secrets-operator](https://github.com/hashicorp/vault-secrets-operator) |
| **Docker Image** | `hashicorp/vault:1.18.1` |

> **Lưu ý**: Từ tháng 8/2023, Vault chuyển từ MPL 2.0 sang BSL 1.1. Phiên bản OSS vẫn **miễn phí cho sử dụng production** — BSL chỉ hạn chế hosting Vault-as-a-Service cạnh tranh với HashiCorp.

---

## 2. Tính Năng Nổi Bật — Vault 1.18.x

| # | Tính Năng | Mô Tả |
|---|-----------|-------|
| 1 | **Raft Integrated Storage GA** | Storage backend tích hợp, không cần Consul |
| 2 | **Vault Secrets Operator v2** | Cải thiện sync secrets → K8s Secrets |
| 3 | **PKI EST & CMPv2** | Hỗ trợ giao thức certificate enrollment mới |
| 4 | **Adaptive Overload Protection** | Tự động throttle khi storage backend quá tải |
| 5 | **Secrets Sync** | Đồng bộ secrets ra external systems |
| 6 | **Workload Identity Federation** | WIF support cho AWS, Azure, GCP |
| 7 | **Transit Managed Keys** | Quản lý keys trên external KMS |
| 8 | **Improved Agent Injector** | Hỗ trợ render templates, custom annotations |

---

## 3. Lịch Sử Phiên Bản

| Version | Release Date | Highlights |
|---------|-------------|------------|
| **1.18.x** | Q4 2024 | Adaptive overload protection, PKI EST, secrets sync GA |
| **1.17.x** | Q3 2024 | Multi-issuer PKI, improved transit, WIF GA |
| **1.16.x** | Q1 2024 | Secrets sync beta, event notifications, VSO v2 |
| **1.15.x** | Q3 2023 | Raft autopilot improvements, PKI ACME |
| **1.14.x** | Q2 2023 | Transit BYOK, PKI cross-signing, audit socket |
| **1.13.x** | Q4 2022 | Kubernetes auth improvements, database plugin multiplexing |
| **1.12.x** | Q3 2022 | PKI improvements, Transform tokenization GA |
| **1.11.x** | Q2 2022 | Key management secrets engine, K8s CSI provider |

---

## 4. Ma Trận Tương Thích — Hanas Platform

### 4.1 Vault Helm Chart

| Chart Version | Vault Default | K8s Tested | Release Date |
|:-------------:|:------------:|:----------:|:------------:|
| 0.32.0 | 1.21.2 | 1.31-1.35 | 01/2026 |
| 0.29.0 | 1.18.1 | 1.28-1.31 | Q4 2024 |
| 0.28.0 | 1.16.1 | 1.25-1.30 | Q2 2024 |
| 0.27.0 | 1.15.2 | 1.24-1.28 | Q4 2023 |

### 4.2 Tương Thích Với Hanas Services

| Service | Phiên Bản | Tích Hợp Vault | Phương Pháp | Ghi Chú |
|---------|-----------|:---:|-------------|---------|
| **Apache NiFi** | 1.14+ / 2.x | ✅ | Native `HashiCorpVaultParameterProvider` | Yêu cầu NiFi ≥ 1.14.0 |
| **Apache Kafka** | Confluent 7.x / Apache 3.x | ✅ | Agent Injector / VSO | SCRAM + mTLS credentials |
| **Apache Airflow** | 2.x+ | ✅ | Native `VaultBackend` | Provider: `apache-airflow-providers-hashicorp` |
| **MinIO** | Latest | ✅ | KES → Vault KMS | Server-Side Encryption |
| **Apache Spark** | 3.4+ | ✅ | Agent Injector sidecar | JDBC credentials injection |
| **Dremio** | 24.x+ | ✅ | VSO → K8s Secrets | Source connection credentials |
| **dbt** | 1.x+ | ✅ | AppRole + env vars | CI/CD pipeline integration |
| **DataHub** | 0.12+ | ✅ | VSO → K8s Secrets | MySQL, Kafka, ES credentials |
| **Dify** | Latest | ✅ | VSO → K8s Secrets | LLM keys, DB, Redis creds |
| **vLLM** | Latest | ✅ | VSO → K8s Secrets | Model access tokens |
| **Langfuse** | Latest | ✅ | VSO / Database Engine | Dynamic PostgreSQL creds |
| **OpenObserve** | Latest | ✅ | VSO → K8s Secrets | Storage credentials |
| **Kubernetes** | ≥ 1.29 | ✅ | Native K8s auth method | ServiceAccount token auth |

---

## 5. Yêu Cầu Hệ Thống

| Yêu Cầu | Minimum | Khuyến Nghị (Production HA) |
|----------|---------|----------------------------|
| **OS** | Linux (amd64/arm64) | Linux amd64 |
| **CPU** | 2 cores | 4-8 cores × 3 nodes |
| **RAM** | 2 GB | 8 GB × 3 nodes |
| **Disk** | 10 GB | 50-100 GB SSD × 3 nodes |
| **Kubernetes** | ≥ 1.29 | Latest stable |
| **Helm** | ≥ 3.6 | Latest stable |
| **Container Runtime** | Docker / containerd | containerd |

---

## 6. Upgrade Path

### 6.1 Upgrade Process

| Bước | Hành Động | Chi Tiết |
|------|-----------|---------|
| 1 | **Backup** | Tạo Raft snapshot: `vault operator raft snapshot save` |
| 2 | **Review Release Notes** | Kiểm tra breaking changes, deprecations |
| 3 | **Test trên Staging** | Deploy version mới trên staging cluster trước |
| 4 | **Update Helm values** | Thay đổi `server.image.tag` sang version mới |
| 5 | **Rolling upgrade** | `helm upgrade vault hashicorp/vault --values vault-values.yaml` |
| 6 | **Unseal nodes** | Mỗi node cần unseal lại sau restart |
| 7 | **Verify cluster** | `vault operator raft list-peers`, `vault status` |
| 8 | **Test policy enforcement** | Verify tất cả services vẫn lấy secrets bình thường |

### 6.2 Downtime Expectations

| Thành Phần | Downtime |
|------------|----------|
| **Vault API** | Rolling restart — minimal downtime (30s per node) |
| **Secret Access** | Agent Injector / VSO cache secrets — **zero app downtime** |
| **Audit Logging** | Buffered — events ghi lại sau khi Vault up |

### 6.3 Rollback

```bash
# Nếu upgrade thất bại — rollback Helm release
helm rollback vault <PREVIOUS_REVISION> --namespace vault

# Nếu data corruption — restore từ snapshot
vault operator raft snapshot restore -force /backup/vault-pre-upgrade.snap
```

> **Quan trọng**: Luôn tạo Raft snapshot **trước khi upgrade**. Vault không hỗ trợ downgrade version — chỉ có thể restore từ backup.

---

## 7. OpenBao — Open-Source Fork

Từ khi HashiCorp chuyển sang BSL, cộng đồng đã tạo [OpenBao](https://openbao.org/) — fork mã nguồn mở (MPL 2.0) của Vault:

| Tiêu Chí | HashiCorp Vault | OpenBao |
|----------|----------------|---------|
| **License** | BSL 1.1 | MPL 2.0 (pure open-source) |
| **Maintained by** | HashiCorp / IBM | Linux Foundation |
| **API Compatible** | ✅ | ✅ (drop-in replacement) |
| **Production Ready** | ✅ GA | ⚠️ Early stage |
| **Ecosystem** | Mature (Helm, VSO, Agent) | Growing |

> **Hanas Platform hiện dùng HashiCorp Vault** vì ecosystem mature, documentation đầy đủ, và BSL không ảnh hưởng đến use case nội bộ. Sẽ theo dõi OpenBao như alternative trong tương lai.

---

## 8. Tham Khảo

| Nguồn | URL |
|-------|-----|
| **Vault Official Docs** | [developer.hashicorp.com/vault](https://developer.hashicorp.com/vault/docs) |
| **GitHub Repository** | [github.com/hashicorp/vault](https://github.com/hashicorp/vault) |
| **Vault Helm Chart** | [github.com/hashicorp/vault-helm](https://github.com/hashicorp/vault-helm) |
| **Vault Secrets Operator** | [github.com/hashicorp/vault-secrets-operator](https://github.com/hashicorp/vault-secrets-operator) |
| **Release Notes** | [github.com/hashicorp/vault/releases](https://github.com/hashicorp/vault/releases) |
| **OpenBao (OSS Fork)** | [openbao.org](https://openbao.org/) |
| **Vault Tutorials** | [developer.hashicorp.com/vault/tutorials](https://developer.hashicorp.com/vault/tutorials) |
