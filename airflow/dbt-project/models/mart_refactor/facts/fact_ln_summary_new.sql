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
    Fact: fact_ln_summary (Daily Summary - Loan)
    Uses fact_summary_transform macro with MTD calculations.
    
    Extended Logic:
    - Adds NPL metrics (3% of derived balance)
    - Adds OVD metrics (5% of derived balance)
    - Logic matched with legacy SQL (WHERE clauses were commented out)
#}

{%- set meta = {
    'source_model': ref('fact_ln_detail_new'),
    'partition_col': 'COB_DATE',
    'group_by_cols': ['D_BRANCH_ID', 'CUSTOMER_TYPE', 'ACCOUNT_TYPE', 'DEBT_GRP'],
    'measures': ['LCY_OUTSTND']
} -%}

WITH base_summary AS (
    {{ fact_summary_transform(meta) }}
)

SELECT
    s.*,
    -- NPL Metrics (3% logic based on legacy SQL)
    s.LCY_OUTSTND_TODAY * 0.03 AS NPL_TODAY,
    s.LCY_OUTSTND_ELM   * 0.03 AS NPL_ELM,
    s.LCY_OUTSTND_ELY   * 0.03 AS NPL_ELY,
    
    -- OVD Metrics (5% logic based on legacy SQL)
    s.LCY_OUTSTND_TODAY * 0.05 AS OVD_TODAY,
    s.LCY_OUTSTND_ELM   * 0.05 AS OVD_ELM,
    s.LCY_OUTSTND_ELY   * 0.05 AS OVD_ELY
FROM base_summary s
