{{ config(
    materialized='incremental',
    file_format='iceberg',
    incremental_strategy='merge'
) }}

{%- set hub_gl  = dv_config('hub_gl') -%}
{%- set dv_system = var("dv_system") -%}

{{ ktl_autovault.hub_transform(model=hub_gl, dv_system=dv_system, include_ghost_record=true) }}
