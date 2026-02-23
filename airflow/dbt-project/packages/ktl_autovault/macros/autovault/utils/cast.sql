{% macro cast(expr, from_dtype, to_dtype, format=none) -%}

    {%- if api.Column.translate_type(from_dtype) == api.Column.translate_type(to_dtype) -%}
        {{ expr }}
    {%- else -%}

        {%- if to_dtype.lower() == "timestamp" and (api.Column.translate_type(from_dtype) == dbt.type_string() or format) -%}
            {{ ktl_autovault.to_timestamp(expr, format) }}
        {%- elif to_dtype.lower() == "date" and (api.Column.translate_type(from_dtype) == dbt.type_string() or format) -%}
            {{ ktl_autovault.to_date(expr, format) }}
        {%- else -%}
            cast({{ expr }} as {{ api.Column.translate_type(to_dtype) }})
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}