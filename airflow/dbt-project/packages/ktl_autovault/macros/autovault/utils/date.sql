{% macro date(string) -%}
    {%- if 'select' in string.lower() -%}
        ({{ string }})
    {%- else -%}
        {{ return(adapter.dispatch('date', 'ktl_autovault') (string)) }}
    {%- endif -%}
{%- endmacro %}


{% macro default__date(string) -%}
    {% do exceptions.raise_not_implemented(
        'date macro not implemented for adapter ' + adapter.type()
    ) %}
{%- endmacro %}


{% macro spark__date(string) -%}
    date'{{ string }}'
{%- endmacro %}


{% macro oracle__date(string) -%}
    to_date('{{ string }}', 'yyyy-mm-dd')
{%- endmacro %}


{% macro to_date(expr, format=none) -%}
    {{ return(adapter.dispatch('to_date', 'ktl_autovault') (expr, format)) }}
{%- endmacro %}


{% macro default__to_date(expr, format) -%}
    {% do exceptions.raise_not_implemented(
        'to_date macro not implemented for adapter ' + adapter.type()
    ) %}
{%- endmacro %}


{% macro spark__to_date(expr, format) -%}
    to_date({{ expr }}, '{{ format if format else "yyyy-MM-dd" }}')
{%- endmacro %}


{% macro oracle__to_date(expr, format) -%}
    to_date({{ expr }}, '{{ format if format else "yyyy-mm-dd" }}')
{%- endmacro %}
