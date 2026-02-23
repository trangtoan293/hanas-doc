{% macro prepare_hash_component(field, error_code, upper) -%}
    {%- if upper -%}
        coalesce(nullif(upper(rtrim(cast({{ field }} as {{ dbt.type_string() }}))), ''), '{{ error_code }}')
    {%- else -%}
        coalesce(nullif(rtrim(cast({{ field }} as {{ dbt.type_string() }})), ''), '{{ error_code }}')
    {%- endif -%}
{%- endmacro %}


{% macro generate_dv_hash_key(
    field_list,
    prepare = true,
    collision_code = none,
    error_code = "-1",
    upper = false,
    method = 'sha256',
    dtype = dbt.type_string()
) -%}

    {{ return(adapter.dispatch('generate_dv_hash_key', 'ktl_autovault') (field_list, prepare, collision_code, error_code, upper, method, dtype)) }}

{%- endmacro %}


{% macro default__generate_dv_hash_key(field_list, prepare, collision_code, error_code, upper, method, dtype) -%}

    {%- set fields = [] -%}

    {%- for field in field_list -%}

        {%- if prepare -%}
            {%- set field = ktl_autovault.prepare_hash_component(field, error_code, upper) -%}
        {%- endif -%}

        {%- do fields.append(field) -%}

        {%- if collision_code -%}
            {%- do fields.append("'#~!'") -%}
            {%- do fields.append("'" ~ collision_code ~ "'") -%}
        {%- endif -%}

        {%- if not loop.last %}
            {%- do fields.append("'#~!'") -%}
        {%- endif -%}

    {%- endfor -%}

    {{ ktl_autovault.hash(dbt.concat(fields), method) }}

{%- endmacro %}


{% macro spark__generate_dv_hash_key(field_list, prepare, collision_code, error_code, upper, method, dtype) -%}
    
    {%- set hashed -%}
        {{ ktl_autovault.default__generate_dv_hash_key(field_list, prepare, collision_code, error_code, upper, method, dtype) }}
    {%- endset -%}

    {%- if api.Column.translate_type(dtype) == dbt.type_string() -%}
        {{ hashed }}
    {%- elif dtype.lower() == 'binary' -%}
        cast({{ hashed }} as binary)
    {%- endif -%}

{%- endmacro %}


{% macro oracle__generate_dv_hash_key(field_list, prepare, collision_code, error_code, upper, method, dtype) -%}
    
    {%- set hashed -%}
        {{ ktl_autovault.default__generate_dv_hash_key(field_list, prepare, collision_code, error_code, upper, method, dtype) }}
    {%- endset -%}

    {%- if dtype.lower() in ['binary', 'raw'] -%}
        {{ hashed }}
    {%- else -%}
        cast({{ hashed }} as {{ api.Column.translate_type(dtype) }})
    {%- endif -%}

{%- endmacro %}
