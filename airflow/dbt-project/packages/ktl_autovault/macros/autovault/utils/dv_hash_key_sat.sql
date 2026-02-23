{% macro render_hash_key_sat_treatment(model, dv_system, ghost_record = false) -%}

    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_sat") | first -%}
    
    {%- if ghost_record -%}
        {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
    
    {%- else -%}
        {%- set field_list = [] -%}

        {# hash key hub components, uppercase #}
        {%- for field in ktl_autovault.render_list_hash_key_hub_component(model) -%}
            {%- do field_list.append(ktl_autovault.prepare_hash_component(field, error_code = "-1", upper = true)) -%}
        {%- endfor -%}

        {%- do field_list.append("'" ~ model.get('collision_code') ~ "'") -%}
        
        {# dependent keys, no uppercase #}
        {%- for field in ktl_autovault.render_list_source_dependent_key_name(model) -%}
            {%- do field_list.append(ktl_autovault.prepare_hash_component(field, error_code = "-1", upper = false)) -%}
        {%- endfor -%}

        {# system time keys, no uppercase #}
        {%- for field in ktl_autovault.render_list_source_ldt_key_name(dv_system) -%}
            {%- do field_list.append(ktl_autovault.prepare_hash_component(field, error_code = "-1", upper = false)) -%}
        {%- endfor -%}
        

        {{ ktl_autovault.generate_dv_hash_key(
            field_list = field_list,
            prepare = false,
            method = var('dv_hash_method', "sha256"),
            dtype = column.get('dtype', var('dv_hash_key_dtype', "string"))
        )
        }} as {{ column.get('target') }}

    {%- endif -%}

{%- endmacro %}


{% macro render_hash_key_lsat_treatment(model, dv_system, ghost_record = false) -%}

    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_sat") | first -%}
    
    {%- if ghost_record -%}
        {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
    
    {%- else -%}
        {%- set field_list = [] -%}

        {# hash key lnk components, uppercase #}
        {%- for field in ktl_autovault.render_list_hash_key_lnk_component(model) -%}
            {%- do field_list.append(ktl_autovault.prepare_hash_component(field, error_code = "-1", upper = true)) -%}
        {%- endfor -%}

        {%- do field_list.append("'" ~ model.get('collision_code') ~ "'") -%}
        
        {# dependent keys, no uppercase #}
        {%- for field in ktl_autovault.render_list_source_dependent_key_name(model) -%}
            {%- do field_list.append(ktl_autovault.prepare_hash_component(field, error_code = "-1", upper = false)) -%}
        {%- endfor -%}

        {# system time keys, no uppercase #}
        {%- for field in ktl_autovault.render_list_source_ldt_key_name(dv_system) -%}
            {%- do field_list.append(ktl_autovault.prepare_hash_component(field, error_code = "-1", upper = false)) -%}
        {%- endfor -%}
        

        {{ ktl_autovault.generate_dv_hash_key(
            field_list = field_list,
            prepare = false,
            method = var('dv_hash_method', "sha256"),
            dtype = column.get('dtype', var('dv_hash_key_dtype', "string"))
        )
        }} as {{ column.get('target') }}

    {%- endif -%}
    
{%- endmacro %}
