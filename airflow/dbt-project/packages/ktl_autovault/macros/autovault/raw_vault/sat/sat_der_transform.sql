{%- macro sat_der_transform(
    model,
    dv_system,
    from_ref_model=false,
    initial_date = var('initial_date', run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")).strftime('%Y-%m-%d'))
) -%}

    {#-
        This macro is used to transform a single source table into a SAT-derivative table.
        Derivative tables are used to process raw data into SAT-suitable format in real-time,
        before being loaded into the main LSAT table in EOD process.
        This approach allows for faster processing and more efficient data handling with large datasets.

        Arguments:
            model (dict): The model configuration, including target, source, and business key definitions.
            dv_system (dict): The system columns configuration, can be defined as project variables in the dbt_project.yml file.
            from_ref_model (bool): Indicates if the source table is a dbt ref model (true) or source model (false).
                If true, the source_schema is not needed. Defaults to false.
            initial_date (str): The initial date for the initial load. Defaults to the current date in 'Asia/Ho_Chi_Minh' timezone.
                This can be ignored if the ref_eod_table is provided as a project variable in dbt_project.yml.

        Example:
            {%- set model_yml -%}
            # this template is used for all type of SAT tables: sat, sat_snp, sat_der

            target_entity_type: sat
            target_schema: integration
            target_table: sat_account
            parent_table: hub_account
            source_schema: source
            source_table: psa_loan_info
            collision_code: mdm
            columns:
              # required keys: hash_key_sat, hash_key_hub, hash_diff, at least one undefined (normal attribute)
              # optional keys: depentent_key
              - target: dv_hkey_sat_account
                dtype: string
                key_type: hash_key_sat

              - target: dv_hkey_hub_account
                dtype: string
                key_type: hash_key_hub
                source:
                - ln_ac_nbr

              - target: dv_hsh_dif
                dtype: string
                key_type: hash_diff

              - target: br_cd
                dtype: decimal(38,0)
                source:
                name: br_cd
                dtype: string

              - target: book_date
                dtype: date
                source:
                name: book_date
                dtype: string

              - target: value_date
                dtype: date
                source:
                name: value_date
                dtype: string

            {%- endset -%}

            {%- set sat_model = fromyaml(model_yml) -%}
            {%- set dv_system = var("dv_system") -%}
            {{ ktl_autovault.sat_der_transform(model=sat_model, dv_system=dv_system) }}
    -#}

    {%- if var('ref_eod_table', none) -%}
        {%- set initial_date = ktl_autovault.eod_initial_date(ref(var('ref_eod_table'))) -%}
    {%- endif -%}

    {%- set src_hkey_hub = ktl_autovault.render_list_hash_key_hub_component(model) -%}
    {%- set src_dep_keys = ktl_autovault.render_list_source_dependent_key_name(model) -%}
    {%- set src_ldt_keys = ktl_autovault.render_list_source_ldt_key_name(dv_system) -%}
    {%- set ldt_keys = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system) -%}

    select
        {{ ktl_autovault.render_hash_key_sat_treatment(model, dv_system) }},
        {{ ktl_autovault.render_hash_key_hub_treatment(model) }},
        {{ ktl_autovault.render_hash_diff_treatment(model) }},

        {% for expr in ktl_autovault.render_list_dependent_key_treatment(model) -%}
            {{ expr }},
        {% endfor %}

        {% for expr in ktl_autovault.render_list_attr_column_treatment(model) -%}
            {{ expr }},
        {% endfor %}

        {% for expr in ktl_autovault.render_list_dv_system_column_treatment(dv_system) -%}
            {{ expr }} {{- ',' if not loop.last }}
        {% endfor %}

    from
        {{ ktl_autovault.render_source_table_name(model, from_ref_model) }}
    where
        1 = 1
        {% for expr in src_hkey_hub + src_dep_keys -%}
            and {{ expr }} is not null
        {% endfor %}

        and {{ src_ldt_keys[0] }} >= {{ ktl_autovault.timestamp(initial_date) }}

        {% if is_incremental() -%}
            and {{ src_ldt_keys[0] }} > coalesce((select max({{ ldt_keys[0] }}) from {{ this }}), {{ ktl_autovault.timestamp('1900-01-01') }})
        {%- endif %}

{%- endmacro -%}
