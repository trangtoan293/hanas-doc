# Lớp Lưu Trữ Dữ Liệu (Data Storage)

## Tổng Quan

Lớp lưu trữ dữ liệu là nền tảng lưu trữ tập trung cho toàn bộ Data Lakehouse, đảm bảo khả năng lưu trữ dữ liệu lớn, đa dạng và mở rộng linh hoạt.

| Thành phần | Vai trò |
|---|---|
| **MinIO** | Object Storage phân tán, S3-compatible, lưu trữ vật lý |
| **Apache Iceberg** | Open Table Format, quản lý bảng transactional trên Data Lake |
| **Apache Polaris** | REST Catalog cho Iceberg, quản lý metadata tập trung, RBAC, credential vending |

## Tổ Chức Vùng Dữ Liệu

```mermaid
graph TD
    MinIO["🗄️ MinIO Object Storage"] --> Landing["📁 landing/<br/><i>Dữ liệu thô từ nguồn</i>"]
    MinIO --> RawVault["📁 raw-vault/<br/><i>Raw Vault<br/>Hub/Link/Satellite</i>"]
    MinIO --> BusinessVault["📁 business-vault/<br/><i>Business Vault<br/>PIT/Bridge</i>"]
    MinIO --> InfoMart["📁 information-mart/<br/><i>Data phục vụ BI/báo cáo</i>"]
    
    style MinIO fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style Landing fill:#fff8e1,stroke:#f57c00
    style RawVault fill:#e8f5e9,stroke:#388e3c
    style BusinessVault fill:#fce4ec,stroke:#c2185b
    style InfoMart fill:#f3e5f5,stroke:#7b1fa2
```

| Vùng | Mục đích | Nội dung |
|------|----------|----------|
| **landing/** | Dữ liệu thô từ nguồn | Files gốc từ NiFi/Kafka |
| **raw-vault/** | Raw Vault | Hub, Link, Satellite tables |
| **business-vault/** | Business Vault | PIT, Bridge, Business Satellite |
| **information-mart/** | Data Mart | Star Schema, Wide Tables cho BI |

## Services

- [MinIO](minio/README.md) — Object Storage
- [Apache Iceberg](apache-iceberg/README.md) — Open Table Format
- [Apache Polaris](data-catalog/README.md) — Data Catalog (REST Catalog cho Iceberg)
