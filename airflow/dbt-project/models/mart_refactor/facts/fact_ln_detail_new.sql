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
    Fact: fact_ln_detail (Daily Snapshot - Loan)
    Uses fact_snapshot_transform macro with config-driven approach.
#}

{%- set meta = {
    'source_model': ref('int_fact_ln_new'),
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
    'measures': ['CUSTOMER_TYPE', 'ACCOUNT_TYPE', 'DEBT_GRP', 'FCY_OUTSTND', 'LCY_OUTSTND']
} -%}

{{ fact_snapshot_transform(meta) }}
