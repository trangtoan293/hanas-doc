# Dremio

## Tổng Quan

Dremio là query engine thống nhất, ảo hóa toàn bộ nguồn dữ liệu vào một catalog logic. Hỗ trợ semantic layer, virtual datasets, acceleration layer và kết nối BI chuẩn (JDBC/ODBC/REST/Arrow Flight).

## Vai Trò Trong Platform

- Ảo hóa đa nguồn: Lakehouse, RDBMS, NoSQL → 1 catalog
- Semantic Layer: chuẩn hóa logic nghiệp vụ (measures, dimensions)
- Virtual Datasets: bảng logic không tạo bản sao vật lý
- Query Optimization: predicate pushdown, partition pruning
- Acceleration: tăng tốc truy vấn cho BI dashboard
- BI Connectivity: JDBC/ODBC/REST cho Superset, Tableau, PowerBI
- Workspace: quản lý không gian làm việc nhóm

## Tính Năng Chính

1. **Data Virtualization**: 1 catalog cho toàn bộ nguồn
2. **Query Optimizer**: Cost-based optimization, pushdown
3. **Acceleration Layer**: Pre-computed aggregations, joins
4. **Iceberg Integration**: Time travel, metadata pruning
5. **Semantic Layer**: Measures, dimensions, business views
6. **Workspace**: Phân quyền, cộng tác nhóm

## Tài Liệu

- [Cài đặt & Triển khai](installation.md)
- [Cấu hình](configuration.md)
- [Hướng dẫn sử dụng](user-guide.md)
- [Best Practices](best-practices.md)
- [Thông tin Version](version-info.md)
