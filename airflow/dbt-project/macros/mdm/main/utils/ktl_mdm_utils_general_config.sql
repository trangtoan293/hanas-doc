{%- macro ktl_mdm_utils_get_general_config(project_name) -%}
    {{ return(context[project_name|lower+'_general_config_yml']()) }}
{%- endmacro -%}


{%- macro ktl_mdm_utils_get_cob_value(general_conf) -%}
    {{ return(general_conf.get("run_date_config").get("cob_date")) }}
{%- endmacro -%}

