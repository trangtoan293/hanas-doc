# Lớp Xử Lý Dữ Liệu (Data Processing)

## Tổng Quan

Lớp xử lý dữ liệu chịu trách nhiệm thực thi và tối ưu toàn bộ hoạt động xử lý dữ liệu phân tán, từ khi dữ liệu thu thập đến khi sẵn sàng phục vụ phân tích và báo cáo.

| Thành phần | Vai trò |
|---|---|
| **Apache Spark** | Xử lý dữ liệu phân tán trong bộ nhớ (distributed compute) |
| **Apache Airflow** | Điều phối pipeline, dependency, retry và lịch chạy (được trình bày chi tiết ở [Lớp Orchestration](../14-orchestration/README.md)) |

## Services

- [Apache Spark](apache-spark/README.md) — Distributed Compute Engine

> Airflow là lớp điều phối xuyên suốt các pipeline; Spark thực thi các job xử lý. Không coi Airflow là compute engine thay thế Spark.
