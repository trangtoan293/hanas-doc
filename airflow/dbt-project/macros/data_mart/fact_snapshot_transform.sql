{#
    Macro: fact_snapshot_transform
    Generic Fact Snapshot transformation with Point-in-Time dimension joins.
    
    Reads config from meta:
        - source_model: ref to intermediate model
        - partition_col: column name for partitioning (e.g., COB_DATE)
        - dimensions: list of dimension join configs
        - measures: list of measure column names
        - ldt_col: (optional) load timestamp column for incremental filtering, default 'DV_LDT'
#}

{% macro fact_snapshot_transform(meta) %}

{%- set source_model = meta.get('source_model') -%}
{%- set partition_col = meta.get('partition_col', 'COB_DATE') -%}
{%- set dimensions = meta.get('dimensions', []) -%}
{%- set measures = meta.get('measures', []) -%}
{%- set ldt_col = meta.get('ldt_col', 'DV_LDT') -%}

WITH ref_dates AS (
    {{ ref_dates_cte() }}
),

-- Filter source data by incremental window (DV_LDT) or COB_DATE
source_filtered AS (
    SELECT *
    FROM {{ source_model }}
    {% if is_incremental() %}
    WHERE {{ ldt_col }} > (SELECT MAX(last_run_time) FROM ref_dates)
      AND {{ ldt_col }} <= (SELECT MAX(run_time) FROM ref_dates)
    {% endif %}
)

SELECT
    f.{{ partition_col }},
    {% for dim in dimensions %}
    d{{ loop.index }}.{{ dim.get('sk_col') }},
    {% endfor %}
    {% for measure in measures %}
    f.{{ measure }}{{ ',' if not loop.last }}
    {% endfor %}
FROM source_filtered f
{% for dim in dimensions %}
JOIN {{ dim.get('ref_model') }} d{{ loop.index }}
    ON f.{{ dim.get('join_key') }} = d{{ loop.index }}.{{ dim.get('ref_key') }}
    {% if is_incremental() %}
    AND f.{{ partition_col }} >= d{{ loop.index }}.EFF_FR_DT
    AND f.{{ partition_col }} <= d{{ loop.index }}.EFF_TO_DT
    {% else %}
    AND d{{ loop.index }}.IN_USE_STATUS = 1
    {% endif %}
{% endfor %}

{% endmacro %}
