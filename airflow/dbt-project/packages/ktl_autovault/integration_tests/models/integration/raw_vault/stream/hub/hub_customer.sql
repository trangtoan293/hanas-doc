
{%- set model = dv_config('hub_customer') -%}
{%- set dv_system = var("dv_system") -%}


{{ ktl_autovault.hub_transform(model=model, dv_system=dv_system, from_psa_model=true) }}
