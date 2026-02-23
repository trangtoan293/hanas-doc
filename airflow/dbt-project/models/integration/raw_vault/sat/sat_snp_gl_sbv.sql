{{ config(
    materialized='table',
    file_format='iceberg'
) }}

{%- set model = dv_config('sat_gl_sbv') -%}
{%- set dv_system = var("dv_system") -%}

{{ ktl_autovault.sat_snp_transform(model=model, dv_system=dv_system) }}
