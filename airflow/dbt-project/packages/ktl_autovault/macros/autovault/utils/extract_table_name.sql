{#
    This file contains macros to render table names in Autovault configuration.
#}

{%- macro render_target_table_name(model) -%}
    {#-
        Render the target table name in model configuration.

        Arguments:
            model (dict): The model configuration containing the target table name.

        Autovault configuration example:
            target_table: sat_account

        -> Output: ref('sat_account')
    -#}
    {{ ref(model.get('target_table')) }}
{%- endmacro -%}

{%- macro render_target_der_table_name(model) -%}
    {#-
        Render the target table name with "sat_der_" prefix in model configuration.

        Arguments:
            model (dict): The model configuration containing the target table name.

        Autovault configuration example:
            target_table: sat_account

        -> Output: ref('sat_der_account')
    -#}
    {{ ref(model.get('target_table').replace("sat_", "sat_der_")) }}
{%- endmacro -%}


{%- macro render_target_snp_table_name(model) -%}
    {#-
        Render the target table name with "sat_snp_" prefix in model configuration.

        Arguments:
            model (dict): The model configuration containing the target table name.

        Autovault configuration example:
            target_table: sat_account

        -> Output: ref('sat_snp_account')
    -#}
    {{ ref(model.get('target_table').replace("sat_", "sat_snp_")) }}
{%- endmacro -%}


{%- macro render_target_lsate_table_name(model) -%}
    {#-
        Render the target table name with "lsate_" prefix in model configuration.

        Arguments:
            model (dict): The model configuration containing the target table name.

        Autovault configuration example:
            target_table: lnk_account

        -> Output: ref('lsate_account')
    -#}
    {{ ref(model.get('target_table').replace("lnk_", "lsate_")) }}
{%- endmacro -%}


{%- macro render_source_table_name(model, from_ref_model=false) -%}
    {#-
        Render the source table name in model configuration.

        Arguments:
            model (dict): The model configuration containing the source table name.
            from_ref_model (bool): Flag to indicate if the source table is a dbt ref model (true) or source model (false).
                Default is false.

        Autovault configuration example:
            source_schema: psa
            source_table: psa_account

        -> Output: source('psa', 'psa_account')
    -#}
    {% if config.get('materialized') == "streaming" -%}
        {{ ktl_autovault.source_view(model.get('source_schema'), model.get('source_table'), from_ref_model) }}
    {%- else -%}
        {{ adapter.dispatch('render_source_table_name', 'ktl_autovault')(model, from_ref_model) }}
    {%- endif -%}
{%- endmacro -%}


{%- macro default__render_source_table_name(model, from_ref_model) -%}
    {%- set schema_name = model.get('source_schema') -%}
    {%- set table_name = model.get('source_table') -%}

    {%- if from_ref_model -%}
        {{ ref(table_name) }}
    {%- else -%}
        {{ source(schema_name, table_name) }}
    {%- endif -%}
{%- endmacro -%}


{%- macro render_source_view_name(model) -%}
    {{ ktl_autovault.source_view(model.get('source_schema'), model.get('source_table')) }}
{%- endmacro -%}


{%- macro render_parent_table_name(model, target_column=none) -%}
    {#-
        Render the parent table name in model configuration.

        Arguments:
            model (dict): The model configuration containing the parent table name.
            target_column (str): The target column name to find the parent table.
                If None, it will return the parent_table of model configuration.            

        Autovault configuration example:
            parent_table: hub_account # return if target_column is None
            columns:
              - target: dv_hkey_hub_account
                dtype: string
                key_type: hash_key_hub
                source:
                  - ln_ac_nbr
                parent: hub_account

        -> Output: ref('hub_account')
    -#}
    {%- if column_name == none -%} {{ model.get('parent_table') }}
    {%- else -%}
        {%- set column = model.get('columns') | selectattr("target", "equalto", target_column) | first -%}
        {%- if column.parent is defined -%} {{ column.get('parent') }}
        {%- else -%} {{ model.get('parent_table') }}
        {%- endif -%}
    {%- endif -%}
{%- endmacro -%}
