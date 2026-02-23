
{{ config(
    materialized='incremental',
    file_format='iceberg',
    incremental_strategy='merge'
) }}

{%- set model = dv_config('lnk_branch_parent') -%}
{%- set dv_system = var("dv_system") -%}

{{ ktl_autovault.lnk_transform(model=model, dv_system=dv_system) }}
