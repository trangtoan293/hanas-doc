{% macro render_hash_key_hub_treatment(model, ghost_record = false) -%}
    
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_hub") | first -%}

    {%- if ghost_record -%}
        {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
    
    {%- else -%}
        {{ ktl_autovault.generate_dv_hash_key(
            field_list = column.get('source'),
            collision_code = model.get('collision_code'),
            error_code = "-1",
            upper = true,
            method = var('dv_hash_method', "sha256"),
            dtype = column.get('dtype', var('dv_hash_key_dtype', "string"))
        )    
        }} as {{ column.get('target') }}
    
    {%- endif -%}

{%- endmacro %}


{% macro render_hash_key_drv_treatment(model, ghost_record = false) -%}
    
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_drv") | first -%}

    {%- if ghost_record -%}
        {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
    
    {%- else -%}
        {{ ktl_autovault.generate_dv_hash_key(
            field_list = column.get('source'),
            collision_code = model.get('collision_code'),
            error_code = "-1",
            upper = true,
            method = var('dv_hash_method', "sha256"),
            dtype = column.get('dtype', var('dv_hash_key_dtype', "string"))
        )    
        }} as {{ column.get('target') }}

    {%- endif -%}

{%- endmacro %}


{% macro render_list_hash_key_hub_treatment(model, ghost_record = false) -%}
    
    {%- set outs = [] -%}

    {%- for column in model.get('columns') -%}
        {%- if column.get('key_type') in ("hash_key_hub", "hash_key_drv") -%}

            {%- set tmp -%}
                
                {%- if ghost_record -%}
                    {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
                
                {%- else -%}
                    {{ ktl_autovault.generate_dv_hash_key(
                        field_list = column.get('source'),
                        collision_code = model.get('collision_code'),
                        error_code = "-1",
                        upper = true,
                        method = var('dv_hash_method', "sha256"),
                        dtype = column.get('dtype', var('dv_hash_key_dtype', "string"))
                    )    
                    }} as {{ column.get('target') }}

                {%- endif -%}
            
            {%- endset -%}

            {% do outs.append(tmp) %}

        {%- endif -%}
    {%- endfor -%}

    {{ return(outs) }}
    
{%- endmacro %}
