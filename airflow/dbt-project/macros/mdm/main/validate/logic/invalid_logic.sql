{# logic invalid rule using regex pattern #}
{%- macro invalid_logic_regex_not_like(obj, rule_code, regex_pattern, is_null) -%}
    {%- if is_null -%}
        CASE WHEN NOT REGEXP_LIKE({{obj}}, '{{regex_pattern}}') OR {{obj}} IS NULL THEN '{{obj}}' END AS error_column_{{obj}}_{{rule_code}},
        CASE WHEN NOT REGEXP_LIKE({{obj}}, '{{regex_pattern}}') THEN CAST({{obj}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) END AS error_value_{{obj}}_{{rule_code}}
    {%- else -%}
        CASE WHEN NOT REGEXP_LIKE({{obj}}, '{{regex_pattern}}') THEN '{{obj}}' END AS error_column_{{obj}}_{{rule_code}},
        CASE WHEN NOT REGEXP_LIKE({{obj}}, '{{regex_pattern}}') THEN CAST({{obj}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) END AS error_value_{{obj}}_{{rule_code}}
    {%- endif -%}
{%- endmacro -%}

{# logic invalid rule using check null #}
{%- macro invalid_logic_check_null(obj, rule_code) -%}
    CASE WHEN {{obj}} IS NULL OR LOWER({{obj}}) = 'null' OR {{obj}}=' ' THEN '{{obj}}' END AS error_column_{{obj}}_{{rule_code}},
    CASE WHEN {{obj}} IS NULL OR LOWER({{obj}}) = 'null' OR {{obj}}=' ' THEN CAST({{obj}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) END AS error_value_{{obj}}_{{rule_code}}
{%- endmacro -%}

{# logic invalid rule check structure cccd --- V8 #}
{%- macro invalid_logic_check_format_CCCD_corr_YOB(obj, column_condition) -%}
    SUBSTR({{ obj }}, 5, 2) != {{ktl_mdm_utils_get_year(column_condition)}}
{%- endmacro -%}

{# logic invalid rule check the legal docs of customer --- S267 #}
{%- macro invalid_logic_check_active_datetime_legal_id(obj, col_condition, condition) -%}
    CASE WHEN {{col_condition}} IS NOT NULL THEN
        CASE WHEN {{ktl_mdm_utils_calculate_date(col_condition)}}/365 <= {{condition[0]}} THEN
            CASE WHEN {{ktl_mdm_utils_calculate_date(obj)}}/365 <= {{condition[1]}} THEN 0
                ELSE 1 
            END
        ELSE 0 END
    ELSE 1 END
{%- endmacro -%}

{# logic invalid rule check range datetime of the legal docs of customer --- S35 #}
{%- macro invalid_logic_check_range_datetime_legal_id(obj, col_condition) -%}
    CASE 
        WHEN {{obj}} IS NOT NULL THEN
            CASE
                WHEN {{col_condition}} IS NOT NULL AND {{obj}} BETWEEN {{col_condition}} AND {{ktl_mdm_utils_get_sysdate()}} THEN 0
                WHEN {{col_condition}} IS NULL AND {{obj}} <= {{ktl_mdm_utils_get_sysdate()}} THEN 0
                ELSE 1
            END
         ELSE 1
    END
{%- endmacro -%}

{# logic invalid rule check length min max #}
{%- macro invalid_logic_check_length(obj, condition, warning_null) -%}
    {%- if warning_null -%}
        LENGTH({{obj}}) < {{condition}} OR {{obj}} is null
    {%- else -%}
        LENGTH({{obj}}) < {{condition}}
    {%- endif -%}
{%- endmacro -%}

{# logic invalid rule check range datetime #}
{%- macro invalid_logic_check_range_datetime(obj, condition, warning_null) -%}

   {%- if condition is none -%}
      NOT ( {{obj}} <= CURRENT_DATE )

   {%- elif condition is not none -%}
      {%- set list_condition = condition.split(":") -%}
      {%- if list_condition | length != 1 -%}

      {{ktl_mdm_utils_calculate_date(obj)}}/365 > {{list_condition[1]}} or {{ktl_mdm_utils_calculate_date(obj)}}/365 < {{list_condition[0]}}
      
      {%- else -%}
      
      {{obj}} = TO_DATE('{{condition}}', 'yyyy-MM-dd')
      
      {%- endif -%}
   {%- endif -%}
{%- endmacro -%}

{# logic invalid rule check format sdt #}
{%- macro invalid_logic_check_format_sdt(obj, condition, warning_null) -%}
    {{obj}} IN (
            {%- for number in condition.split(":") -%}
                    '{{ number }}'{%- if not loop.last -%}, {%- endif -%}
            {%- endfor -%}
    )
{%- endmacro -%}

{# logic invalid rule check email #}
{%- macro invalid_logic_check_email(obj, catalog_condition, catalog_column, cus_type, warning_null) -%}
    LEFT JOIN (SELECT {{catalog_column}} FROM {{catalog_condition}} WHERE CUS_TYPE = '{{cus_type}}') k
    ON LOWER( {{ obj }} ) = LOWER( k.{{catalog_column}} )
    WHERE {{ catalog_column }} is null
{%- endmacro -%}

{# logic invalid rule check suffix email #}
{%- macro invalid_logic_check_suffix_email(obj, catalog_condition, catalog_column, cus_type, warning_null) -%}
    LEFT JOIN (SELECT {{catalog_column}} FROM {{catalog_condition}} WHERE CUS_TYPE = '{{cus_type}}') sf
    ON LOWER( SUBSTR({{obj}}, INSTR({{obj}}, '@')+1) ) = LOWER( sf.{{catalog_column}} )
    WHERE sf.{{catalog_column}} is null
{%- endmacro -%}

{# logic invalid rule check catalog category#}
{%- macro invalid_logic_check_catalog_category(obj, catalog_condition, catalog_config, source, catagory_type) -%}
    {%- set _source = catalog_config.column_source -%}
    {%- set _category_type = catalog_config.column_category_type -%}
    {%- set _standard_value = catalog_config.column_standard_value -%}
    
    LEFT JOIN  ( SELECT * FROM {{catalog_condition}} WHERE LOWER({{_category_type}}) = LOWER('{{catagory_type}}')
                    AND LOWER({{_source}})  = LOWER('{{source}}') ) k
    ON LOWER(k.{{_standard_value}}) = LOWER({{obj}})
    WHERE {{_standard_value}} IS NULL
{%- endmacro -%}


{# logic invalid rule check head number cccd #}
{%- macro invalid_logic_check_head_number_cccd(obj, catalog_condition, catalog_column, warning_null) -%}
    {%- if warning_null -%}
    LEFT JOIN {{ catalog_condition }} k 
    ON SUBSTR({{ obj }}, 1, 3) = k.{{ catalog_column }}
    WHERE {{catalog_column}} is null
    {%- else -%}
    LEFT JOIN {{ catalog_condition }} k 
    ON SUBSTR({{ obj }}, 1, 3) = k.{{ catalog_column }}
    WHERE {{catalog_column}} is null and {{obj}} is not null
    {%- endif -%}
{%- endmacro -%}
