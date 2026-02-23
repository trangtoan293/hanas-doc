

{%- macro lnk_customer_account_dv_config() -%}
    {%- set model_yml -%}

collision_code: mdm
target_entity_type: lnk
target_schema: datavault
target_table: lnk_customer_account
description: ""
source_schema: datavault
source_table: loan_info
columns:
  - target: dv_hkey_lnk_customer_account
    dtype: string
    key_type: hash_key_lnk
    source:
      - ln_ac_nbr
      - cst_no
  - target: dv_hkey_hub_account
    dtype: string
    key_type: hash_key_hub
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

