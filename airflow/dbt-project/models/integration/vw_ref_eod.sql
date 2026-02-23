{{ config(
    materialized = 'table',
    file_format='iceberg'
) }}

select
    cob_date,
    lag(cob_date, 1, {{ ktl_autovault.timestamp('1900-01-01') }}) over (partition by 1 order by cob_date asc) as last_cob_date,
    optime as run_time,
    lag(optime, 1, {{ ktl_autovault.timestamp('1900-01-01') }}) over (partition by 1 order by cob_date asc) as last_run_time
from
    {{ source('landing', 'ref_eod') }}
