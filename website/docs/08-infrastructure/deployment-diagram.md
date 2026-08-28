# Sơ Đồ Triển Khai

## Lưu ý

Đây là sơ đồ triển khai tham chiếu cho môi trường on-premise. Sơ đồ production phải được thay bằng bản có IP/VLAN/DNS, số node, zone, firewall flow và endpoint thực tế đã được phê duyệt.

```mermaid
flowchart TB
    Users["Người dùng / BI / Ứng dụng"]
    Sources["Hệ thống nguồn<br/>RDBMS • File • API • CDC"]
    Ingress["Firewall / Load Balancer / Ingress<br/>TLS • SSO • Audit"]

    subgraph K8s["Kubernetes Cluster — Site DC"]
        subgraph Control["Control plane"]
            API["API Server / Scheduler / Controller"]
        end
        subgraph Data["Workload node pools"]
            Ingestion["NiFi • Kafka"]
            Compute["Airflow • Spark • dbt"]
            Serving["Dremio • Superset • DataHub"]
            AI["Dify • vLLM • Langfuse"]
            Security["Ranger • Vault"]
            Observe["OpenObserve / Collectors"]
        end
        subgraph State["Persistent state"]
            DB["PostgreSQL / MySQL / Metadata DB"]
            PV["Persistent Volumes"]
        end
    end

    Object[("MinIO Object Storage<br/>Landing • Vault • Mart • Backup")]
    DR[("MinIO Site DR")]
    Velero["Velero<br/>Cluster/PV Backup"]

    Users --> Ingress --> Serving
    Sources --> Ingress --> Ingestion
    Ingestion --> Object
    Compute --> Object
    Object --> Serving
    Object --> AI
    Control --> Data
    Data --> DB
    Data --> PV
    Data -. logs/metrics/traces .-> Observe
    Velero --> Object
    Object -. asynchronous replication .-> DR

    style K8s fill:#f7f9fc,stroke:#607d8b
    style Control fill:#e3f2fd,stroke:#1976d2
    style Data fill:#fff3e0,stroke:#ef6c00
    style State fill:#f3e5f5,stroke:#7b1fa2
    style Object fill:#e8f5e9,stroke:#388e3c
    style DR fill:#ffebee,stroke:#c62828
```

## Luồng kết nối chính

| Luồng | Giao tiếp tham chiếu | Kiểm soát |
|---|---|---|
| Nguồn → NiFi/Kafka | JDBC, SFTP/FTP, HTTPS, CDC, Kafka protocol | Firewall allowlist, credential riêng, TLS |
| Ingestion → MinIO | S3 API/HTTPS | Service account, bucket policy, encryption |
| Airflow → Spark/Kubernetes | Kubernetes API/CRD | ServiceAccount least privilege |
| Spark/dbt → Lakehouse | Catalog API/Thrift + S3 | Catalog role và S3 credential |
| Dremio → Lakehouse | Catalog + S3 | Read/write policy, query audit |
| BI → Dremio | JDBC/ODBC/Arrow Flight/HTTPS | SSO/RBAC, row/column policy |
| Service → OpenObserve | OTLP/HTTP, Fluent Bit/Vector, Prometheus remote write | TLS, token/Basic auth, stream policy |
| DC → DR | Site Replication qua network riêng | Allowlist, encryption, replication status |

## Deployment register

| Hạng mục | Giá trị production |
|---|---|
| Site DC/DR | `<CẦN ĐIỀN>` |
| Kubernetes cluster/context | `<CẦN ĐIỀN>` |
| Node pool và topology zone | `<CẦN ĐIỀN>` |
| MinIO endpoint/bucket | `<CẦN ĐIỀN>` |
| Catalog profile | `<HIVE DEV / POLARIS PROD / KHÁC>` |
| Ingress/DNS/TLS issuer | `<CẦN ĐIỀN>` |
| Network flow/firewall ticket | `<CẦN ĐIỀN>` |
| Backup location/retention | `<CẦN ĐIỀN>` |
| RPO/RTO được phê duyệt | `<CẦN ĐIỀN>` |

## Kiểm tra sau triển khai

- `kubectl get nodes` và `kubectl get pods -A` đạt trạng thái mong đợi.
- Các endpoint health/readiness của service phản hồi đúng.
- Source test → ingestion → object/table → Dremio → dashboard chạy thành công.
- Log/metric/trace xuất hiện trên OpenObserve; alert test được ghi nhận.
- Backup hoàn tất, object xuất hiện ở DR và restore test có biên bản.
