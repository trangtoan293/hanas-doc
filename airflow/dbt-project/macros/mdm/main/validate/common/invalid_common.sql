{# get dict information of rule invalid #}
{%- macro selected_info_rule_invalid(rule_code, type_mode='validate') -%}
    {%- set rule_info = ktl_mdm_get_info_rule(code = rule_code,
                                              rule_desc_yml = ktl_mdm_utils_get_rule_desc_config('ktlmdm') , 
                                              rule_type = type_mode
                                              )-%}
                                                  
    {%- if rule_info is not none -%}
        {%- set selected_info = {  
            'code': rule_info.get('code'),  
            'rule_template': rule_info.get('rule_template'),
            'regex_pattern': rule_info.get('regex_pattern'),
            'catalog_condition': rule_info.get('catalog_condition'),
            'catalog_column': rule_info.get('catalog_column'),
            'column_condition': rule_info.get('column_condition'),
            'condition': rule_info.get('condition'),
            'warning_null': rule_info.get('warning_null')
        } -%}  

        {{ return(selected_info) }}
    {%- endif -%}

    {{ return(none) }}
{%- endmacro -%}

{# create format sql_select with invalid rule using sql_statement #}
{%- macro gen_sql_select_format(lst_col_key, _error_code, _error_column, _error_value, name_table) -%}
    SELECT 
        {{ lst_col_key | join(", ") }},
        {{_error_code}} AS error_code,
        cast({{_error_column}} as {{ktl_mdm_utils_types_string(nbyte = 255)}}) AS error_column,
        cast({{_error_value}} as {{ktl_mdm_utils_types_string(nbyte = 2000)}}) AS error_value,
        {{ktl_mdm_utils_metadata_get_ldt_statement("mdm_ldt")}}
    FROM {{name_table}}
    WHERE {{_error_column}} IS NOT NULL
{%- endmacro -%}

{# find logic rule invalid alike format #}
{%- macro find_logic_invalid_format(obj, rule_info, source = none, cus_type = none, catalog_name = none) -%}

    {%- if rule_info.get('rule_template') == 'check_active_datetime_legal_id' -%}
        {{ 
            return(invalid_logic_check_active_datetime_legal_id(obj= obj, 
                                    col_condition = rule_info.get('column_condition'),
                                    condition = rule_info.get('condition')
            )) 
        }}
    {%- elif rule_info.get('rule_template') == 'check_legal_id_range_datetime' -%}
        {{
            return(invalid_logic_check_range_datetime_legal_id(obj=obj, col_condition=rule_info.get('column_condition')))
        }}
    
    {%- elif rule_info.get('rule_template') == 'check_length' -%}
        {{
            return(invalid_logic_check_length(obj = obj , condition = rule_info.get('condition'), warning_null = rule_info.get('warning_null')))
        }}
    
    {%- elif rule_info.get('rule_template') == 'check_range_datetime' -%}
        {{
            return(invalid_logic_check_range_datetime(obj = obj, condition = rule_info.get('condition'), warning_null = rule_info.get('warning_null')))
        }}

    {%- elif rule_info.get('rule_template') == 'validatetp_check_invalid_email' -%}
        {{
            return(invalid_logic_check_email(obj = obj, catalog_condition = rule_info.get('catalog_condition'), catalog_column = rule_info.get('catalog_column'), cus_type=cus_type, warning_null=rule_info.get('warning_null')))
        }}

    {%- elif rule_info.get('rule_template') == 'check_invalid_suffix_email' -%}
        {{
           return(invalid_logic_check_suffix_email(obj = obj, catalog_condition = rule_info.get('catalog_condition'), catalog_column = rule_info.get('catalog_column'), cus_type=cus_type, warning_null=rule_info.get('warning_null'))) 
        }}
    {%- elif rule_info.get('rule_template') == 'check_invalid_category' -%}
        {# get category type using for catalog rule #}
        {%- set category_type = ktl_mdm_get_condition_for_col(column_apply = obj, dict = rule_info) -%} 
        {# get config table catalog #}
        {%- set catalog_config = ktl_mdm_get_info_table_catalog(group_name=catalog_name)-%}
        
        {{
            return(invalid_logic_check_catalog_category(obj = obj, catalog_condition = rule_info.get('catalog_condition'), catalog_config = catalog_config, source = source, catagory_type = category_type) )
        }}
        
    {%- elif rule_info.get('rule_template') == 'check_format_sdt' -%}
        
        {{
            return(invalid_logic_check_format_sdt(obj=obj, condition=rule_info.get('condition'), warning_null=rule_info.get('warning_null')) )
        }}

    {%- elif rule_info.get('rule_template') == 'check_head_cccd' -%}    
        {{
            return(invalid_logic_check_head_number_cccd(obj=obj, catalog_condition=rule_info.get('catalog_condition'), catalog_column= rule_info.get('catalog_column'), warning_null=rule_info.get('warning_null')) )
        }}
    {%- else -%}
        {{ return(none) }}
    {%- endif -%}
{%- endmacro -%}

{# dispath config calculate range time in diff system oracle --- spark #}
{%- macro ktl_mdm_utils_calculate_date(ncolumn) -%}
    {{ return(adapter.dispatch('ktl_mdm_utils_calculate_date')(ncolumn)) }}
{%- endmacro -%}

{%- macro oracle__ktl_mdm_utils_calculate_date(ncolumn) -%}
    {{ return("(SYSDATE - "~ncolumn~")") }}
{%- endmacro -%}

{%- macro spark__ktl_mdm_utils_calculate_date(ncolumn) -%}
    {{ return("DATEDIFF(CURRENT_DATE, "~ncolumn~")") }}
{%- endmacro -%}
