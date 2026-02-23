
{# gen sql invalid rule regex pattern #}
{%- macro invalid_registry_rule_regex_pattern(lst_col_key, lst_col_apply, rule_info, name_table_temp, cus_type=none) -%}
    {%- set rule_code = rule_info.get('code') -%}
    {%- set logic_rule = [] -%}
    {%- set select_lst = [] -%}

    {%- for col_name in lst_col_apply -%}
        {%- set gen_logic_rule = invalid_logic_regex_not_like(obj = col_name,
                                                            rule_code = rule_code,
                                                            regex_pattern = rule_info.get('regex_pattern'),
                                                            is_null = rule_info.get('warning_null')
                                                            ) -%}
        {%- do logic_rule.append(gen_logic_rule) -%}

        {%- set select_unionall = gen_sql_select_format(
                            lst_col_key = lst_col_key,
                            _error_code = "{}_error_code".format(rule_code),
                            _error_column = "error_column_{}_{}".format(col_name, rule_code),
                            _error_value = "error_value_{}_{}".format(col_name, rule_code),
                            name_table = name_table_temp) -%}


        {%- do select_lst.append(select_unionall) -%}
    {%- endfor -%}

    {%- set sql_statement -%}
        CAST('{{rule_code}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as {{rule_code}}_error_code,
        {{logic_rule | join(",\n")}}
    {%- endset -%}

    {%- set sql_select -%}
        {{ select_lst | join("\nUNION ALL\n") }}
    {%- endset -%}
    
    {%- set result =  {
        'sql_statement': sql_statement,
        'sql_select': sql_select
    } -%}

    {%- do return(result) -%}

{%- endmacro -%}

{# gen sql invalid rule check null #}
{%- macro invalid_registry_rule_check_null(lst_col_key, lst_col_apply, rule_info, name_table_temp, cus_type=none) -%}
    {%- set rule_code = rule_info.get('code') -%}
    {%- set logic_rule = [] -%}
    {%- set select_lst = [] -%}

    {%- for col_name in lst_col_apply -%}
        {%- set gen_logic_rule = invalid_logic_check_null(obj = col_name,
                                                         rule_code = rule_code
                                                        ) -%}
        {%- do logic_rule.append(gen_logic_rule) -%}

        {%- set select_unionall = gen_sql_select_format(
                            lst_col_key = lst_col_key,
                            _error_code = "{}_error_code".format(rule_code),
                            _error_column = "error_column_{}_{}".format(col_name, rule_code),
                            _error_value = "error_value_{}_{}".format(col_name, rule_code),
                            name_table = name_table_temp) -%}


        {%- do select_lst.append(select_unionall) -%}
    {%- endfor -%}
    
    {%- set sql_statement -%}
        CAST('{{rule_code}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as {{rule_code}}_error_code,
        {{logic_rule | join(",\n")}}
    {%- endset -%}

    {%- set sql_select -%}
        {{ select_lst | join("\nUNION ALL\n") }}
    {%- endset -%}
    
    {%- set result =  {
        'sql_statement': sql_statement,
        'sql_select': sql_select
    } -%}

    {%- do return(result) -%}
{%- endmacro -%}

{# gen sql invalid rule check structure CCCD V8 #}
{%- macro invalid_registry_rule_check_format_CCCD_corr_YOB(lst_col_key, lst_col_apply, rule_info, name_table, cus_type=none) -%}
    
    {%- set rule_code = rule_info.get('code') -%}

    {%- set lst_sql_select = [] -%}

    {%- for col_name in lst_col_apply -%}
        {%- set gen_logic_rule = invalid_logic_check_format_CCCD_corr_YOB(obj = col_name,
                                                        column_condition = rule_info.get('condition')
                                                        ) -%}
        {%- set obj_sql_select -%}
        SELECT 
            {{lst_col_key | join(", ")}},
            CAST('{{rule_code}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_code,
            CAST('{{col_name}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_column,
            cast({{col_name}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) as error_value,
            {{ktl_mdm_utils_metadata_get_ldt_statement("mdm_ldt")}}
        FROM {{ name_table }}
        WHERE 
            {{ gen_logic_rule }}
        {%- endset -%}

        {%- do lst_sql_select.append(obj_sql_select) -%}
    {%- endfor -%}

    {% set result = {
        'sql_statement': Undefined,
        'sql_select': lst_sql_select | join("\nUNION ALL\n")
    } %}
    {% do return(result) %}

{%- endmacro -%}

{# gen sql invalid rule check structure number 4 CCCD V10#}
{%- macro invalid_registry_rule_check_structure_4_CCCD(lst_col_key, lst_col_apply, rule_info, name_table, source = none, cus_type=none) -%}
    {%- set rule_code = rule_info.get('code') -%}
    {%- set lst_catalog = rule_info.get('catalog_condition') -%}
    {%- set lst_col_condition = rule_info.get('column_condition').split(":") -%}
    {%- set col_date = lst_col_condition[0] -%}
    {%- set col_gender = lst_col_condition[1] -%}

    {% set obj_join_catalog %}
        SELECT 
            lower(a.gender_value) as gender_value,
            b.start_year,
            b.end_year,
            b.personid_digi4
        FROM {{ lst_catalog[0] }} a
        LEFT JOIN {{ lst_catalog[1] }} b
        ON a.gender_code = b.gender_code
        WHERE a.source = '{{ source }}'
    {% endset %}


    {%- set lst_sql_select = [] -%}

    {%- for col_name in lst_col_apply -%}
        {%- set sql_statement -%}
            SELECT 
                {{lst_col_key | join(", ")}},
                {{col_name}},
                {{lst_col_condition | join(", ")}},
                LOWER({{col_gender}}) AS GENDER_LOWER,
                CAST(SUBSTR({{col_name}}, 4, 1) AS INT) AS DIGI4,
                CAST(EXTRACT(YEAR FROM {{col_date}}) AS INT) AS YEAR_PER
            FROM {{name_table}}
            WHERE {{col_name}} IS NOT NULL AND {{col_date}} IS NOT NULL AND {{col_gender}} IS NOT NULL
        {%- endset -%}

        {%- set obj_left_join -%}
            LEFT JOIN ({{obj_join_catalog}}) k
            ON  t.GENDER_LOWER = k.gender_value AND
                t.DIGI4 = k.personid_digi4 AND
                t.YEAR_PER BETWEEN k.start_year AND k.end_year
            WHERE gender_value IS NULL 
        {%- endset -%}

        {%- set sql_select -%}
            SELECT
                {{lst_col_key | join(", ") }},
                CAST('{{rule_code}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_code,
                CAST('{{col_name}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_column,
                cast({{col_name}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) as error_value,
                {{ktl_mdm_utils_metadata_get_ldt_statement("mdm_ldt")}}
            FROM ( {{sql_statement}} ) t
            {{obj_left_join}}
        {%- endset -%}

        {%- do lst_sql_select.append(sql_select) -%}
    {%- endfor -%}

    {% set result = {
        'sql_statement': Undefined,
        'sql_select': lst_sql_select | join("\nUNION ALL\n")
    } %}
    {% do return(result) %}
{%- endmacro -%}

{# gen sql invalid rule check the legal docs of customer S267 #}
{# gen sql invalid rule check range datetime of legal docs of customer S35#}
{%- macro invalid_registry_rule_check_legal_id_datetime_range_activate(lst_col_key, lst_col_apply, rule_info, name_table, cus_type=none) -%}
    {%- set rule_code = rule_info.get('code') -%}

    {%- set lst_sql_select = [] -%}

    {%- for col_name in lst_col_apply -%}
        {%- set gen_logic_rule = find_logic_invalid_format(obj=col_name, rule_info = rule_info) -%}
        {%- set id_col = col_name | replace('_02', '_01') -%}

        {%- set obj_first_step -%}
            SELECT 
                {{lst_col_key | join(", ")}},
                {{col_name}}, 
                {{rule_info.get('column_condition')}},
                {{gen_logic_rule}} AS {{col_name}}_ERROR 
            FROM {{name_table}} 
            WHERE {{id_col}} IS NOT NULL
        {%- endset -%}

        {%- set obj_sql_select -%}
            SELECT 
                {{lst_col_key | join(", ")}},
                cast('{{rule_code}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_code,
                cast('{{col_name}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_column,
                cast({{col_name}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) as error_value,
                {{ktl_mdm_utils_metadata_get_ldt_statement("mdm_ldt")}}
            FROM ( {{obj_first_step}} )
            WHERE {{col_name}}_ERROR = 1
        {%- endset -%}

        {%- do lst_sql_select.append(obj_sql_select) -%}
    {%- endfor -%}
    
    {%- set result = {
        'sql_statement': Undefined,
        'sql_select': lst_sql_select | join("\nUNION ALL\n")
    } -%}

    {%- do return(result) -%}
{%- endmacro -%}

{# gen sql invalid rule check length #}
{# gen sql invalid rule check range datetime of customer #}
{# gen sql invalid rule check format sdt #}
{# gen sql invalid rule check head number cccd #}
{%- macro invalid_registry_rule_check_only_where(lst_col_key, lst_col_apply, rule_info, name_table, cus_type=none) -%}
    {%- set rule_code = rule_info.get('code') -%}

    {%- set lst_sql_select = [] -%}

    {%- for col_name in lst_col_apply -%}
        {%- set gen_logic_rule = find_logic_invalid_format(obj=col_name, rule_info = rule_info) -%}
        
        {%- set obj_sql_select -%}
            SELECT 
                {{lst_col_key | join(", ")}},
                cast('{{rule_code}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_code,
                cast('{{col_name}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_column,
                cast({{col_name}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) as error_value,
                {{ktl_mdm_utils_metadata_get_ldt_statement("mdm_ldt")}}
            FROM {{name_table}}
            WHERE {{gen_logic_rule}}
        {%- endset -%}

        {%- do lst_sql_select.append(obj_sql_select) -%}
    {%- endfor -%}
    
    {%- set result = {
        'sql_statement': Undefined,
        'sql_select': lst_sql_select | join("\nUNION ALL\n")
    } -%}

    {%- do return(result) -%}
{%- endmacro -%}

{# gen sql invalid rule check invalid email #}
{# gen sql invalid rule check invalid catalog category #}
{%- macro invalid_registry_rule_check_only_left_join(lst_col_key, lst_col_apply, rule_info, name_table, source = none, cus_type=none, catalog_name = none) -%}
    {%- set rule_code = rule_info.get('code') -%}
    
    {%- set lst_sql_select = [] -%}

    {%- for col_name in lst_col_apply -%}
        {%- set gen_logic_rule = find_logic_invalid_format(obj=col_name, rule_info = rule_info, source = source, 
                                                           cus_type = cus_type, catalog_name = catalog_name) -%}
        
        {% set obj_sql_table %}
            SELECT 
                {{lst_col_key | join(", ") }}, 
                {{col_name}}
            FROM {{ name_table }}
            {% if rule_info.get('warning_null') -%}
                WHERE {{col_name}} IS NOT NULL
            {%- endif %}
        {% endset -%}
        
        {%- set obj_sql_select -%}
            SELECT 
                {{lst_col_key | join(", ")}},
                cast('{{rule_code}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_code,
                cast('{{col_name}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_column,
                cast({{col_name}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) as error_value,
                {{ktl_mdm_utils_metadata_get_ldt_statement("mdm_ldt")}}
            FROM ({{obj_sql_table}})
            {{gen_logic_rule}} {# logic left join #}
        {%- endset -%}

        {%- do lst_sql_select.append(obj_sql_select) -%}
    {%- endfor -%}
    
    {%- set result = {
        'sql_statement': Undefined,
        'sql_select': lst_sql_select | join("\nUNION ALL\n")
    } -%}

    {%- do return(result) -%}
{%- endmacro -%}


{# gen sql invalid rule check legal id and national #}
{%- macro invalid_registry_rule_check_legal_id_national(lst_col_key, lst_col_apply, rule_info, name_table, source = none) -%}
    {%- set rule_code = rule_info.get('code') -%}
    
    
    {%- set lst_condition = rule_info.get('condition').split(":") -%}
    {%- set col_PP = lst_condition[2] -%} {# get column_name passport of condition config #}

    {%- set condition_check_approve -%}
        CASE WHEN REPLACE(REPLACE(UPPER({{lst_condition | join("||")}}), '|', ''), 'NULL', '') IS NULL THEN 0 ELSE 1 END FLAG_NATION,
        CASE WHEN REPLACE(REPLACE(UPPER({{col_PP}}), '|', ''), 'NULL', '') IS NULL THEN 0 ELSE 1 END FLAG_NOT_NATION
    {%- endset -%}

    {%- set lst_sql_select = [] -%}
    
    {%- for col_name in lst_col_apply -%}
        {%- set sql_select_1 -%}
            SELECT 
                {{lst_col_key | join(", ") }},
                {{col_name}},
                {{lst_condition | join(",")}},
                {{ condition_check_approve }}
            FROM {{name_table}}
        {%- endset -%}

        {%- set obj_clause -%}
            CASE 
                WHEN ({{col_name}} = 'VN' OR {{col_name}} = 'ZZ') AND (FLAG_NATION = 1) THEN 1 
                WHEN ({{col_name}} != 'VN' OR {{col_name}} != 'ZZ') AND (FLAG_NOT_NATION = 1) THEN 1 
                ELSE 0
            END AS CHECK_VALID
        {%- endset -%}

        {%- set sql_select_2 -%}
            SELECT
                {{lst_col_key | join(", ") }},
                {{col_name}},
                {{lst_condition | join(",")}},
                {{obj_clause}}
            FROM ( {{sql_select_1}} )
        {%- endset -%}
        
        {%- set sql_select -%}
            SELECT 
                {{lst_col_key | join(", ") }},
                cast('{{rule_code}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_code,
                cast('{{col_name}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_column,
                cast({{col_name}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) as error_value,
                {{ktl_mdm_utils_metadata_get_ldt_statement("mdm_ldt")}}
            FROM ( {{sql_select_2}} )
            WHERE CHECK_VALID = 0
        {%- endset -%}

        {%- do lst_sql_select.append(sql_select) -%}
    {%- endfor -%}

    {%- set result = {
        'sql_statement': Undefined,
        'sql_select': lst_sql_select | join("\nUNION ALL\n")
    } -%}

    {% do return(result) %}
{%- endmacro -%}
{# gen sql invalid rule check PASS_NO length by LOAI_GTTT --- V4 #}
{%- macro invalid_registry_rule_check_pass_no_by_loai_gttt(lst_col_key, lst_col_apply, rule_info, name_table, cus_type=none) -%}
    {%- set rule_code = rule_info.get('code') -%}
    
    {%- set lst_sql_select = [] -%}
    
    {%- for col_name in lst_col_apply -%}
        {%- set loai_gttt_col = 'LOAI_GTTT' -%}
        
        {%- set obj_sql_select -%}
            SELECT 
                {{lst_col_key | join(", ")}},
                cast('{{rule_code}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_code,
                cast('{{col_name}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_column,
                cast({{col_name}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) as error_value,
                {{ktl_mdm_utils_metadata_get_ldt_statement("mdm_ldt")}}
            FROM {{name_table}}
            WHERE 
                ({{ loai_gttt_col }} = 'CCCD' AND LENGTH({{ col_name }}) != 12)
                OR ({{ loai_gttt_col }} = 'CMT' AND LENGTH({{ col_name }}) NOT IN (9, 12))
                OR {{ col_name }} IS NULL
                OR {{ loai_gttt_col }} IS NULL
        {%- endset -%}

        {%- do lst_sql_select.append(obj_sql_select) -%}
    {%- endfor -%}
    
    {%- set result = {
        'sql_statement': Undefined,
        'sql_select': lst_sql_select | join("\nUNION ALL\n")
    } -%}
    
    {% do return(result) %}
{%- endmacro -%}

{# gen sql invalid rule check PASS_I_DT with open date --- V7 #}
{%- macro invalid_registry_rule_check_legal_id_with_open_date(lst_col_key, lst_col_apply, rule_info, name_table, cus_type=none) -%}
    {%- set rule_code = rule_info.get('code') -%}
    {%- set d_o_b_col = rule_info.get('column_condition') -%}
    
    {%- set lst_sql_select = [] -%}
    
    {%- for col_name in lst_col_apply -%}
        {%- set obj_sql_select -%}
            SELECT 
                {{lst_col_key | join(", ")}},
                cast('{{rule_code}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_code,
                cast('{{col_name}}' as {{ktl_mdm_utils_types_string(nbyte = 255)}}) as error_column,
                cast({{col_name}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) as error_value,
                {{ktl_mdm_utils_metadata_get_ldt_statement("mdm_ldt")}}
            FROM {{name_table}}
            WHERE 
                {{ col_name }} IS NULL
                OR {{ d_o_b_col }} IS NULL
                OR {{ col_name }} < {{ d_o_b_col }}
        {%- endset -%}

        {%- do lst_sql_select.append(obj_sql_select) -%}
    {%- endfor -%}
    
    {%- set result = {
        'sql_statement': Undefined,
        'sql_select': lst_sql_select | join("\nUNION ALL\n")
    } -%}
    
    {% do return(result) %}
{%- endmacro -%}
