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
    MDM Golden Records: Final output of quality-verified customer records
    
    Incremental: Inherits from upstream merge model
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
),
merge_filtered AS (
    SELECT m.*
    FROM {{ ref('mdm_corecif_merge') }} m
    JOIN ref_dates rd
      ON m.dv_ldt > rd.last_run_time AND m.dv_ldt <= rd.run_time
)
SELECT
    CIF_NO,
    CUSTOMER_TYPE,
    F_NAME,
    M_NAME,
    L_NAME,
    CO_NAME,
    POS_CD,
    SEX_CD,
    D_O_B,
    PASS_NO,
    PASS_I_DT,
    PASS_E_DT,
    NOI_CAP_GTTT,
    LOAI_GTTT,
    SO_THI_THUC,
    VISA_ISSUE_DT,
    VISA_EXPIRY_DT,
    NOI_CAP_THI_THUC,
    QUOC_TICH,
    LEG_ST,
    RES_ADD_1,
    RES_CNTRY_CD,
    OFF_ADD_2,
    OFF_CNTRY_CD,
    QUOC_GIA_NUOC_NGOAI,
    RES_PH_NO_1,
    RES_PH_NO_2,
    MOBILE,
    EMAIL_ID1,
    EMAIL_ID2,
    dv_ldt,
    dv_src_ldt
FROM merge_filtered
WHERE IS_GOLDEN = 1
{% else %}
SELECT
    CIF_NO,
    CUSTOMER_TYPE,
    F_NAME,
    M_NAME,
    L_NAME,
    CO_NAME,
    POS_CD,
    SEX_CD,
    D_O_B,
    PASS_NO,
    PASS_I_DT,
    PASS_E_DT,
    NOI_CAP_GTTT,
    LOAI_GTTT,
    SO_THI_THUC,
    VISA_ISSUE_DT,
    VISA_EXPIRY_DT,
    NOI_CAP_THI_THUC,
    QUOC_TICH,
    LEG_ST,
    RES_ADD_1,
    RES_CNTRY_CD,
    OFF_ADD_2,
    OFF_CNTRY_CD,
    QUOC_GIA_NUOC_NGOAI,
    RES_PH_NO_1,
    RES_PH_NO_2,
    MOBILE,
    EMAIL_ID1,
    EMAIL_ID2,
    dv_ldt,
    dv_src_ldt
FROM {{ ref('mdm_corecif_merge') }}
WHERE IS_GOLDEN = 1
{% endif %}
