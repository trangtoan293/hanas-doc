
{%- macro dv_config(model_name) -%}
    
    {%- set all = [] -%}

    {%- if model_name=="hub_account" -%}
        {{ return(hub_account_dv_config()) }}
    {%- endif -%}
    {%- do all.append(hub_account_dv_config()) -%}

    {%- if model_name=="hub_customer" -%}
        {{ return(hub_customer_dv_config()) }}
    {%- endif -%}
    {%- do all.append(hub_customer_dv_config()) -%}

    {%- if model_name=="lnk_customer_account" -%}
        {{ return(lnk_customer_account_dv_config()) }}
    {%- endif -%}
    {%- do all.append(lnk_customer_account_dv_config()) -%}

    {%- if model_name=="lsat_customer_account" -%}
        {{ return(lsat_customer_account_dv_config()) }}
    {%- endif -%}
    {%- do all.append(lsat_customer_account_dv_config()) -%}

    {%- if model_name=="sat_account" -%}
        {{ return(sat_account_dv_config()) }}
    {%- endif -%}
    {%- do all.append(sat_account_dv_config()) -%}

    {%- if model_name=="all" -%}
        {{ return(all) }}
    {%- endif -%}
                 
    {{ exceptions.raise_compiler_error("Not found model '" + model_name + "', please ensure it is defined in directory 'ktl_autovault_configs' and rerun 'ktl-dbt load-autovault-configs'.") }}

{%- endmacro -%}
