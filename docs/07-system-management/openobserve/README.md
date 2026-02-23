# OpenObserve

## Tổng Quan

OpenObserve là nền tảng giám sát tập trung, thu thập và phân tích log, metrics và traces từ toàn bộ các thành phần trong Data Platform.

## Vai Trò Trong Platform

- Thu thập log từ tất cả services (NiFi, Kafka, Spark, Airflow...)
- Giám sát metrics hệ thống (CPU, RAM, disk, network)
- Theo dõi traces xuyên suốt pipeline
- Dashboard giám sát trực quan
- Cảnh báo sự cố tự động
- Hỗ trợ điều tra root cause analysis

## Tính Năng Chính

1. **Centralized Logging**: Thu thập log từ toàn bộ platform
2. **Metrics Collection**: Giám sát tài nguyên hệ thống
3. **Distributed Tracing**: Theo dõi luồng xử lý end-to-end
4. **Dashboards**: Trực quan hóa, tùy chỉnh theo vai trò
5. **Alerting**: Cảnh báo theo ngưỡng, gửi thông báo
6. **RBAC**: Phân quyền truy cập log/metric/dashboard

## Tài Liệu

- [Cài đặt & Triển khai](installation.md)
- [Cấu hình](configuration.md)
- [Hướng dẫn sử dụng](user-guide.md)
- [Best Practices](best-practices.md)
- [Thông tin Version](version-info.md)
