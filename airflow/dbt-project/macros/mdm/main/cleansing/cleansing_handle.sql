{# cleansing handle : gen all sql_statement for column apply rule cleansing #}
{%- macro cleansing_handle(lst_column_model, rule_apply, table_source, product_type='INDIVIDUAL', system='COREBANK', type_mode = 'cleansing') -%}

    {%- set lst_sql_statement = [] -%}

    {%- set _count = namespace(value=0) -%}

    {%- for item in rule_apply -%}

        {%- set info_rule_cleansing = selected_info_rule_cleansing(rule_code= item.get('name'))-%}

        {%- set lst_col_not_rule = reject_column(lst_column_model, item.get('list_column')) -%}

        {%- set lst_col_vailable = ktl_mdm_get_column_available(lst_column_model, item.get('list_column')) -%}

        {%- set tbl_name = 'TBL{}'.format(_count.value) -%}

        {%- if _count.value == 0 -%}
            {%- set obj_sql_statement -%} 
                TBL0 AS ({{ cleansing_find_rule(system = system,
                                                rule_info = info_rule_cleansing,
                                                lst_column_metadata = lst_col_not_rule,
                                                lst_column_apply = lst_col_vailable,
                                                table_name = table_source) }})
            {%- endset -%}
        {%- else -%}
            {%- set obj_sql_statement -%}
                {{tbl_name}} AS ({{ cleansing_find_rule(system = system,
                                                        rule_info = info_rule_cleansing,
                                                        lst_column_metadata = lst_col_not_rule,
                                                        lst_column_apply = lst_col_vailable,
                                                        table_name = 'TBL{}'.format(_count.value - 1) ) }})
            {%- endset -%}
        {%- endif -%}    

        {%- do lst_sql_statement.append(obj_sql_statement) -%}
        {%- set _count.value = _count.value + 1 -%}
    {%- endfor -%}

    {{cleansing_gen_sql_format(lst_column_model = lst_column_model,
                                lst_sql_statement = lst_sql_statement,
                                table_finish = 'TBL{}'.format(_count.value - 1),
                              _table = 'CLEANSING') }}
{%- endmacro -%}

{# format sql statement after gen logic #}
{%- macro cleansing_gen_sql_format(lst_column_model, lst_sql_statement, table_finish, _table) -%}
    {%- if lst_sql_statement | length == 0 -%}
        SELECT
        {{ lst_column_model | join(",\n")}}
        FROM {{_table}}
    {%- else-%}
        WITH 
            {{ lst_sql_statement | join(",\n") }}
        SELECT
            {{ lst_column_model | join(",\n") }}
        FROM {{table_finish}}
    {%- endif -%}
{%- endmacro -%}

{# find cleansing rule #}
{%- macro cleansing_find_rule(system, rule_info, lst_column_metadata, lst_column_apply, table_name) -%}
    {%- set rule_template = rule_info.get('rule_template') -%}

    {%- if rule_template == 'cleantp_remove_pattern' -%}
        {{ return(cleansing_registry_rule_regex_pattern(table_name, lst_column_metadata, lst_column_apply, rule_info)) }}
    {%- elif rule_template == 'cleantp_replace_head_phone' -%}
        {{ return(cleansing_registry_rule_replace_to_head_phone(table_name, lst_column_metadata, lst_column_apply, rule_info)) }}
    {%- elif rule_template == 'cleantp_replace_category' -%}
        {{ return(cleansing_registry_rule_coalesce_catalog(table_name, lst_column_metadata, lst_column_apply, rule_info, system)) }}
    {%- elif rule_template == 'cleantp_format_datetime' -%}
        {{ return(cleansing_resigtry_rule_convert_str_to_data(table_name, lst_column_metadata, lst_column_apply, rule_info, source)) }}
    {%- else -%}
        {{ return(none) }}
    {%- endif -%}
{%- endmacro -%}
