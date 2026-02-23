{%- macro sat_snp_transform_incremental(
    model,
    dv_system,
    start_date = var('incre_start_date', none),
    end_date = var('incre_end_date', run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")).strftime('%Y-%m-%d'))
) -%}

    {%- set hkey_hub_name = ktl_autovault.render_hash_key_hub_name(model) -%}
    {%- set dep_keys = ktl_autovault.render_list_dependent_key_name(model) -%}
    {%- set ldt_keys = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system) -%}
    {%- set cdc_ops = ktl_autovault.render_dv_system_cdc_ops_name(dv_system) -%}
    {%- set hash_diff = ktl_autovault.render_hash_diff_name(model) -%}

    with
        cte_sat_der_latest_records as (
            select *
            from
                (
                    select
                        sat_der.*,

                        row_number() over (
                            partition by
                                {% for key in [hkey_hub_name] + dep_keys -%}
                                    {{ key }} {{- ',' if not loop.last }}
                                {% endfor %}
                            order by
                                {% for key in ldt_keys -%}
                                    {{ key }} desc {{- ',' if not loop.last }}
                                {%- endfor %}
                        ) as row_num

                    from {{ ktl_autovault.render_target_der_table_name(model) }} sat_der
                    where
                        {% if start_date -%}
                            {{ ldt_keys[0] }} >= {{ ktl_autovault.timestamp(start_date) }}
                        {% else -%} 1 = 1
                        {% endif -%}

                        and {{ ldt_keys[0] }} < {{ ktl_autovault.timestamp(end_date) }}
                )
            where row_num = 1
        )

    select
        {{ ktl_autovault.render_hash_key_sat_name(model) }},
        {{ ktl_autovault.render_hash_key_hub_name(model) }},
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

    from cte_sat_der_latest_records sat_der
    where
        not exists (
            select 1
            from {{ this }} sat_snp
            where
                sat_der.{{ hkey_hub_name }} = sat_snp.{{ hkey_hub_name }}

                {% for column in dep_keys -%}
                    and sat_der.{{ column }} = sat_snp.{{ column }}
                {% endfor %}

                and sat_der.{{ hash_diff }} = sat_snp.{{ hash_diff }}
                and lower(sat_der.{{ cdc_ops }}) not in ('d', 't')
                and lower(sat_snp.{{ cdc_ops }}) not in ('d', 't')
        )

{%- endmacro -%}
