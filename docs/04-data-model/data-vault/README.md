# Data Vault 2.0

## Tổng Quan

Data Vault 2.0 là phương pháp mô hình hóa dữ liệu cho hệ thống Data Warehouse/Lakehouse, thiết kế tối ưu cho tính mở rộng, tính bền vững và khả năng xử lý phân tán.

## Ba Lớp Mô Hình

| Lớp | Vai trò | Thành phần |
|---|---|---|
| **Raw Vault** | Lưu trữ dữ liệu gốc đã chuẩn hóa | Hub, Link, Satellite |
| **Business Vault** | Logic nghiệp vụ nâng cao | PIT, Bridge, Business Sat |
| **Information Mart** | Phục vụ báo cáo & phân tích | Star Schema, Wide Table |

## Tài Liệu Chi Tiết

- [Raw Vault](raw-vault.md) — Hub, Link, Satellite
- [Business Vault](business-vault.md) — PIT, Bridge, Business Satellite
- [Information Mart](information-mart.md) — Star Schema, Wide Table
