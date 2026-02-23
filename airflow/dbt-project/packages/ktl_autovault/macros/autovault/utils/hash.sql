{% macro hash(field, method = 'sha256') -%}
    {{ return(adapter.dispatch('hash', 'ktl_autovault') (field, method)) }}
{%- endmacro %}


{% macro spark__hash(field, method) -%}

    {%- if method == 'md5' -%}
        md5({{ field }})
    {%- elif method == 'sha1' -%}
        sha1({{ field }})
    {%- elif method == 'sha256' -%}
        sha2({{ field }}, 256)
    {%- elif method == 'sha384' -%}
        sha2({{ field }}, 384)
    {%- elif method == 'sha512' -%}
        sha2({{ field }}, 512)
    {%- endif -%}

{%- endmacro %}


{% macro oracle__hash(field, method) -%}

    STANDARD_HASH({{field}}, '{{ method.upper() }}')

{%- endmacro %}