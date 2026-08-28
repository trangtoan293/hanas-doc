# dbt - Best Practices

## Thiết Kế & Kiến Trúc

### Data Vault Naming Conventions

| Entity | Prefix | Ví dụ |
|---|---|---|
| Hub | `hub_` | `hub_customer`, `hub_gl`, `hub_branch` |
| Link | `lnk_` | `lnk_branch_gl`, `lnk_branch_parent` |
| Satellite (main) | `sat_` | `sat_customer`, `sat_gl` |
| Satellite (snapshot) | `sat_snp_` | `sat_snp_customer`, `sat_snp_gl` |
| Satellite (derived T-1) | `sat_der_` | `sat_der_customer`, `sat_der_gl` |
| Link-Satellite | `lsat_` | `lsat_branch_gl` |

### Hash Key Naming

| Key Type | Prefix | Ví dụ |
|---|---|---|
| Hub hash key | `dv_hkey_hub_` | `dv_hkey_hub_customer` |
| Satellite hash key | `dv_hkey_sat_` | `dv_hkey_sat_customer` |
| Link hash key | `dv_hkey_lnk_` | `dv_hkey_lnk_branch_gl` |
| Link-Satellite hash key | `dv_hkey_lsat_` | `dv_hkey_lsat_branch_gl` |
| Hash diff | `dv_hsh_dif` | Luôn cùng tên |

### Layer Separation

```
models/
├── source/          # source.yml - Khai báo landing tables
├── integration/     # Raw Vault layer - Hub/Link/Sat
├── mdm/             # MDM pipeline - Cleanse/Validate/Match/Merge
├── data_mart/       # Dimension + Fact tables cho BI
└── mart_refactor/   # Refactored mart (intermediate/dims/facts)
```

- **1 model = 1 file SQL**: Không trộn nhiều models trong 1 file
- **Sử dụng `ref()` và `source()`**: Luôn dùng macro, không hardcode table names
- **Schema override**: Dùng `generate_schema_name` macro để đặt schema trực tiếp (không prefix)

### AutoVault Config Organization

```
ktl_autovault_configs/
├── hub/    # 1 file YAML cho mỗi Hub entity
├── sat/    # 1 file YAML cho mỗi Satellite entity
├── lnk/   # 1 file YAML cho mỗi Link entity
└── lsat/   # 1 file YAML cho mỗi Link-Satellite entity
```

- File name = table name (ví dụ: `hub_customer.yml` → table `hub_customer`)
- `collision_code` giúp phân biệt nguồn dữ liệu khi merge từ nhiều source systems

## Hiệu Năng

### Materialization Strategy

| Layer | Materialized | Lý do |
|---|---|---|
| Hub | `incremental` (merge) | Deduplicate business keys, chỉ insert mới |
| Satellite | `table` | Full rebuild mỗi lần chạy |
| MDM | `incremental` (merge) | Merge by `unique_key` (CIF_NO) |
| Data Mart | `table` | Full rebuild cho consistency |

### Iceberg Table Optimizations

```yaml
+tblproperties:
  "hive.engine.enabled": "true"
  "read.parquet.vectorization.enabled": "true"       # Vectorized reads
  "read.parquet.vectorization.batch-size": "10000"    # Batch size cho vectorization
```

### Incremental Load Best Practices

1. **Sử dụng `ref_eod_table`** thay vì hardcode dates:
   ```sql
   -- Đúng
   WHERE dv_ldt > rd.last_run_time AND dv_ldt <= rd.run_time
   
   -- Sai
   WHERE dv_ldt > '2025-12-01' AND dv_ldt <= '2025-12-31'
   ```

2. **Ghost Records cho Hub**: Luôn `include_ghost_record=true` khi tạo Hub

3. **Merge Strategy**: Sử dụng `incremental_strategy='merge'` cho Hub và MDM models

4. **Schema Evolution**: Dùng `on_schema_change='sync_all_columns'` cho MDM models

### Hashing

- **Thuật toán**: SHA256 (`dv_hash_method: sha256`)
- **Data type**: binary (`dv_hash_key_dtype: binary`)
- Hash key được sinh tự động từ business keys qua `ktl_autovault` macros

## Bảo Mật

### Quản Lý Credentials

- **Không hardcode** credentials trong `profiles.yml` cho production
- Sử dụng `env_var()` Jinja function:
  ```yaml
  access.key: "{{ env_var('AWS_ACCESS_KEY_ID') }}"
  secret.key: "{{ env_var('AWS_SECRET_ACCESS_KEY') }}"
  ```
- Inject credentials qua Kubernetes Secrets hoặc Vault

### Schema Isolation

- Mỗi layer có schema riêng (`landing`, `integration`, `mdm`, `data_mart`)
- `generate_schema_name` macro đảm bảo schema name chính xác, không prefix

## Vận Hành Production

### Deployment Checklist

1. Kiểm tra `dbt deps` thành công
2. Chạy `dbt compile` để validate SQL
3. Seed data loaded (`ref_eod`, MDM catalogs)
4. Environment variables configured
5. Lakehouse logging enabled (`--log-to-lakehouse`)
6. Artifact upload configured (`--upload-artifacts`)

### Execution Order

```bash
# 1. Install dependencies
dbt deps

# 2. Load seed data
python dbt_seed.py

# 3. Run integration layer (Raw Vault)
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev --select integration.*

# 4. Run MDM pipeline
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev --select mdm.*

# 5. Run Data Mart
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev --select data_mart.*
```

### Monitoring

- **Lakehouse Logs**: Query `LakeHouse.etladmin.job_run_logs` và `job_sql_logs` để monitor
- **Artifacts trên S3**: Check `manifest.json`, `run_results.json` cho execution details
- **DataHub**: Column lineage và metadata tự động publish sau mỗi run

### Error Handling

- `dbt_runner.py` exit code `1` khi có lỗi → Airflow/K8s sẽ retry
- Error details ghi trong `run_results.json` và `dbt.log`
- Upload artifacts **trước** khi exit fail → vẫn có thể debug từ S3

### Backdate Processing

Các model `*_backdate` trong data_mart hỗ trợ xử lý dữ liệu lịch sử:

```bash
# Chạy backdate models với cob_date cụ thể
python dbt_runner.py --use-subprocess --dbt-command ktl_dbt \
  run --target dev --select fact_dp_detail_backdate \
  --vars '{"cob_date": "2025-11-15"}'
```
