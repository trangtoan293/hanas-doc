{#
    Macro: dim_scd2_transform
    Generic SCD Type 2 transformation for Dimension tables.
    
    Reads config from model.config.meta:
        - source_model: ref to intermediate model
        - business_key: list of column names
        - surrogate_key: column name for SK
        - attributes: list of columns to track changes
        - validity.start_col, validity.end_col, validity.status_col
        - timestamp_col: source column for record timestamp
#}

{% macro dim_scd2_transform(meta) %}

{%- set source_model = meta.get('source_model') -%}
{%- set business_keys = meta.get('business_key', []) -%}
{%- set surrogate_key = meta.get('surrogate_key', 'SK_ID') -%}
{%- set attributes = meta.get('attributes', []) -%}
{%- set validity = meta.get('validity', {}) -%}
{%- set eff_fr_col = validity.get('start_col', 'EFF_FR_DT') -%}
{%- set eff_to_col = validity.get('end_col', 'EFF_TO_DT') -%}
{%- set status_col = validity.get('status_col', 'IN_USE_STATUS') -%}
{%- set timestamp_col = meta.get('timestamp_col', 'DV_SRC_LDT') -%}
{%- set all_columns = business_keys + attributes -%}

WITH ref_dates AS (
    {{ ref_dates_cte() }}
),

-- Build validity windows from source using Window Function
source_with_validity AS (
    SELECT 
        src.*,
        src.{{ timestamp_col }} AS valid_from,
        COALESCE(
            LEAD(src.{{ timestamp_col }}) OVER (
                PARTITION BY {% for bk in business_keys %}src.{{ bk }}{{ ', ' if not loop.last }}{% endfor %}
                ORDER BY src.{{ timestamp_col }}
            ),
            TIMESTAMP('9999-12-31 23:59:59')
        ) AS valid_to
    FROM {{ source_model }} src
),

-- Snapshot for each date in ref_dates
snapshots_by_date AS (
    SELECT 
        rd.cob_date,
        rd.run_time,
        {% for col in all_columns %}
        src.{{ col }},
        {% endfor %}
        src.{{ timestamp_col }},
        -- Generate hash for change detection
        SHA2(CONCAT(
            {% for col in attributes %}
            COALESCE(CAST(src.{{ col }} AS STRING), ''){{ ', \'|\', ' if not loop.last }}
            {% endfor %}
        ), 256) AS attr_hash
    FROM ref_dates rd
    JOIN source_with_validity src
        ON rd.run_time >= src.valid_from 
       AND rd.run_time < src.valid_to
)

{% if is_incremental() %}
-- =============================================================================
-- INCREMENTAL MODE: Detect changes and manage SCD2 history
-- =============================================================================

-- Get existing active records
, existing_dim_state AS (
    SELECT 
        {% for bk in business_keys %}{{ bk }},{% endfor %}
        SHA2(CONCAT(
            {% for col in attributes %}
            COALESCE(CAST({{ col }} AS STRING), ''){{ ', \'|\', ' if not loop.last }}
            {% endfor %}
        ), 256) AS existing_hash,
        {{ eff_fr_col }} AS existing_eff_fr_dt,
        {{ surrogate_key }} AS existing_sk
    FROM {{ this }}
    WHERE {{ status_col }} = 1
      AND {{ eff_fr_col }} < (SELECT MIN(cob_date) FROM ref_dates)
)

-- Detect changes comparing with previous day OR existing dim
, changes_detected AS (
    SELECT 
        s.*,
        ex.existing_hash,
        ex.existing_sk,
        ex.existing_eff_fr_dt,
        COALESCE(
            LAG(s.attr_hash) OVER (PARTITION BY {% for bk in business_keys %}s.{{ bk }}{{ ', ' if not loop.last }}{% endfor %} ORDER BY s.cob_date),
            ex.existing_hash
        ) AS prev_hash,
        CASE 
            WHEN LAG(s.attr_hash) OVER (PARTITION BY {% for bk in business_keys %}s.{{ bk }}{{ ', ' if not loop.last }}{% endfor %} ORDER BY s.cob_date) IS NULL 
                 AND ex.existing_hash IS NULL THEN 'NEW'
            WHEN s.attr_hash <> COALESCE(
                LAG(s.attr_hash) OVER (PARTITION BY {% for bk in business_keys %}s.{{ bk }}{{ ', ' if not loop.last }}{% endfor %} ORDER BY s.cob_date),
                ex.existing_hash
            ) THEN 'CHANGED'
            ELSE 'SAME'
        END AS change_type
    FROM snapshots_by_date s
    LEFT JOIN existing_dim_state ex 
        ON {% for bk in business_keys %}s.{{ bk }} = ex.{{ bk }}{{ ' AND ' if not loop.last }}{% endfor %}
)

-- Keep only NEW/CHANGED records
, changes_only AS (
    SELECT * FROM changes_detected
    WHERE change_type IN ('NEW', 'CHANGED')
)

-- New/Changed records
, new_records AS (
    SELECT
        SHA2(CONCAT(
            {% for bk in business_keys %}CAST(c.{{ bk }} AS STRING), '|', {% endfor %}
            CAST(CAST(c.cob_date AS DATE) AS STRING)
        ), 256) AS {{ surrogate_key }},
        CAST(c.cob_date AS DATE) AS {{ eff_fr_col }},
        COALESCE(
            DATE_SUB(LEAD(c.cob_date) OVER (PARTITION BY {% for bk in business_keys %}c.{{ bk }}{{ ', ' if not loop.last }}{% endfor %} ORDER BY c.cob_date), 1),
            TO_DATE('9999-12-31')
        ) AS {{ eff_to_col }},
        CASE 
            WHEN LEAD(c.cob_date) OVER (PARTITION BY {% for bk in business_keys %}c.{{ bk }}{{ ', ' if not loop.last }}{% endfor %} ORDER BY c.cob_date) IS NULL THEN 1 
            ELSE 0 
        END AS {{ status_col }},
        c.{{ timestamp_col }} AS LAST_MODIFY_TIME,
        {% for col in all_columns %}
        c.{{ col }}{{ ',' if not loop.last }}
        {% endfor %}
    FROM changes_only c
)

-- Close existing records if there's a change
, records_to_close AS (
    SELECT 
        ex.existing_sk AS {{ surrogate_key }},
        d.{{ eff_fr_col }},
        DATE_SUB((SELECT MIN(cob_date) FROM changes_only co WHERE {% for bk in business_keys %}co.{{ bk }} = ex.{{ bk }}{{ ' AND ' if not loop.last }}{% endfor %}), 1) AS {{ eff_to_col }},
        0 AS {{ status_col }},
        d.LAST_MODIFY_TIME,
        {% for col in all_columns %}
        d.{{ col }}{{ ',' if not loop.last }}
        {% endfor %}
    FROM existing_dim_state ex
    JOIN {{ this }} d ON ex.existing_sk = d.{{ surrogate_key }}
    WHERE EXISTS (SELECT 1 FROM changes_only co WHERE {% for bk in business_keys %}co.{{ bk }} = ex.{{ bk }}{{ ' AND ' if not loop.last }}{% endfor %})
)

-- Union all changes with deduplication
, all_changes AS (
    SELECT * FROM new_records
    UNION ALL
    SELECT * FROM records_to_close
)

, deduplicated_changes AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY {{ surrogate_key }} ORDER BY {{ status_col }} DESC, {{ eff_to_col }} DESC) AS rn
    FROM all_changes
)

SELECT 
    {{ surrogate_key }}, {{ eff_fr_col }}, {{ eff_to_col }}, {{ status_col }}, LAST_MODIFY_TIME,
    {% for col in all_columns %}
    {{ col }}{{ ',' if not loop.last }}
    {% endfor %}
FROM deduplicated_changes
WHERE rn = 1

{% else %}
-- =============================================================================
-- FULL REFRESH MODE: Load all with active status, EFF_FR_DT = 1900-01-01
-- =============================================================================

SELECT
    SHA2(CONCAT(
        {% for bk in business_keys %}CAST({{ bk }} AS STRING), '|', {% endfor %}
        CAST(CAST(cob_date AS DATE) AS STRING)
    ), 256) AS {{ surrogate_key }},
    TO_DATE('1900-01-01') AS {{ eff_fr_col }},
    TO_DATE('9999-12-31') AS {{ eff_to_col }},
    1 AS {{ status_col }},
    {{ timestamp_col }} AS LAST_MODIFY_TIME,
    {% for col in all_columns %}
    {{ col }}{{ ',' if not loop.last }}
    {% endfor %}
FROM snapshots_by_date
WHERE cob_date = (SELECT MAX(cob_date) FROM ref_dates)

{% endif %}

{% endmacro %}
