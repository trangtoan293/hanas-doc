
{%- set lnk_model = dv_config('lnk_customer_account') -%}
{%- set lsat_model_1 = dv_config('lsat_customer_account') -%}

{%- set dv_system = var("dv_system") -%}

{{ ktl_autovault.pit_lnk_transform(lnk_model, [lsat_model_1], dv_system) }}
