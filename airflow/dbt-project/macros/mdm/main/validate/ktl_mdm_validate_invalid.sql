
{# invalid handle : gen all sql_statement for column apply rule invalid #}
{%- macro ktl_mdm_validate_invalid(general_conf, metadata_conf, rule_apply, table_source, product_type='INDIVIDUAL', source='COREBANK', type_mode = 'validate') -%}

    {# Metadata_config #}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}
    {%- set ldt_col =  ktl_mdm_utils_metadata_get_ldt_col(metadata_conf) -%}
    {%- set cob_col =  ktl_mdm_utils_metadata_get_cob_col(metadata_conf) -%}
    {%- set cob_value = ktl_mdm_utils_get_cob_value(general_conf) -%}

    {%- set lst_column_model = ktl_mdm_utils_metadata_get_metadata_column_lst(metadata_conf) -%}
    
    {# Main handler #}
    {%- set source_system = "CAST('"~source~"' as "~ktl_mdm_utils_types_string(nbyte = 255)~") AS SOURCE_SYSTEM" -%}
    {%- set lst_col_key = [pk_key, source_system] -%} 

    {%- set lst_invalid_gen_available = invalid_gen_rule_available(lst_col_key = lst_col_key, 
                                    rule_apply=rule_apply,
                                    lst_column_model = lst_column_model,
                                    table_source_name = table_source,
                                    cus_type = 'KHCN'
                    ) -%}

    {{
        invalid_find_combine_sql(key = pk_key, lst_invalid_gen_available = lst_invalid_gen_available, 
                                table_source = table_source
                                )
    }}
{%- endmacro -%}

{# gen rule and columna apply invalid availabe #}
{%- macro invalid_gen_rule_available(lst_col_key, rule_apply, lst_column_model, table_source_name, cus_type, product_type='INDIVIDUAL', source='COREBANK') -%}
    
    {%- set lst_sql_statement = [] -%}
    {%- set lst_sql_select = [] -%}
    {%- set lst_sql_regex_statement = [] -%}

    {%- for item in rule_apply -%}
        {%- set info_rule_invalid = selected_info_rule_invalid(rule_code= item.get('name'))-%}

        {%- if info_rule_invalid is none -%}
            {%- continue -%}
        {%- endif -%}

        {# get column apply rule available in metdata column #}
        {%- set lst_col_available = ktl_mdm_get_column_available(lst_column_model, item.get('list_column')) -%}

        {%- if lst_col_available | length != 0 -%}
            {# find rule gen available logic #}
            {%- set find_invalid = invalid_find_rule_gen(lst_col_key, lst_col_apply=lst_col_available, 
                                                         rule_info=info_rule_invalid,
                                                         name_table = table_source_name,
                                                         source = source,
                                                         cus_type = cus_type) -%}
            
            {%- if find_invalid is not none -%}
                {%- if info_rule_invalid.get('rule_template') == 'validatetp_regex_not_like' 
                    or info_rule_invalid.get('rule_template') == 'check_null'-%}

                    {%- do lst_sql_regex_statement.append(find_invalid['sql_statement']) -%}
                {%- else -%}
                    {%- if find_invalid['sql_statement'] is not undefined -%}
                        {%- do lst_sql_statement.append(find_invalid['sql_statement']) -%}
                    {%- endif -%}
                {%- endif -%}
                {%- do lst_sql_select.append(find_invalid['sql_select']) -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
    
    {%- set invalid_gen =  {
        'lst_sql_regex_statement': lst_sql_regex_statement,
        'lst_sql_statement': lst_sql_statement,
        'lst_sql_select': lst_sql_select
    } -%}

    {%- do return(invalid_gen) -%}
{%- endmacro -%}

{# combine all results sql invalid follow group by rule_dict.template #}
{%- macro invalid_find_combine_sql(key, lst_invalid_gen_available, table_source, tbl_regex = 'CTE_REGEX') -%}

    {%- set sub_sql_regex -%}
    {{tbl_regex}} AS (
        SELECT 
            {{key}},
            {{lst_invalid_gen_available['lst_sql_regex_statement'] | join(",\n") }}
        FROM {{table_source}}
    )
    {%- endset -%}

    {%- set sub_sql -%}
        {{lst_invalid_gen_available['lst_sql_statement'] | join(",\n") }}
    {%- endset -%}

    {%- set select_sql -%}
        {{lst_invalid_gen_available['lst_sql_select'] | join("\nUNION ALL\n") }}
    {%- endset -%}
    
    WITH 
        {{sub_sql_regex}} {% if sub_sql_regex and sub_sql %} ,{% endif %}
        {{sub_sql}}
        {{select_sql}}
{%- endmacro -%}

{# create list process invalid rule #}
{%- macro invalid_find_rule_gen(lst_col_key, lst_col_apply, rule_info, name_table, source = none, cus_type = none) -%}

    {%- set rule_template = rule_info.get('rule_template') -%}
    
    {%- if rule_template == 'validatetp_regex_not_like' -%}
 
        {%- set name_table_temp = 'CTE_REGEX' -%}  

        {{ return(invalid_registry_rule_regex_pattern(lst_col_key, lst_col_apply, rule_info, name_table_temp)) }}

    {%- elif rule_template == 'check_null' -%}
        
        {%- set name_table_temp = 'CTE_REGEX' -%}

        {{ return(invalid_registry_rule_check_null(lst_col_key, lst_col_apply, rule_info, name_table_temp)) }}

    {%- elif rule_template == 'validatetp_format_CCCD_corr_YOB' -%}

        {{ return(invalid_registry_rule_check_format_CCCD_corr_YOB(lst_col_key, lst_col_apply, rule_info, name_table)) }}

    {%- elif rule_template == 'check_active_datetime_legal_id' or rule_template == 'check_legal_id_range_datetime' -%}

        {{ return(invalid_registry_rule_check_legal_id_datetime_range_activate(lst_col_key, lst_col_apply, rule_info, name_table)) }}

    {%- elif rule_template == 'check_length' or rule_template == 'check_range_datetime' or rule_template == 'check_format_sdt' or rule_template == 'check_head_cccd' -%}
        
        {{ return(invalid_registry_rule_check_only_where(lst_col_key, lst_col_apply, rule_info, name_table) )}}

    {%- elif rule_template == 'validatetp_check_invalid_email' or rule_template == 'check_invalid_suffix_email'-%}

        {{ return(invalid_registry_rule_check_only_left_join(lst_col_key, lst_col_apply, rule_info, name_table, cus_type=cus_type)) }}
    
    {%- elif rule_template == 'check_invalid_category' -%}
        
        {{ return(invalid_registry_rule_check_only_left_join(lst_col_key, lst_col_apply, rule_info, name_table, source, cus_type, catalog_name = 'mdm_catalog_category') ) }}

    {%- elif rule_template == 'check_legal_id' -%}
        
        {{ return(invalid_registry_rule_check_legal_id_national(lst_col_key, lst_col_apply, rule_info, name_table)) }}
    
    {%- elif rule_template == 'validatetp_check_number_4_cccd' -%}

        {{ return(invalid_registry_rule_check_structure_4_CCCD(lst_col_key, lst_col_apply, rule_info, name_table, source = source))}}
    
    {%- elif rule_template == 'validatetp_pass_no_by_loai_gttt' -%}

        {{ return(invalid_registry_rule_check_pass_no_by_loai_gttt(lst_col_key, lst_col_apply, rule_info, name_table)) }}

    {%- elif rule_template == 'check_legal_id_range_datetime_with_open_date' -%}

        {{ return(invalid_registry_rule_check_legal_id_with_open_date(lst_col_key, lst_col_apply, rule_info, name_table)) }}
    
    {%- else -%}
        {{ return(none) }}
    {%- endif -%}
{%- endmacro -%}