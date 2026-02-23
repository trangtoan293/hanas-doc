# Apache Iceberg

## Tổng Quan

Apache Iceberg là định dạng bảng mở (open table format) cho Data Lake/Lakehouse, hỗ trợ quản lý dữ liệu quy mô lớn với ACID transactions, time travel và schema evolution.

## Vai Trò Trong Platform

- Quản lý bảng dữ liệu transactional trên MinIO
- Hỗ trợ ACID cho insert/update/delete/merge
- Time travel: truy vấn dữ liệu tại thời điểm quá khứ
- Schema evolution: thay đổi cấu trúc không cần rewrite dữ liệu
- Hidden partitioning: tối ưu truy vấn tự động

## Tính Năng Chính

1. **ACID Transactions**: Snapshot-based isolation
2. **Time Travel**: Truy vấn/rollback snapshot
3. **Schema Evolution**: Thêm/xóa/đổi tên cột an toàn
4. **Hidden Partitioning**: Partition logic ẩn, tối ưu tự động
5. **Metadata Pruning**: File-level statistics, partition pruning
6. **Tương thích**: Spark, Flink, Dremio, Trino, Hive

## Tài Liệu

- [Cài đặt & Triển khai](installation.md)
- [Cấu hình](configuration.md)
- [Hướng dẫn sử dụng](user-guide.md)
- [Best Practices](best-practices.md)
- [Thông tin Version](version-info.md)
