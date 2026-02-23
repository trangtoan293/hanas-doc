# Apache Spark

## Tổng Quan

Apache Spark là engine xử lý dữ liệu phân tán trong bộ nhớ, đảm nhiệm các tác vụ xử lý phức tạp, khối lượng lớn: batch, streaming, SQL, machine learning.

## Vai Trò Trong Platform

- Xử lý dữ liệu batch quy mô lớn (ETL/ELT)
- Làm sạch, chuẩn hóa, biến đổi dữ liệu
- Xử lý Data Vault (Hub/Link/Satellite)
- Đọc/ghi dữ liệu Iceberg trên MinIO

## Tính Năng Chính

1. **In-memory Processing**: Xử lý nhanh trong bộ nhớ
2. **Distributed Computing**: Phân tán trên nhiều node
3. **Spark SQL**: Truy vấn dữ liệu bằng SQL
4. **Structured Streaming**: Xử lý dòng dữ liệu
5. **Tích hợp**: Iceberg, MinIO (S3), Kafka, Airflow

## Tài Liệu

- [Cài đặt & Triển khai](installation.md)
- [Cấu hình](configuration.md)
- [Hướng dẫn sử dụng](user-guide.md)
- [Best Practices](best-practices.md)
- [Thông tin Version](version-info.md)
