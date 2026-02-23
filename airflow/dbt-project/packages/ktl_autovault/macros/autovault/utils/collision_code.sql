{% macro render_collision_code_treatment(model, ghost_record = false) -%}
    {{ return(adapter.dispatch('render_collision_code_treatment', 'ktl_autovault') (model, ghost_record)) }}
{%- endmacro %}


{% macro spark__render_collision_code_treatment(model, ghost_record) -%}

    {%- if ghost_record -%}
        {%- set column = fromyaml("dtype: string") -%}
        {{ ktl_autovault.render_ghost_record(column) }} as {{ ktl_autovault.render_collision_code_name() }}
    
    {%- else -%}
        {{ "'" + model.get('collision_code') + "'" }} as {{ ktl_autovault.render_collision_code_name() }}

    {%- endif -%}

{%- endmacro %}


{% macro oracle__render_collision_code_treatment(model, ghost_record) -%}

    {%- if ghost_record -%}
        {%- set column = fromyaml("dtype: varchar2(32)") -%}
        {{ ktl_autovault.render_ghost_record(column) }} as {{ ktl_autovault.render_collision_code_name() }}
    
    {%- else -%}
        cast({{ "'" + model.get('collision_code') + "'" }} as varchar2(32)) as {{ ktl_autovault.render_collision_code_name() }}

    {%- endif -%}

{%- endmacro %}
