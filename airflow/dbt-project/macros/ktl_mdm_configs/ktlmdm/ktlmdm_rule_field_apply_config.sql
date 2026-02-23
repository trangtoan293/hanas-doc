{%- macro ktlmdm_rule_field_apply_config_yml() -%}
    {%- set config_map = {
        'KTL_MDM': shb_rule_field_apply_config_yml().get('KTL_MDM')
    } -%}
    {{ return(config_map) }}
{%- endmacro -%}
