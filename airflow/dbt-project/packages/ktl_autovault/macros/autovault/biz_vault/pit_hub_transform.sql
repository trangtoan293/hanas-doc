
{% macro pit_hub_transform(hub_model, sat_models, dv_system, time_dimension = none) -%}
    
    {%- set hkey_hub_name = ktl_autovault.render_hash_key_hub_name(hub_model) -%}
    {%- set dv_loadts = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system)[0] -%}

    with
    {% if not time_dimension -%}
        
        time_dim as (
        {%- for sat_model in sat_models %}

            {% set sat_hkey_hub = ktl_autovault.render_hash_key_hub_name(sat_model) -%}
            
            select
                {{ sat_hkey_hub }} {%- if sat_hkey_hub != hkey_hub_name %} as {{ hkey_hub_name }} {%- endif %},
                {{ dv_loadts }} as snapshot_ts
            from
                {{ ktl_autovault.render_target_table_name(sat_model) }}
            {% if not loop.last -%} union {%- endif %}
        
        {%- endfor %}
        ),
        
    {%- endif %}

    {%- for sat_model in sat_models %}

        {% set sat_alias = sat_model.get('target_table') -%}
        {%- set sat_hkey_hub = ktl_autovault.render_hash_key_hub_name(sat_model) -%}
        
        {{ sat_alias }} as (

            select
                {{ ktl_autovault.render_hash_key_sat_name(sat_model) }},
                {{ sat_hkey_hub }} {%- if sat_hkey_hub != hkey_hub_name %} as {{ hkey_hub_name }} {%- endif %},
                {{ dv_loadts }},
                lead({{ dv_loadts }}, 1, '9999-12-31') over (
                    partition by {{ sat_hkey_hub }}
                    order by {{ dv_loadts }} asc
                ) as {{ dv_loadts }}_end
            from
                {{ ktl_autovault.render_target_table_name(sat_model) }}
                
        )
        {%- if not loop.last -%} , {%- endif %}

    {%- endfor %}

    select
        hub.{{ hkey_hub_name }},
        {% for expr in ktl_autovault.render_list_biz_key_name(hub_model) -%}
            hub.{{ expr }},
        {% endfor -%}
        cast(time_dim.snapshot_ts as timestamp) as snapshot_ts,
        
        {%- for sat_model in sat_models %}

            {% set sat_alias = sat_model.get('target_table') -%}
            {%- set hkey_sat_name = ktl_autovault.render_hash_key_sat_name(sat_model) -%}
            {%- set hkey_sat_column = sat_model.get('columns') | selectattr("key_type", "equalto", "hash_key_sat") | first -%}
            
            coalesce({{ sat_alias }}.{{ hkey_sat_name }}, {{ ktl_autovault.render_ghost_record(hkey_sat_column) }}) as {{ hkey_sat_name }}
            {%- if not loop.last -%} , {%- endif %}
        
        {%- endfor %}

    from
        {{ ktl_autovault.render_target_table_name(hub_model) }} hub
        {% if not time_dimension -%}
            join time_dim on hub.{{ hkey_hub_name }} = time_dim.{{ hkey_hub_name }}
        {% else -%}
            join {{ time_dimension }} time_dim on time_dim.snapshot_ts >= hub.{{ dv_loadts }}
        {% endif -%}

        {%- for sat_model in sat_models %}

            {% set sat_alias = sat_model.get('target_table') -%}
            
            left join {{ sat_alias }}
                on {{ sat_alias }}.{{ hkey_hub_name }} = hub.{{ hkey_hub_name }}
                and time_dim.snapshot_ts >= {{ sat_alias }}.{{ dv_loadts }}
                and time_dim.snapshot_ts < {{ sat_alias }}.{{ dv_loadts }}_end

        {%- endfor %}

{%- endmacro %}
