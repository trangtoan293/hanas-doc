# DBT (data build tool)

## Tổng Quan

DBT là công cụ transformation dữ liệu SQL-based trong Hanas Data Platform, cho phép định nghĩa và quản lý logic chuyển đổi dữ liệu dưới dạng mã (analytics as code). Project `ktl_dbt` sử dụng **DBT-spark** kết hợp **Apache Iceberg** để quản lý toàn bộ mô hình Data Vault và Data Mart.

### Kiến Trúc Tổng Thể

```
Landing (Kafka Streaming)
    │
    ▼
Integration / Raw Vault (Hub → Link → Satellite)
    │
    ├── MDM (Cleanse → Validate → Match → Merge → Golden Records)
    │
    ▼
Data Mart (Dimension + Fact Tables)
```

### Thành Phần Chính

| Thành phần | Mô tả |
|---|---|
| **ktl_autovault** | Package tự sinh Data Vault models (Hub/Link/Sat/LSat) từ YAML config |
| **DBT-spark** | Adapter kết nối DBT với Apache Spark engine |
| **Apache Iceberg** | Table format cho ACID transactions, time travel, schema evolution |
| **Hive Metastore** | Quản lý metadata catalog |
| **MinIO S3** | Object storage cho dữ liệu warehouse |

## Vai Trò Trong Platform

- **Raw Vault**: Quản lý logic Hub, Link, Satellite, Link-Satellite với incremental load
- **MDM (Master Data Management)**: Pipeline làm sạch, validate, match, merge dữ liệu khách hàng
- **Data Mart**: Tạo Dimension và Fact tables cho BI/báo cáo (huy động, cho vay, lợi nhuận)
- **Version Control**: Git-based collaboration cho logic biến đổi dữ liệu
- **Automated Documentation**: Tự động sinh catalog.json và DBT docs
- **Lakehouse Logging**: Ghi log chi tiết job/SQL execution vào Iceberg tables

## Cấu Trúc Dự Án

```
DBT-project/
├── dbt_project.yml              # Cấu hình chính DBT project
├── profiles.yml                 # Connection profiles (Spark + Iceberg)
├── packages.yml                 # Package dependencies
├── dbt_runner.py                # Runner chính - chạy DBT models
├── dbt_compile.py               # Compile và xem compiled SQL
├── dbt_seed.py                  # Load seed data
├── dbt_lakehouse_logger.py      # Log execution metadata to Lakehouse
│
├── ktl_autovault_configs/       # YAML configs cho Data Vault auto-generation
│   ├── hub/                     # Hub entity configs
│   ├── lnk/                     # Link entity configs
│   ├── sat/                     # Satellite entity configs
│   └── lsat/                    # Link-Satellite entity configs
│
├── models/
│   ├── source/                  # Source definitions (landing tables)
│   ├── integration/             # Raw Vault models
│   │   ├── raw_vault/
│   │   │   ├── hub/             # Hub tables (hub_customer, hub_gl, hub_branch, hub_card)
│   │   │   ├── lnk/             # Link tables (lnk_branch_gl, lnk_branch_parent)
│   │   │   ├── sat/             # Satellite tables (main, snapshot _snp, derived _der)
│   │   │   └── lsat/            # Link-Satellite tables
│   │   └── vw_ref_eod.sql       # View tham chiếu thời gian EOD
│   ├── mdm/                     # MDM pipeline models
│   ├── data_mart/               # Dimension + Fact tables
│   └── mart_refactor/           # Refactored mart (intermediate, dims, facts)
│
├── macros/                      # Custom macros
│   ├── generate_schema_name.sql # Override schema naming
│   ├── mdm/                     # MDM-specific macros
│   ├── data_mart/               # Data mart macros
│   └── ktl_mdm_configs/         # MDM cleansing rule configs
│
├── seeds/                       # Seed data (CSV → Iceberg tables)
│   ├── ref_eod.csv              # Reference EOD dates
│   └── mdm/                     # MDM seed data
│
├── utils/                       # Python utilities
│   ├── datahub_publisher.py     # Publish metadata lên DataHub
│   ├── column_lineage_publisher.py  # Column-level lineage
│   ├── dbt_catalog.py           # Catalog builder
│   ├── dbt_artifacts_uploader.py    # Upload artifacts lên S3
│   ├── dbt_docs.py              # Docs generation
│   └── lakehouse_logger.py      # Lakehouse logging utility
│
└── packages/                    # Local packages
    └── ktl_autovault/           # AutoVault package
```

## Tính Năng Chính

1. **AutoVault Models**: Tự động sinh SQL cho Data Vault entities từ YAML config
2. **Incremental Load**: Xử lý tăng dần dựa trên `ref_eod_table` (EOD time window)
3. **MDM Pipeline**: Cleanse → Validate → Match → Merge → Golden Records
4. **DAG Management**: Quản lý dependency giữa models qua `ref()` và `source()`
5. **Lakehouse Logging**: Ghi metadata job/SQL vào Iceberg tables cho audit
6. **Artifact Management**: Upload manifest, run_results, catalog lên S3/MinIO
7. **DataHub Integration**: Publish metadata và column lineage lên DataHub
8. **Dual Execution Mode**: Hỗ trợ cả `dbtRunner` (in-process) và subprocess

## Tài Liệu

- [Cài đặt & Triển khai](installation.md)
- [Cấu hình](configuration.md)
- [Hướng dẫn sử dụng](user-guide.md)
- [Best Practices](best-practices.md)
- [Thông tin Version](version-info.md)
