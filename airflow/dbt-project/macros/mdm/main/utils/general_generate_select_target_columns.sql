{%- macro generate_select_target_columns_clause(model, table_symbol_with_dot, num_tab) -%}
    {%- set tab_str = "\t" * num_tab -%}
    {%- set result_lst = [] -%}

    {%- for column in model.get('columns') -%}
        {%- set column_name = column.get('target') -%}
        {%- do result_lst.append(table_symbol_with_dot~column_name) -%}

        {% if column.get('extend_columns') is not none %}
            {% if column.get('extend_columns').get('change_date') is not none %}
                {%- set cdt_column = column.get("extend_columns").get("change_date") -%}
                {%- do result_lst.append(table_symbol_with_dot~cdt_column) -%}
            {% endif %}
        {% endif %}
    {%- endfor -%}
    
    {%- set result_clause = result_lst|join(",\n"~tab_str) -%}
    {{return (result_clause)}}
{%- endmacro -%}

{%- macro generate_select_err_cnt_columns_clause(model, table_symbol_with_dot, num_tab) -%}
    {%- set tab_str = "\t" * num_tab -%}
    {%- set result_lst = [] -%}

    {%- for column in model.get('columns') -%}
        {%- if  column.get('extend_columns') is not none -%}
            {%- if  column.get('extend_columns').get('error_count') is not none -%}
                {%- set err_cnt_column = column.get('extend_columns').get('error_count') -%}
                {%- do result_lst.append(table_symbol_with_dot~err_cnt_column) -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
    
    {%- set result_clause = result_lst|join(",\n"~tab_str) -%}
    {{return (result_clause)}}
{%- endmacro -%}

