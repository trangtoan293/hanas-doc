-- depends_on: {{ ref('vw_ref_eod') }}
{{
    config(
        materialized='incremental',
        file_format='iceberg',
        unique_key='CIF_NO',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns'
    )
}}

{#
    MDM Source: Customer from Core CIF
    
    Incremental strategy: merge by CIF_NO
    - Filter: Records changed within [last_run_time, run_time] window
    - Each CIF_NO keeps only the latest version
#}

{% if is_incremental() %}
WITH ref_dates AS (
    SELECT run_time, last_run_time
    FROM {{ ref('vw_ref_eod') }}
    {% if var('cob_date', none) %}
    WHERE cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {% else %}
    WHERE cob_date = (SELECT MAX(cob_date) FROM {{ ref('vw_ref_eod') }})
    {% endif %}
)
{% endif %}

SELECT
    h.CIF_NO,
    s.CUSTOMER_TYPE,
    s.F_NAME,
    s.M_NAME,
    s.L_NAME,
    s.CO_NAME,
    s.POS_CD,
    s.SEX_CD,
    s.D_O_B,
    s.PASS_NO,
    s.PASS_I_DT,
    s.PASS_E_DT,
    s.NOI_CAP_GTTT,
    s.LOAI_GTTT,
    s.SO_THI_THUC,
    s.VISA_ISSUE_DT,
    s.VISA_EXPIRY_DT,
    s.NOI_CAP_THI_THUC,
    s.QUOC_TICH,
    s.LEG_ST,
    s.RES_ADD_1,
    s.RES_CNTRY_CD,
    s.OFF_ADD_2,
    s.OFF_CNTRY_CD,
    s.QUOC_GIA_NUOC_NGOAI,
    s.RES_PH_NO_1,
    s.RES_PH_NO_2,
    s.MOBILE,
    s.EMAIL_ID1,
    s.EMAIL_ID2,
    s.dv_ldt,
    s.dv_src_ldt
FROM {{ ref('hub_customer') }} h
INNER JOIN {{ ref('sat_snp_customer') }} s
ON h.dv_hkey_hub_customer = s.dv_hkey_hub_customer
{% if is_incremental() %}
CROSS JOIN ref_dates rd
WHERE s.dv_ldt > rd.last_run_time
  AND s.dv_ldt <= rd.run_time
{% endif %}
