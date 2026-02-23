{%- macro lnk_transform(model, dv_system, from_ref_model=false, include_ghost_record=true) -%}

    {#-
        This macro is used to transform a single source table into a link table.

        Args:
            model (dict): The model configuration, including target, source, and business key definitions.
            dv_system (dict): The system columns configuration, can be defined as project variables in the dbt_project.yml file.
            from_ref_model (bool): Indicates if the source table is a dbt ref model (true) or source model (false).
                If true, the source_schema is not needed. Defaults to false.
            include_ghost_record (bool, optional): Indicates if ghost records should be included in initial load. Defaults to true.
0
        Example:
            {%- set model_yml -%}

            target_entity_type: lnk
            target_schema: integration
            target_table: lnk_customer_account
            source_schema: source
            source_table: psa_loan_info
            collision_code: mdm
            columns:
              # required keys: hash_key_lnk, hash_key_hub
              # optional keys: hash_key_drv (for LSAT-effective tables)
              - target: dv_hkey_lnk_customer_account
                dtype: string
                key_type: hash_key_lnk
                source:
                  - ln_ac_nbr
                  - cst_no

              - target: dv_hkey_hub_account
                dtype: string
                key_type: hash_key_drv
                source:
                  - ln_ac_nbr
                    parent: hub_account

              - target: dv_hkey_hub_customer
                dtype: string
                key_type: hash_key_hub
                source:
                  - cst_no
                    parent: hub_customer

            {%- endset -%}

            {%- set lnk_model = fromyaml(model_yml) -%}
            {%- set dv_system = var("dv_system") -%}
            {{ ktl_autovault.lnk_transform(model=lnk_model, dv_system=dv_system) }}
    -#}

    {%- set hkey_name = ktl_autovault.render_hash_key_lnk_name(model) -%}
    {%- set ldt_keys = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system) -%}
    {%- set src_ldt_keys = ktl_autovault.render_list_source_ldt_key_name(dv_system) -%}

    with
        cte_stg_lnk as (
            select
                {{ ktl_autovault.render_hash_key_lnk_treatment(model) }},

                {% for expr in ktl_autovault.render_list_hash_key_hub_treatment(model) -%}
                    {{ expr }},
                {% endfor %}

                {% for expr in ktl_autovault.render_list_dv_system_column_treatment(dv_system) -%}
                    {{ expr }},
                {% endfor %}

                {{ ktl_autovault.render_collision_code_treatment(model) }}

            from
                {{ ktl_autovault.render_source_table_name(model, from_ref_model) }}
            where
                1 = 1
                {% for expr in ktl_autovault.render_list_hash_key_lnk_component(model) -%}
                    and {{ expr }} is not null
                {% endfor %}
                
                {% if is_incremental() -%}

                    {#
                        When running incrementally:
                        - It checks if the source's load date/time is greater than the maximum load date/time in the existing table for the specific collision code.
                        - If no records exist for this collision code, it falls back to '1900-01-01' as a starting point.
                        - This approach filters out records that have already been loaded.
                        The collision code allow tracking of records from different origins within the same link table.
                    -#}

                    and {{ src_ldt_keys[0] }} > coalesce(
                        (
                            select max({{ ldt_keys[0] }}) from {{ this }}
                            where {{ ktl_autovault.render_collision_code_name() }} = '{{ model.get("collision_code") }}'
                        ),
                        {{ ktl_autovault.timestamp('1900-01-01') }}
                    )
                {%- endif %}
        ),
        
        cte_stg_lnk_latest_records as (
            select *
            from
                (
                    select
                        cte_stg_lnk.*,

                        row_number() over (
                            partition by {{ hkey_name }}
                            order by
                                {% for key in ldt_keys -%}
                                    {{ key }} asc {{- ',' if not loop.last }}
                                {% endfor %}
                        ) as row_num

                    from cte_stg_lnk
                )
            where row_num = 1
        )

    select
        {{ hkey_name }},

        {% for expr in ktl_autovault.render_list_hash_key_hub_name(model) -%}
            {{ expr }},
        {% endfor %}

        {% for expr in ktl_autovault.render_list_dv_system_column_name(dv_system) -%}
            {{ expr }},
        {% endfor %}

        {{ ktl_autovault.render_collision_code_name() }}

    from cte_stg_lnk_latest_records src
    
    {%- if is_incremental() %}

        where
            not exists (
                select 1
                from {{ this }} tgt
                where tgt.{{ hkey_name }} = src.{{ hkey_name }}
            )

    {%- endif %}
        
    {%- if not is_incremental() and include_ghost_record %}

    union all

    {{ ktl_autovault.lnk_ghost_record(model, dv_system) }}
    
    {%- endif %}

{%- endmacro -%}
