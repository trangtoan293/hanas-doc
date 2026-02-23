
{% macro pit_lnk_transform(lnk_model, lsat_models, dv_system, time_dimension) -%}
    
    {%- set hkey_lnk_name = ktl_autovault.render_hash_key_lnk_name(lnk_model) -%}
    {%- set dv_loadts = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system)[0] -%}

    with
    {% if not time_dimension -%}

        time_dim as (
        {%- for lsat_model in lsat_models %}

            {% set lsat_hkey_lnk = ktl_autovault.render_hash_key_lnk_name(lsat_model) -%}
            
            select
                {{ lsat_hkey_lnk }} {%- if lsat_hkey_lnk != hkey_lnk_name %} as {{ hkey_lnk_name }} {%- endif %},
                {{ dv_loadts }} as snapshot_ts
            from
                {{ ktl_autovault.render_target_table_name(lsat_model) }}
            {% if not loop.last -%} union {%- endif %}
        
        {%- endfor %}
        ),

    {%- endif %}

    {%- for lsat_model in lsat_models %}

        {% set lsat_alias = lsat_model.get('target_table') -%}
        {%- set lsat_hkey_lnk = ktl_autovault.render_hash_key_lnk_name(lsat_model) -%}
        
        {{ lsat_alias }} as (

            select
                {{ ktl_autovault.render_hash_key_lsat_name(lsat_model) }},
                {{ lsat_hkey_lnk }} {%- if lsat_hkey_lnk != hkey_lnk_name %} as {{ hkey_lnk_name }} {%- endif %},
                {{ dv_loadts }},
                lead({{ dv_loadts }}, 1, '9999-12-31') over (
                    partition by {{ lsat_hkey_lnk }}
                    order by {{ dv_loadts }} asc
                ) as {{ dv_loadts }}_end
            from
                {{ ktl_autovault.render_target_table_name(lsat_model) }}
                
        )
        {%- if not loop.last -%} , {%- endif %}

    {%- endfor %}

    select
        lnk.{{ hkey_lnk_name }},
        cast(time_dim.snapshot_ts as timestamp) as snapshot_ts,
        
        {%- for lsat_model in lsat_models %}

            {% set lsat_alias = lsat_model.get('target_table') -%}
            {%- set hkey_lsat_name = ktl_autovault.render_hash_key_lsat_name(lsat_model) -%}
            {%- set hkey_lsat_column = lsat_model.get('columns') | selectattr("key_type", "equalto", "hash_key_sat") | first -%}
            
            coalesce({{ lsat_alias }}.{{ hkey_lsat_name }}, {{ ktl_autovault.render_ghost_record(hkey_lsat_column) }}) as {{ hkey_lsat_name }}
            {%- if not loop.last -%} , {%- endif %}
        
        {%- endfor %}

    from
        {{ ktl_autovault.render_target_table_name(lnk_model) }} lnk
        {% if not time_dimension -%}
            join time_dim on lnk.{{ hkey_lnk_name }} = time_dim.{{ hkey_lnk_name }}
        {% else -%}
            join {{ time_dimension }} time_dim on time_dim.snapshot_ts >= lnk.{{ dv_loadts }}
        {% endif -%}

        {%- for lsat_model in lsat_models %}

            {% set lsat_alias = lsat_model.get('target_table') -%}
            
            left join {{ lsat_alias }}
                on {{ lsat_alias }}.{{ hkey_lnk_name }} = lnk.{{ hkey_lnk_name }}
                and time_dim.snapshot_ts >= {{ lsat_alias }}.{{ dv_loadts }}
                and time_dim.snapshot_ts < {{ lsat_alias }}.{{ dv_loadts }}_end

        {%- endfor %}

{%- endmacro %}
