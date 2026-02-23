
{%- set source_relation = source('duytk_test', 'loan_info') -%}
{%- set primary_keys = ['ln_ac_nbr'] -%}

{{ ktl_autovault.psa_transform(source_relation, primary_keys) }}
