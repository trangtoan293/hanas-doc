{%- macro get_cob_date() -%}
{#
    Lấy cob_date từ vw_ref_eod dựa trên var('cob_date') hoặc max(cob_date)
    Returns: Subquery trả về cob_date
#}
(
    SELECT cob_date FROM {{ ref('vw_ref_eod') }}
    {% if var('cob_date', none) %}
    WHERE cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {% else %}
    WHERE cob_date = (SELECT MAX(cob_date) FROM {{ ref('vw_ref_eod') }})
    {% endif %}
)
{%- endmacro -%}


{%- macro get_run_time() -%}
{#
    Lấy run_time từ vw_ref_eod dựa trên var('cob_date') hoặc max(cob_date)
    Returns: Subquery trả về run_time (end of incremental window)
#}
(
    SELECT run_time FROM {{ ref('vw_ref_eod') }}
    {% if var('cob_date', none) %}
    WHERE cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {% else %}
    WHERE cob_date = (SELECT MAX(cob_date) FROM {{ ref('vw_ref_eod') }})
    {% endif %}
)
{%- endmacro -%}


{%- macro get_last_run_time() -%}
{#
    Lấy last_run_time từ vw_ref_eod dựa trên var('cob_date') hoặc max(cob_date)
    Returns: Subquery trả về last_run_time (start of incremental window)
#}
(
    SELECT last_run_time FROM {{ ref('vw_ref_eod') }}
    {% if var('cob_date', none) %}
    WHERE cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {% else %}
    WHERE cob_date = (SELECT MAX(cob_date) FROM {{ ref('vw_ref_eod') }})
    {% endif %}
)
{%- endmacro -%}


{%- macro get_ref_dates() -%}
{#
    Lấy danh sách ngày từ vw_ref_eod để hỗ trợ backfill
    
    Modes:
    - Backfill: var('start_date') + var('end_date') → trả về nhiều rows
    - Daily: var('cob_date') → trả về 1 row
    - Default: MAX(cob_date) → trả về 1 row
    
    Returns: Subquery trả về cob_date, run_time, last_run_time cho từng ngày
#}
(
    SELECT cob_date, run_time, last_run_time
    FROM {{ ref('vw_ref_eod') }}
    {% if var('start_date', none) and var('end_date', none) %}
    WHERE cob_date >= {{ ktl_autovault.timestamp(var('start_date')) }}
      AND cob_date <= {{ ktl_autovault.timestamp(var('end_date')) }}
    {% elif var('cob_date', none) %}
    WHERE cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {% else %}
    WHERE cob_date = (SELECT MAX(cob_date) FROM {{ ref('vw_ref_eod') }})
    {% endif %}
)
{%- endmacro -%}


{%- macro scd2_surrogate_key(business_keys, eff_date_column='EFF_FR_DT') -%}
{#
    Tạo surrogate key cho SCD Type 2 dimension bằng SHA256
    
    Args:
        business_keys: List các cột business key
        eff_date_column: Cột ngày hiệu lực (default: EFF_FR_DT)
    
    Returns: SHA256 hash của business keys + effective date
#}
SHA2(CONCAT(
    {%- for key in business_keys -%}
    CAST({{ key }} AS STRING)
    {%- if not loop.last -%}, '|', {%- endif -%}
    {%- endfor -%}
    , '|', CAST({{ eff_date_column }} AS STRING)
), 256)
{%- endmacro -%}


{#
    Macro: ref_dates_cte
    Generate CTE content for date range filtering based on dbt variables.
    (Same as get_ref_dates but without parentheses - for use in CTE definition)
    
    Usage in model:
        WITH ref_dates AS (
            {{ ref_dates_cte() }}
        ),
        ...
#}
{% macro ref_dates_cte() %}
    SELECT cob_date, run_time, last_run_time
    FROM {{ ref('vw_ref_eod') }}
    {% if var('start_date', none) and var('end_date', none) %}
    WHERE cob_date >= {{ ktl_autovault.timestamp(var('start_date')) }}
      AND cob_date <= {{ ktl_autovault.timestamp(var('end_date')) }}
    {% elif var('cob_date', none) %}
    WHERE cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {% else %}
    WHERE cob_date = (SELECT MAX(cob_date) FROM {{ ref('vw_ref_eod') }})
    {% endif %}
{% endmacro %}
