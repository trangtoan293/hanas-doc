{# Helper macro to get match rules from config #}
{%- macro mdm_get_match_rules(product, source_system) -%}
    {%- set rule_desc_config = shb_rule_desc_config_yml() -%}
    
    {%- set rules = [] -%}
    {%- if rule_desc_config.match is defined -%}
        {%- for rule in rule_desc_config.match -%}
            {%- set rule_info = {
                'code': rule.code,
                'description': rule.description,
                'match_columns': rule.match_columns,
                'customer_type_filter': rule.get('customer_type_filter')
            } -%}
            {%- do rules.append(rule_info) -%}
        {%- endfor -%}
    {%- endif -%}
    
    {{ return(rules) }}
{%- endmacro -%}

{# Main macro to generate match flags based on config #}
{%- macro generate_match_flags(source_ref, product='CORECIF', source_system='SHB') -%}

{%- set match_rules = mdm_get_match_rules(product, source_system) -%}
{%- set all_columns = mdm_get_all_columns(product, source_system) -%}

SELECT
    base.*,
    {%- for rule in match_rules %}
    CASE
        WHEN COUNT(*) OVER (
            PARTITION BY 
                {%- if rule.customer_type_filter %}
                CASE WHEN base.CUSTOMER_TYPE = '{{ rule.customer_type_filter }}' THEN 1 ELSE 0 END,
                {%- endif %}
                {%- for col in rule.match_columns %}
                base.{{ col }}{% if not loop.last %},{% endif %}
                {%- endfor %}
        ) > 1
        {%- if rule.customer_type_filter %}
        AND base.CUSTOMER_TYPE = '{{ rule.customer_type_filter }}'
        {%- endif %}
        {%- for col in rule.match_columns %}
        AND base.{{ col }} IS NOT NULL
        {%- endfor %}
        THEN 1
        ELSE 0
    END AS FLAG_DUP_{{ rule.code }}
    {%- if not loop.last %},{% endif %}
    {%- endfor %}
FROM {{ source_ref }} base

{%- endmacro -%}
