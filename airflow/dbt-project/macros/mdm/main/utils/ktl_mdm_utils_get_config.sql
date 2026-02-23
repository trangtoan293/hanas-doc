{# By Project name #}

{%- macro ktl_mdm_utils_get_rule_desc_config(project_name) -%}
    {{ return(context[project_name|lower+'_rule_desc_config_yml']()) }}
{%- endmacro -%}

{%- macro ktl_mdm_utils_get_rule_template_config(project_name) -%}
    {{ return(context[project_name|lower+'_rule_template_config_yml']()) }}
{%- endmacro -%}


{# get condition for column apply rule CL3 #}
{%- macro ktl_mdm_get_condition_for_col(column_apply, dict)-%}
    {%- set column_condition = dict.get('column_condition') -%}
    {%- if column_condition is none -%}
        {{ return(none) }}
    {%- endif -%}
    {%- set list_condition = column_condition.split(",") -%}
    {%- for ele_col in list_condition -%}
        {%- if column_apply in ele_col -%}
            {%- set condition_for_col = ele_col.split(":") -%}
            {%- do return(condition_for_col[1]) -%}
            {%- break -%}
        {%- endif -%}
    {%- endfor -%}
{%- endmacro -%}

{# get info table catalog #}
{%- macro ktl_mdm_get_info_table_catalog(group_name, name_type ='catalog_table') -%}
    {% for group in var(name_type).get('ref_group') %}
        {% if group.name == group_name %}
           {{ return(group) }}
        {% endif %}
    {% endfor %}
    
    {{exceptions.raise_compiler_error("MDMError:  Not found in Group '" ~ p_group_name ~"'")}}

{% endmacro %}

{# gen info rule from ktl_mdm_rule_desc_yml #}
{%- macro ktl_mdm_gen_lst_rule(rule_desc_yml, rule_type) -%}
    {%- set lst_rule = [] -%}
    {%- for _rule in rule_desc_yml[rule_type] -%}
        {%- do lst_rule.append(_rule['code']) -%}
    {%- endfor -%}
    {{ return(lst_rule) }}
{%- endmacro -%}

{# get info rule config #}
{%- macro ktl_mdm_get_info_rule(code ,rule_desc_yml, rule_type) -%}
    {%- for _rule in rule_desc_yml[rule_type] -%}
        {%- if _rule['code'] == code -%}
            {{return(_rule)}}
        {%- endif -%}
    {%- endfor -%}
    {{return(none)}}
{%- endmacro -%}