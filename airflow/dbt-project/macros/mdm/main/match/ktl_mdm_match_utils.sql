{%- macro ktl_mdm_match_utils_get_manual_match(rule_apply) -%}
    {%- set result_lst = [] -%}
    {%- for rule in rule_apply.get('matched_by_rules') -%}
        {%- if rule.get('type') is not none -%}
            {%- if rule.get('type')|lower == 'manual' -%}
                {%- do result_lst.append(rule) -%}
            {%- endif -%}
        {%- else -%} {# Default manual if not set type in config #}
            {%- do result_lst.append(rule) -%}
        {%- endif -%}
    {%- endfor -%}
    {{ return(result_lst) }}
{%- endmacro -%}

{%- macro ktl_mdm_match_utils_get_auto_match(rule_apply) -%}
    {%- set result_lst = [] -%}
    {%- for rule in rule_apply.get('matched_by_rules') -%}
        {%- if rule.get('type') is not none -%}
            {%- if rule.get('type')|lower == 'auto' -%}
                {%- do result_lst.append(rule) -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
    {{ return(result_lst) }}
{%- endmacro -%}