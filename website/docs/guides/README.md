# Hướng Dẫn Thực Hành (Guides)

## Tổng Quan

Section này cung cấp hướng dẫn thực hành end-to-end, giúp team tự phát triển luồng dữ liệu hoàn chỉnh trên Hanas Data Platform.

## Bắt Đầu

| # | Tài liệu | Mô tả |
|---|---|---|
| 1 | [Quickstart](quickstart.md) | Dựng environment + chạy data flow đầu tiên |
| 2 | [End-to-End Tutorial](end-to-end-tutorial.md) | Tutorial đầy đủ từ Source → BI |

## Hướng Dẫn Tích Hợp (Integration Guides)

Hướng dẫn cách các service kết nối và tương tác với nhau:

| # | Tài liệu | Luồng |
|---|---|---|
| 1 | [NiFi → MinIO](integration/nifi-to-minio.md) | Thu thập batch → Landing Zone |
| 2 | [Airflow + Spark Pipeline](integration/airflow-spark-pipeline.md) | Orchestration + Processing |
| 3 | [Spark + Iceberg](integration/spark-iceberg-operations.md) | Đọc/ghi bảng Iceberg trên MinIO |
| 4 | [dbt + Data Vault](integration/dbt-data-vault.md) | Build Raw Vault → Business Vault → Mart |
| 5 | [Dremio + Lakehouse](integration/dremio-lakehouse.md) | Query engine + Semantic Layer |
| 6 | [Kafka Streaming](integration/kafka-streaming-flow.md) | CDC/Streaming → Spark → Iceberg |

## Code Examples

| # | Tài liệu | Nội dung |
|---|---|---|
| 1 | [NiFi Flow mẫu](examples/sample-nifi-flow.md) | Template flow JDBC → MinIO |
| 2 | [Airflow DAG mẫu](examples/sample-airflow-dag.md) | DAG xử lý Data Vault |
| 3 | [Spark Job mẫu](examples/sample-spark-job.md) | PySpark ETL job |
| 4 | [dbt Models mẫu](examples/sample-dbt-models.md) | Hub/Link/Satellite/Mart models |
| 5 | [Dremio Setup mẫu](examples/sample-dremio-setup.md) | Virtual dataset, reflection, workspace |

## Xử Lý Sự Cố

- [Troubleshooting](troubleshooting.md) — Lỗi thường gặp & cách xử lý
