# Lớp Lưu Trữ Dữ Liệu (Data Storage)

## Tổng Quan

Lớp lưu trữ dữ liệu là nền tảng lưu trữ tập trung cho toàn bộ Data Lakehouse, đảm bảo khả năng lưu trữ dữ liệu lớn, đa dạng và mở rộng linh hoạt.

| Thành phần | Vai trò |
|---|---|
| **MinIO** | Object Storage phân tán, S3-compatible, lưu trữ vật lý |
| **Apache Iceberg** | Open Table Format, quản lý bảng transactional trên Data Lake |

## Tổ Chức Vùng Dữ Liệu

```
MinIO (Object Storage)
├── landing/          # Dữ liệu thô từ nguồn
├── raw-vault/        # Raw Vault (Hub/Link/Satellite)
├── business-vault/   # Business Vault
└── information-mart/ # Data phục vụ BI/báo cáo
```

## Services

- [MinIO](minio/README.md) — Object Storage
- [Apache Iceberg](apache-iceberg/README.md) — Open Table Format
