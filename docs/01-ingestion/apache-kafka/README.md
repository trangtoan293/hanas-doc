# Apache Kafka

## Tổng Quan

Apache Kafka là nền tảng truyền phát dữ liệu theo thời gian thực, thiết kế theo mô hình phân tán (distributed commit log). Kafka phục vụ thu nhận, lưu trữ, truyền tải và phân phối các luồng dữ liệu có tốc độ cao, độ trễ thấp, liên tục 24/7.

## Vai Trò Trong Platform

- Thu thập dữ liệu streaming từ các nguồn real-time (CDC, events, logs)
- Đảm bảo truyền tải dữ liệu tin cậy giữa các thành phần
- Hỗ trợ event replay, xử lý lại dữ liệu khi cần
- Buffer dữ liệu cho downstream processing (Spark, NiFi)

## Kiến Trúc Lõi

- **Topic**: Đơn vị logic nhóm các bản tin cùng loại
- **Partition**: Chia nhỏ topic để xử lý song song
- **Broker**: Máy chủ lưu trữ partition
- **Cluster**: Tập hợp các broker

## Tính Năng Chính

1. **Thông lượng cao**: Xử lý hàng trăm nghìn sự kiện/giây
2. **Độ trễ thấp**: Millisecond-level latency
3. **Mở rộng ngang**: Thêm broker không cần dừng hệ thống
4. **High Availability**: Replication, ISR, leader election tự động
5. **Event Replay**: Đọc lại dữ liệu bất kỳ thời điểm
6. **Consumer Groups**: Xử lý song song phân tán
7. **Bảo mật**: TLS, SASL, ACL theo topic

## Tài Liệu

- [Cài đặt & Triển khai](installation.md)
- [Cấu hình](configuration.md)
- [Hướng dẫn sử dụng](user-guide.md)
- [Best Practices](best-practices.md)
- [Thông tin Version](version-info.md)
