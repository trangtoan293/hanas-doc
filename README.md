# Hanas Data Platform - Tài Liệu Kỹ Thuật

> Bộ tài liệu kỹ thuật chuẩn cho Nền tảng Dữ liệu Hanas (Data Lakehouse Platform)

---

## 🏗️ Cấu Trúc Repository

```
hanas_docs/
├── docs/                    # Tài liệu kỹ thuật gốc (Markdown)
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
│   ├── 10-training/        # Đào tạo
│   ├── 11-maintenance/     # Bảo hành & bảo trì
│   ├── 11-maintenance/     # Bảo hành & bảo trì
│   ├── 12-ai-service/      # Lớp AI Service (Dify, vLLM, Langfuse)
│   ├── guides/             # Hướng dẫn thực hành
│   ├── 12-ai-service/      # Lớp AI Service (Dify, vLLM, Langfuse)
│   ├── guides/             # Hướng dẫn thực hành
│   ├── package/            # Packages hỗ trợ
│   └── ref_AI/             # Tài liệu tham khảo AI
├── website/                 # Docusaurus website source
├── Nguyen_ly_thiet_ke.md   # Nguyên lý thiết kế hệ thống
└── docker-compose.yml      # Docker setup
```

---

## 🚀 Bắt Đầu Nhanh

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

## 📚 Mục Lục Tài Liệu

### [00 - Tổng Quan Platform](docs/00-overview/README.md)
- [Kiến trúc tổng thể](docs/00-overview/architecture.md)
- [Mục tiêu hệ thống](docs/00-overview/objectives.md)
- [Từ điển thuật ngữ](docs/00-overview/glossary.md)

### [01 - Lớp Thu Thập Dữ Liệu](docs/01-ingestion/README.md)
- [Apache NiFi](docs/01-ingestion/apache-nifi/) — Thu thập batch, ETL visual
  - [Cài đặt](docs/01-ingestion/apache-nifi/installation.md)
  - [Cấu hình](docs/01-ingestion/apache-nifi/configuration.md)
  - [Hướng dẫn sử dụng](docs/01-ingestion/apache-nifi/user-guide.md)
  - [Best practices](docs/01-ingestion/apache-nifi/best-practices.md)
- [Apache Kafka](docs/01-ingestion/apache-kafka/) — Streaming, real-time
  - [Cài đặt](docs/01-ingestion/apache-kafka/installation.md)
  - [Cấu hình](docs/01-ingestion/apache-kafka/configuration.md)
  - [Hướng dẫn sử dụng](docs/01-ingestion/apache-kafka/user-guide.md)
  - [Best practices](docs/01-ingestion/apache-kafka/best-practices.md)

### [02 - Lớp Lưu Trữ Dữ Liệu](docs/02-storage/README.md)
- [MinIO](docs/02-storage/minio/) — Object Storage (S3-compatible)
- [Apache Iceberg](docs/02-storage/apache-iceberg/) — Open Table Format

### [03 - Lớp Xử Lý Dữ Liệu](docs/03-processing/README.md)
- [Apache Airflow](docs/03-processing/apache-airflow/) — Orchestration & Scheduling
- [Apache Spark](docs/03-processing/apache-spark/) — Distributed Compute Engine

### [04 - Lớp Mô Hình Dữ Liệu](docs/04-data-model/README.md)
- [dbt](docs/04-data-model/dbt/) — SQL-based Transformation
- [Data Vault 2.0](docs/04-data-model/data-vault/) — Phương pháp mô hình hóa
- [Naming Conventions](docs/04-data-model/naming-conventions.md)

### [05 - Lớp Quản Trị Dữ Liệu](docs/05-governance/README.md)
- [DataHub](docs/05-governance/datahub/) — Metadata, Catalog, Lineage

### [06 - Lớp Liên Kết Dữ Liệu](docs/06-federation/README.md)
- [Dremio](docs/06-federation/dremio/) — Query Engine, Semantic Layer

### [07 - Lớp Quản Trị Hệ Thống](docs/07-system-management/README.md)
- [OpenObserve](docs/07-system-management/openobserve/) — Logging, Metrics, Tracing

### [08 - Hạ Tầng & Triển Khai](docs/08-infrastructure/README.md)
- [Kubernetes](docs/08-infrastructure/kubernetes/) — Container Orchestration
- [DC-DR](docs/08-infrastructure/dc-dr/) — Disaster Recovery
- [Sơ đồ triển khai](docs/08-infrastructure/deployment-diagram.md)

### [09 - An Toàn Thông Tin](docs/09-security/README.md)
- [Apache Ranger](docs/09-security/apache-ranger/) — Authorization & Access Control
- [HashiCorp Vault](docs/09-security/hashicorp-vault/) — Secrets Management
- [Authentication](docs/09-security/authentication.md)
- [Authorization](docs/09-security/authorization.md)

### [10 - Đào Tạo & Chuyển Giao](docs/10-training/README.md)
- [System Admin Training](docs/10-training/system-admin-training.md)
- [Data Governance Training](docs/10-training/data-governance-training.md)
- [Data Processing Training](docs/10-training/data-processing-training.md)
- [Data Consumer Training](docs/10-training/data-consumer-training.md)

### [11 - Bảo Hành & Bảo Trì](docs/11-maintenance/README.md)
- [Quy trình bảo hành](docs/11-maintenance/warranty-process.md)
- [Quy trình bảo trì](docs/11-maintenance/maintenance-process.md)
- [SLA](docs/11-maintenance/sla.md)

### [12 - Lớp AI Service](website/docs/12-ai-service/README.md)
AI Workflow, Inference & Observability — Mở rộng platform với khả năng AI.
- [Dify](website/docs/12-ai-service/dify/) — AI Workflow Platform (chatbot, RAG, agent)
- [vLLM](website/docs/12-ai-service/vllm/) — LLM Inference Engine (OpenAI-compatible API)
- [Langfuse](website/docs/12-ai-service/langfuse/) — LLM Observability (tracing, evaluation)

### [📘 Hướng Dẫn Thực Hành](docs/guides/README.md)
- [Quickstart](docs/guides/quickstart.md) — Dựng environment + data flow đầu tiên
- [End-to-End Tutorial](docs/guides/end-to-end-tutorial.md) — Oracle → NiFi → Spark → dbt → Dremio → BI
- [Integration Guides](docs/guides/integration/) — Cách các service kết nối nhau
- [Code Examples](docs/guides/examples/) — DAG, dbt models, Spark jobs mẫu
- [Troubleshooting](docs/guides/troubleshooting.md) — Xử lý sự cố thường gặp

---

## 📊 Danh Mục Services

| Lớp | Service | Vai Trò | Status |
|---|---|---|---|
| **Ingestion** | Apache NiFi | Thu thập batch, ETL visual | ✅ Documented |
| **Ingestion** | Apache Kafka | Streaming, real-time | ✅ Documented |
| **Storage** | MinIO | Object Storage (S3-compatible) | ✅ Documented |
| **Storage** | Apache Iceberg | Open Table Format | ✅ Documented |
| **Processing** | Apache Airflow | Orchestration, scheduling | ✅ Documented |
| **Processing** | Apache Spark | Distributed compute engine | ✅ Documented |
| **Data Model** | dbt | SQL-based transformation | ✅ Documented |
| **Governance** | DataHub | Metadata, catalog, lineage | ✅ Documented |
| **Federation** | Dremio | Query engine, semantic layer | ✅ Documented |
| **System Mgmt** | OpenObserve | Logging, metrics, tracing | ✅ Documented |
| **Security** | Apache Ranger | Authorization, access control | ✅ Documented |
| **Security** | HashiCorp Vault | Secrets management | ✅ Documented |
| **Infra** | Kubernetes | Container orchestration | ✅ Documented |
| **Infra** | Velero | K8s backup & recovery | ✅ Documented |
| **AI Service** | Dify | AI Workflow Platform | ✅ Documented |
| **AI Service** | vLLM | LLM Inference Engine | ✅ Documented |
| **AI Service** | Langfuse | LLM Observability | ✅ Documented |

---

## 🛠️ Tài Nguyên Bổ Sung

### 📦 Packages
- [ktl_airflow_utils](docs/package/ktl_airflow_utils/) — Utilities cho Apache Airflow

### 🤖 Tài Liệu Tham Khảo AI
- [Dify README](docs/ref_AI/Dify_README.md)
- [Use Cases](docs/ref_AI/use_case.md)
- [vLLM Docker Setup](docs/ref_AI/vllm_docker/)

### 📄 Tài Liệu Thiết Kế
- [Nguyên lý thiết kế (PDF)](docs/Nguyen_ly_thiet_ke.pdf)
- [Nguyên lý thiết kế (Markdown)](docs/Nguyen_ly_thiet_ke.md)

---

## 🌐 Website

Tài liệu được xây dựng bằng [Docusaurus](https://docusaurus.io/) và được tự động deploy.

```bash
# Local development (yêu cầu Node.js 20+)
cd website
npm install
npm start
```

---

## 🤝 Đóng Góp

1. Fork repository
2. Tạo branch feature (`git checkout -b feature/amazing-feature`)
3. Commit thay đổi (`git commit -m 'Add amazing feature'`)
4. Push lên branch (`git push origin feature/amazing-feature`)
5. Mở Pull Request


