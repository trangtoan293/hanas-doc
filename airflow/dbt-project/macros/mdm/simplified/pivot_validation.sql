{# Main macro to pivot validation results and join back to cleansed data #}
{%- macro pivot_validation_results(validation_ref, cleansed_ref, product='CORECIF', source_system='SHB') -%}

{%- set pk_col = mdm_get_pk_column(product, source_system) -%}
{%- set all_columns = mdm_get_all_columns(product, source_system) -%}
{%- set all_rules = mdm_get_validation_rules(product, source_system) -%}

{# Get unique columns that have validations #}
{%- set validated_columns = [] -%}
{%- for rule in all_rules -%}
    {%- for col in rule.columns -%}
        {%- if col not in validated_columns -%}
            {%- do validated_columns.append(col) -%}
        {%- endif -%}
    {%- endfor -%}
{%- endfor -%}

WITH validation_pivoted AS (
    SELECT
        {{ pk_col }},
        {%- for col in validated_columns %}
        SUM(CASE WHEN `COLUMN` = '{{ col }}' THEN 1 ELSE 0 END) AS {{ col }}_ERR_CNT
        {%- if not loop.last %},{% endif %}
        {%- endfor %}
    FROM {{ validation_ref }}
    GROUP BY {{ pk_col }}
)

SELECT
    {%- for col in all_columns %}
    c.{{ col }},
    {%- endfor %}
    {%- for col in validated_columns %}
    COALESCE(v.{{ col }}_ERR_CNT, 0) AS {{ col }}_ERR_CNT,
    {%- endfor %}
    {%- for col in validated_columns %}
    COALESCE(v.{{ col }}_ERR_CNT, 0){% if not loop.last %} + {% endif %}
    {%- endfor %} AS TOTAL_ERR_CNT
FROM {{ cleansed_ref }} c
LEFT JOIN validation_pivoted v
    ON c.{{ pk_col }} = v.{{ pk_col }}

{%- endmacro -%}
