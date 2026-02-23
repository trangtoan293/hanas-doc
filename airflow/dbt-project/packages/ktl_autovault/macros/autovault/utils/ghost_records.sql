{% macro render_ghost_record(column) -%}
  {{ return(adapter.dispatch('render_ghost_record', 'ktl_autovault') (column)) }}
{%- endmacro %}


{% macro spark__render_ghost_record(column) -%}

    {%- set key_type = column.get('key_type', '') -%}

    {%- if key_type[:9] == "hash_key_" or key_type == "hash_diff" -%}

        {%- set method = var('dv_hash_method', "sha256") -%}
        {%- set dtype = api.Column.translate_type(column.get('dtype', var('dv_hash_key_dtype', "string"))) -%}

        {%- if method == 'md5' -%}
            {%- set length = 32 -%}
        {%- elif method == 'sha1' -%}
            {%- set length = 40 -%}
        {%- elif method == 'sha256' -%}
            {%- set length = 64 -%}
        {%- elif method == 'sha384' -%}
            {%- set length = 96 -%}
        {%- elif method == 'sha512' -%}
            {%- set length = 128 -%}
        {%- endif -%}

        {%- if dtype == 'string' -%}
            repeat('0', {{ length }})
        {%- else -%}
            cast(repeat('0', {{ length }}) as {{ dtype }})
        {%- endif -%}
    
    {%- else -%}
        {%- set dtype = api.Column.translate_type(column.get('dtype')) -%}
        
        {%- if dtype == 'string' -%}
            '0'
        {%- elif dtype == 'binary' -%}
            X'0'
        {%- elif dtype == 'boolean' -%}
            false
        {%- elif dtype == 'date' -%}
            date'1900-01-01'
        {%- elif dtype == 'timestamp' -%}
            timestamp'1900-01-01 00:00:00'
        {%- else -%}
            cast(0 as {{ dtype }})
        {%- endif -%}
    
    {%- endif -%}

{%- endmacro %}


{% macro oracle__render_ghost_record(column) -%}

    {%- set key_type = column.get('key_type', '') -%}

    {%- if key_type[:9] == "hash_key_" or key_type == "hash_diff" -%}
        
        {%- set method = var('dv_hash_method', "sha256") -%}
        {%- set dtype = api.Column.translate_type(column.get('dtype', var('dv_hash_key_dtype', "string"))) -%}

        {%- if method == 'md5' -%}
            {%- set length = 32 -%}
        {%- elif method == 'sha1' -%}
            {%- set length = 40 -%}
        {%- elif method == 'sha256' -%}
            {%- set length = 64 -%}
        {%- elif method == 'sha384' -%}
            {%- set length = 96 -%}
        {%- elif method == 'sha512' -%}
            {%- set length = 128 -%}
        {%- endif -%}

        {%- if dtype in ['binary', 'raw'] -%}
            cast(rpad('0', {{ length }}, '0') as raw({{ length//2 }}))
        {%- else -%}
            cast(rpad('0', {{ length }}, '0') as {{ dtype }})
        {%- endif -%}
    
    {%- else -%}
        {%- set dtype = api.Column.translate_type(column.get('dtype')).lower() -%}

        {%- if 'char' in dtype or dtype[:3] == 'raw' -%}
            cast('0' as {{ dtype }})
        {%- elif dtype == 'date' -%}
            date'1900-01-01'
        {%- elif dtype == 'timestamp' -%}
            timestamp'1900-01-01 00:00:00'
        {%- else -%}
            cast(0 as {{ dtype }})
        {%- endif -%}
    
    {%- endif -%}

{%- endmacro %}
