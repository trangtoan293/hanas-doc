{% macro timestamp(string) -%}
    {%- if 'select' in string.lower() -%}
        ({{ string }})
    {%- else -%}
        {{ return(adapter.dispatch('timestamp', 'ktl_autovault') (string)) }}
    {%- endif -%}
{%- endmacro %}


{% macro default__timestamp(string) -%}
    {% do exceptions.raise_not_implemented(
        'timestamp macro not implemented for adapter ' + adapter.type()
    ) %}
{%- endmacro %}


{% macro spark__timestamp(string) -%}
    timestamp'{{ string }}'
{%- endmacro %}


{% macro oracle__timestamp(string) -%}
    to_timestamp('{{ string }}', 'yyyy-mm-dd hh24:mi:ss.FF')
{%- endmacro %}


{% macro to_timestamp(expr, format=none) -%}
    {{ return(adapter.dispatch('to_timestamp', 'ktl_autovault') (expr, format)) }}
{%- endmacro %}


{% macro default__to_timestamp(expr, format) -%}
    {% do exceptions.raise_not_implemented(
        'to_timestamp macro not implemented for adapter ' + adapter.type()
    ) %}
{%- endmacro %}


{% macro spark__to_timestamp(expr, format) -%}
    to_timestamp({{ expr }}, '{{ format if format else "yyyy-MM-dd HH:mm:ss.SSS" }}')
{%- endmacro %}


{% macro oracle__to_timestamp(expr, format) -%}
    to_timestamp({{ expr }}, '{{ format if format else "yyyy-mm-dd hh24:mi:ss.FF" }}')
{%- endmacro %}
