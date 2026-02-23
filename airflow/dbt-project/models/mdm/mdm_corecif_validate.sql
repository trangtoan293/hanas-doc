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
    MDM Validate: Pivot validation results per CIF
    
    Incremental: Inherits from upstream models
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
cleansed_filtered AS (
    SELECT c.*
    FROM {{ ref('mdm_corecif_cleansed') }} c
    JOIN ref_dates rd
      ON c.dv_ldt > rd.last_run_time AND c.dv_ldt <= rd.run_time
),
input_invalid AS (
    SELECT i.*
    FROM {{ ref('mdm_corecif_invalid') }} i
    JOIN ref_dates rd
      ON i.dv_ldt > rd.last_run_time AND i.dv_ldt <= rd.run_time
),
validated AS (
{{ pivot_validation_results(
    validation_ref='input_invalid',
    cleansed_ref='cleansed_filtered',
    product='CORECIF',
    source_system='SHB'
) }}
)
SELECT * FROM validated WHERE CIF_NO <> '0'
{% else %}
WITH validated AS (
{{ pivot_validation_results(
    validation_ref=ref('mdm_corecif_invalid'),
    cleansed_ref=ref('mdm_corecif_cleansed'),
    product='CORECIF',
    source_system='SHB'
) }}
)
SELECT * FROM validated WHERE CIF_NO <> '0'
{% endif %}
