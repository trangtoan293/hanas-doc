# Apache NiFi

## Tổng Quan

Apache NiFi là nền tảng xử lý và phân phối dữ liệu theo mô hình flow-based, cung cấp giao diện đồ họa trực quan (web-based UI) để thiết kế, quản lý và giám sát các luồng dữ liệu. NiFi đóng vai trò thu thập dữ liệu batch trong kiến trúc Hanas Data Platform.

## Vai Trò Trong Platform

- Thu thập dữ liệu từ đa nguồn (RDBMS, file, API, SFTP...)
- Chuyển đổi và chuẩn hóa dữ liệu trước khi đưa vào Data Lake
- Điều phối luồng dữ liệu end-to-end với giao diện visual
- Giám sát, kiểm soát và truy vết dữ liệu (Data Provenance)

## Tính Năng Chính

1. **Kết nối đa nguồn**: JDBC, SFTP, HTTP, S3, Kafka, API REST...
2. **Xử lý inline**: Chuyển đổi, lọc, làm giàu dữ liệu trong luồng
3. **Quản lý áp suất ngược (Back Pressure)**: Kiểm soát tốc độ xử lý
4. **Hàng đợi ưu tiên**: Sắp xếp và điều phối FlowFile
5. **Bảo mật**: TLS, phân quyền truy cập, mã hóa dữ liệu
6. **Data Provenance**: Truy vết toàn bộ hành trình dữ liệu
7. **Pipeline replay**: Chạy lại pipeline khi có lỗi

## Tài Liệu

- [Cài đặt & Triển khai](installation.md)
- [Cấu hình](configuration.md)
- [Hướng dẫn sử dụng](user-guide.md)
- [Best Practices](best-practices.md)
- [Thông tin Version](version-info.md)
