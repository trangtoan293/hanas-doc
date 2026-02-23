
{%- set model = dv_config('lsat_customer_account') -%}
{%- set dv_system = var("dv_system") -%}


{{ ktl_autovault.lsat_transform(model=model, dv_system=dv_system) }}
