{# cleansing rule remove character  #}
{%- macro cleansing_registry_rule_regex_pattern(table_name, lst_column_metadata, lst_column_apply, rule_info) -%}
    {%- set gen_logic= [] -%}

    {%- for col_name in lst_column_apply -%}
        {%- set obj_cls = cleansing_logic_remove_character(col_name, rule_info.get('character')) -%}
        {%- do gen_logic.append(obj_cls) -%}  
    {%- endfor -%}

    {%- set obj_gen -%}
    SELECT 
        {{lst_column_metadata | join(",\n") }},
        {{gen_logic | join(",\n") }}
    FROM {{table_name}}
    {%- endset -%}

    {{ return(obj_gen) }}
{%- endmacro -%}

{# cleansing rule remove character +84 , 84 -> 0 and replace to head_phone  #}
{%- macro cleansing_registry_rule_replace_to_head_phone(table_name, lst_column_metadata, lst_column_apply, rule_info, catalog_name = 'mdm_phone_number_prefix') -%}
    {%- set catalog_table = ktl_mdm_get_info_table_catalog(group_name=catalog_name) -%}

    {%- set _catalog  =  rule_info.get('catalog_condition') -%}

    {%- set gen_logic = [] -%}
    {%- set gen_left_join = [] -%}

    {%- for column in lst_column_apply -%}
        {%- set obj_rp_head_84 = cleansing_logic_replace_character_84(obj = column) -%}

        {%- set obj_head_phone -%}
            {{ cleansing_logic_replace_head_phone(obj = obj_rp_head_84,
                                _old_phone = catalog_table.column_old_phone, 
                                _new_phone = catalog_table.column_new_phone ) }} AS {{column}}
        {%- endset -%}

        {%- do gen_logic.append(obj_head_phone) -%}

        {%- set obj_join_catalog -%}
        LEFT JOIN {{_catalog}} catalog
        ON (LENGTH({{obj_rp_head_84}})=11
        AND (
            (SUBSTR({{obj_rp_head_84}}, 1, 3)=catalog.{{catalog_table.column_old_phone}})
            OR
            (SUBSTR({{obj_rp_head_84}}, 1, 4)=catalog.{{catalog_table.column_old_phone}})
        )
        )
        {%- endset -%}

        {%- do gen_left_join.append(obj_join_catalog) -%}
    {%- endfor -%}

    {%- set obj_gen -%}
        SELECT 
            {{lst_column_metadata | join(",\n") }},
            {{gen_logic | join(",\n") }}
        FROM {{table_name}}
        {{gen_left_join | join("\n")}}
    {%- endset -%}

    {{ return(obj_gen) }}
{%- endmacro -%}

{# cleansing rule coalesce catalog column #}
{%- macro cleansing_registry_rule_coalesce_catalog(table_name, lst_column_metadata, lst_column_apply, rule_info, source, catalog_name = 'mdm_catalog_category') -%}
    {%- set catalog_table = ktl_mdm_get_info_table_catalog(group_name=catalog_name) -%}

    {%- set _catalog_condition = rule_info.get('catalog_condition') -%}

    {%- set _count = namespace(value=0) -%}
    {%- set _coalesce = [] -%}
    {%- set _left_join = [] -%}

    {%- for column in lst_column_apply -%}
        {%- set condition_type = ktl_mdm_get_condition_for_col(column_apply = column, dict = rule_info) -%}
        {%- if condition_type is none -%}
            {%- continue -%}
        {%- endif -%}

        {%- set _count.value = _count.value + 1 -%} 
        {%- set _as = 'a'~_count.value -%}

        {%- do _coalesce.append(cleansing_logic_coalesce_catalog(obj = column, _standard_value = catalog_table.column_standard_value, _alias = _as)) -%}

        {%- set obj_left_join -%}
            LEFT JOIN {{_catalog_condition}} {{_as}} 
            ON LOWER(a.{{column}}) = LOWER({{_as}}.{{catalog_table.column_original_value}}) 
            AND {{_as}}.{{catalog_table.column_category_type}} = LOWER('{{condition_type}}') 
            AND LOWER({{_as}}.{{catalog_table.column_source}}) = LOWER('{{source}}')
        {%- endset -%}
        
        {%- do _left_join.append(obj_left_join) -%}
    {%- endfor -%}

    {%- set obj_gen -%}
        SELECT 
            {{lst_column_metadata | join(",\n") }},
            {{_coalesce | join(",\n") }}
        FROM {{table_name}} a
        {{_left_join | join("\n")}}
    {%- endset -%}

    {{ return(obj_gen) }}

{%- endmacro -%}

{# cleansing rule convert string to date with format #}
{%- macro cleansing_resigtry_rule_convert_str_to_data(table_name, lst_column_metadata, lst_column_apply, rule_info, source) -%}
    
    {%- set gen_logic = [] -%}
    
    {%- for col_name in lst_column_apply -%}
        {%- set obj_cls = cleansing_logic_convert_str_to_date(col_name, rule_info.get('from_str_format'))-%}
        {%- do gen_logic.append(obj_cls) -%} 
    {%- endfor -%}

    {%- set obj_gen -%}
    SELECT 
        {{lst_column_metadata | join(",\n") }},
        {{gen_logic | join(",\n") }}
    FROM {{table_name}}
    {%- endset -%}

    {{ return(obj_gen) }}
{%- endmacro -%}