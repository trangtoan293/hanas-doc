

{%- macro lsat_customer_account_dv_config() -%}
    {%- set model_yml -%}

collision_code: mdm
target_entity_type: lsat
target_schema: datavault
target_table: lsat_customer_account
description: ''
source_schema: datavault
source_table: loan_info
columns:
  - target: dv_hkey_lsat_customer_account
    dtype: binary
    key_type: hash_key_sat
    source: 'null'
  - target: dv_hkey_lnk_customer_account
    dtype: binary
    key_type: hash_key_lnk
    source:
      - ln_ac_nbr
      - cst_no
  - target: dv_hsh_dif
    dtype: binary
    key_type: hash_diff
  - target: br_cd
    dtype: decimal(38,0)
    source:
      name: br_cd
      dtype: string
  - target: book_date
    dtype: date
    source:
      name: book_date
      dtype: string
      format: MM/DD/YYYY
  - target: value_date
    dtype: date
    source:
      name: value_date
      dtype: string
      format: MM/DD/YYYY
  - target: maturity_date
    dtype: date
    source:
      name: maturity_date
      dtype: string
      format: MM/DD/YYYY
  - target: amt_financed
    dtype: float
    source:
      name: amt_financed
      dtype: string
  - target: close_date
    dtype: date
    source:
      name: close_date
      dtype: string
      format: MM/DD/YYYY
  - target: account_status
    dtype: string
    source:
      name: account_status
      dtype: string
  - target: sub_cd
    dtype: string
    source:
      name: sub_cd
      dtype: string
  - target: ten_sp_ksp
    dtype: string
    source:
      name: ten_sp_ksp
      dtype: string
  - target: ccy_cd
    dtype: string
    source:
      name: ccy_cd
      dtype: string
  - target: product_code
    dtype: string
    source:
      name: product_code
      dtype: string
parent_table: lnk_customer_account


    {%- endset -%}

    {%- set model = fromyaml(model_yml) -%}
    {{ return(model) }}

{%- endmacro -%}

