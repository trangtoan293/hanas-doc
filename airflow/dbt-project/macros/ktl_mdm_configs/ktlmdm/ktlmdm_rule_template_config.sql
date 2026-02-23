{%- macro ktlmdm_rule_template_config_yml() -%}
    {%- set config_map = {
        'cleansing': [],
        'validate': []
    } -%}
    {{ return(config_map) }}
{%- endmacro -%}
