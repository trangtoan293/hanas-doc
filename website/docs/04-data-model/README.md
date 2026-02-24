---
sidebar_position: 4
---

# Lớp Mô Hình Dữ Liệu (Data Model)

## Tổng Quan

Lớp mô hình dữ liệu chịu trách nhiệm tổ chức, cấu trúc hóa và chuẩn hóa dữ liệu nhằm đảm bảo tính nhất quán, toàn vẹn, khả năng mở rộng và truy xuất nguồn gốc. Kiến trúc áp dụng phương pháp **Data Vault 2.0** — phương pháp mô hình hóa cho hệ thống dữ liệu phân tán quy mô lớn.

## Luồng Dữ Liệu Tổng Quan

```mermaid
flowchart TB
    subgraph Source["Data Sources"]
        OGG[Oracle GoldenGate]
        FILE[File Upload]
    end
    
    subgraph Landing["Landing Zone"]
        LND["Raw Data<br/>Partition by OP_TIME"]
    end
    
    subgraph DataVault["Data Vault 2.0"]
        subgraph RawVault["Raw Vault"]
            RV["Hub, Link, Satellite<br/>Hash Keys, History"]
        end
        
        subgraph BizVault["Business Vault"]
            BV["Business Logic<br/>Reusable Components"]
        end
    end
    
    subgraph DataMart["Data Mart"]
        DM["Star Schema<br/>Enriched Data"]
    end
    
    Source --> Landing
    Landing --> RawVault
    RawVault --> BizVault
    BizVault --> DataMart
    
    style Landing fill:#fff3e0,stroke:#ef6c00
    style RawVault fill:#e8f5e9,stroke:#388e3c
    style BizVault fill:#e3f2fd,stroke:#1976d2
    style DataMart fill:#f3e5f5,stroke:#7b1fa2
```

## Kiến Trúc Ba Lớp

```mermaid
flowchart TB
    subgraph InfoMart["Information Mart"]
        IM["Star Schema, Wide Table<br/>Analytical Views"]
        IM_NOTE["<i>Phục vụ BI, Báo cáo</i>"]
    end
    
    subgraph BusinessVault["Business Vault"]
        BV["PIT, Bridge<br/>Business Satellite"]
        BV_NOTE["<i>Logic nghiệp vụ nâng cao</i>"]
    end
    
    subgraph RawVault["Raw Vault"]
        RV["Hub, Link, Satellite"]
        RV_NOTE["<i>Dữ liệu gốc đã chuẩn hóa</i>"]
    end
    
    RawVault --> BusinessVault
    BusinessVault --> InfoMart
    
    style InfoMart fill:#e3f2fd,stroke:#1976d2,stroke-width:3px
    style BusinessVault fill:#fff3e0,stroke:#ef6c00,stroke-width:3px
    style RawVault fill:#e8f5e9,stroke:#388e3c,stroke-width:3px
    style IM_NOTE fill:none,stroke:none
    style BV_NOTE fill:none,stroke:none
    style RV_NOTE fill:none,stroke:none
```

## Thành Phần Chính

| Thành phần | Mô tả | Công nghệ |
|------------|-------|-----------|
| **Landing** | Vùng tiếp nhận dữ liệu thô từ source | OGG, File Upload |
| **Raw Vault** | Dữ liệu mô hình hóa theo kiến trúc Data Vault 2.0 | Oracle, dbt |
| **Business Vault** | Logic nghiệp vụ phức tạp, tái sử dụng | Oracle, dbt |
| **Information Mart** | Dữ liệu chuẩn hóa phục vụ phân tích | Oracle |
| **Airflow** | Công cụ điều phối luồng xử lý dữ liệu | Apache Airflow |
| **dbt** | Công cụ transform tự động cho Raw Vault | dbt |

## Tại Sao Data Vault 2.0?

- **Schema Drift Tolerance**: Không bị phá vỡ khi nguồn thay đổi
- **Horizontal Scalability**: Hub/Link/Sat độc lập, xử lý song song
- **Full Historization**: Satellite append-only, giữ toàn bộ lịch sử
- **Metadata-driven**: Pipeline có thể tự động sinh từ metadata
- **Lakehouse-native**: Thiết kế append-only khớp với Iceberg/Parquet

## Data Vault 2.0 là gì?

Data Vault 2.0 là phương pháp mô hình hóa dữ liệu được phát triển bởi **Dan Linstedt**, thiết kế tối ưu cho:

- **Agility**: Linh hoạt với thay đổi nguồn dữ liệu
- **Scalability**: Mở rộng ngang (horizontal scaling)
- **Auditability**: Truy vết đầy đủ lịch sử thay đổi
- **Parallel Processing**: Xử lý song song các thành phần độc lập

### Ba Thành Phần Cốt Lõi

```mermaid
erDiagram
    HUB_CUSTOMER {
        string HASH_KEY_HUB PK
        string CUSTOMER_ID "Business Key"
        timestamp LOAD_DATE
        string RECORD_SOURCE
    }
    
    LINK_CUST_ACCT {
        string HASH_KEY_LINK PK
        string HASH_KEY_HUB_CUST FK
        string HASH_KEY_HUB_ACCT FK
        timestamp LOAD_DATE
        string RECORD_SOURCE
    }
    
    SAT_CUSTOMER {
        string HASH_KEY_SAT PK
        string HASH_KEY_HUB FK
        string HASH_DIFF
        string CUSTOMER_NAME
        string ADDRESS
        timestamp EFFECTIVE_FROM
        timestamp LOAD_DATE
    }
    
    HUB_CUSTOMER ||--o{ LINK_CUST_ACCT : "participates"
    HUB_CUSTOMER ||--o{ SAT_CUSTOMER : "described by"
```

## Landing Zone

### Mục Đích

Landing là nơi tiếp nhận dữ liệu thô từ các hệ thống nguồn mà **không có bất kỳ biến đổi nào**. Dữ liệu trong Landing Zone được lưu trữ tạm thờiphục vụ cho việc tải vào vùng Data Vault.

### Cột Hệ Thống Hỗ Trợ Truy Vết

| Cột | Mô tả | Nguồn |
|-----|-------|-------|
| `OP_TIME` | Thờigian phát sinh dữ liệu tại nguồn | Source |
| `OP_TYPE` | Loại thao tác CDC (INIT, INSERT, UPDATE, DELETE) | Source |
| `OP_NO` | System Change Number (SCN) | Source |
| `OP_RBA` | Redo Byte Address trong redo log | Source |

### Chiến Lược Partition

```sql
-- Partition theo ngày
PARTITION BY RANGE (OP_TIME) (
    PARTITION p20240101 VALUES LESS THAN (TO_DATE('2024-01-02', 'YYYY-MM-DD')),
    PARTITION p20240102 VALUES LESS THAN (TO_DATE('2024-01-03', 'YYYY-MM-DD')),
    ...
)
```

### Data Retention

- **Policy**: Xóa tự động dữ liệu cũ hơn 30 ngày
- **Method**: Partition drop hoặc truncate
- **Schedule**: Chạy hàng ngày qua Airflow

## So Sánh Với Các Phương Pháp Khác

| Tiêu chí | Kimball (Star Schema) | Inmon (3NF) | Data Vault 2.0 |
|----------|----------------------|-------------|----------------|
| **Flexibility** | Thấp | Trung bình | Cao |
| **Scalability** | Trung bình | Thấp | Cao |
| **Historization** | Phức tạp | Phức tạp | Tự nhiên |
| **Integration** | Khó khăn | Khó khăn | Dễ dàng |
| **Auditability** | Hạn chế | Hạn chế | Đầy đủ |
| **Agility** | Thấp | Thấp | Cao |

## Tài Liệu Chi Tiết

- [dbt](dbt/README.md) — Công cụ transformation SQL-based
- [Data Vault 2.0](data-vault/README.md) — Phương pháp mô hình hóa
- [Quy ước đặt tên](naming-conventions.md)

## Tài Liệu Tham Khảo

- [Data Vault 2.0](https://en.wikipedia.org/wiki/Data_vault_modeling) — Phương pháp mô hình hóa dữ liệu
- [AutomateDV](https://automate-dv.readthedocs.io/) — dbt package cho Data Vault 2.0
- [Data Vault Alliance](https://datavaultalliance.com/) — Tổ chức chuẩn hóa Data Vault
- [Dan Linstedt](https://danlinstedt.com/) — Tác giả Data Vault
