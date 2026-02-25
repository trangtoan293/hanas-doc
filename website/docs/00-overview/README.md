# Tổng Quan Hanas Data Platform

## Giới Thiệu

Hanas Data Platform là nền tảng dữ liệu hợp nhất (Data Lakehouse) tích hợp AI Service, được thiết kế để tiếp nhận, lưu trữ, xử lý, quản trị dữ liệu và vận hành ứng dụng AI một cách thống nhất. Nền tảng kết hợp linh hoạt giữa lưu trữ Data Lake, quản trị Data Warehouse và AI Workflow, phân tách thành nhiều lớp từ thu thập đến tiêu thụ dữ liệu và ứng dụng AI.

![Kiến trúc tổng thể Hanas Data Platform](hanas_architect.png)

## Kiến Trúc

| # | Lớp | Mô Tả | Services |
|---|---|---|---|
| 1 | **Thu thập dữ liệu** (Data Ingestion) | Kéo dữ liệu từ các nguồn vào Lakehouse (batch & streaming) | NiFi, Kafka |
| 2 | **Lưu trữ dữ liệu** (Data Storage) | Lưu trữ tập trung, đa định dạng, mở rộng linh hoạt | MinIO, Iceberg |
| 3 | **Xử lý dữ liệu** (Data Processing) | Điều phối, thực thi ETL/ELT, xử lý phân tán | Airflow, Spark |
| 4 | **Mô hình dữ liệu** (Data Model) | Tổ chức dữ liệu theo Data Vault 2.0 | dbt |
| 5 | **Quản trị dữ liệu** (Data Governance) | Metadata, catalog, lineage, data quality | DataHub |
| 6 | **Liên kết dữ liệu** (Data Federation) | Query engine, semantic layer, BI connectivity | Dremio |
| 7 | **Quản trị hệ thống** (System Mgmt) | Logging, metrics, tracing, alerting | OpenObserve |
| 8 | **Dịch vụ AI** (AI Service) | Quy trình AI, suy luận LLM, giám sát | Dify, vLLM, Langfuse |

## Tài Liệu Liên Quan

- [Kiến trúc tổng thể](architecture.md)
- [Mục tiêu Data Platform](objectives.md)
- [Từ điển thuật ngữ](glossary.md)

