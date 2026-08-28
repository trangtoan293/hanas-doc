# DataHub - Thông Tin Version

## Version Hiện Tại

| Thông tin | Giá trị |
|---|---|
| **Version** | v0.14.1 (khuyến nghị) |
| **DataHub 1.0 GA** | Q1 2025 — first enterprise-ready release |
| **Helm Chart** | 0.8.x |
| **Ngày triển khai** | _Theo lịch project_ |
| **Môi trường** | Kubernetes |
| **License** | Apache License 2.0 |

## Component Versions

| Component | Image | Version |
|---|---|---|
| **DataHub GMS** | `acryldata/datahub-gms` | v0.14.1 |
| **DataHub Frontend** | `acryldata/datahub-frontend-react` | v0.14.1 |
| **MAE Consumer** | `acryldata/datahub-mae-consumer` | v0.14.1 |
| **MCE Consumer** | `acryldata/datahub-mce-consumer` | v0.14.1 |
| **DataHub Actions** | `acryldata/datahub-actions` | v0.1.1 |
| **DataHub CLI** | `acryldata-datahub` (PyPI) | ≥ 0.14.1 |

## Dependencies

| Dependency | Version khuyến nghị | Ghi chú |
|---|---|---|
| **Elasticsearch** | 7.17.x / OpenSearch 2.x | Search index backend |
| **MySQL** | 8.0+ | Primary metadata store |
| **PostgreSQL** | 14+ | Alternative cho MySQL |
| **Kafka** | 3.x (Confluent 7.x) | Internal message bus |
| **ZooKeeper** | 3.8+ | Kafka coordination |

## Tương Thích Với Hanas Platform

| Service | Version Hanas | Tích hợp DataHub | Phương thức |
|---|---|---|---|
| **Apache NiFi** | 2.x | Ingestion Recipe | Pull: provenance events, flow lineage |
| **Apache Kafka** | 3.x (Confluent) | Ingestion Recipe | Pull: topics, schemas, consumer groups |
| **MinIO** | RELEASE.2025-04-22T22-12-26Z theo baseline | Via Iceberg/Hive | Indirect: qua Iceberg catalog metadata |
| **Apache Iceberg** | 1.8.1 theo runtime Spark | Ingestion Recipe | Pull: table schemas, partitions, snapshots |
| **Apache Airflow** | 2.x theo deployment | Plugin + TaskGroup | Push: DAG lineage, task metadata |
| **Apache Spark** | 3.5.x | Java Agent | Push: job lineage, dataset I/O |
| **dbt** | 1.8.x | Airflow TaskGroup | Push: model lineage, test results, docs |
| **Dremio** | 25.x | Ingestion Recipe | Pull: virtual datasets, query lineage |
| **Hive Metastore** | 3.1.x | Ingestion Recipe | Pull: database/table schemas |

## Lịch Sử Phiên Bản

| Version | Ngày | Thay đổi chính |
|---|---|---|
| **v1.0.0** | 2025-Q1 | Enterprise-ready GA, redesigned UI, AI asset support |
| **v0.14.1** | 2024-Q4 | Stability release, bug fixes, performance improvements |
| **v0.14.0** | 2024-Q4 | Column-level lineage GA, improved dbt integration |
| **v0.13.x** | 2024-Q3 | Domains GA, Glossary enhancements, RBAC improvements |
| **v0.12.x** | 2024-Q2 | Ingestion v2, stateful ingestion, Iceberg source support |
| **v0.11.x** | 2024-Q1 | Incidents, freshness assertions, UI redesign |

## Roadmap 2025

| Feature | Trạng thái | Ảnh hưởng Hanas |
|---|---|---|
| **Metrics Catalog** | Planned | Register & track KPIs từ Information Mart |
| **Universal Data Registry** | In Progress | Complete visibility toàn bộ data assets |
| **Policy Enforcement** | Planned | Auto-propagate classification & compliance tags |
| **Python SDK v2** | In Progress | Cải thiện programmatic metadata management |
| **AI & Context** | Released (v1.4) | Semantic search, Context Documents |
| **Enhanced Lineage** | In Progress | Hierarchical lineage, cross-platform tracing |

## Lưu Ý Upgrade

> **Khi upgrade DataHub, cần lưu ý:**
> - Backup MySQL + Elasticsearch **trước** khi upgrade
> - Kiểm tra [Migration Guide](https://datahubproject.io/docs/how/updating-datahub) cho từng version
> - Elasticsearch reindex có thể cần sau major upgrade
> - Test trên staging trước khi deploy production
> - Ingestion recipes có thể cần cập nhật config fields mới
