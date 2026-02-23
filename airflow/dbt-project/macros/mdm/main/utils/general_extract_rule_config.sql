{# {%- macro get_dict_from_rule_group_config(p_group_name, p_rule_type,p_rule_code) -%}

    {% for group in var('mdm_system').get('rule_group') %}
        {% if group.name == p_group_name %}
            {% for dict in group.get(p_rule_type) %}
                {% if dict.code == p_rule_code %}
                    {{ return(dict) }}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endfor %}
    
    {{exceptions.raise_compiler_error("MDMError: Rule Validate '" ~ p_rule_code ~ "' not found in Group '" ~ p_group_name ~"'")}}

{% endmacro %} #}



{%- macro get_target_name_rule_model(model, name_rule_type, code_rule) -%}

    {%- set column_rule = [] -%}
    {%- set column_select = [] -%}

    {%- for column in model.get('columns') -%}
        {%- set objs =  [column.get('source').get('name')] -%}

        {%- if column.get(name_rule_type) is not none and code_rule in column.get(name_rule_type)-%}
            {%- if code_rule == 'CL3' -%}
                {%- set pair = column.get('target') -%}
                {%- do column_rule.append(pair) -%}
            {% else %}
                {%- do column_rule.append(column.get('target')) -%}
            {% endif %} 
        {%- else -%}
            {%- do column_select.append(column.get('target')) -%}
        {% endif %}
        
        {%- if column.get('extend_columns') is not none -%}
            {%- set column_cdt = column.get('extend_columns').get('change_date') -%}
            {%- do column_select.append(column_cdt + ' AS ' + column_cdt) -%}
        {%- endif -%}
            
    {% endfor %}

    {{ return((column_rule, column_select)) }}

{% endmacro %}


{%- macro get_value_group(group_name, name_type) -%}
    {% for group in var(name_type).get('rule_group') %}
        {% if group.name == group_name %}
           {{ return(group) }}
        {% endif %}
    {% endfor %}
    
    {{exceptions.raise_compiler_error("MDMError:  Not found in Group '" ~ p_group_name ~"'")}}

{% endmacro %}

{%- macro get_dict_from_rule_group(p_group_name, p_rule_type,p_rule_code) -%}

    {% for group in var("mdm_system").get('rule_group') %}
        {% if group.name == p_group_name %}
            {% for dict in group.get(p_rule_type) %}
                {% if dict.code == p_rule_code %}
                    {{ return(dict) }}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endfor %}
    
    {{exceptions.raise_compiler_error("MDMError: Rule Validate '" ~ p_rule_code ~ "' not found in Group '" ~ p_group_name ~"'")}}

{% endmacro %}


{%- macro check_valid_column_for_rule(model, code, type_rule) -%}
    {%- set column_clause_lst = [] -%}
    {%- for column in model.get('columns') -%}
        {%- if column.get(type_rule) is not none and code in column.get(type_rule) -%}
            {%- do column_clause_lst.append(obj_clause) -%}
        {%- endif -%}
    {%- endfor -%}
    {{column_clause_lst | length }}
    
{%- endmacro -%}

{%- macro get_condition_col_for_rule(model, name_column, code_rule, name_rule_type, name_condition)-%}
    {%- set condition_col = [] -%}
    {% for column in model.get('columns') %}
        {%- set objs =  column.get('source').get('name') -%} 
        {% if column.get(name_rule_type) is not none and code_rule in column.get(name_rule_type) and objs == name_column %}
            {%- set get_name = code_rule + '_condition' -%}
            {{ column.get(get_name).get(name_condition) }}
            {% break %}
        {% endif %}
    {% endfor %}
{% endmacro %}


{%- macro get_condition_for_col(column_apply, dict)-%}

    {% set list_condition = dict.get('column_condition').split(",") %}

    {% for ele_col in list_condition %}
        {% if column_apply in ele_col %}
            {% set condition_for_col = ele_col.split(":")%}
            {% do return(condition_for_col[1]) %}
            {% break %}
        {% endif%}
    {% endfor %}
{%- endmacro -%}