{% macro lsate_transform(model, dv_system, from_ref_model=false) -%}

    {%- set lnk_table_name = ktl_autovault.render_target_table_name(model) -%}

    {%- set hkey_lnk_name = ktl_autovault.render_hash_key_lnk_name(model) -%}
    {%- set hkey_drv_name = ktl_autovault.render_hash_key_drv_name(model) -%}
    {%- set ldt_keys = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system) -%}
    {%- set src_ldt_keys = ktl_autovault.render_list_source_ldt_key_name(dv_system) -%}

    with
        cte_stg_lsate as (
            select
                {{ ktl_autovault.render_hash_key_drv_treatment(model) }},
                {{ ktl_autovault.render_hash_key_lnk_treatment(model) }},
                {{ src_ldt_keys[0] }} as dv_startts,

                {% for expr in ktl_autovault.render_list_dv_system_column_treatment(dv_system) -%}
                    {{ expr }} {{- ',' if not loop.last }}
                {% endfor %}
            from
                {{ ktl_autovault.render_source_table_name(model, from_ref_model) }}
            where
                1 = 1
                {% for expr in ktl_autovault.render_list_hash_key_drv_component(model) -%}
                    and {{ expr }} is not null
                {% endfor %}
                
                {%- if is_incremental() -%}
                    and {{ src_ldt_keys[0] }} > coalesce((select max({{ ldt_keys[0] }}) from {{ this }}), {{ ktl_autovault.timestamp('1900-01-01') }})
                {%- endif %}
        ),
        
        {%- if is_incremental() %}

        cte_current_effectivity as (
            select
                lnk.{{ hkey_drv_name }},
                lsate.{{ hkey_lnk_name }},
                lsate.dv_startts
            from
                (
                    select *
                    from
                        (
                            select
                                {{ hkey_lnk_name }},
                                dv_startts,
                                dv_endts,
                                
                                row_number() over (
                                    partition by {{ hkey_lnk_name }}
                                    order by
                                        {% for key in ldt_keys -%}
                                            {{ key }} desc {{- ',' if not loop.last }}
                                        {% endfor %}
                                ) as row_num

                            from {{ this }}
                        ) lsate
                    where
                        row_num = 1
                        and dv_endts = {{ ktl_autovault.timestamp('9999-12-31') }}
                ) lsate
            join
                {{ lnk_table_name }} lnk
                    on lsate.{{ hkey_lnk_name }} = lnk.{{ hkey_lnk_name }}
        ),

        cte_close_driver_key as (
            select
                {{ hkey_drv_name }},
                {{ hkey_lnk_name }},
                dv_startts,

                {% for expr in ktl_autovault.render_list_dv_system_column_name(dv_system) -%}
                    {{ expr }} {{- ',' if not loop.last }}
                {% endfor %}
            from
                (
                    select
                        *,
                        row_number() over (
                            partition by {{ hkey_drv_name }}
                            order by
                                {% for key in ldt_keys -%}
                                    {{ key }} desc {{- ',' if not loop.last }}
                                {% endfor %}
                        ) as row_num

                    from cte_stg_lsate
                ) stg
            where
                row_num = 1
        ),

        cte_close_effectivity as (
            select
                curr.{{ hkey_lnk_name }},
                curr.dv_startts,
                drv.dv_startts as dv_endts,

                {% for expr in ktl_autovault.render_list_dv_system_column_name(dv_system) -%}
                    drv.{{ expr }} {{- ',' if not loop.last }}
                {% endfor %}
            from
                cte_current_effectivity curr
                join cte_close_driver_key drv
                    on curr.{{ hkey_drv_name }} = drv.{{ hkey_drv_name }}
                    and curr.{{ hkey_lnk_name }} != drv.{{ hkey_lnk_name }}
        ),

        {%- endif %}

        cte_new_effectivity as (
            select
                {{ hkey_lnk_name }},
                dv_startts,

                lead(dv_startts, 1, {{ ktl_autovault.timestamp('9999-12-31') }}) over (
                    partition by {{ hkey_drv_name }}
                    order by
                        {% for key in ldt_keys -%}
                            {{ key }} asc {{- ',' if not loop.last }}
                        {% endfor %}
                ) dv_endts,

                {% for expr in ktl_autovault.render_list_dv_system_column_name(dv_system) -%}
                    {{ expr }} {{- ',' if not loop.last }}
                {% endfor %}
            from
                (
                    select
                        *,

                        lag({{ hkey_lnk_name }}, 1, {{ ktl_autovault.render_hash_key_lnk_ghost_record(model) }}) over (
                            partition by {{ hkey_drv_name }}
                            order by
                                {% for key in ldt_keys -%}
                                    {{ key }} asc {{- ',' if not loop.last }}
                                {% endfor %}
                        ) as prev_hkey_lnk

                    from cte_stg_lsate
                ) subq
            where
                prev_hkey_lnk != {{ hkey_lnk_name }}
        )

    select *
    from cte_new_effectivity lsate
    where
        exists (
            select 1
            from {{ lnk_table_name }} lnk
            where lsate.{{ hkey_lnk_name }} = lnk.{{ hkey_lnk_name }}
        )

    {%- if is_incremental() %}

    union all
    
    select * from cte_close_effectivity

    {%- endif -%}

{%- endmacro %}
