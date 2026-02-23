# Quy Ước Đặt Tên

## Data Vault

| Loại | Prefix | Ví dụ |
|---|---|---|
| Hub | `hub_` | `hub_customer`, `hub_account` |
| Link | `lnk_` | `lnk_customer_account` |
| Satellite | `sat_` | `sat_customer_details` |
| PIT | `pit_` | `pit_customer` |
| Bridge | `brdg_` | `brdg_customer_account` |

## Information Mart

| Loại | Prefix | Ví dụ |
|---|---|---|
| Fact | `fct_` | `fct_transactions` |
| Dimension | `dim_` | `dim_customer` |

## Vùng Dữ Liệu

| Vùng | Mô tả |
|---|---|
| `landing` | Dữ liệu thô từ nguồn |
| `raw_vault` | Raw Vault (Hub/Link/Sat) |
| `business_vault` | Business Vault |
| `information_mart` | Mart phục vụ BI |

<-r TODO: Bổ sung quy ước đặt tên chi tiết -->
