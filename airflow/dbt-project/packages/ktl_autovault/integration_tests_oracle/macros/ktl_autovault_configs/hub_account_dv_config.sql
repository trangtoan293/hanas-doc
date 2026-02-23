

{%- macro hub_account_dv_config() -%}
    {%- set model_yml -%}

collision_code: mdm
target_entity_type: hub
target_schema: datavault
target_table: hub_account
source_schema: datavault
source_table: loan_info
columns:
  - target: dv_hkey_hub_account
    dtype: binary
    key_type: hash_key_hub
    source:
      - ln_ac_nbr
  - target: ln_ac_nbr
    dtype: string
    key_type: biz_key
    source:
      name: ln_ac_nbr
      dtype: string


    {%- endset -%}

    {%- set model = fromyaml(model_yml) -%}
    {{ return(model) }}

{%- endmacro -%}

