---
sidebar_position: 5
---

# Quy Ước Đặt Tên

## Tổng Quan

Quy ước đặt tên thống nhất giúp dễ dàng nhận diện loại đối tượng, mục đích sử dụng và vị trí trong kiến trúc Data Vault.

## Data Vault Objects

### Raw Vault

| Loại | Prefix | Ví dụ | Mô tả |
|------|--------|-------|-------|
| **Hub** | `hub_` | `hub_customer`, `hub_account` | Lưu trữ business key |
| **Link** | `lnk_` | `lnk_customer_account` | Quan hệ giữa các Hub |
| **Satellite** | `sat_` | `sat_customer_details` | Thuộc tính của Hub |
| **Link Satellite** | `lsat_` | `lsat_cust_acct_relation` | Thuộc tính của Link |
| **Link Satellite Effective** | `lsate_` | `lsate_cust_acct_eff` | Quan hệ có hiệu lực |

### Business Vault

| Loại | Prefix | Ví dụ | Mô tả |
|------|--------|-------|-------|
| **Bridge Table** | `brdg_` | `brdg_customer_account` | Pre-join nhiều bảng |
| **Point-In-Time** | `pit_` | `pit_customer` | Snapshot theo thờgian |
| **Business Satellite** | `sat_biz_` | `sat_biz_customer_kpi` | Satellite tính toán |

### Satellite Variants

| Loại | Hậu tố | Ví dụ | Mô tả |
|------|--------|-------|-------|
| **Main Satellite** | (none) | `sat_customer_detail` | Bảng lưu trữ chính |
| **Derived View** | `_der` | `sat_customer_detail_der` | View dữ liệu mới nhất |
| **Snapshot** | `_snp` | `sat_customer_detail_snp` | Bảng snapshot MERGE |

## Information Mart

| Loại | Prefix | Ví dụ | Mô tả |
|------|--------|-------|-------|
| **Fact Table** | `fct_` | `fct_transactions` | Bảng số liệu |
| **Dimension** | `dim_` | `dim_customer` | Bảng chiều |
| **Aggregate** | `agg_` | `agg_daily_summary` | Bảng tổng hợp |
| **Wide Table** | `wide_` | `wide_customer_360` | Bảng rộng denormalized |
| **Analytical View** | `v_` | `v_daily_transaction_summary` | View phân tích |

## Vùng Dữ Liệu (Schemas)

| Vùng | Schema Name | Mô tả |
|------|-------------|-------|
| **Landing** | `landing` | Dữ liệu thô từ nguồn |
| **Raw Vault** | `raw_vault` | Raw Vault (Hub/Link/Sat) |
| **Business Vault** | `business_vault` | Business Vault |
| **Information Mart** | `information_mart` | Mart phục vụ BI |
| **Reference** | `ref_` | Bảng tham chiếu |

## Reference Tables

| Loại | Prefix | Ví dụ | Mô tả |
|------|--------|-------|-------|
| **Reference Master** | `ref_` | `ref_product_type` | Bảng master tham chiếu |
| **Reference Transaction** | `ref_` | `ref_transaction_code` | Bảng transaction tham chiếu |

```sql
-- Ví dụ Ref Table
CREATE TABLE ref_product_type (
    product_type_code VARCHAR2(10),
    product_type_name VARCHAR2(100),
    
    -- System Columns (no hash columns)
    dv_src_ldt TIMESTAMP,
    dv_scn NUMBER,
    dv_rba VARCHAR2(50),
    dv_ldt TIMESTAMP
);
```

## Cột (Columns)

### Hash Columns

| Tên cột | Mô tả | Độ dài |
|---------|-------|--------|
| `hkey_hub` | Hash key của Hub | VARCHAR2(64) |
| `hkey_link` | Hash key của Link | VARCHAR2(64) |
| `hkey_sat` | Hash key của Satellite | VARCHAR2(64) |
| `hkey_lsat` | Hash key của Link Satellite | VARCHAR2(64) |
| `hash_diff` | Hash diff cho change detection | VARCHAR2(64) |

### System Columns (Data Vault)

| Tên cột | Mô tả | Kiểu dữ liệu |
|---------|-------|--------------|
| `dv_cdc_ops` | Loại thao tác CDC | VARCHAR2(10) |
| `dv_src_ldt` | Thờgian phát sinh tại nguồn | TIMESTAMP |
| `dv_scn` | System Change Number | NUMBER |
| `dv_rba` | Redo Byte Address | VARCHAR2(50) |
| `dv_src_rec` | Tên bảng Landing nguồn | VARCHAR2(100) |
| `dv_ldt` | Load Date Timestamp | TIMESTAMP |
| `dv_ccd` | Collision Code | VARCHAR2(10) |

### Information Mart Columns

| Tên cột | Mô tả | Kiểu dữ liệu |
|---------|-------|--------------|
| `*_key` | Surrogate key | NUMBER |
| `dim_*_key` | Foreign key đến Dimension | NUMBER |
| `is_current` | SCD Type 2 flag | VARCHAR2(1) |
| `effective_date` | Ngày hiệu lực | DATE |
| `expiry_date` | Ngày hết hiệu lực | DATE |
| `created_date` | Ngày tạo record | TIMESTAMP |
| `updated_date` | Ngày cập nhật | TIMESTAMP |

## Quy Tắc Đặt Tên

### 1. Quy Tắc Chung

- Sử dụng **chữ thường** và dấu gạch dưới
- Tên phải **mô tả rõ ràng** nội dung
- Tránh tên viết tắt không phổ biến
- Giới hạn độ dài: **tối đa 30 ký tự** (Oracle limit)

### 2. Tên Bảng

```
<prefix>_<business_entity>[_<descriptor>]

Ví dụ:
- hub_customer           (Hub cho Customer)
- sat_customer_detail    (Satellite chi tiết Customer)
- lnk_cust_acct          (Link Customer-Account)
- fct_transactions       (Fact Transactions)
- dim_customer           (Dimension Customer)
- brdg_acct_limit        (Bridge Account Limit)
- pit_customer           (Point-In-Time Customer)
```

### 3. Tên Cột

```
-- Hash columns
hkey_hub
hkey_link
hkey_sat
hash_diff

-- Business keys
customer_id
account_number
product_code

-- Attributes
customer_name
account_balance
product_category

-- System columns
dv_src_ldt
dv_ldt
dv_cdc_ops
```

### 4. Tên Constraint

```sql
-- Primary Key
CONSTRAINT pk_hub_customer PRIMARY KEY (hkey_hub)
CONSTRAINT pk_sat_cust_detail PRIMARY KEY (hkey_sat, dependent_key)

-- Foreign Key
CONSTRAINT fk_lnk_cust FOREIGN KEY (hkey_hub_customer) 
    REFERENCES hub_customer(hkey_hub)

-- Unique
CONSTRAINT uk_hub_customer UNIQUE (customer_id)

-- Check
CONSTRAINT chk_sat_cust_ops CHECK (dv_cdc_ops IN ('INIT', 'INSERT', 'UPDATE', 'DELETE'))
```

### 5. Tên Index

```sql
-- Standard index
CREATE INDEX idx_sat_cust_hkey ON sat_customer_detail(hkey_hub);

-- Composite index
CREATE INDEX idx_lnk_cust_acct ON lnk_cust_acct(hkey_hub_customer, hkey_hub_account);

-- Function-based index
CREATE INDEX idx_sat_cust_date ON sat_customer_detail(TRUNC(dv_src_ldt));

-- Bitmap index (for low cardinality)
CREATE BITMAP INDEX bidx_fct_type ON fct_transactions(transaction_type);
```

## Ví Dụ Đầy Đủ

### Raw Vault

```sql
-- Hub Table
CREATE TABLE hub_customer (
    hkey_hub VARCHAR2(64) NOT NULL,
    customer_id VARCHAR2(50) NOT NULL,
    dv_cdc_ops VARCHAR2(10),
    dv_src_ldt TIMESTAMP,
    dv_scn NUMBER,
    dv_rba VARCHAR2(50),
    dv_src_rec VARCHAR2(100),
    dv_ldt TIMESTAMP,
    dv_ccd VARCHAR2(10) DEFAULT 'NAB',
    CONSTRAINT pk_hub_customer PRIMARY KEY (hkey_hub)
);

-- Link Table
CREATE TABLE lnk_cust_acct (
    hkey_link VARCHAR2(64) NOT NULL,
    hkey_hub_customer VARCHAR2(64) NOT NULL,
    hkey_hub_account VARCHAR2(64) NOT NULL,
    driven_key_hub VARCHAR2(64),
    dv_cdc_ops VARCHAR2(10),
    dv_src_ldt TIMESTAMP,
    dv_scn NUMBER,
    dv_rba VARCHAR2(50),
    dv_src_rec VARCHAR2(100),
    dv_ldt TIMESTAMP,
    CONSTRAINT pk_lnk_cust_acct PRIMARY KEY (hkey_link),
    CONSTRAINT fk_lnk_cust FOREIGN KEY (hkey_hub_customer) 
        REFERENCES hub_customer(hkey_hub),
    CONSTRAINT fk_lnk_acct FOREIGN KEY (hkey_hub_account) 
        REFERENCES hub_account(hkey_hub)
);

-- Satellite Table
CREATE TABLE sat_customer_detail (
    hkey_sat VARCHAR2(64) NOT NULL,
    hkey_hub VARCHAR2(64) NOT NULL,
    hash_diff VARCHAR2(64) NOT NULL,
    dependent_key VARCHAR2(50),
    customer_name VARCHAR2(200),
    address VARCHAR2(500),
    phone VARCHAR2(20),
    email VARCHAR2(100),
    dv_src_ldt TIMESTAMP,
    dv_scn NUMBER,
    dv_rba VARCHAR2(50),
    dv_ldt TIMESTAMP,
    CONSTRAINT pk_sat_cust_detail PRIMARY KEY (hkey_sat, dependent_key)
);
```

### Business Vault

```sql
-- Bridge Table
CREATE TABLE brdg_acct_transfer_limit (
    bridge_key VARCHAR2(64),
    hkey_hub_account VARCHAR2(64),
    hkey_hub_customer VARCHAR2(64),
    hkey_hub_product VARCHAR2(64),
    transfer_limit_amount NUMBER,
    daily_limit NUMBER,
    monthly_limit NUMBER,
    is_vip_account VARCHAR2(1),
    risk_category VARCHAR2(20),
    dv_ldt TIMESTAMP,
    CONSTRAINT pk_bridge_acct_tl PRIMARY KEY (bridge_key)
);

-- PIT Table
CREATE TABLE pit_customer (
    pit_key VARCHAR2(64),
    snapshot_date DATE,
    hkey_hub_customer VARCHAR2(64),
    hkey_sat_detail VARCHAR2(64),
    hkey_sat_address VARCHAR2(64),
    ldts_sat_detail TIMESTAMP,
    ldts_sat_address TIMESTAMP,
    dv_ldt TIMESTAMP,
    CONSTRAINT pk_pit_customer PRIMARY KEY (pit_key, snapshot_date)
);

-- Business Satellite
CREATE TABLE sat_biz_customer_kpi (
    hkey_sat VARCHAR2(64),
    hkey_hub VARCHAR2(64),
    hash_diff VARCHAR2(64),
    total_transactions NUMBER,
    avg_transaction_amount NUMBER,
    customer_segment VARCHAR2(50),
    risk_score NUMBER,
    dv_ldt TIMESTAMP,
    CONSTRAINT pk_sat_biz_cust_kpi PRIMARY KEY (hkey_sat)
);
```

### Information Mart

```sql
-- Fact Table
CREATE TABLE fct_transactions (
    transaction_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dim_customer_key NUMBER NOT NULL,
    dim_account_key NUMBER NOT NULL,
    dim_product_key NUMBER NOT NULL,
    dim_date_key NUMBER NOT NULL,
    transaction_id VARCHAR2(50),
    transaction_amount NUMBER(18,2),
    transaction_fee NUMBER(18,2),
    is_reversal VARCHAR2(1) DEFAULT 'N',
    created_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    source_system VARCHAR2(50)
);

-- Dimension Table
CREATE TABLE dim_customer (
    customer_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id VARCHAR2(50) NOT NULL,
    customer_name VARCHAR2(200),
    customer_segment VARCHAR2(50),
    risk_category VARCHAR2(20),
    effective_date DATE,
    expiry_date DATE,
    is_current VARCHAR2(1) DEFAULT 'Y',
    created_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    updated_date TIMESTAMP
);
```

## Checklist Đặt Tên

- [ ] Sử dụng prefix đúng cho loại đối tượng
- [ ] Tên mô tả rõ ràng nghiệp vụ
- [ ] Độ dài không quá 30 ký tự
- [ ] Sử dụng chữ thường và dấu gạch dưới
- [ ] Constraint names tuân theo quy ước
- [ ] Index names có prefix idx_ hoặc bidx_
- [ ] System columns theo quy ước dv_*
