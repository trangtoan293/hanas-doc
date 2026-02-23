{# Main macro to apply cleansing rules based on config #}
{%- macro apply_cleansing_rules(source_ref, product='CORECIF', source_system='SHB') -%}

{%- set all_rules = mdm_get_cleansing_rules(product, source_system) -%}
{%-set all_columns = mdm_get_all_columns(product, source_system) -%}

WITH source_data AS (
    SELECT * FROM {{ source_ref }}
)

{%- for rule in all_rules %}
, {{ rule.code }}_applied AS (
    SELECT
    {%- for col in all_columns %}
        {%- if col in rule.columns %}
            {%- if rule.template == 'cleantp_replace_category' %}
        COALESCE(cat_{{ rule.code }}_{{ col }}.STANDARD_VALUE, source.{{ col }}) AS {{ col }}
            {%- elif rule.template == 'cleantp_remove_pattern' %}
        REGEXP_REPLACE(source.{{ col }}, '{{ rule.character }}', '') AS {{ col }}
            {%- elif rule.template == 'cleantp_format_datetime' %}
        TO_DATE(SUBSTR(source.{{ col }}, 1, 10), '{{ rule.from_str_format }}') AS {{ col }}
            {%- else %}
        source.{{ col }}
            {%- endif %}
        {%- else %}
        source.{{ col }}
        {%- endif %}
        {%- if not loop.last %},{% endif %}
    {%- endfor %}
    FROM {% if loop.first %}source_data{% else %}{{ all_rules[loop.index0 - 1].code }}_applied{% endif %} source
    {%- if rule.template == 'cleantp_replace_category' %}
        {%- for col in rule.columns %}
    LEFT JOIN {{ ref('mdm_catalog_category') }} cat_{{ rule.code }}_{{ col }}
        ON LOWER(source.{{ col }}) = LOWER(cat_{{ rule.code }}_{{ col }}.ORIGINAL_VALUE)
        AND cat_{{ rule.code }}_{{ col }}.CATEGORY_TYPE = LOWER('{{ rule.column_condition.split(':')[1] }}')
        AND LOWER(cat_{{ rule.code }}_{{ col }}.SOURCE_SYSTEM) = LOWER('{{ source_system }}')
        {%- endfor %}
    {%- endif %}
)
{%- endfor %}

SELECT * FROM {{ all_rules[-1].code }}_applied

{%- endmacro -%}
