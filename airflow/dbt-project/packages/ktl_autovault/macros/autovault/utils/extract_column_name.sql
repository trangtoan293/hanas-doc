{#
    This file contains macros to render column names of target tables in Autovault configuration.
#}

{% macro render_collision_code_name(with_dtype=false) -%}
    {#-
        Render the column name for collision code.
        Used for HUB and LINK tables.

        Arguments:
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.
    -#}
    dv_ccd {%- if with_dtype %} {{ dbt.type_string() }} {%- endif -%}
{%- endmacro %}


{% macro render_hash_key_hub_name(model, with_dtype=false) -%}
    {#-
        Render the first column name with type hash_key_hub.
        Used for HUB and SAT tables.

        Arguments:
            model (dict): The model configuration containing the columns.
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

        Autovault configuration example:
            columns:
              - target: dv_hkey_hub_account
                dtype: binary
                key_type: hash_key_hub
                source:
                  - ln_ac_nbr

        -> Output: dv_hkey_hub_account
    -#}
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_hub") | first -%}
    {{ column.get('target') }}
    {%- if with_dtype %} {{ api.Column.translate_type(column.get('dtype')) }} {%- endif -%}
{%- endmacro %}


{% macro render_list_hash_key_hub_name(model, with_dtype=false) -%}
    {#-
        Render all column names with type hash_key_hub or hash_key_drv.
        Used for LINK tables.

        Arguments:
            model (dict): The model configuration containing the columns.
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

        Autovault configuration example:
            columns:
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

        -> Output: [dv_hkey_hub_account, dv_hkey_hub_customer]
    -#}
    {%- set outs = [] -%}

    {%- for column in model.get('columns') | selectattr("key_type", "equalto", "hash_key_hub") | list + model.get('columns') | selectattr("key_type", "equalto", "hash_key_drv") | list -%}

        {%- set tmp -%}
            {{ column.get('target') }} {%- if with_dtype %} {{ api.Column.translate_type(column.get('dtype')) }} {%- endif -%}
        {%- endset -%}
        
        {% do outs.append(tmp) %}

    {%- endfor -%}

    {{ return(outs) }}

{%- endmacro %}


{% macro render_hash_key_lnk_name(model, with_dtype=false) -%}
    {#-
        Render the first column name with type hash_key_lnk.
        Used for LINK and LSAT tables.

        Arguments:
            model (dict): The model configuration containing the columns.
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

        Autovault configuration example:
            columns:
              - target: dv_hkey_lnk_customer_account
                dtype: string
                key_type: hash_key_lnk
                source:
                  - ln_ac_nbr
                  - cst_no

        -> Output: dv_hkey_lnk_customer_account
    -#}
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_lnk") | first -%}
    {{ column.get('target') }}
    {%- if with_dtype %} {{ api.Column.translate_type(column.get('dtype')) }} {%- endif -%}
{%- endmacro %}


{% macro render_hash_key_drv_name(model, with_dtype=false) -%}
    {#-
        Render the first column name with type hash_key_drv.
        Used for LINK and LSAT-Effective tables.

        Arguments:
            model (dict): The model configuration containing the columns.
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

        Autovault configuration example:
            columns:
              - target: dv_hkey_hub_account
                dtype: string
                key_type: hash_key_drv
                source:
                  - ln_ac_nbr
                parent: hub_account

        -> Output: dv_hkey_hub_account
    -#}
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_drv") | first -%}
    {{ column.get('target') }}
    {%- if with_dtype %} {{ api.Column.translate_type(column.get('dtype')) }} {%- endif -%}
{%- endmacro %}


{% macro render_hash_key_sat_name(model, with_dtype=false) -%}
    {#-
        Render the first column name with type hash_key_sat.
        Used for SAT/LSAT tables.

        Arguments:
            model (dict): The model configuration containing the columns.
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

        Autovault configuration example:
            columns:
              - target: dv_hkey_sat_account
                dtype: string
                key_type: hash_key_sat

        -> Output: dv_hkey_sat_account
    -#}
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_key_sat") | first -%}
    {{ column.get('target') }}
    {%- if with_dtype %} {{ api.Column.translate_type(column.get('dtype')) }} {%- endif -%}
{%- endmacro %}


{% macro render_hash_key_lsat_name(model, with_dtype=false) -%}
    {#-
        Alias of render_hash_key_sat_name, used for LSAT tables.

        Arguments:
            model (dict): The model configuration containing the columns.
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

        Autovault configuration example:
            columns:
              - target: dv_hkey_lsat_customer_account
                dtype: string
                key_type: hash_key_sat

        -> Output: dv_hkey_lsat_customer_account
    -#}
    {{ ktl_autovault.render_hash_key_sat_name(model, with_dtype) }}
{%- endmacro %}


{% macro render_hash_diff_name(model, with_dtype=false) -%}
    {#-
        Render the first column name with type hash_diff.
        Used for SAT/LSAT tables.

        Arguments:
            model (dict): The model configuration containing the columns.
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

        Autovault configuration example:
            columns:
              - target: dv_hsh_dif
                dtype: string
                key_type: hash_diff

        -> Output: dv_hsh_dif
    -#}
    {%- set column = model.get('columns') | selectattr("key_type", "equalto", "hash_diff") | first -%}
    {{ column.get('target') }}
    {%- if with_dtype %} {{ api.Column.translate_type(column.get('dtype')) }} {%- endif -%}
{%- endmacro %}


{% macro render_list_biz_key_name(model, with_dtype=false) -%}
    {#-
        Render all column names with type biz_key.
        Used for HUB tables.

        Arguments:
            model (dict): The model configuration containing the columns.
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

        Autovault configuration example:
            columns:
              - target: ln_ac_nbr
                dtype: string
                key_type: biz_key
                source:
                  name: ln_ac_nbr
                  dtype: string
        
        -> Output: [ln_ac_nbr]
    -#}
    {%- set outs = [] -%}
    
    {%- for column in model.get('columns') | selectattr("key_type", "equalto", "biz_key") -%}
    
        {%- set tmp -%}
            {{column.get('target')}} {%- if with_dtype %} {{ api.Column.translate_type(column.get('dtype')) }} {%- endif -%}
        {%- endset -%}
    
        {% do outs.append(tmp) %}
    
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}


{% macro render_list_dependent_key_name(model, with_dtype=false) -%}
    {#-
        Render all column names with type dependent_key.
        Used for SAT/LSAT tables.

        Arguments:
            model (dict): The model configuration containing the columns.
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

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
    
    {%- for column in model.get('columns') | selectattr('key_type', 'equalto', "dependent_key") -%}
    
        {%- set tmp -%}
            {{column.get('target')}} {%- if with_dtype %} {{ api.Column.translate_type(column.get('dtype')) }} {%- endif -%}
        {%- endset -%}
    
        {% do outs.append(tmp) %}
    
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}


{% macro render_list_attr_column_name(model, with_dtype=false) -%}
    {#-
        Render all column names with undefined key_type (normal attributes).
        Used for SAT/LSAT tables.

        Arguments:
            model (dict): The model configuration containing the columns.
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

        Autovault configuration example:
            columns:
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

        -> Output: [br_cd, book_date, value_date]
    -#}
    {%- set outs = [] -%}
    
    {%- for column in model.get('columns') | selectattr('key_type', 'undefined') -%}
    
        {%- set tmp -%}
            {{column.get('target')}} {%- if with_dtype %} {{ api.Column.translate_type(column.get('dtype')) }} {%- endif -%}
        {%- endset -%}
    
        {% do outs.append(tmp) %}
    
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}


{% macro render_list_dv_system_column_name(dv_system, with_dtype=false) -%}
    {#-
        Render all column names in the dv_system configuration.
        Used for all entities in Datavault.

        Arguments:
            dv_system: the dv_system configuration containing the columns
            with_dtype (boolean): Flag to include data type in the output, used for create table statements.

        Autovault configuration example:
            columns:
              - target: dv_src_ldt
                dtype: timestamp
                source:
                  name: load_datetime
                  dtype: timestamp

              - target: dv_src_rec
                dtype: string
                source:
                  name: record_source
                  dtype: string
                
              - target: dv_cdc_ops
                dtype: string
                source:
                  name: cdc_operation
                  dtype: string

        -> Output: [dv_src_ldt, dv_src_rec, dv_cdc_ops]
    -#}
    {%- set outs = [] -%}
    
    {%- for column in dv_system.get('columns') -%}
    
        {%- set tmp -%}
            {{column.get('target')}} {%- if with_dtype %} {{ api.Column.translate_type(column.get('dtype')) }}{%- endif -%}
        {%- endset -%}
    
        {% do outs.append(tmp) %}
    
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}


{% macro render_list_dv_system_ldt_key_name(dv_system) -%}
    {#-
        Render all column names used for load datetime and offset in the Data Vault system configuration,
        including dv_src_ldt, dv_kaf_ldt, and dv_kaf_ofs, in priority order.
        Used for all entities in Datavault.

        Arguments:
            dv_system: the Data Vault system configuration containing the columns

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

        -> Output: [dv_src_ldt, dv_kaf_ldt, dv_kaf_ofs]
    -#}
    {%- set outs = [] -%}
    
    {%- for key in ('dv_src_ldt', 'dv_kaf_ldt', 'dv_kaf_ofs') -%}
        {%- if key in (dv_system.get('columns') | map(attribute='target') | list) -%}
            {%- do outs.append(key) -%}
        {%- endif -%}
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}


{% macro render_dv_system_cdc_ops_name(dv_system) -%}
    {#-
        Render the column name used for change data capture operation in the dv_system configuration.
        Used for all entities in Datavault.

        Arguments:
            dv_system: the dv_system configuration containing the columns

        Autovault configuration example:
            columns:
              - target: dv_cdc_ops
                dtype: string
                source:
                  name: cdc_operation
                  dtype: string

        -> Output: [dv_cdc_ops]
    -#}
    {{ (dv_system.get('columns') | selectattr('target', 'equalto', 'dv_cdc_ops') | first).get('target') }}
{%- endmacro %}
