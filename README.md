# Hanas Data Platform - Tài Liệu Kỹ Thuật

> Bộ tài liệu kỹ thuật chuẩn cho Nền tảng Dữ liệu Hanas (Data Lakehouse Platform)

---

## Mục Lục

### [00 - Tổng Quan Platform](docs/00-overview/README.md)
Giới thiệu chung, kiến trúc tổng thể, mục tiêu và từ điển thuật ngữ.

### [01 - Lớp Thu Thập Dữ Liệu (Data Ingestion)](docs/01-ingestion/README.md)
- [Apache NiFi](docs/01-ingestion/apache-nifi/README.md) — Thu thập batch, ETL visual
- [Apache Kafka](docs/01-ingestion/apache-kafka/README.md) — Streaming, real-time

### [02 - Lớp Lưu Trữ Dữ Liệu (Data Storage)](docs/02-storage/README.md)
- [MinIO](docs/02-storage/minio/README.md) — Object Storage (S3-compatible)
- [Apache Iceberg](docs/02-storage/apache-iceberg/README.md) — Open Table Format

### [03 - Lớp Xử Lý Dữ Liệu (Data Processing)](docs/03-processing/README.md)
- [Apache Airflow](docs/03-processing/apache-airflow/README.md) — Orchestration & Scheduling
- [Apache Spark](docs/03-processing/apache-spark/README.md) — Distributed Compute Engine

### [04 - Lớp Mô Hình Dữ Liệu (Data Model)](docs/04-data-model/README.md)
- [dbt](docs/04-data-model/dbt/README.md) — SQL-based Transformation
- [Data Vault 2.0](docs/04-data-model/data-vault/README.md) — Phương pháp mô hình hóa dữ liệu

### [05 - Lớp Quản Trị Dữ Liệu (Data Governance)](docs/05-governance/README.md)
- [DataHub](docs/05-governance/datahub/README.md) — Metadata, Catalog, Lineage

### [06 - Lớp Liên Kết Dữ Liệu (Data Federation)](docs/06-federation/README.md)
- [Dremio](docs/06-federation/dremio/README.md) — Query Engine, Semantic Layer

### [07 - Lớp Quản Trị Hệ Thống (System Management)](docs/07-system-management/README.md)
- [OpenObserve](docs/07-system-management/openobserve/README.md) — Logging, Metrics, Tracing

### [08 - Hạ Tầng & Triển Khai (Infrastructure)](docs/08-infrastructure/README.md)
- [Kubernetes](docs/08-infrastructure/kubernetes/README.md) — Container Orchestration
- [DC-DR](docs/08-infrastructure/dc-dr/README.md) — Disaster Recovery

### [09 - An Toàn Thông Tin (Security)](docs/09-security/README.md)
- [Apache Ranger](docs/09-security/apache-ranger/README.md) — Authorization & Access Control
- [HashiCorp Vault](docs/09-security/hashicorp-vault/README.md) — Secrets Management

### [10 - Đào Tạo & Chuyển Giao (Training)](docs/10-training/README.md)
Quản trị hệ thống, quản trị dữ liệu, xử lý dữ liệu, khai thác dữ liệu.

### [11 - Bảo Hành & Bảo Trì (Maintenance)](docs/11-maintenance/README.md)
Quy trình bảo hành, bảo trì và SLA.

### [📘 Hướng Dẫn Thực Hành (Guides)](docs/guides/README.md)
- [Quickstart](docs/guides/quickstart.md) — Dựng environment + data flow đầu tiên
- [End-to-End Tutorial](docs/guides/end-to-end-tutorial.md) — Oracle → NiFi → Spark → dbt → Dremio → BI
- [Integration Guides](docs/guides/integration/) — Cách các service kết nối nhau
- [Code Examples](docs/guides/examples/) — DAG, dbt models, Spark jobs mẫu (từ production)
- [Troubleshooting](docs/guides/troubleshooting.md) — Xử lý sự cố thường gặp

---

## Danh Mục Services

| Lớp | Service | Vai Trò | Version |
|---|---|---|---|
| Ingestion | Apache NiFi | Thu thập batch, ETL visual | TBD |
| Ingestion | Apache Kafka | Streaming, real-time | TBD |
| Storage | MinIO | Object Storage (S3-compatible) | TBD |
| Storage | Apache Iceberg | Open Table Format | TBD |
| Processing | Apache Airflow | Orchestration, scheduling | TBD |
| Processing | Apache Spark | Distributed compute engine | TBD |
| Data Model | dbt | SQL-based transformation | TBD |
| Governance | DataHub | Metadata, catalog, lineage | TBD |
| Federation | Dremio | Query engine, semantic layer | TBD |
| System Mgmt | OpenObserve | Logging, metrics, tracing | TBD |
| Security | Apache Ranger | Authorization, access control | TBD |
| Security | HashiCorp Vault | Secrets management | TBD |
| Infra | Kubernetes | Container orchestration | TBD |
| Infra | Velero | K8s backup & recovery | TBD |
