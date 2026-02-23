{% macro render_hash_diff_treatment(model, ghost_record = false) -%}
    
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_diff") | first -%}

    {%- if ghost_record -%}
        {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
    
    {%- else -%}
    
        {%- set field_list = [] -%}

        {# all attributes except dv hash keys and dependent keys, no uppercase #}
        {%- for column in model.get('columns') | selectattr("key_type", "undefined") | list -%}
            {%- do field_list.append(column.get('source').get('name')) -%}
        {%- endfor -%}

        {{ ktl_autovault.generate_dv_hash_key(
            field_list = field_list,
            error_code = "0"*16,
            upper = false,
            method = var('dv_hash_method', "sha256"),
            dtype = column.get('dtype', var('dv_hash_key_dtype', "string"))
        )    
        }} as {{ column.get('target') }}
    
    {%- endif -%}

{%- endmacro %}
