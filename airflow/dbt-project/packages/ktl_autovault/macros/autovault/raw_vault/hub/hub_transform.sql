{% macro hub_transform(model, dv_system, from_ref_model=false, include_ghost_record=true) -%}

    {#-
        This macro is used to transform multiple source tables into a hub table.
        Multiple source tables can be defined in the model configuration by using the 'sources' key.
        The macro will iterate through each source table and apply hub_transform_single macro, then combine the logic using union all.
        If the model configuration does not include the 'sources' key, it will treat the model as hub_transform_single.

        Arguments:
            model (dict): The model configuration, including target, source, and business key definitions.
            dv_system (dict): The system columns configuration, can be defined as project variables in the dbt_project.yml file.
            from_ref_model (bool, optional): Indicates if the source tables are dbt ref models (true) or source models (false). Defaults is false.
            include_ghost_record (bool, optional): Indicates if ghost records should be included in initial load. Defaults to true.

        Example:
            {%- set model_yml -%}

            target_schema: integration
            target_table: hub_customer
            target_entity_type: hub
            sources:
              - source_schema: source
                source_table: corebank_customer
                collision_code: CORE
                columns:
                  - target: dv_hkey_hub_customer
                    dtype: string
                    key_type: hash_key_hub
                    source:
                      - CUS_CUSTOMER_CODE

                  - target: CUS_CUSTOMER_CODE
                    dtype: int
                    key_type: biz_key
                    source:
                      dtype: int
                      name: CUS_CUSTOMER_CODE

              - source_schema: source
                source_table: crm_customer
                collision_code: CRM
                columns:
                  - target: dv_hkey_hub_customer
                    dtype: string
                    key_type: hash_key_hub
                    source:
                      - CRM_CUS_ID

                  - target: CUS_CUSTOMER_CODE
                    dtype: int
                    key_type: biz_key
                    source:
                      dtype: int
                      name: CRM_CUS_ID

            {%- endset -%}

            {%- set hub_model = fromyaml(model_yml) -%}
            {%- set dv_system = var("dv_system") -%}
            {{ ktl_autovault.hub_transform(model=hub_model, dv_system=dv_system) }}
    -#}

    {%- set sources = model.get('sources', [model]) -%}

    {%- if (sources | length) > 1 -%}

    {#-
        If the model configuration includes multiple sources, iterate through each source and apply hub_transform_single macro.
    -#}

    {%- set from_ref_model = from_ref_model or sources[0].get('from_ref_model', false) -%}


    {%- do model.update(sources[0]) -%}
    {%- for source in sources -%}

        {%- do model.update(source) -%}

    select * from (
        {{ ktl_autovault.hub_transform_single(model, dv_system, from_ref_model) }}
    )

    {#
        The logic will be combined using union all.
        If the materialization is streaming, it will not use ; instead to separate the queries.
    -#}

    {% if not loop.last -%}
        {%- if config.get('materialized') == "streaming" -%} ;
        {%- else -%} union all
        {%- endif %}

    {% endif -%}

    {%- endfor -%}

    {%- else -%}

        {%- do model.update(sources[0]) -%}
        {{ ktl_autovault.hub_transform_single(model, dv_system, from_ref_model) }}

    {% endif -%}

    {%- if not is_incremental() and include_ghost_record -%}

    union all

    {{ ktl_autovault.hub_ghost_record(model, dv_system) }}

    {%- endif -%}

{%- endmacro %}


{% macro hub_transform_single(model, dv_system, from_ref_model=false) -%}

    {#-
        This macro is used to transform a single source table into a hub table.

        Arguments:
            model (dict): The model configuration, including target, source, and business key definitions.
            dv_system (dict): The system columns configuration, can be defined as project variables in the dbt_project.yml file.
            from_ref_model (bool, optional): Indicates if the source table is a dbt ref model (true) or source model (false). Defaults is false.

        Example:
            {%- set model_yml -%}

            target_schema: integration
            target_table: hub_customer
            target_entity_type: hub
            source_schema: source
            source_table: corebank_customer
            collision_code: CORE
            columns:
              # required keys: hash_key_hub, biz_key
              - target: dv_hkey_hub_customer
                dtype: string
                key_type: hash_key_hub
                source:
                  - CUS_CUSTOMER_CODE

              - target: CUS_CUSTOMER_CODE
                dtype: int
                key_type: biz_key
                source:
                  dtype: int
                  name: CUS_CUSTOMER_CODE

            {%- endset -%}

            {%- set hub_model = fromyaml(model_yml) -%}
            {%- set dv_system = var("dv_system") -%}
            {{ ktl_autovault.hub_transform_single(model=hub_model, dv_system=dv_system) }}
    -#}

    {%- set hkey_name = ktl_autovault.render_hash_key_hub_name(model) -%}
    {%- set ldt_keys = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system) -%}
    {%- set src_ldt_keys = ktl_autovault.render_list_source_ldt_key_name(dv_system) -%}

    with
        cte_stg_hub as (
            select
                {{ ktl_autovault.render_hash_key_hub_treatment(model) }},

                {% for expr in ktl_autovault.render_list_biz_key_treatment(model) -%}
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
                {%- for expr in ktl_autovault.render_list_hash_key_hub_component(model) %}
                    and {{ expr }} is not null
                {%- endfor %}

                {%- if is_incremental() %}

                    {#
                        When running incrementally:
                        - It checks if the source's load date/time is greater than the maximum load date/time in the existing table for the specific collision code.
                        - If no records exist for this collision code, it falls back to '1900-01-01' as a starting point.
                        - This approach filters out records that have already been loaded.
                        The collision code allow tracking of records from different origins within the same hub table.
                    -#}

                    and {{ src_ldt_keys[0] }} > coalesce(
                        (
                            select max({{ ldt_keys[0] }}) from {{ this }}
                            where {{ ktl_autovault.render_collision_code_name() }} = {{ "'" + model.get('collision_code') + "'" }}
                        ),
                        {{ ktl_autovault.timestamp('1900-01-01') }}
                    )

                {%- endif %}
        ),

        cte_stg_hub_latest_records as (
            select *
            from
                (
                    select
                        cte_stg_hub.*,

                        row_number() over (
                            partition by {{ hkey_name }}
                            order by
                                {% for key in ldt_keys -%}
                                    {{ key }} asc {{- ',' if not loop.last }}
                                {% endfor %}
                        ) as row_num

                    from cte_stg_hub
                )
            where row_num = 1
        )

    select
        {{ hkey_name }},

        {% for expr in ktl_autovault.render_list_biz_key_name(model) -%}
            {{ expr }},
        {% endfor %}

        {% for expr in ktl_autovault.render_list_dv_system_column_name(dv_system) -%}
            {{ expr }},
        {% endfor %}

        {{ ktl_autovault.render_collision_code_name() }}

    from
        cte_stg_hub_latest_records src

    {%- if is_incremental() %}

    where
        not exists (
            select 1
            from {{ this }} tgt
            where tgt.{{ hkey_name }} = src.{{ hkey_name }}
        )

    {%- endif -%}

{%- endmacro %}
