{%- macro ktlmdm_metadata_config_yml() -%}
    {%- set config_map = {
        'shb': shb_metadata_config_yml().get('KTL_MDM')
    } -%}
    {{ return(config_map) }}
{%- endmacro -%}
