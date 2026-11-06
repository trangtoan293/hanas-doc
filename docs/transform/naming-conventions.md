---
title: Quy ước đặt tên
sidebar_label: Quy ước đặt tên
sidebar_position: 6
description: Quy ước đặt tên namespace, bảng, view, cột và khóa cho dữ liệu medallion và Data Vault trên lakehouse.
---

Quy ước thống nhất giúp bạn nhận ra loại bảng, lớp dữ liệu và mục đích sử dụng chỉ từ tên. Quy ước dưới đây là khuyến nghị, đi kèm [chuẩn mô hình hóa](modeling-standards.md); nền tảng không cưỡng chế.

## Quy tắc chung

- Dùng chữ thường và dấu gạch dưới (`snake_case`), không dấu, không khoảng trắng.
- Tên mô tả rõ nội dung; tránh viết tắt không phổ biến.
- Dạng tên bảng: `<prefix>_<thực_thể>[_<mô_tả>]`.
- Dùng số ít cho thực thể (`customer`, không phải `customers`), trừ khi cả nhóm đã thống nhất khác.
- Giữ tên ngắn gọn. Nếu có hệ thống đích giới hạn độ dài tên, kiểm tra giới hạn đó trước khi chốt.

## Namespace theo lớp

| Lớp | Namespace gợi ý |
|---|---|
| Bronze / landing | `bronze` hoặc `landing` |
| Raw vault | `raw_vault` |
| Business vault | `business_vault` |
| Silver | `silver` |
| Information mart / gold | `information_mart` hoặc `gold` |
| Bảng tham chiếu | `reference` |

## Tiền tố bảng

### Raw vault

| Loại | Tiền tố | Ví dụ |
|---|---|---|
| Hub | `hub_` | `hub_customer` |
| Link | `lnk_` | `lnk_customer_account` |
| Satellite | `sat_` | `sat_customer_detail` |
| Link satellite | `lsat_` | `lsat_customer_account` |
| Effectivity satellite | `lsate_` | `lsate_customer_account` |

### Business vault

| Loại | Tiền tố | Ví dụ |
|---|---|---|
| Bridge | `brdg_` | `brdg_account_limit` |
| Point-in-time | `pit_` | `pit_customer` |
| Business satellite | `sat_biz_` | `sat_biz_customer_kpi` |

Biến thể satellite dùng hậu tố: `_der` cho view bản ghi hiện hành, `_snp` cho bảng snapshot. Ví dụ `sat_customer_detail_der`.

### Information mart

| Loại | Tiền tố | Ví dụ |
|---|---|---|
| Fact | `fct_` | `fct_transaction` |
| Dimension | `dim_` | `dim_customer` |
| Aggregate | `agg_` | `agg_daily_summary` |
| Wide table | `wide_` | `wide_customer_360` |
| View phân tích | `v_` | `v_daily_transaction_summary` |
| Bảng tham chiếu | `ref_` | `ref_product_type` |

### Model dbt

Trong dbt, tên model cũng là tên bảng đích, nên áp dụng cùng tiền tố. Model trung gian dùng tiền tố `int_`, bảng nguồn khai báo dùng `src_`, và model làm sạch ở silver dùng `stg_` nếu nhóm theo mô hình dbt chuẩn. Chọn một cách và dùng thống nhất trong cả project.

## Tên cột

### Khóa

| Cột | Ý nghĩa |
|---|---|
| `hkey_hub` | Hash key của hub. |
| `hkey_link` | Hash key của link. |
| `hkey_sat`, `hkey_lsat` | Hash key của satellite, link satellite. |
| `hash_diff` | Hash dùng phát hiện thay đổi thuộc tính. |
| `<thực_thể>_key` | Surrogate key của dimension. |
| `dim_<thực_thể>_key` | Khóa ngoại từ fact tới dimension. |
| `<thực_thể>_id` | Business key gốc, ví dụ `customer_id`. |

### Cột kỹ thuật

| Cột | Ý nghĩa |
|---|---|
| `dv_ldt` | Thời điểm nạp. |
| `dv_src_ldt` | Thời điểm phát sinh tại nguồn. |
| `dv_src_rec` | Nguồn của bản ghi. |
| `dv_cdc_ops` | Loại thao tác CDC. |
| `dv_ccd` | Mã xử lý va chạm khóa. |
| `is_current` | Cờ bản ghi hiện hành (SCD Type 2). |
| `effective_date`, `expiry_date` | Khoảng hiệu lực (SCD Type 2). |

Cột boolean đặt tên bắt đầu `is_` hoặc `has_`; cột thời điểm kết thúc `_ts` hoặc `_date` tùy kiểu dữ liệu; cột số tiền ghi kèm đơn vị khi không rõ, ví dụ `amount_vnd`.

## Ví dụ

```sql
create table raw_vault.hub_customer (
    hkey_hub    varchar not null,
    customer_id varchar not null,
    dv_cdc_ops  varchar,
    dv_src_ldt  timestamp,
    dv_src_rec  varchar,
    dv_ldt      timestamp
);

create table raw_vault.sat_customer_detail (
    hkey_hub      varchar not null,
    hash_diff     varchar not null,
    customer_name varchar,
    phone         varchar,
    dv_src_ldt    timestamp,
    dv_ldt        timestamp
);
```

Kiểu dữ liệu và cú pháp tạo bảng phụ thuộc nơi bạn tạo: bảng Iceberg qua [SQL Editor](../query/sql-studio.md) (menu **Workspaces**) hoặc materialization của dbt.

## Giới hạn

:::caution Giới hạn hiện tại

Các tên constraint và index theo mẫu `pk_`, `fk_`, `idx_` chỉ áp dụng khi hệ thống đích hỗ trợ chúng. Bảng Iceberg không thực thi khóa chính hay khóa ngoại; hãy kiểm tra tính toàn vẹn bằng test dbt.

:::

## Tiếp theo

- [Chuẩn mô hình hóa](modeling-standards.md).
- [Phát triển model trong dbt Studio](dbt-studio.md).
- [Duyệt và tìm tài sản trong Catalog](../govern/catalog.md).
