{{
    config(
        materialized='incremental',
        file_format='iceberg',
        incremental_strategy='insert_overwrite',
        partition_by=['COB_DATE'],
        on_schema_change='sync_all_columns'
    )
}}

{#
    Fact: fact_pl_detail (Daily Snapshot - P&L)
    Uses fact_snapshot_transform macro with config-driven approach.
#}

{%- set meta = {
    'source_model': ref('int_fact_pl_new'),
    'partition_col': 'COB_DATE',
    'dimensions': [
        {
            'name': 'dim_branch',
            'join_key': 'BRANCH_CODE',
            'ref_model': ref('dim_branch_new'),
            'ref_key': 'BRANCH_CODE',
            'sk_col': 'D_BRANCH_ID'
        }
    ],
    'measures': ['PL_CODE', 'FCY_OUTSTND', 'LCY_OUTSTND']
} -%}

{{ fact_snapshot_transform(meta) }}
