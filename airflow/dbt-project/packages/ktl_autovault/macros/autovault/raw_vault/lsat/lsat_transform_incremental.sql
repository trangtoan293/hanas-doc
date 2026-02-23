{%- macro lsat_transform_incremental(
    model,
    dv_system,
    start_date = var('incre_start_date', none),
    end_date = var('incre_end_date', run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")).strftime('%Y-%m-%d'))
) -%}

    {%- set hkey_lnk_name = ktl_autovault.render_hash_key_lnk_name(model) -%}
    {%- set dep_keys = ktl_autovault.render_list_dependent_key_name(model) -%}
    {%- set ldt_keys = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system) -%}
    {%- set cdc_ops = ktl_autovault.render_dv_system_cdc_ops_name(dv_system) -%}
    {%- set hash_diff = ktl_autovault.render_hash_diff_name(model) -%}

    with
        cte_lsat_der_latest_records as (
            select *
            from
                (
                    select
                        der.*,

                        row_number() over (
                            partition by
                                {% for key in [hkey_lnk_name] + dep_keys -%}
                                    {{ key }} {{- ',' if not loop.last }}
                                {% endfor %}
                            order by
                                {% for key in ldt_keys -%}
                                    {{ key }} desc {{- ',' if not loop.last }}
                                {%- endfor %}
                        ) as row_num

                    from {{ ktl_autovault.render_target_der_table_name(model) }} der
                    where
                        {% if start_date -%}
                            {{ ldt_keys[0] }} >= {{ ktl_autovault.timestamp(start_date) }}
                        {% else -%} 1 = 1
                        {% endif -%}

                        and {{ ldt_keys[0] }} < {{ ktl_autovault.timestamp(end_date) }}
                )
            where row_num = 1
        ),

        cte_lsat_latest_records as (
            select *
            from
                (
                    select
                        lsat.*,

                        row_number() over (
                            partition by
                                {% for key in [hkey_lnk_name] + dep_keys -%}
                                    {{ key }} {{- ',' if not loop.last }}
                                {% endfor %}
                            order by
                                {% for key in ldt_keys -%}
                                    {{ key }} desc {{- ',' if not loop.last }}
                                {%- endfor %}
                        ) as row_num

                    from {{ this }} lsat
                )
            where row_num = 1
        )

    select
        {{ ktl_autovault.render_hash_key_lsat_name(model) }},
        {{ ktl_autovault.render_hash_key_lnk_name(model) }},
        {{ ktl_autovault.render_hash_diff_name(model) }},

        {% for name in ktl_autovault.render_list_dependent_key_name(model) -%}
            {{ name }},
        {% endfor %}

        {% for name in ktl_autovault.render_list_attr_column_name(model) -%}
            {{ name }},
        {% endfor %}

        {% for name in ktl_autovault.render_list_dv_system_column_name(dv_system) -%}
            {{ name }} {{- ',' if not loop.last }}
        {% endfor %}

    from cte_lsat_der_latest_records lsat_der
    where
        not exists (
            select 1
            from cte_lsat_latest_records lsat
            where
                lsat_der.{{ hkey_lnk_name }} = lsat.{{ hkey_lnk_name }}

                {% for column in dep_keys -%}
                    and lsat_der.{{ column }} = lsat.{{ column }}
                {% endfor %}

                and lsat_der.{{ hash_diff }} = lsat.{{ hash_diff }}
                and lower(lsat_der.{{ cdc_ops }}) not in ('d', 't')
                and lower(lsat.{{ cdc_ops }}) not in ('d', 't')
        )

{%- endmacro -%}
