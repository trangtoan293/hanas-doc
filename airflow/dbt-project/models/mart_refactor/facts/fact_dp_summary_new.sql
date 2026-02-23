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
    Fact: fact_dp_summary (Daily Summary - Deposit)
    Uses fact_summary_transform macro with MTD calculations.
#}

{%- set meta = {
    'source_model': ref('fact_dp_detail_new'),
    'partition_col': 'COB_DATE',
    'group_by_cols': ['D_BRANCH_ID', 'CUSTOMER_TYPE', 'ACCOUNT_TYPE'],
    'measures': ['LCY_CURR_BALANCE']
} -%}

{{ fact_summary_transform(meta) }}
