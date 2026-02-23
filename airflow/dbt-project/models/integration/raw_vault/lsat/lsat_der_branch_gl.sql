
{{ config(
    materialized='incremental',
    file_format='iceberg',
    incremental_strategy='merge'
) }}

{%- set model = dv_config('lsat_branch_gl') -%}
{%- set dv_system = var("dv_system") -%}


{{ ktl_autovault.lsat_der_transform(model=model, dv_system=dv_system) }}
