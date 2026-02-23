{# Main macro to generate validation SQL based on config #}
{%- macro generate_validation_sql(source_ref, product='CORECIF', source_system='SHB', original_source_ref='') -%}

{%- set all_rules = mdm_get_validation_rules(product, source_system) -%}
{%- set pk_col = mdm_get_pk_column(product, source_system) -%}

{# Build list of SQL statements #}
{%- set sql_statements = [] -%}

{%- for rule in all_rules %}
    {%- for column in rule.columns %}
        {%- set use_original = ((rule.validate_original == 'YES' or rule.validate_original == true) and original_source_ref != '') -%}
        {%- set col_reference = 'orig.' ~ column if use_original else 'cleansed.' ~ column -%}
        {%- set where_clause = '' -%}
        
        {%- if rule.template == 'check_null' -%}
            {%- set where_clause = col_reference ~ " IS NULL OR LOWER(" ~ col_reference ~ ") = 'null' OR " ~ col_reference ~ " = ' '" -%}
        {%- elif rule.template == 'check_date_conversion' -%}
            {%- set where_clause = col_reference ~ " IS NOT NULL AND TO_DATE(SUBSTR(" ~ col_reference ~ ", 1, 10), '" ~ rule.date_format ~ "') IS NULL" -%}
        {%- elif rule.template == 'validatetp_regex_not_like' -%}
            {%- set where_clause = "COALESCE(" ~ col_reference ~ ", 'NULL') <> 'NULL' AND NOT REGEXP_LIKE(" ~ col_reference ~ ", '" ~ rule.regex_pattern ~ "')" -%}
        {%- elif rule.template == 'check_invalid_category' -%}
            {%- set cat_type = rule.column_condition.split(':')[1] -%}
            {%- set where_clause = col_reference ~ " NOT IN (SELECT DISTINCT STANDARD_VALUE FROM " ~ ref('mdm_catalog_category') ~ " WHERE CATEGORY_TYPE = '" ~ cat_type ~ "' AND SOURCE_SYSTEM = '" ~ source_system ~ "')" -%}
        {%- elif rule.template == 'check_active_datetime_legal_id' -%}
            {%- set months = rule.condition.split(':')[0] | int * 12 -%}
            {%- set where_clause = "cleansed.LOAI_GTTT IN ('CCCD') AND cleansed.PASS_E_DT IS NOT NULL AND cleansed.PASS_I_DT IS NOT NULL AND cleansed.PASS_E_DT <> add_months(cleansed.PASS_I_DT, " ~ months ~ ")" -%}
        {%- elif rule.template == 'check_legal_id_range_datetime_with_open_date' -%}
            {%- set where_clause = col_reference ~ " IS NOT NULL AND cleansed." ~ rule.column_condition ~ " IS NOT NULL AND " ~ col_reference ~ " <= cleansed." ~ rule.column_condition -%}
        {%- elif rule.template == 'validatetp_pass_no_by_loai_gttt' -%}
            {%- set where_clause = "(cleansed.LOAI_GTTT IN ('CCCD') AND (NOT REGEXP_LIKE(" ~ col_reference ~ ", '[^0-9]') AND LENGTH(" ~ col_reference ~ ") <> 12 OR REGEXP_LIKE(" ~ col_reference ~ ", '[^0-9]'))) OR (cleansed.LOAI_GTTT IN ('CMT') AND (NOT REGEXP_LIKE(" ~ col_reference ~ ", '^[^0-9]') AND LENGTH(" ~ col_reference ~ ") NOT IN (9,12) OR REGEXP_LIKE(" ~ col_reference ~ ", '[^0-9]')))" -%}
        {%- else -%}
            {%- set where_clause = "1=0 -- Unknown template: " ~ rule.template -%}
        {%- endif -%}
        
        
        {%- set table_name = original_source_ref.identifier if (use_original and original_source_ref.identifier) else (original_source_ref | string).split('.')[-1] if use_original else (source_ref.identifier if source_ref.identifier else (source_ref | string).split('.')[-1]) -%}
        
        {%- set sql_stmt -%}
SELECT
    cleansed.{{ pk_col }} AS {{ pk_col }},
    '{{ table_name }}' AS `TABLE`,
    '{{ column }}' AS `COLUMN`,
    '{{ rule.code }}' AS `RULE`,
    CAST({{ col_reference }} AS STRING) AS `VALUE`,
    cleansed.dv_ldt AS dv_ldt
FROM {{ source_ref }} cleansed
{%- if use_original %}
LEFT JOIN {{ original_source_ref }} orig
    ON cleansed.{{ pk_col }} = orig.{{ pk_col }}
{%- endif %}
WHERE {{ where_clause }}
        {%- endset -%}
        
        {%- do sql_statements.append(sql_stmt) -%}
    {%- endfor %}
{%- endfor %}

{# Join all statements with UNION ALL #}
{{ sql_statements | join('\nUNION ALL\n') }}

{%- endmacro -%}
