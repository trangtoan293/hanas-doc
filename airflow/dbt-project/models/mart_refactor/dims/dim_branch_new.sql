{{
    config(
        materialized='incremental',
        file_format='iceberg',
        unique_key='D_BRANCH_ID',
        incremental_strategy='merge',
        merge_update_columns=['EFF_TO_DT', 'IN_USE_STATUS'],
        on_schema_change='sync_all_columns'
    )
}}

{#
    Dimension: dim_branch (SCD Type 2)
    Uses dim_scd2_transform macro with config-driven approach.
#}

{%- set meta = {
    'source_model': ref('int_dim_branch_new'),
    'business_key': ['BRANCH_CODE'],
    'surrogate_key': 'D_BRANCH_ID',
    'attributes': ['BRANCH_NAME', 'PARENT_CODE', 'PARENT_NAME', 'KV_NAME', 'NBR_STAFF'],
    'validity': {
        'start_col': 'EFF_FR_DT',
        'end_col': 'EFF_TO_DT',
        'status_col': 'IN_USE_STATUS'
    },
    'timestamp_col': 'DV_SRC_LDT'
} -%}

{{ dim_scd2_transform(meta) }}
