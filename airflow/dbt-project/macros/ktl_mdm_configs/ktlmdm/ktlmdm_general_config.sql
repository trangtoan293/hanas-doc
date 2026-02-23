{%- macro ktlmdm_general_config_yml() -%}
    {%- set config_map = {
        'run_date_config': {
            'cob_date': "CURRENT_DATE()"
        },
        'general_config': {
            'match_column_cnt': 6,
            'match_group_cnt': 3
        }
    } -%}
    {{ return(config_map) }}
{%- endmacro -%}
