{%- macro get_pkey_from_model(model) -%}
    {%- for column in model.get('columns') -%}
        {% if column.get('key_type') == 'primary_key' %}
            {{ return(column.get('target')) }}
        {%- endif -%}
    {%- endfor -%}
{% endmacro %}