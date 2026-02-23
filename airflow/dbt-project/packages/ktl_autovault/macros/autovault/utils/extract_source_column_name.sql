{#
    This file contains macros to render column names of source tables in Autovault configuration.
#}

{% macro render_list_hash_key_hub_component(model) -%}
    {#-
        Render a list of source column names for the first hash_key_hub key in model configuration.

        Arguments:
            model (dict): The model configuration containing the columns.

        Autovault configuration example:
            columns:
              - target: dv_hkey_hub_account
                dtype: binary
                key_type: hash_key_hub
                source:
                  - ln_ac_nbr

        -> Output: [ln_ac_nbr]
    -#}
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_hub") | first -%}
    {{ return(column.get('source') | list) }}
{%- endmacro %}


{% macro render_list_hash_key_drv_component(model) -%}
    {#-
        Render a list of source column names for the first hash_key_drv key in model configuration.

        Arguments:
            model (dict): The model configuration containing the columns.

        Autovault configuration example:
            columns:
              - target: dv_hkey_hub_account
                dtype: string
                key_type: hash_key_drv
                source:
                  - ln_ac_nbr
                parent: hub_account

        -> Output: [ln_ac_nbr]
    -#}
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_drv") | first -%}
    {{ return(column.get('source') | list) }}
{%- endmacro %}


{% macro render_list_hash_key_lnk_component(model) -%}
    {#-
        Render a list of source column names for the first hash_key_lnk key in model configuration.

        Arguments:
            model (dict): The model configuration containing the columns.

        Autovault configuration example:
            columns:
              - target: dv_hkey_lnk_customer_account
                dtype: string
                key_type: hash_key_lnk
                source:
                  - ln_ac_nbr
                  - cst_no

        -> Output: [ln_ac_nbr, cst_no]
    -#}
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_lnk") | first -%}
    {{ return(column.get('source') | list) }}
{%- endmacro %}


{% macro render_list_source_dependent_key_name(model) -%}
    {#-
        Render a list of source column names for all dependent_key in model configuration.

        Arguments:
            model (dict): The model configuration containing the columns.

        Autovault configuration example:
            columns:
              - target: ln_ac_nbr
                dtype: string
                key_type: dependent_key
                source:
                  name: ln_ac_nbr
                  dtype: string

        -> Output: [ln_ac_nbr]
    -#}
    {%- set outs = [] -%}
    
    {%- for column in model.get('columns') | selectattr("key_type", "equalto", "dependent_key") | list -%}
        {%- do outs.append(column.get('source').get('name')) -%}
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}


{% macro render_list_source_ldt_key_name(dv_system) -%}
    {#-
        Render a list of source column names for all load datetime and offset in Data Vault system configuration,
        including dv_src_ldt, dv_kaf_ldt, and dv_kaf_ofs.

        Arguments:
            dv_system (dict): The Data Vault system configuration containing the columns.

        Autovault configuration example:
            columns:
              - target: dv_src_ldt
                dtype: timestamp
                source:
                  name: load_datetime
                  dtype: timestamp

              - target: dv_kaf_ldt
                dtype: timestamp
                source:
                  name: kaf_load_datetime
                  dtype: timestamp

              - target: dv_kaf_ofs
                dtype: string
                source:
                  name: kaf_offset
                  dtype: string

        -> Output: [load_datetime, kaf_load_datetime, kaf_offset]
    -#}
    {%- set outs = [] -%}
    
    {%- for key in ('dv_src_ldt', 'dv_kaf_ldt', 'dv_kaf_ofs') -%}
        {%- if key in (dv_system.get('columns') | map(attribute='target') | list) -%}
            {%- set tmp = (dv_system.get('columns') | selectattr('target', 'equalto', key) | first).get('source').get('name') -%}
            {%- do outs.append(tmp) -%}
        {%- endif -%}
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}
