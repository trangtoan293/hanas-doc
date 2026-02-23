# MinIO

## Tổng Quan

MinIO là hệ thống lưu trữ đối tượng (Object Storage) phân tán, tương thích API S3. MinIO đóng vai trò lớp lưu trữ vật lý cốt lõi cho toàn bộ Data Lakehouse.

## Vai Trò Trong Platform

- Lưu trữ tập trung dữ liệu Landing, Raw Vault, Business Vault, Information Mart
- Phục vụ đồng thời nhiều engine (Spark, Dremio, NiFi)
- Lưu trữ dữ liệu lịch sử dài hạn (đối soát, kiểm toán)
- Backup storage cho Velero (DC-DR)

## Tính Năng Chính

1. **Object-based Storage**: Lưu trữ dạng đối tượng, không phụ thuộc thư mục vật lý
2. **Distributed Architecture**: Cluster nhiều node, mở rộng linh hoạt
3. **S3-compatible API**: Tương thích với toàn bộ hệ sinh thái S3
4. **Site Replication**: Đồng bộ dữ liệu DC-DR
5. **Phân quyền**: Policy-based access control

## Tài Liệu

- [Cài đặt & Triển khai](installation.md)
- [Cấu hình](configuration.md)
- [Hướng dẫn sử dụng](user-guide.md)
- [Best Practices](best-practices.md)
- [Thông tin Version](version-info.md)
