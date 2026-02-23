{#-
    This file contains macros to derive columns in Autovault configuration.
-#}

{% macro derive_column(column) -%}
    {#-
        Derive a source column based on comparison of name and datatype with the target column.

        Arguments:
            column (dict): The column configuration containing source, target (and optional format used for datetime conversion).

        Autovault configuration example:
            columns:
              - target: load_date
                dtype: datetime
                source:
                  name: load_date
                  dtype: string
                  format: 'yyyy-MM-dd'

        -> Output: to_date(load_date, 'yyyy-MM-dd') as load_date
    -#}
    {%- set source_col = column.get('source') -%}
    {%- set target_expr = ktl_autovault.cast(source_col.get('name'), source_col.get('dtype'), column.get('dtype'), source_col.get('format')) -%}

    {{ target_expr }} {%- if target_expr != column.get('target') %} as {{ column.get('target') }} {%- endif -%}

{%- endmacro %}


{% macro render_list_biz_key_treatment(model, ghost_record = false) -%}
    {#-
        Render transformation of a list of columns with key type biz_key in model configuration.

        Arguments:
            model (dict): The model configuration containing the columns.
            ghost_record (bool): If true, render the ghost record for the column.
                Default is false.

        Autovault configuration example:
            columns:
              - target: dv_hkey_hub_account
                dtype: string
                key_type: biz_key
                source:
                  name: ln_ac_nbr
                  dtype: string

        -> Output: ["coalesce(nullif(upper(rtrim(cast(ln_ac_nbr as string))), ''), '-1') as dv_hkey_hub_account"]
    -#}
    {%- set outs = [] -%}

    {%- for column in model.get('columns') | selectattr("key_type", "equalto", "biz_key") -%}

        {%- set tmp -%}

            {%- if ghost_record -%}
                {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
            
            {%- else -%}
                {%- if api.Column.translate_type(column.get('dtype')) == dbt.type_string() -%}
                    {{ ktl_autovault.prepare_hash_component(column.get('source').get('name'), error_code = "-1", upper = true) }} as {{ column.get('target') }}
                {%- else -%}
                    {{ ktl_autovault.derive_column(column) }}
                {%- endif -%}

            {%- endif -%}

        {%- endset -%}

        {%- do outs.append(tmp) -%}
        
    {%- endfor -%}

    {{ return(outs) }}

{%- endmacro %}


{% macro render_list_dependent_key_treatment(model, ghost_record = false) -%}
    {#-
        Render transformation of a list of columns with key type dependent_key in model configuration.

        Arguments:
            model (dict): The model configuration containing the columns.
            ghost_record (bool): If true, render the ghost record for the column.
                Default is false.

        Autovault configuration example:
            columns:
              - target: ln_ac_nbr
                dtype: int
                key_type: dependent_key
                source:
                  name: ln_ac_nbr
                  dtype: string

        -> Output: ["cast(ln_ac_nbr as int) as ln_ac_nbr"]
    -#}
    {%- set outs = [] -%}

    {%- for column in model.get('columns') | selectattr('key_type', 'equalto', "dependent_key") -%}

        {%- set tmp -%}

            {%- if ghost_record -%}
                {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
            
            {%- else -%}
                {{ ktl_autovault.derive_column(column) }}
            
            {%- endif -%}
        
        {%- endset -%}

        {%- do outs.append(tmp) -%}
    
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}


{% macro render_list_attr_column_treatment(model, ghost_record = false) -%}
    {#-
        Render transformation of a list of columns with undefined key type in model configuration.

        Arguments:
            model (dict): The model configuration containing the columns.
            ghost_record (bool): If true, render the ghost record for the column.
                Default is false.

        Autovault configuration example:
            columns:
              - target: br_cd
                dtype: int
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
                  dtype: date

        -> Output: ["cast(br_cd as int) as br_cd", "to_date(book_date) as book_date", "value_date"]
    -#}
    {%- set outs = [] -%}

    {%- for column in model.get('columns') | selectattr('key_type', 'undefined') -%}

        {%- set tmp -%}

            {%- if ghost_record -%}
                {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
            
            {%- else -%}
                {{ ktl_autovault.derive_column(column) }}
            
            {%- endif -%}
        
        {%- endset -%}

        {%- do outs.append(tmp) -%}
    
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}


{%- macro render_list_dv_system_column_treatment(dv_system, ghost_record = false) -%}
    {#-
        Render transformation of a list of columns in Data Vault system configuration.

        Arguments:
            dv_system (dict): The Data Vault system configuration containing the columns.
            ghost_record (bool): If true, render the ghost record for the column.
                Default is false.

        Autovault configuration example:
            columns:
              - target: dv_src_ldt
                dtype: timestamp
                source:
                  name: load_datetime
                  dtype: string
                  format: 'yyyy-MM-dd HH:mm:ss.SSS'
              - target: dv_kaf_ldt
                dtype: timestamp
                source:
                  name: kaf_load_datetime
                  dtype: string

        -> Output: ["to_timestamp(load_datetime, 'yyyy-MM-dd HH:mm:ss.SSS') as dv_src_ldt", "to_timestamp(kaf_load_datetime) as dv_kaf_ldt"]
    -#}
    {%- set outs = [] -%}

    {%- for column in dv_system.get('columns') -%}

        {%- set tmp -%}

            {%- if ghost_record -%}
                {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
            
            {%- else -%}
                {{ ktl_autovault.derive_column(column) }}
            
            {%- endif -%}
        
        {%- endset -%}

        {%- do outs.append(tmp) -%}
    
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro -%}
