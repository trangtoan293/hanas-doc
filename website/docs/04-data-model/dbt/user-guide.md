# dbt - Hướng Dẫn Sử Dụng

## Chạy dbt Models

### Sử Dụng dbt_runner.py

`dbt_runner.py` là entry point chính, hỗ trợ 2 chế độ:

| Mode | Flag | Mô tả |
|---|---|---|
| **dbtRunner** | _(mặc định)_ | Chạy in-process, dùng cho single command |
| **subprocess** | `--use-subprocess` | Chạy subprocess, hỗ trợ multiple commands, recommended cho K8s |

```bash
# Chạy tất cả models
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev

# Chạy model cụ thể
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev --select hub_customer

# Chạy theo folder
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev --select integration.*

# Chạy multiple commands (deps → run → test) - dùng -- để phân tách
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev -- test --target dev
```

### Compile Models

```bash
# Compile tất cả models
python dbt_compile.py

# Compile model cụ thể
python dbt_compile.py --select hub_customer

# Compile với custom vars
python dbt_compile.py --select hub_customer --vars '{"cob_date": "2025-12-30"}'
```

Output sẽ hiển thị compiled SQL cho từng model:

```
──────────────────────────────────
Model: hub_customer
  Table: demo.integration.hub_customer
──────────────────────────────────
<compiled SQL code>
```

### Load Seed Data

```bash
# Load tất cả seeds
python dbt_seed.py

# Load seed cụ thể
python dbt_seed.py --select ref_eod

# Full refresh (drop & recreate)
python dbt_seed.py --full-refresh
```

## Tạo Data Vault Model Mới

### Bước 1: Tạo AutoVault Config

Tạo file YAML trong `ktl_autovault_configs/<entity_type>/`:

**Hub** (`ktl_autovault_configs/hub/hub_<entity>.yml`):
```yaml
source_schema: landing
source_table: <source_streaming_table>
target_entity_type: hub
target_schema: integration
target_table: hub_<entity>
collision_code: demo
columns:
  - target: dv_hkey_hub_<entity>
    key_type: hash_key_hub
    dtype: string
    source:
      - <BUSINESS_KEY>
  - target: <BUSINESS_KEY>
    key_type: biz_key
    dtype: string
    source:
      name: <BUSINESS_KEY>
      dtype: string
```

**Satellite** (`ktl_autovault_configs/sat/sat_<entity>.yml`):
```yaml
source_schema: landing
source_table: <source_streaming_table>
target_entity_type: sat
target_schema: integration
target_table: sat_<entity>
parent_table: hub_<entity>
collision_code: demo
columns:
  - target: dv_hkey_sat_<entity>
    key_type: hash_key_sat
    dtype: string
  - target: dv_hkey_hub_<entity>
    key_type: hash_key_hub
    dtype: string
    source:
      - <BUSINESS_KEY>
  - target: dv_hsh_dif
    dtype: string
    key_type: hash_diff
  # Thêm các attribute columns...
  - target: <COLUMN_NAME>
    dtype: string
    source:
      name: <SOURCE_COLUMN>
      dtype: string
```

### Bước 2: Tạo dbt Model SQL

**Hub model** (`models/integration/raw_vault/hub/hub_<entity>.sql`):
```sql
{{ config(
    materialized='incremental',
    file_format='iceberg',
    incremental_strategy='merge'
) }}

{%- set hub = dv_config('hub_<entity>') -%}
{%- set dv_system = var("dv_system") -%}

{{ ktl_autovault.hub_transform(model=hub, dv_system=dv_system, include_ghost_record=true) }}
```

**Satellite model** (`models/integration/raw_vault/sat/sat_<entity>.sql`):
```sql
{{ config(
    materialized='table',
    file_format='iceberg'
) }}

{%- set model = dv_config('sat_<entity>') -%}
{%- set dv_system = var("dv_system") -%}

{{ ktl_autovault.sat_transform(model=model, dv_system=dv_system) }}
```

### Bước 3: Khai Báo Source (nếu cần)

Thêm source table vào `models/source/source.yml`:
```yaml
sources:
  - name: landing
    schema: landing
    tables:
      - name: <new_source_streaming_table>
```

### Bước 4: Thêm Documentation

Thêm docs vào `models/integration/raw_vault/raw_vault_docs.md`:
```markdown
{% docs hub_<entity> %}
Mô tả entity...
{% enddocs %}
```

### Bước 5: Test

```bash
# Compile để kiểm tra SQL
python dbt_compile.py --select hub_<entity>

# Chạy model
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev --select hub_<entity>+
```

## Quản Lý Incremental Load

### Cơ Chế ref_eod

Bảng `vw_ref_eod` cung cấp time window cho incremental load:

```sql
-- vw_ref_eod.sql
SELECT
    cob_date,
    lag(cob_date) OVER (...) AS last_cob_date,
    optime AS run_time,
    lag(optime) OVER (...) AS last_run_time
FROM {{ source('landing', 'ref_eod') }}
```

### Incremental pattern trong models:

```sql
{% if is_incremental() %}
WITH ref_dates AS (
    SELECT run_time, last_run_time
    FROM {{ ref('vw_ref_eod') }}
    {% if var('cob_date', none) %}
    WHERE cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {% else %}
    WHERE cob_date = (SELECT MAX(cob_date) FROM {{ ref('vw_ref_eod') }})
    {% endif %}
)
{% endif %}

SELECT ...
FROM source_table
{% if is_incremental() %}
CROSS JOIN ref_dates rd
WHERE dv_ldt > rd.last_run_time AND dv_ldt <= rd.run_time
{% endif %}
```

### Chỉ Định cob_date

```bash
# Chạy với cob_date cụ thể
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev --vars '{"cob_date": "2025-12-30"}'

# Không chỉ định → tự động dùng MAX(cob_date) từ vw_ref_eod
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev
```

## MDM Pipeline

MDM (Master Data Management) pipeline xử lý dữ liệu khách hàng qua các bước:

```
hub_customer + sat_snp_customer
        │
        ▼
mdm_source_corecif        ── Staging: join Hub + Satellite với time window
        │
        ▼
mdm_corecif_cleansed      ── Cleanse: áp dụng cleansing rules (chuẩn hóa tên, mã)
        │
        ▼
mdm_corecif_validate      ── Validate: kiểm tra tính hợp lệ của dữ liệu
        │
        ▼
mdm_corecif_match         ── Match: tìm bản ghi trùng lặp
        │
        ▼
mdm_corecif_merge         ── Merge: gộp bản ghi trùng
        │
        ▼
mdm_corecif_golden_records ── Golden: bản ghi master cuối cùng
```

Tất cả models đều sử dụng `incremental + merge` strategy với `unique_key='CIF_NO'`.

## Data Mart

### Dimensions

| Model | Mô tả |
|---|---|
| `dim_time` | Chiều thời gian (ngày, tuần, tháng, quý, năm) |
| `dim_branch` | Chiều chi nhánh (code, name, parent, khu vực) |
| `dim_pl_item` | Chiều khoản mục tài chính |

### Facts

| Model | Mô tả |
|---|---|
| `fact_dp_detail` / `fact_dp_summary` | Huy động - chi tiết / tổng hợp |
| `fact_ln_detail` / `fact_ln_summary` | Cho vay - chi tiết / tổng hợp |
| `fact_pl_detail` / `fact_pl_summary` | Lợi nhuận - chi tiết / tổng hợp |
| `*_backdate` | Phiên bản backdate cho các fact tables |

## Logging & Monitoring

### Lakehouse Logging

Khi bật `--log-to-lakehouse`, execution metadata được ghi vào Iceberg tables:

| Table | Nội dung |
|---|---|
| `LakeHouse.etladmin.job_run_logs` | Job metadata: start/end time, status, source |
| `LakeHouse.etladmin.job_sql_logs` | Compiled SQL, execution time, rows affected |

### Upload Artifacts lên S3

```bash
python dbt_runner.py \
  --upload-artifacts \
  --s3-bucket data \
  --s3-prefix dbt/artifacts/2025-12-30 \
  --s3-endpoint-url http://minio:9000
```

Artifacts upload: `manifest.json`, `run_results.json`, `catalog.json`, `dbt.log`

### Catalog & Documentation

Sau khi chạy thành công, `dbt_runner.py` tự động:
1. Generate `catalog.json` via `DbtDocsGenerator`
2. Fallback: build catalog từ Spark `DESCRIBE TABLE` nếu `dbt docs generate` thất bại
3. Upload catalog lên S3 cùng các artifacts khác
