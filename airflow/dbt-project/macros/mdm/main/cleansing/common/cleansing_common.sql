{# get dict information of rule cleansing #}
{%- macro selected_info_rule_cleansing(rule_code, type_mode='cleansing') -%}
    {%- set rule_info = ktl_mdm_get_info_rule(code = rule_code,
                                              rule_desc_yml = ktl_mdm_utils_get_rule_desc_config('ktlmdm') , 
                                              rule_type = type_mode
                                              )-%}
                                                  
    {%- if rule_info is not none -%}
        {%- set selected_info = {  
            'code': rule_info.get('code'),  
            'rule_template': rule_info.get('rule_template'),
            'character': rule_info.get('character'),
            'catalog_condition': rule_info.get('catalog_condition'),
            'column_condition': rule_info.get('column_condition'),
            'from_str_format': rule_info.get('from_str_format')
        } -%}  

        {{ return(selected_info) }}
    {%- endif -%}

    {{ return(none) }}
{%- endmacro -%}


{# reject list column model and list column using rule#}
{%- macro reject_column(lst_col_metadata, lst_col_apply) -%}
    {%- set difference = lst_col_metadata | reject('in', lst_col_apply) -%}

    {{return(difference | list) }}
{%- endmacro -%}