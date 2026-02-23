{{ config(
    materialized='table',
    file_format='iceberg'
) }}

{%- set model = dv_config('lsat_branch_gl') -%}
{%- set dv_system = var("dv_system") -%}


{{ ktl_autovault.lsat_transform(model=model, dv_system=dv_system) }}
