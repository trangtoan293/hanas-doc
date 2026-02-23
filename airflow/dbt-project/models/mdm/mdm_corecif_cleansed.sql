-- depends_on: {{ ref('vw_ref_eod') }}
{{
    config(
        materialized='incremental',
        file_format='iceberg',
        unique_key='CIF_NO',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns'
    )
}}

{#
    MDM Cleansing: Apply cleansing rules to source data
    
    Incremental: Inherits from upstream mdm_source_corecif
#}

{% if is_incremental() %}
WITH ref_dates AS (
    SELECT run_time, last_run_time
    FROM {{ ref('vw_ref_eod') }}
    {% if var('cob_date', none) %}
    WHERE cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {% else %}
    WHERE cob_date = (SELECT MAX(cob_date) FROM {{ ref('vw_ref_eod') }})
    {% endif %}
),
source_filtered AS (
    SELECT s.*
    FROM {{ ref('mdm_source_corecif') }} s
    JOIN ref_dates rd
      ON s.dv_ldt > rd.last_run_time AND s.dv_ldt <= rd.run_time
),
cleansed AS (
{{ apply_cleansing_rules(
    source_ref='source_filtered',
    product='CORECIF',
    source_system='SHB'
) }}
)
SELECT * FROM cleansed WHERE CIF_NO <> '0'
{% else %}
WITH cleansed AS (
{{ apply_cleansing_rules(
    source_ref=ref('mdm_source_corecif'),
    product='CORECIF',
    source_system='SHB'
) }}
)
SELECT * FROM cleansed WHERE CIF_NO <> '0'
{% endif %}
