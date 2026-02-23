{#
    Macro: fact_summary_transform
    Generic Fact Summary transformation with MTD calculations.
    
    Reads config from meta:
        - source_model: ref to fact detail model
        - partition_col: column name for partitioning (e.g., COB_DATE)
        - group_by_cols: list of columns to group by
        - measures: list of measure column names to aggregate
#}

{% macro fact_summary_transform(meta) %}

{%- set source_model = meta.get('source_model') -%}
{%- set partition_col = meta.get('partition_col', 'COB_DATE') -%}
{%- set group_by_cols = meta.get('group_by_cols', []) -%}
{%- set measures = meta.get('measures', []) -%}

WITH ref_dates AS (
    {{ ref_dates_cte() }}
),

dim_time AS (
    SELECT * FROM {{ ref('dim_time') }}
),

-- =============================================================================
-- Prepare Datasets for UNION ALL
-- =============================================================================

-- 1. Current Day Data
curr_data AS (
    SELECT 
        t.{{ partition_col }},
        t.ELM_DATE, t.ELY_DATE, t.DAY_AGO, t.BOM_DATE, t.DAY_IN_MONTH,
        {% for col in group_by_cols %}f.{{ col }},{% endfor %}
        -- Measures mapping
        {% for m in measures %}f.{{ m }} AS {{ m }}_TODAY,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_DAGO,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_ELM,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_ELY,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_MTD{% endfor %}
    FROM {{ source_model }} f
    JOIN dim_time t ON f.{{ partition_col }} = t.{{ partition_col }}
    {% if is_incremental() %}
    WHERE t.{{ partition_col }} IN (SELECT cob_date FROM ref_dates)
    {% endif %}
),

-- 2. Day Ago Data
dago_data AS (
    SELECT 
        t.{{ partition_col }},
        t.ELM_DATE, t.ELY_DATE, t.DAY_AGO, t.BOM_DATE, t.DAY_IN_MONTH,
        {% for col in group_by_cols %}f.{{ col }},{% endfor %}
        {% for m in measures %}0 AS {{ m }}_TODAY,{% endfor %}
        {% for m in measures %}f.{{ m }} AS {{ m }}_DAGO,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_ELM,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_ELY,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_MTD{% endfor %}
    FROM {{ source_model }} f
    JOIN dim_time t ON f.{{ partition_col }} = t.DAY_AGO -- f.date = t.DAY_AGO implies f is yesterday relative to t
    {% if is_incremental() %}
    WHERE t.{{ partition_col }} IN (SELECT cob_date FROM ref_dates)
    {% endif %}
),

-- 3. End of Last Month Data
elm_data AS (
    SELECT 
        t.{{ partition_col }},
        t.ELM_DATE, t.ELY_DATE, t.DAY_AGO, t.BOM_DATE, t.DAY_IN_MONTH,
        {% for col in group_by_cols %}f.{{ col }},{% endfor %}
        {% for m in measures %}0 AS {{ m }}_TODAY,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_DAGO,{% endfor %}
        {% for m in measures %}f.{{ m }} AS {{ m }}_ELM,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_ELY,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_MTD{% endfor %}
    FROM {{ source_model }} f
    JOIN dim_time t ON f.{{ partition_col }} = t.ELM_DATE
    {% if is_incremental() %}
    WHERE t.{{ partition_col }} IN (SELECT cob_date FROM ref_dates)
    {% endif %}
),

-- 4. End of Last Year Data
ely_data AS (
    SELECT 
        t.{{ partition_col }},
        t.ELM_DATE, t.ELY_DATE, t.DAY_AGO, t.BOM_DATE, t.DAY_IN_MONTH,
        {% for col in group_by_cols %}f.{{ col }},{% endfor %}
        {% for m in measures %}0 AS {{ m }}_TODAY,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_DAGO,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_ELM,{% endfor %}
        {% for m in measures %}f.{{ m }} AS {{ m }}_ELY,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_MTD{% endfor %}
    FROM {{ source_model }} f
    JOIN dim_time t ON f.{{ partition_col }} = t.ELY_DATE
    {% if is_incremental() %}
    WHERE t.{{ partition_col }} IN (SELECT cob_date FROM ref_dates)
    {% endif %}
),

-- 5. Month To Date Data (Accumulative)
mtd_data AS (
    SELECT 
        t.{{ partition_col }},
        t.ELM_DATE, t.ELY_DATE, t.DAY_AGO, t.BOM_DATE, t.DAY_IN_MONTH,
        {% for col in group_by_cols %}f.{{ col }},{% endfor %}
        {% for m in measures %}0 AS {{ m }}_TODAY,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_DAGO,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_ELM,{% endfor %}
        {% for m in measures %}0 AS {{ m }}_ELY,{% endfor %}
        {% for m in measures %}f.{{ m }} AS {{ m }}_MTD{% endfor %}
    FROM {{ source_model }} f
    JOIN dim_time t ON f.{{ partition_col }} BETWEEN t.BOM_DATE AND t.{{ partition_col }}
    {% if is_incremental() %}
    WHERE t.{{ partition_col }} IN (SELECT cob_date FROM ref_dates)
    {% endif %}
),

-- Union All
unioned_data AS (
    SELECT * FROM curr_data
    UNION ALL
    SELECT * FROM dago_data
    UNION ALL
    SELECT * FROM elm_data
    UNION ALL
    SELECT * FROM ely_data
    UNION ALL
    SELECT * FROM mtd_data
)

-- =============================================================================
-- Final Aggregation
-- =============================================================================
SELECT 
    {{ partition_col }},
    ELM_DATE, ELY_DATE, DAY_AGO, BOM_DATE, DAY_IN_MONTH,
    {% for col in group_by_cols %}{{ col }},{% endfor %}
    {% for m in measures %}
    SUM({{ m }}_TODAY) AS {{ m }}_TODAY,
    SUM({{ m }}_DAGO) AS {{ m }}_DAGO,
    SUM({{ m }}_ELM) AS {{ m }}_ELM,
    SUM({{ m }}_ELY) AS {{ m }}_ELY,
    SUM({{ m }}_MTD) AS {{ m }}_MTD,
    SUM({{ m }}_MTD) / MAX(DAY_IN_MONTH) AS {{ m }}_AVG_MTD{{ ',' if not loop.last }}
    {% endfor %}
FROM unioned_data
GROUP BY 
    {{ partition_col }},
    ELM_DATE, ELY_DATE, DAY_AGO, BOM_DATE, DAY_IN_MONTH
    {% for col in group_by_cols %}, {{ col }}{% endfor %}

{% endmacro %}
