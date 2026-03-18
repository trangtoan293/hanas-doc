# DBT - Cấu Hình

## Cấu Hình Project (`dbt_project.yml`)

### Thông Tin Cơ Bản

```yaml
name: 'ktl_dbt'
version: '1.0.0'
config-version: 2
profile: 'ktl_dbt'

model-paths: ["models"]
test-paths: ["tests"]
target-path: "/tmp/dbt_target"
log-path: "/tmp/dbt_logs"
clean-targets: ["/tmp/dbt_target", "/tmp/dbt_logs"]
```

### Variables (vars)

#### Quản Lý Thời Gian EOD

| Variable | Giá trị | Mô tả |
|---|---|---|
| `ref_eod_table` | `vw_ref_eod` | Bảng tham chiếu thời gian EOD (cob_date, run_time) |
| `initial_cob_date` | _(optional)_ | Ngày COB cho initial load. Nếu không chỉ định → dùng latest run_time |
| `cob_date` | _(optional)_ | Ngày COB cho incremental load. Nếu không chỉ định → dùng max(cob_date) |

> **Cơ chế hoạt động**: Models sử dụng `vw_ref_eod` để xác định khoảng thời gian incremental load:
> - `run_time` = `incre_end_date`
> - `last_run_time` = `incre_start_date`
> - Dữ liệu filter: `WHERE dv_ldt > last_run_time AND dv_ldt <= run_time`

#### Data Vault Settings

| Variable | Giá trị | Mô tả |
|---|---|---|
| `dv_hash_method` | `sha256` | Thuật toán hash cho hash keys |
| `dv_hash_key_dtype` | `binary` | Data type của hash keys |

#### Data Vault System Columns (`dv_system`)

| Column | Dtype | Source | Mô tả |
|---|---|---|---|
| `dv_kaf_ldt` | timestamp | `K_TIMESTAMP` | Thời điểm load từ Kafka |
| `dv_kaf_ofs` | bigint | `1` | Kafka offset |
| `dv_cdc_ops` | string | `op_type` | Loại CDC: R/I/U/D |
| `dv_src_ldt` | timestamp | `current_ts` | Thời điểm insert từ source |
| `dv_src_rec` | string | `table` | Tên bảng source |
| `dv_ldt` | timestamp | `current_timestamp()` | Thời điểm load vào raw vault |

#### MDM Catalog Config

```yaml
catalog_table:
  ref_group:
    - name: mdm_catalog_category
      column_original_value: ORIGINAL_VALUE
      column_standard_value: STANDARD_VALUE
      column_category_type: CATEGORY_TYPE
      column_source: SOURCE_SYSTEM
```

### Model Configurations

| Layer | Schema | Materialized | File Format | Ghi chú |
|---|---|---|---|---|
| `integration` | `integration` | table | iceberg | Raw Vault models, `is_streaming: false` |
| `mdm` | `mdm` | table | iceberg | MDM pipeline models |
| `data_mart` | `data_mart` | table | iceberg | Dimension + Fact tables |
| `mart_refactor/intermediate` | `mart_refactor` | table | iceberg | Intermediate calculations |
| `mart_refactor/dims` | `mart_refactor_dims` | table | iceberg | Refactored dimensions |
| `mart_refactor/facts` | `mart_refactor_facts` | table | iceberg | Refactored facts |
| `seeds` | `landing` | - | iceberg | CSV seed data |

#### Iceberg Table Properties

```yaml
+tblproperties:
  "hive.engine.enabled": "true"
  "read.parquet.vectorization.enabled": "true"
  "read.parquet.vectorization.batch-size": "10000"
```

## Cấu Hình Connection (`profiles.yml`)

### Dev Environment

```yaml
ktl_dbt:
  target: dev
  outputs:
    dev:
      type: spark
      method: session
      schema: "{{ env_var('SCHEMA_NAME') }}"
      host: local[*]
      port: 7077
      threads: 8
      connect_timeout: 60
      connect_retries: 3
      retry_all: true
```

### Spark + Iceberg Configuration

| Config | Giá trị | Mô tả |
|---|---|---|
| `spark.sql.extensions` | `IcebergSparkSessionExtensions` | Iceberg SQL extensions |
| `spark.sql.catalog.demo` | `SparkCatalog` | Iceberg catalog tên `demo` |
| `spark.sql.catalog.demo.type` | `hive` | Sử dụng Hive Metastore |
| `spark.sql.catalog.demo.uri` | `thrift://<host>:9083` | Hive Metastore URI |
| `spark.sql.catalog.demo.io-impl` | `S3FileIO` | S3 I/O implementation |
| `spark.sql.catalog.demo.s3.endpoint` | `http://<host>` | MinIO/S3 endpoint |
| `spark.sql.catalog.demo.warehouse` | `s3a://data/warehouse/` | Warehouse path |
| `spark.sql.defaultCatalog` | `demo` | Default catalog |

### S3/MinIO Configuration

| Config | Mô tả |
|---|---|
| `spark.hadoop.fs.s3a.endpoint` | MinIO endpoint URL |
| `spark.hadoop.fs.s3a.access.key` | Access key (hoặc `env_var('AWS_ACCESS_KEY_ID')`) |
| `spark.hadoop.fs.s3a.secret.key` | Secret key (hoặc `env_var('AWS_SECRET_ACCESS_KEY')`) |
| `spark.hadoop.fs.s3a.path.style.access` | `true` (bắt buộc cho MinIO) |
| `spark.hadoop.fs.s3a.ssl.enabled` | `false` |
| `spark.hadoop.fs.s3a.impl` | `S3AFileSystem` |

## Cấu Hình AutoVault (`ktl_autovault_configs/`)

### Hub Config (ví dụ: `hub/hub_customer.yml`)

```yaml
source_schema: landing
source_table: core_cif_streaming
target_entity_type: hub
target_schema: integration
target_table: hub_customer
collision_code: demo
columns:
  - target: dv_hkey_hub_customer
    key_type: hash_key_hub       # Hash key tự động sinh
    dtype: string
    source:
      - CIF_NO                   # Business key(s) để hash
  - target: CIF_NO
    key_type: biz_key            # Business key giữ nguyên
    dtype: string
    source:
      name: CIF_NO
      dtype: string
```

### Satellite Config (ví dụ: `sat/sat_customer.yml`)

```yaml
source_schema: landing
source_table: core_cif_streaming
target_entity_type: sat
target_schema: integration
target_table: sat_customer
parent_table: hub_customer       # Liên kết với Hub
collision_code: demo
columns:
  - target: dv_hkey_sat_customer
    key_type: hash_key_sat       # Satellite hash key
    dtype: string
  - target: dv_hkey_hub_customer
    key_type: hash_key_hub       # FK đến Hub
    dtype: string
    source:
      - CIF_NO
  - target: dv_hsh_dif
    dtype: string
    key_type: hash_diff           # Hash diff cho change detection
  - target: CUSTOMER_TYPE        # Attribute columns...
    dtype: string
    source:
      name: CUSTOMER_TYPE
      dtype: string
```

### Link Config (ví dụ: `lnk/lnk_branch_gl.yml`)

```yaml
source_schema: landing
source_table: gl_poc_streaming
target_entity_type: lnk
target_schema: integration
target_table: lnk_branch_gl
collision_code: demo
columns:
  - target: dv_hkey_lnk_branch_gl
    key_type: hash_key_lnk       # Link hash key
    dtype: string
    source:
      - POS_CD                   # Composite key từ 2 Hub
      - AC_NO
  - target: dv_hkey_hub_branch
    key_type: hash_key_hub
    parent: hub_branch            # FK đến Hub Branch
    dtype: string
    source:
      - POS_CD
  - target: dv_hkey_hub_gl
    key_type: hash_key_hub
    parent: hub_gl                # FK đến Hub GL
    dtype: string
    source:
      - AC_NO
```

## Cấu Hình Packages (`packages.yml`)

```yaml
packages:
  - package: DBT-labs/dbt_utils
    version: 1.3.0
  - package: DBT-labs/spark_utils
    version: 0.3.0
  - local: ./packages/ktl_autovault  # Local AutoVault package
```

## Environment Variables

| Variable | Bắt buộc | Mô tả |
|---|---|---|
| `SCHEMA_NAME` | ✅ | Schema name cho DBT target |
| `AWS_ACCESS_KEY_ID` | ✅ | S3/MinIO access key |
| `AWS_SECRET_ACCESS_KEY` | ✅ | S3/MinIO secret key |
| `DBT_PROFILES_DIR` | _(auto)_ | Thư mục chứa profiles.yml |
| `DBT_PROJECT_DIR` | _(auto)_ | Thư mục chứa dbt_project.yml |
| `DBT_TARGET_PATH` | _(default: /tmp/dbt_target)_ | Thư mục output artifacts |
| `DBT_LOG_PATH` | _(default: /tmp/dbt_logs)_ | Thư mục log files |
