
{%- macro ktl_mdm_utils_get_rule_field_apply_config(project_name,product,source,component) -%}
    {%- for product_item in context[project_name|lower+'_rule_field_apply_config_yml']().get('KTL_MDM') -%}
        {%- if product_item.get('product')|lower == product|lower -%}
            {%- if component|lower == 'merge' -%}
            {%- else -%}
                {%- for source_item in product_item.get('source_system') -%}
                    {%- if source_item.get('name')|lower == source|lower -%}
                        {%- set conf = source_item.get(component|lower) -%}
                        {# If conf already a mapping, ensure required keys for MATCH #}
                        {%- if conf is mapping -%}
                            {%- if component|lower == 'match' -%}
                                {%- set has_mbr = conf.get('matched_by_rules') is not none -%}
                                {%- set has_priority = conf.get('auto_match_pkkey_priority_by') is not none -%}
                                {%- if has_mbr and has_priority -%}
                                    {{ return(conf) }}
                                {%- else -%}
                                    {{ return({
                                        'matched_by_rules': conf.get('matched_by_rules', []),
                                        'auto_match_pkkey_priority_by': conf.get('auto_match_pkkey_priority_by', {})
                                    }) }}
                                {%- endif -%}
                            {%- else -%}
                                {{ return(conf) }}
                            {%- endif -%}
                        {%- endif -%}
                        {# If conf is a list: for MATCH wrap (with default priority map), otherwise return list directly (e.g., CLEANSING expects a list) #}
                        {%- if conf is sequence and (conf is not string) -%}
                            {%- if component|lower == 'match' -%}
                                {{ return({'matched_by_rules': conf, 'auto_match_pkkey_priority_by': {} }) }}
                            {%- else -%}
                                {{ return(conf) }}
                            {%- endif -%}
                        {%- endif -%}
                        {{ return(conf) }}
                    {%- endif -%}
                {%- endfor -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
{%- endmacro -%}


{# get list column apply rule available #}
{%- macro ktl_mdm_get_column_available(lst_col_metadata, lst_col_rule_apply) -%}
    {%- set result = [] -%}

    {%- for item in lst_col_rule_apply -%}
        {%- if item in lst_col_metadata -%}
            {%- do result.append(item) -%}
        {%- endif -%}
    {%- endfor -%}

    {{ return(result) }}
{%- endmacro -%}