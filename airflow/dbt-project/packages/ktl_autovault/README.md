# KTL Autovault Package

This dbt package provides macros to automate the creation of Raw Vault models following the Data Vault 2.0 architecture. It includes utilities for generating Hub, Link, Satellite, and Link Satellite models through configuration-driven development.

## Installation

Add the following URL to your `packages.yml`:

http://{GIT_USER}:{GIT_PAT}@192.168.1.48:7979/de-team/ktl_autovault.git

Example:
```yaml
# packages.yml

packages:
  - git: "http://reader:7PmXk-DsZo8bX_Y6zKZH@192.168.1.48:7979/de-team/ktl_autovault.git"
    revision: main
```

## Authentication

If you encounter authentication issues with Personal Access Token (PAT), please ask an administrator to create a new token from:

[http://192.168.1.48:7979/de-team/ktl_autovault/-/settings/access_tokens](http://192.168.1.48:7979/de-team/ktl_autovault/-/settings/access_tokens)

## Configuration

### System Columns

All Raw Vault models require specific system columns. Configure these in your `dbt_project.yml`:

```yaml
# dbt_project.yml

vars:
  dv_system:
    columns:
      - target: dv_src_ldt
        dtype: timestamp
        description: 'Source system load datetime'
        source:
          name: load_datetime
          dtype: timestamp

      - target: dv_src_rec
        dtype: string
        description: 'Source record system name'
        source:
          name: record_source
          dtype: string
          
      - target: dv_cdc_ops
        dtype: string
        description: 'CDC operation type (R=read, I=insert, U=update, D=delete)'
        source:
          name: cdc_operation
          dtype: string

      - target: dv_kaf_ldt
        dtype: timestamp
        description: 'Kafka load datetime'
        source:
          name: current_timestamp()
          dtype: timestamp

      - target: dv_kaf_ofs
        dtype: bigint
        description: 'Kafka offset'
        source:
          name: "1"
          dtype: bigint

      - target: dv_ldt
        dtype: timestamp
        description: 'Raw Vault load datetime'
        source:
          name: current_timestamp()
          dtype: timestamp
```

System columns must be present in all source tables with consistent naming

### End-of-Day (EOD) Configuration

There are two ways to configure EOD processing for Raw Vault models:

#### 1. Using Reference EOD Table

You can specify a reference EOD table that contains the necessary timing information:

```yaml
vars:
  # Name of table that raw vault models get EOD time from
  # Table must have columns: cob_date, last_cob_date, run_time, last_run_time
  ref_eod_table: vw_ref_eod
  
  # Initial COB date for first load
  # If not specified, latest run_time will be used
  initial_cob_date: "2024-11-04"
  
  # COB date for incremental loads
  # Uses run_time as incre_end_date and last_run_time as incre_start_date
  # If not specified, latest run_time will be used
  cob_date: "2024-11-05"
```

#### 2. Using Direct Date Parameters

If not using a reference EOD table, you can specify dates directly:

```yaml
vars:
  # Start date for initial batch load
  initial_date: "2024-01-01"
  
  # Start date for incremental loads
  # Default: 1900-01-01
  incre_start_date: "2024-11-04"
  
  # End date for incremental loads
  # Default: current date
  incre_end_date: "2024-11-05"
```

#### Configuration Priority

1. If `ref_eod_table` is specified:
   - System uses the EOD table for timing information
   - `initial_cob_date` and `cob_date` can be used to specify specific dates
   - Direct date parameters are ignored

2. If `ref_eod_table` is not specified:
   - System uses `initial_date`, `incre_start_date`, and `incre_end_date`
   - These must be explicitly set or system defaults will be used

### Raw Vault - Hub Configuration

Hubs represent business entities and require configuration of business keys and their corresponding hash keys.

Example configuration as macro:

```yaml
-- macros/hub_customer_dv_config.sql

{%- macro hub_customer_dv_config() -%}
{%- set model_yml -%}

target_entity_type: hub
target_schema: duytk_test
target_table: hub_customer
sources:
  - collision_code: loan
    source_schema: duytk_test
    source_table: loan_info
    columns:
      - target: dv_hkey_hub_customer
        key_type: hash_key_hub
        source:
          - cst_no
      - target: cst_no
        dtype: double
        key_type: biz_key
        source:
          name: cst_no
          dtype: string

{%- endset -%}
{%- set model = fromyaml(model_yml) -%}
{{ return(model) }}
{%- endmacro -%}
```

Key components:
- `target_entity_type`: Must be 'hub'
- `target_schema`: Target schema name
- `target_table`: Target table name
- `sources`: List of source tables
  - `collision_code`: Unique identifier for the source
  - `source_schema`: Source schema name
  - `source_table`: Source table name
  - `columns`: Column mappings including:
    - hash_key_hub
    - biz_key

To generate a Hub model:

```sql
-- models/hub_customer.sql

{%- set model = dv_config('hub_customer') -%}
{%- set dv_system = var("dv_system") -%}
{{ ktl_autovault.hub_transform(model=model, dv_system=dv_system) }}
```

Notes:

1. Hub models support multiple sources with consistent target column names

    ```yaml
    # hub configs
    ...
    sources:
      - collision_code: loan
        source_schema: duytk_test
        source_table: loan_info
        columns:
          - target: dv_hkey_hub_customer
            key_type: hash_key_hub
            source:
              - cst_no
          - target: cst_no
            dtype: double
            key_type: biz_key
            source:
              name: cst_no
              dtype: string

      - collision_code: loan_1
        source_schema: duytk_test
        source_table: loan_info_1
        columns:
          - target: dv_hkey_hub_customer
            key_type: hash_key_hub
            source:
              - cst_no
          - target: cst_no
            dtype: double
            key_type: biz_key
            source:
              name: cst_no
              dtype: string
    ```

2. Required column types:
   - `hash_key_hub`: Hash key for the hub
   - `biz_key`: Business key columns

3. Remember to define your sources in `sources.yml`:

    ```yaml
    # models/sources.yml

    sources:
      - name: duytk_test
        schema: duytk_test
        tables:
          - name: loan_info
    ```

4. Set `from_psa_model=true` when using ref models instead of sources.yml

    ```sql
    {{ ktl_autovault.hub_transform(model=model, dv_system=dv_system, from_psa_model=true) }}
    ```

### Raw Vault - Link Configuration

Links represent relationships between business entities and require configuration of relationship keys and their corresponding hub references.

Example configuration as macro:

```yaml
-- macros/lnk_customer_account_dv_config.sql

{%- macro lnk_customer_account_dv_config() -%}
{%- set model_yml -%}

target_entity_type: lnk
target_schema: duytk_test
target_table: lnk_customer_account

collision_code: mdm
source_schema: duytk_test
source_table: psa_loan_info
columns:
  - target: dv_hkey_lnk_customer_account
    dtype: string
    key_type: hash_key_lnk
    source:
      - ln_ac_nbr
      - cst_no

  - target: dv_hkey_hub_account
    dtype: string
    key_type: hash_key_drv
    source:
      - ln_ac_nbr
    parent: hub_account

  - target: dv_hkey_hub_customer
    dtype: string
    key_type: hash_key_hub
    source:
      - cst_no
    parent: hub_customer

{%- endset -%}
{%- set model = fromyaml(model_yml) -%}
{{ return(model) }}
{%- endmacro -%}
```

Key components:
- `target_entity_type`: Must be 'lnk'
- `target_schema`: Target schema name
- `target_table`: Target table name
- `collision_code`: Unique identifier for the source
- `source_schema`: Source schema name
- `source_table`: Source table name
- `columns`: Column mappings inluding:
  - hash_key_lnk
  - hash_key_hub (or hash_key_drv)
  - `parent`: Reference to parent hub (required for hub hash keys)

To generate a Link model:

```sql
-- models/lnk_customer_account.sql

{%- set model = dv_config('lnk_customer_account') -%}
{%- set dv_system = var("dv_system") -%}
{{ ktl_autovault.lnk_transform(model=model, dv_system=dv_system) }}
```

Notes:

1. Link models require at least two hub references to establish relationships:
    ```yaml
    columns:
      - target: dv_hkey_hub_customer    # First hub reference
        key_type: hash_key_hub
        source:
          - cst_no
        parent: hub_customer

      - target: dv_hkey_hub_account     # Second hub reference
        key_type: hash_key_drv
        source:
          - ln_ac_nbr
        parent: hub_account
    ```

3. The link hash key (`hash_key_lnk`) must include all source columns that are used to generate the hub hash keys:
    ```yaml
    - target: dv_hkey_lnk_customer_account
      key_type: hash_key_lnk
      source:
        - ln_ac_nbr    # Used in hub_account
        - cst_no       # Used in hub_customer
    ```

4. Remember to define your sources in `sources.yml`:
    ```yaml
    # models/sources.yml
    
    sources:
      - name: duytk_test
        schema: duytk_test
        tables:
          - name: psa_loan_info
    ```

5. Set `from_psa_model=true` when using ref models instead of sources.yml:
    ```sql
    {{ ktl_autovault.lnk_transform(model=model, dv_system=dv_system, from_psa_model=true) }}
    ```

### Raw Vault - Satellite Configuration

Satellites store descriptive attributes and context for business entities, capturing how these attributes change over time. They are linked to Hubs. There are three types of satellites supported:

1. Standard Satellite (SAT)
2. Derivative Satellite (SAT_DER)
3. Snapshot Satellite (SAT_SNP)

Example configuration as macro:

```yaml
-- macros/sat_account_dv_config.sql

{%- macro sat_account_dv_config() -%}
{%- set model_yml -%}

target_entity_type: sat
target_schema: duytk_test
target_table: sat_account
parent_table: hub_account

collision_code: mdm
source_schema: duytk_test
source_table: psa_loan_info
columns:
  - target: dv_hkey_sat_account
    dtype: string
    key_type: hash_key_sat
    source: "null"

  - target: dv_hkey_hub_account
    dtype: string
    key_type: hash_key_hub
    source:
      - ln_ac_nbr

  - target: dv_hsh_dif
    dtype: string
    key_type: hash_diff

  # Business attributes...
  - target: amt_financed
    dtype: double
    source:
      name: amt_financed
      dtype: string

{%- endset -%}
{%- set model = fromyaml(model_yml) -%}
{{ return(model) }}
{%- endmacro -%}
```

To generate different types of Satellite models:

```sql
-- 1. Standard Satellite (SAT)
-- models/sat_account.sql

{%- set model = dv_config('sat_account') -%}
{%- set dv_system = var("dv_system") -%}
{{ ktl_autovault.sat_transform(model=model, dv_system=dv_system) }}

-- 2. Derived Satellite (SAT_DER)
-- models/sat_der_account.sql

{%- set model = dv_config('sat_account') -%}
{%- set dv_system = var("dv_system") -%}
{{ ktl_autovault.sat_der_transform(model=model, dv_system=dv_system) }}

-- 3. Snapshot Satellite (SAT_SNP)
-- models/sat_snp_account.sql

{%- set model = dv_config('sat_account') -%}
{%- set dv_system = var("dv_system") -%}
{{ ktl_autovault.sat_snp_transform(model=model, dv_system=dv_system) }}
```

Key differences between satellite types:

1. Standard Satellite (SAT)
    - Uses `sat_transform` macro
    - Stores historical changes with effective dates

2. Derivative Satellite (SAT_DER)
    - Uses `sat_der_transform` macro
    - Stores short historical changes up to current date
    - Prepares for SAT and SAT_SNP

3. Snapshot Satellite (SAT_SNP)
   - Uses `sat_snp_transform` macro
   - Captures latest point-in-time snapshots of attributes

Common components for all types:
- `target_entity_type`: 'sat'
- `target_schema`: Target schema name
- `target_table`: Target table name (of LSAT only)
- `parent_table`: Reference to the parent hub
- `collision_code`: Unique identifier for the source
- `source_schema`: Source schema name
- `source_table`: Source table name
- `columns`: Column mappings inluding:
  - hash_key_sat
  - hash_key_hub
  - dependent_key
  - hash_diff
  - other business attributes (no key_type)

Usage notes:

1. Keep consistent naming conventions:
     - SAT: `sat_[entity]`
     - SAT_DER: `sat_der_[entity]`
     - SAT_SNP: `sat_snp_[entity]`

2. The hash_key_sat is the surrogate key of the satellite. It is automatically calculated based on the hash_key_hub, dependent_key and system columns (no need to define source columns).

3. The hash_diff is automatically calculated based on the business attributes to detect changes over time.

4. Each satellite must have exactly one parent hub specified in `parent_table`.

5. Remember to define your sources in `sources.yml`:
    ```yaml
    # models/sources.yml
    
    sources:
      - name: duytk_test
        schema: duytk_test
        tables:
          - name: psa_loan_info
    ```

6. Set `from_psa_model=true` when using ref models instead of sources.yml:
    ```sql
    {{ ktl_autovault.lnk_transform(model=model, dv_system=dv_system, from_psa_model=true) }}
    ```

### Raw Vault - Link-Satellite Configuration

Like Sat but linked to Links. There are three types of link-satellites supported:

1. Standard Link-Satellite (LSAT)
2. Derivative Link-Satellite (LSAT_DER)
3. Snapshot Link-Satellite (LSAT_SNP)

Example configuration as macro:

```yaml
-- macros/lsat_customer_account_dv_config.sql

{%- macro lsat_customer_account_dv_config() -%}
{%- set model_yml -%}

target_entity_type: lsat
target_schema: duytk_test
target_table: lsat_customer_account
parent_table: lnk_customer_account

collision_code: mdm
source_schema: duytk_test
source_table: psa_loan_info
columns:
  - target: dv_hkey_lsat_customer_account
    dtype: string
    key_type: hash_key_sat

  - target: dv_hkey_lnk_customer_account
    dtype: string
    key_type: hash_key_lnk
    source:
      - ln_ac_nbr
      - cst_no

  - target: dv_hsh_dif
    dtype: string
    key_type: hash_diff

  # Business attributes...
  - target: br_cd
    dtype: decimal(38,0)
    source:
      name: br_cd
      dtype: string

{%- endset -%}
{%- set model = fromyaml(model_yml) -%}
{{ return(model) }}
{%- endmacro -%}
```

To generate different types of Satellite models:

```sql
-- 1. Standard Link-Satellite (LSAT)
-- models/lsat_customer_account.sql

{%- set model = dv_config('lsat_customer_account') -%}
{%- set dv_system = var("dv_system") -%}
{{ ktl_autovault.lsat_transform(model=model, dv_system=dv_system) }}

-- 2. Derived Link-Satellite (LSAT_DER)
-- models/lsat_der_customer_account.sql

{%- set model = dv_config('lsat_customer_account') -%}
{%- set dv_system = var("dv_system") -%}
{{ ktl_autovault.lsat_der_transform(model=model, dv_system=dv_system) }}

-- 3. Snapshot Link-Satellite (LSAT_SNP)
-- models/lsat_snp_customer_account.sql

{%- set model = dv_config('lsat_customer_account') -%}
{%- set dv_system = var("dv_system") -%}
{{ ktl_autovault.lsat_snp_transform(model=model, dv_system=dv_system) }}
```

Key differences between satellite types:

1. Standard Link-Satellite (LSAT)
    - Uses `lsat_transform` macro
    - Stores historical changes with effective dates

2. Derivative Link-Satellite (LSAT_DER)
    - Uses `lsat_der_transform` macro
    - Stores short historical changes up to current date
    - Prepares for SAT and SAT_SNP

3. Snapshot Link-Satellite (LSAT_SNP)
   - Uses `lsat_snp_transform` macro
   - Captures latest point-in-time snapshots of attributes

Common components for all types:
- `target_entity_type`: 'lsat'
- `target_schema`: Target schema name
- `target_table`: Target table name (of LSAT only)
- `parent_table`: Reference to the parent link
- `collision_code`: Unique identifier for the source
- `source_schema`: Source schema name
- `source_table`: Source table name
- `columns`: Column mappings inluding:
  - hash_key_sat
  - hash_key_lnk
  - dependent_key
  - hash_diff
  - other business attributes (no key_type)

Usage notes:

1. Keep consistent naming conventions:
     - LSAT: `lsat_[entity]`
     - LSAT_DER: `lsat_der_[entity]`
     - LSAT_SNP: `lsat_snp_[entity]`

2. The hash_key_sat is the surrogate key of the link-satellite. It is automatically calculated based on the hash_key_lnk, dependent_key and system columns (no need to define source columns).

3. The hash_diff is automatically calculated based on the business attributes to detect changes over time.

4. Each satellite must have exactly one parent link specified in `parent_table`.

5. Remember to define your sources in `sources.yml`:
    ```yaml
    # models/sources.yml
    
    sources:
      - name: duytk_test
        schema: duytk_test
        tables:
          - name: psa_loan_info
    ```

6. Set `from_psa_model=true` when using ref models instead of sources.yml:
    ```sql
    {{ ktl_autovault.lnk_transform(model=model, dv_system=dv_system, from_psa_model=true) }}
    ```

### Columns Configuration

The columns configuration defines how source columns are mapped to target columns in Data Vault models. Each column definition specifies the transformation rules, data types, and key types for Data Vault structures.

Basic Structure

```yaml
columns:
  - target: <target_column_name>
    key_type: <key_type>
    dtype: <data_type>
    source: <source_configuration>
```

Column Types

1. Hash Key Hub

    Used for generating unique identifiers in Hub models.

    ```yaml
    - target: dv_hkey_hub_customer    # Target column name in the vault
      key_type: hash_key_hub          # Specifies this is a hub hash key
      source:                         # List of source columns to generate hash from
        - cst_no
    ```

    Key points:
    - `key_type`: Must be `hash_key_hub` for hub hash keys
    - `source`: List format for multiple columns to be included in hash generation
    - No `dtype` needed as hash keys are automatically handled

2. Business Key

    Represents the natural business keys from source systems.

    ```yaml
    - target: cst_no                  # Target column name in the vault
      dtype: double                   # Target data type
      key_type: biz_key               # Specifies this is a business key
      source:                         # Source column configuration
        name: cst_no                  # Source column name
        dtype: string                 # Source data type
    ```

    Key points:
    - `key_type`: Must be `biz_key` for business keys
    - `source`: Source column format with:
      - `name`: Source column name
      - `dtype`: Source data type (for type casting if needed)

3. Hash Key Link

    Used for generating unique identifiers in Link models.

    ```yaml
    - target: dv_hkey_lnk_customer_account    # Target column name in the vault
      key_type: hash_key_lnk                  # Specifies this is a lnk hash key
      source:                                 # List of source columns to generate hash from
        - ln_ac_nbr
        - cst_no
    ```

    Key points:
    - `key_type`: Must be `hash_key_lnk` for link hash keys
    - `source`: List format for multiple columns to be included in hash generation
    - No `dtype` needed as hash keys are automatically handled

4. Hash Key Satellite/Link-Satellite

    Used for generating unique surrogate key in Satellite/Link-Satellite models.

    ```yaml
    - target: dv_hkey_sat_customer    # Target column name in the vault
      key_type: hash_key_sat          # Specifies this is a sat hash key
    ```

    Key points:
    - `key_type`: Must be `hash_key_sat` for hub hash keys
    - No `source` and `dtype` needed as hash keys are automatically handled. It is calculated based on the hash_key_hub/hash_key_lnk, dependent_key and system columns

5. Dependent Keys of Satellite

    Represents the dependent keys of Satellite models belong with hash key Hub/Link.

    ```yaml
    - target: value_date              # Target column name in the vault
      dtype: date                     # Target data type
      key_type: dependent_key         # Specifies this is a dependent key
      source:                         # Source column configuration
        name: value_date              # Source column name
        dtype: date                   # Source data type
    ```

    Key points:
    - `key_type`: Must be `dependent_key` for dependent keys
    - `source`: Source column format with:
      - `name`: Source column name
      - `dtype`: Source data type (for type casting if needed)

6. Hash Diff of Satellite

    Represents the attributes changes of Satellite/Link-Satellite models.

    ```yaml
    - target: dv_hsh_dif              # Target column name in the vault
      key_type: hash_diff             # Specifies this is a dependent key
    ```

    Key points:
    - `key_type`: Must be `hash_diff` for hub hash keys
    - No `source` and `dtype` needed as hash keys are automatically handled. It is calculated based on the business attributes (no include biz keys, dependent keys)

7. Other business attributes

    ```yaml
    - target: amt_financed            # Target column name in the vault
      dtype: double                   # Target data type
      source:                         # Source column configuration
        name: amt_financed            # Source column name
        dtype: string                 # Source data type
    ```

    Key points:
    - No `key_type` configuration
    - `source`: Source column format with:
      - `name`: Source column name
      - `dtype`: Source data type (for type casting if needed)

## Contributing

[Your contribution guidelines here]

## License

[Your license information here]