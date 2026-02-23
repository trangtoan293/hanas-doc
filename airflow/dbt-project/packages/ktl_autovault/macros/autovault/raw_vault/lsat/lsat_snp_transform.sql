{%- macro lsat_snp_transform(
    model,
    dv_system,
    from_ref_model=false,
    include_ghost_record=true
) -%}

    {#-
        This macro is used to transform a single source table into a LSAT-snapshot table.
        LSAT-snapshot tables are used to store the latest snapshot of the data in EOD process,
        which helps users to create reports and dashboards with the most recent data instead of processing the entire history.
        
        Arguments:
            model (dict): The model configuration, including target, source, and business key definitions.
            dv_system (dict): The system columns configuration, can be defined as project variables in the dbt_project.yml file.
            from_ref_model (bool): Indicates if the source table is a dbt ref model (true) or source model (false).
                If true, the source_schema is not needed. Defaults to false.
            include_ghost_record (bool, optional): Indicates if ghost records should be included in initial load. Defaults to true.

        Example:
            {%- set model_yml -%}
            # this template is used for all type of LSAT tables: lsat, lsat_snp, lsat_der

            target_entity_type: lsat
            target_schema: integration
            target_table: lsat_customer_account
            parent_table: lnk_customer_account
            source_schema: source
            source_table: psa_loan_info
            collision_code: mdm
            columns:
              # required keys: hash_key_sat, hash_key_lnk, hash_diff, at least one undefined (normal attribute)
              # optional keys: depentent_key
              - target: dv_hkey_lsat_customer_account
                dtype: string
                key_type: hash_key_sat

              - target: dv_hkey_lnk_customer_account
                dtype: string
                key_type: hash_key_lnk
                source:
                  - ln_ac_nbr
                  - cst_no

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

            {%- set lsat_model = fromyaml(model_yml) -%}
            {%- set dv_system = var("dv_system") -%}
            {{ ktl_autovault.lsat_snp_transform(model=lsat_model, dv_system=dv_system) }}
    -#}

    {{ config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=[ktl_autovault.render_hash_key_lnk_name(model)]+ktl_autovault.render_list_dependent_key_name(model)
    ) }}

    {%- if var('ref_eod_table', none) -%}
        {%- set initial_date = ktl_autovault.eod_initial_date(ref(var('ref_eod_table'))) -%}
        {%- set start_date = ktl_autovault.eod_incre_start_date(ref(var('ref_eod_table'))) -%}
        {%- set end_date = ktl_autovault.eod_incre_end_date(ref(var('ref_eod_table'))) -%}
    {%- else -%}
        {%- set initial_date = var('initial_date', run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")).strftime('%Y-%m-%d')) -%}
        {%- set start_date = var('incre_start_date', none) -%}
        {%- set end_date = var('incre_end_date', run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")).strftime('%Y-%m-%d')) -%}
    {%- endif -%}

    -- depends_on: {{ ktl_autovault.render_target_der_table_name(model) }}
    -- depends_on: {{ ktl_autovault.render_source_table_name(model, from_ref_model) }}

    {% if not is_incremental() -%}

        {{ ktl_autovault.lsat_snp_transform_initial(model=model, dv_system=dv_system, from_ref_model=from_ref_model, initial_date=initial_date) }}

        {% if include_ghost_record -%}
        
        union all

        {{ ktl_autovault.lsat_ghost_record(model, dv_system) }}
        
        {% endif -%}

    {%- elif is_incremental() -%}

        {{ ktl_autovault.lsat_snp_transform_incremental(model=model, dv_system=dv_system, start_date=start_date, end_date=end_date) }}

    {%- endif -%}

{%- endmacro -%}
