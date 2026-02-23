{%- macro ktl_mdm_utils_types_string(nbyte = 255) -%}
    {{ return(adapter.dispatch('ktl_mdm_utils_types_string')(nbyte)) }}
{%- endmacro -%}

{%- macro oracle__ktl_mdm_utils_types_string(nbyte) -%}
    {{ return("VARCHAR2("~nbyte~")") }}
{%- endmacro -%}

{%- macro spark__ktl_mdm_utils_types_string(nbyte) -%}
    {{ return("STRING") }}
{%- endmacro -%}

{# dispath config get year in diff system oracle --- spark #}
{%- macro ktl_mdm_utils_get_year(ncolumn) -%}
    {{ return(adapter.dispatch('ktl_mdm_utils_get_year')(ncolumn)) }}
{%- endmacro -%}

{%- macro oracle__ktl_mdm_utils_get_year(ncolumn) -%}
    {{ return("SUBSTR(TO_CHAR(EXTRACT(YEAR FROM " ~ ncolumn ~ ")), 3)") }}
{%- endmacro -%}

{%- macro spark__ktl_mdm_utils_get_year(ncolumn) -%}
    {{ return("SUBSTR(CAST(YEAR("~ ncolumn~ ") AS STRING), 3, 2)") }}
{%- endmacro -%}

{# dispath config get datetime now in diff system oracle --- spark #}
{%- macro ktl_mdm_utils_get_sysdate() -%}
    {{ return(adapter.dispatch('ktl_mdm_utils_get_sysdate')()) }}
{%- endmacro -%}

{%- macro oracle__ktl_mdm_utils_get_sysdate(ncolumn) -%}
    {{ return("SYSDATE") }}
{%- endmacro -%}

{%- macro spark__ktl_mdm_utils_get_sysdate(ncolumn) -%}
    {{ return("CURRENT_DATE") }}
{%- endmacro -%}


