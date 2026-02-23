{% macro eod_initial_date(ref_table) -%}
    
    {%- if var('initial_cob_date', none) -%}
        select run_time from {{ ref_table }} where cob_date = {{ ktl_autovault.timestamp(var('initial_cob_date')) }}
    {%- else -%}
        select run_time from {{ ref_table }} where cob_date = (select max(cob_date) from {{ ref_table }})
    {%- endif -%}
     
{%- endmacro %}


{% macro eod_incre_start_date(ref_table) -%}
    
    {%- if var('cob_date', none) -%}
        select last_run_time from {{ ref_table }} where cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {%- else -%}
        select last_run_time from {{ ref_table }} where cob_date = (select max(cob_date) from {{ ref_table }})
    {%- endif -%}
     
{%- endmacro %}


{% macro eod_incre_end_date(ref_table) -%}
    
    {%- if var('cob_date', none) -%}
        select run_time from {{ ref_table }} where cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {%- else -%}
        select run_time from {{ ref_table }} where cob_date = (select max(cob_date) from {{ ref_table }})
    {%- endif -%}
     
{%- endmacro %}
