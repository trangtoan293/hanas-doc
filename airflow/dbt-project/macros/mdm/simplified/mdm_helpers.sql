{# Helper macro to get cleansing rules from config #}
{%- macro mdm_get_cleansing_rules(product, source_system) -%}
    {%- set rule_desc_config = shb_rule_desc_config_yml() -%}
    {%- set rule_apply_config = shb_rule_field_apply_config_yml() -%}
    
    {%- set rules = [] -%}
    {%- for product_config in rule_apply_config.KTL_MDM -%}
        {%- if product_config.product == product -%}
            {%- for sys_config in product_config.source_system -%}
                {%- if sys_config.name == source_system -%}
                    {%- for rule_apply in sys_config.cleansing -%}
                        {%- set rule_code = rule_apply.name -%}
                        {%- set columns = rule_apply.list_column -%}
                        
                        {# Find rule description #}
                        {%- for rule_desc in rule_desc_config.cleansing -%}
                            {%- if rule_desc.code == rule_code -%}
                                {%- set rule_info = {
                                    'code': rule_code,
                                    'columns': columns,
                                    'template': rule_desc.rule_template,
                                    'description': rule_desc.description,
                                    'character': rule_desc.get('character'),
                                    'from_str_format': rule_desc.get('from_str_format'),
                                    'catalog_condition': rule_desc.get('catalog_condition'),
                                    'column_condition': rule_desc.get('column_condition')
                                } -%}
                                {%- do rules.append(rule_info) -%}
                            {%- endif -%}
                        {%- endfor -%}
                    {%- endfor -%}
                {%- endif -%}
            {%- endfor -%}
        {%- endif -%}
    {%- endfor -%}
    
    {{ return(rules) }}
{%- endmacro -%}

{# Helper macro to get validation rules from config #}
{%- macro mdm_get_validation_rules(product, source_system) -%}
    {%- set rule_desc_config = shb_rule_desc_config_yml() -%}
    {%- set rule_apply_config = shb_rule_field_apply_config_yml() -%}
    
    {%- set rules = [] -%}
    {%- for product_config in rule_apply_config.KTL_MDM -%}
        {%- if product_config.product == product -%}
            {%- for sys_config in product_config.source_system -%}
                {%- if sys_config.name == source_system -%}
                    {%- for rule_apply in sys_config.validate -%}
                        {%- set rule_code = rule_apply.name -%}
                        {%- set columns = rule_apply.list_column -%}
                        
                        {# Find rule description #}
                        {%- for rule_desc in rule_desc_config.validate -%}
                            {%- if rule_desc.code == rule_code -%}
                                {%- set rule_info = {
                                    'code': rule_code,
                                    'columns': columns,
                                    'template': rule_desc.rule_template,
                                    'description': rule_desc.description,
                                    'regex_pattern': rule_desc.get('regex_pattern'),
                                    'warning_null': rule_desc.get('warning_null'),
                                    'catalog_condition': rule_desc.get('catalog_condition'),
                                    'column_condition': rule_desc.get('column_condition'),
                                    'condition': rule_desc.get('condition'),
                                    'validate_original': rule_desc.get('validate_original', 'NO'),
                                    'date_format': rule_desc.get('date_format')
                                } -%}
                                {%- do rules.append(rule_info) -%}
                            {%- endif -%}
                        {%- endfor -%}
                    {%- endfor -%}
                {%- endif -%}
            {%- endfor -%}
        {%- endif -%}
    {%- endfor -%}
    
    {{ return(rules) }}
{%- endmacro -%}

{# Helper macro to get all column names from metadata config #}
{%- macro mdm_get_all_columns(product, source_system) -%}
    {%- set metadata_config = shb_metadata_config_yml() -%}
    {%- set columns = [] -%}
    
    {%- for product_config in metadata_config.KTL_MDM -%}
        {%- if product_config.product == product -%}
            {%- for sys_config in product_config.source_system -%}
                {%- if sys_config.name == source_system -%}
                    {%- for col in sys_config.columns -%}
                        {%- do columns.append(col.name) -%}
                    {%- endfor -%}
                {%- endif -%}
            {%- endfor -%}
        {%- endif -%}
    {%- endfor -%}
    
    {{ return(columns) }}
{%- endmacro -%}

{# Helper macro to get primary key column #}
{%- macro mdm_get_pk_column(product, source_system) -%}
    {%- set metadata_config = shb_metadata_config_yml() -%}
    
    {%- for product_config in metadata_config.KTL_MDM -%}
        {%- if product_config.product == product -%}
            {%- for sys_config in product_config.source_system -%}
                {%- if sys_config.name == source_system -%}
                    {%- for col in sys_config.columns -%}
                        {%- if col.is_pk -%}
                            {{ return(col.name) }}
                        {%- endif -%}
                    {%- endfor -%}
                {%- endif -%}
            {%- endfor -%}
        {%- endif -%}
    {%- endfor -%}
{%- endmacro -%}
