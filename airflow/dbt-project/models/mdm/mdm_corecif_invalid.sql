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
    MDM Validation: Generate validation errors for cleansed data
    
    Incremental: Inherits from upstream cleansed model
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
source_filtered AS (
    SELECT s.*
    FROM {{ ref('mdm_source_corecif') }} s
    JOIN ref_dates rd
      ON s.dv_ldt > rd.last_run_time AND s.dv_ldt <= rd.run_time
)
{{ generate_validation_sql(
    source_ref='cleansed_filtered',
    product='CORECIF',
    source_system='SHB',
    original_source_ref='source_filtered'
) }}
{% else %}
{{ generate_validation_sql(
    source_ref=ref('mdm_corecif_cleansed'),
    product='CORECIF',
    source_system='SHB',
    original_source_ref=ref('mdm_source_corecif')
) }}
{% endif %}
