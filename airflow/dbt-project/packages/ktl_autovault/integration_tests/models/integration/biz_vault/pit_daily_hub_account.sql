
{%- set hub_model = dv_config('hub_account') -%}
{%- set sat_model_1 = dv_config('sat_account') -%}

{%- set dv_system = var("dv_system") -%}

{{ ktl_autovault.pit_hub_transform(hub_model, [sat_model_1], dv_system, time_dimension=ref('daily_time_dim')) }}
