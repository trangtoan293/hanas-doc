{% macro psa_transform(source_relation, primary_keys) -%}

    {%- set columns = adapter.get_columns_in_relation(source_relation) -%}
    {%- set hash_full_record = 'hash_full_record' -%}
    {%- set load_datetime = 'load_datetime' -%}
    {%- set record_source = 'record_source' -%}
    {%- set cdc_operation = 'cdc_operation' -%}

    with
        cte_stg as (
            select
                {% for column in columns -%}
                    {{ column.name }},
                {% endfor -%}

                {{ ktl_autovault.generate_dv_hash_key(
                    columns | map(attribute='name') | list,
                    prepare = true,
                    collision_code = none,
                    error_code = "N/A",
                    upper = false,
                    method = 'sha256',
                    dtype = var('dv_hash_key_dtype', "string")
                ) }} as {{ hash_full_record }}
            from
                {{ source_relation }}
        )

    {%- if is_incremental() -%}
        ,

        cte_psa_latest as (
            select
                {% for column in columns -%}
                    {{ column.name }},
                {% endfor -%}
                {{ hash_full_record }}
            from
                (
                    select
                        psa.*,
                        row_number() over (
                            partition by {{ primary_keys | join(', ') }}
                            order by {{ load_datetime }} desc
                        ) as row_num
                        
                    from
                        {{ this }} psa
                )
            where
                row_num = 1
                and {{ cdc_operation }} != 'D'
        )

    select
        *
    from
        (
            select
                stg.*,
                current_timestamp() as {{ load_datetime }},
                '{{ source_relation }}' as {{ record_source }},
                case
                    when psa.{{ hash_full_record }} is null then 'I'
                    when stg.{{ hash_full_record }} != psa.{{ hash_full_record }} then 'U'
                    else null
                end as {{ cdc_operation }}
            from
                cte_stg stg
                left join cte_psa_latest psa
                    on 1=1
                    {% for column in primary_keys -%}
                        and stg.{{ column }} = psa.{{ column }}
                    {% endfor %}
        )
    where
        {{ cdc_operation }} is not null

    union all

    select
        psa.*,
        current_timestamp() as {{ load_datetime }},
        '{{ source_relation }}' as {{ record_source }},
        'D' as {{ cdc_operation }}
    from
        cte_psa_latest psa
    where
        not exists (
            select 1 from cte_stg stg
            where
                1=1
                {% for column in primary_keys -%}
                    and stg.{{ column }} = psa.{{ column }}
                {% endfor %}
        )

    {%- else %}

    select
        stg.*,
        current_timestamp() as {{ load_datetime }},
        '{{ source_relation }}' as {{ record_source }},
        'I' as {{ cdc_operation }}
    from
        cte_stg stg

    {%- endif %}

{%- endmacro %}