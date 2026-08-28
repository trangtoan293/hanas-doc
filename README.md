# Hanas Data Platform - Tài Liệu Kỹ Thuật

> Bộ tài liệu kỹ thuật chuẩn cho Nền tảng Dữ liệu Hanas (Data Lakehouse Platform)

---

## Cấu Trúc Repository

```
hanas_docs/
├── website/docs/            # Tài liệu Docusaurus (Source chính)
│   ├── 00-overview/        # Tổng quan Platform
│   ├── 01-ingestion/       # Lớp thu thập dữ liệu
│   ├── 02-storage/         # Lớp lưu trữ
│   ├── 03-processing/      # Lớp xử lý
│   ├── 04-data-model/      # Lớp mô hình dữ liệu
│   ├── 05-governance/      # Quản trị dữ liệu
│   ├── 06-federation/      # Liên kết dữ liệu
│   ├── 07-system-management/# Quản trị hệ thống
│   ├── 08-infrastructure/  # Hạ tầng & triển khai
│   ├── 09-security/        # An toàn thông tin
│   ├── 12-ai-service/      # Lớp AI Service (Dify, vLLM, Langfuse)
│   └── guides/             # Hướng dẫn thực hành
├── docs/                    # Tài liệu gốc (backup/sync từ website/docs)
├── website/                 # Docusaurus website source
└── docker-compose.yml      # Docker setup
```

---

## Bắt Đầu Nhanh

### Yêu Cầu

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Chạy Development (Hot Reload)

```bash
# Khởi động server dev tại http://localhost:3000
docker-compose --profile dev up docs-dev
```

### Chạy Production

```bash
# Build và chạy production tại http://localhost:80
docker-compose --profile prod up -d docs-prod
```

Xem thêm chi tiết tại [DOCKER.md](./DOCKER.md).

---

## Mục Lục Tài Liệu

### [00 - Tổng Quan Platform](website/docs/00-overview/README.md)
- [Kiến trúc tổng thể](website/docs/00-overview/architecture.md)
- [Mục tiêu hệ thống](website/docs/00-overview/objectives.md)
- [Từ điển thuật ngữ](website/docs/00-overview/glossary.md)

### [01 - Lớp Thu Thập Dữ Liệu](website/docs/01-ingestion/README.md)
- [Apache NiFi](website/docs/01-ingestion/apache-nifi/) — Thu thập batch, ETL visual
  - [Cài đặt](website/docs/01-ingestion/apache-nifi/installation.md)
  - [Cấu hình](website/docs/01-ingestion/apache-nifi/configuration.md)
  - [Hướng dẫn sử dụng](website/docs/01-ingestion/apache-nifi/user-guide.md)
  - [Best practices](website/docs/01-ingestion/apache-nifi/best-practices.md)
- [Apache Kafka](website/docs/01-ingestion/apache-kafka/) — Streaming, real-time
  - [Cài đặt](website/docs/01-ingestion/apache-kafka/installation.md)
  - [Cấu hình](website/docs/01-ingestion/apache-kafka/configuration.md)
  - [Hướng dẫn sử dụng](website/docs/01-ingestion/apache-kafka/user-guide.md)
  - [Best practices](website/docs/01-ingestion/apache-kafka/best-practices.md)

### [02 - Lớp Lưu Trữ Dữ Liệu](website/docs/02-storage/README.md)
- [MinIO](website/docs/02-storage/minio/) — Object Storage (S3-compatible)
- [Apache Iceberg](website/docs/02-storage/apache-iceberg/) — Open Table Format

### [03 - Lớp Xử Lý Dữ Liệu](website/docs/03-processing/README.md)
- [Apache Airflow](website/docs/14-orchestration/apache-airflow/) — Orchestration & Scheduling
- [Apache Spark](website/docs/03-processing/apache-spark/) — Distributed Compute Engine

### [04 - Lớp Mô Hình Dữ Liệu](website/docs/04-data-model/README.md)
- [dbt](website/docs/04-data-model/dbt/) — SQL-based Transformation
- [Data Vault 2.0](website/docs/04-data-model/data-vault/) — Phương pháp mô hình hóa
- [Naming Conventions](website/docs/04-data-model/naming-conventions.md)

### [05 - Lớp Quản Trị Dữ Liệu](website/docs/05-governance/README.md)
- [DataHub](website/docs/05-governance/datahub/) — Metadata, Catalog, Lineage

### [06 - Lớp Liên Kết Dữ Liệu](website/docs/06-federation/README.md)
- [Dremio](website/docs/06-federation/dremio/) — Query Engine, Semantic Layer

### [07 - Lớp Trực Quan Hóa](website/docs/13-visualization/README.md)
- [Apache Superset](website/docs/13-visualization/apache-superset/) — Dashboard và BI

### [08 - Lớp Quản Trị Hệ Thống](website/docs/07-system-management/README.md)
- [OpenObserve](website/docs/07-system-management/openobserve/) — Logging, Metrics, Tracing

### [09 - Hạ Tầng & Triển Khai](website/docs/08-infrastructure/README.md)
- [Kubernetes](website/docs/08-infrastructure/kubernetes/) — Container Orchestration
- [DC-DR](website/docs/08-infrastructure/dc-dr/) — Disaster Recovery
- [Sơ đồ triển khai](website/docs/08-infrastructure/deployment-diagram.md)

### [10 - An Toàn Thông Tin](website/docs/09-security/README.md)
- [Apache Ranger](website/docs/09-security/apache-ranger/) — Authorization & Access Control
- [HashiCorp Vault](website/docs/09-security/hashicorp-vault/) — Secrets Management
- [Authentication](website/docs/09-security/authentication.md)
- [Authorization](website/docs/09-security/authorization.md)

### [11 - Lớp AI Service](website/docs/12-ai-service/README.md)
AI Workflow, Inference & Observability — Mở rộng platform với khả năng AI.
- [Dify](website/docs/12-ai-service/dify/) — AI Workflow Platform (chatbot, RAG, agent)
- [vLLM](website/docs/12-ai-service/vllm/) — LLM Inference Engine (OpenAI-compatible API)
- [Langfuse](website/docs/12-ai-service/langfuse/) — LLM Observability (tracing, evaluation)

### [Hướng Dẫn Thực Hành](website/docs/guides/README.md)
- [Quickstart](website/docs/guides/quickstart.md) — Dựng environment + data flow đầu tiên
- [End-to-End Tutorial](website/docs/guides/end-to-end-tutorial.md) — Oracle → NiFi → Spark → dbt → Dremio → BI
- [Integration Guides](website/docs/guides/integration/) — Cách các service kết nối nhau
- [Code Examples](website/docs/guides/examples/) — DAG, dbt models, Spark jobs mẫu
- [Troubleshooting](website/docs/guides/troubleshooting.md) — Xử lý sự cố thường gặp

---

## Danh Mục Services

| Lớp | Service | Vai Trò | Status |
|---|---|---|---|
| **Ingestion** | Apache NiFi | Thu thập batch, ETL visual | Documented |
| **Ingestion** | Apache Kafka | Streaming, real-time | Documented |
| **Storage** | MinIO | Object Storage (S3-compatible) | Documented |
| **Storage** | Apache Iceberg | Open Table Format | Documented |
| **Processing** | Apache Airflow | Orchestration, scheduling | Documented |
| **Processing** | Apache Spark | Distributed compute engine | Documented |
| **Data Model** | dbt | SQL-based transformation | Documented |
| **Governance** | DataHub | Metadata, catalog, lineage | Documented |
| **Federation** | Dremio | Query engine, semantic layer | Documented |
| **System Mgmt** | OpenObserve | Logging, metrics, tracing | Documented |
| **Security** | Apache Ranger | Authorization, access control | Documented |
| **Security** | HashiCorp Vault | Secrets management | Documented |
| **Infra** | Kubernetes | Container orchestration | Documented |
| **Infra** | Velero | K8s backup & recovery | Documented |
| **AI Service** | Dify | AI Workflow Platform | Documented |
| **AI Service** | vLLM | LLM Inference Engine | Documented |
| **AI Service** | Langfuse | LLM Observability | Documented |

---

## Tài Nguyên Bổ Sung

### Tài Liệu Tham Khảo
- [Baseline triển khai](website/docs/00-overview/platform-baseline.md) — Phiên bản, endpoint, sizing, SLA và thông tin cần chốt
- [Tài liệu thuyết minh giải pháp kỹ thuật](website/docs/Thuyet%20minh%20giai%20phap%20ky%20thuat%20202602111.docx) — Tài liệu nguồn/đối chiếu nội bộ

---

## Website

Tài liệu được xây dựng bằng [Docusaurus](https://docusaurus.io/) và được tự động deploy.

```bash
# Local development (yêu cầu Node.js 20+)
cd website
npm install
npm start
```

---

## Đóng Góp

1. Fork repository
2. Tạo branch feature (`git checkout -b feature/amazing-feature`)
3. Commit thay đổi (`git commit -m 'Add amazing feature'`)
4. Push lên branch (`git push origin feature/amazing-feature`)
5. Mở Pull Request

---

## License

Copyright © 2024 Hanas Data Platform. All rights reserved.
