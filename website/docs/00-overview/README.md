# Tổng Quan Hanas Data Platform

## Giới Thiệu

Hanas Data Platform là nền tảng dữ liệu hợp nhất (Data Lakehouse), được thiết kế để tiếp nhận, lưu trữ, xử lý và quản trị dữ liệu một cách thống nhất. Nền tảng kết hợp linh hoạt giữa lưu trữ Data Lake và quản trị Data Warehouse, phân tách thành nhiều lớp từ thu thập đến tiêu thụ dữ liệu.

![Kiến trúc tổng thể Hanas Data Platform](hanas_architect.png)

## Kiến Trúc 7 Lớp

| # | Lớp | Mô Tả | Services |
|---|---|---|---|
| 1 | **Thu thập dữ liệu** (Ingestion) | Kéo dữ liệu từ các nguồn vào Lakehouse (batch & streaming) | NiFi, Kafka |
| 2 | **Lưu trữ dữ liệu** (Storage) | Lưu trữ tập trung, đa định dạng, mở rộng linh hoạt | MinIO, Iceberg |
| 3 | **Xử lý dữ liệu** (Processing) | Điều phối, thực thi ETL/ELT, xử lý phân tán | Airflow, Spark |
| 4 | **Mô hình dữ liệu** (Data Model) | Tổ chức dữ liệu theo Data Vault 2.0 | dbt |
| 5 | **Quản trị dữ liệu** (Governance) | Metadata, catalog, lineage, data quality | DataHub |
| 6 | **Liên kết dữ liệu** (Federation) | Query engine, semantic layer, BI connectivity | Dremio |
| 7 | **Quản trị hệ thống** (System Mgmt) | Logging, metrics, tracing, alerting | OpenObserve |

## Tài Liệu Liên Quan

- [Kiến trúc tổng thể](architecture.md)
- [Mục tiêu Data Platform](objectives.md)
- [Từ điển thuật ngữ](glossary.md)
