

{%- macro hub_customer_dv_config() -%}
    {%- set model_yml -%}

collision_code: mdm
target_entity_type: hub
target_schema: datavault
target_table: hub_customer
source_schema: datavault
source_table: loan_info
columns:
  - target: dv_hkey_hub_customer
    key_type: hash_key_hub
    source:
      - cst_no
  - target: cst_no
    dtype: number(38,0)
    key_type: biz_key
    source:
      name: cst_no
      dtype: string


    {%- endset -%}

    {%- set model = fromyaml(model_yml) -%}
    {{ return(model) }}

{%- endmacro -%}

