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
    MDM Merge: Combine cleansed data with validation and match results
    
    Incremental: Inherits from upstream models
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
cleansed_filtered AS (
    SELECT c.*
    FROM {{ ref('mdm_corecif_cleansed') }} c
    JOIN ref_dates rd
      ON c.dv_ldt > rd.last_run_time AND c.dv_ldt <= rd.run_time
),
CIF_VAL_SCORES AS (
    SELECT
        CIF_NO,
        COALESCE(LOAI_GTTT_ERR_CNT, 0) AS LOAI_GTTT,
        COALESCE(PASS_NO_ERR_CNT, 0) AS PASS_NO,
        COALESCE(PASS_E_DT_ERR_CNT, 0) AS PASS_E_DT,
        COALESCE(PASS_I_DT_ERR_CNT, 0) AS PASS_I_DT,
        COALESCE(MOBILE_ERR_CNT, 0) AS MOBILE,
        COALESCE(QUOC_TICH_ERR_CNT, 0) AS QUOC_TICH,
        (COALESCE(LOAI_GTTT_ERR_CNT, 0) + 
         COALESCE(PASS_NO_ERR_CNT, 0) + 
         COALESCE(PASS_E_DT_ERR_CNT, 0) + 
         COALESCE(PASS_I_DT_ERR_CNT, 0) + 
         COALESCE(MOBILE_ERR_CNT, 0) + 
         COALESCE(QUOC_TICH_ERR_CNT, 0)) AS SCORE
    FROM {{ ref('mdm_corecif_validate') }}
),

FLAG_DUPLICATES AS (
    SELECT
        CIF_NO,
        FLAG_DUP_M1
    FROM {{ ref('mdm_corecif_match') }}
),

RANKED_DUPLICATES AS (
    SELECT
        C.CIF_NO,
        C.LOAI_GTTT,
        C.PASS_NO,
        ROW_NUMBER() OVER (
            PARTITION BY C.LOAI_GTTT, C.PASS_NO
            ORDER BY
                COALESCE(V.SCORE, 0) ASC,
                CASE WHEN C.CUSTOMER_TYPE = 'I' THEN 1 ELSE 2 END ASC,
                C.CIF_NO ASC
        ) AS RANKED
    FROM cleansed_filtered C
    JOIN FLAG_DUPLICATES D 
        ON C.CIF_NO = D.CIF_NO
    LEFT JOIN CIF_VAL_SCORES V 
        ON C.CIF_NO = V.CIF_NO
    WHERE
        D.FLAG_DUP_M1 = 1
        AND C.LOAI_GTTT IS NOT NULL
        AND C.PASS_NO IS NOT NULL
),

CARD_ADDR AS (
    SELECT
        H.CIF_NO,
        S.ADDR
    FROM {{ ref('hub_card') }} H
    LEFT JOIN {{ ref('sat_snp_card') }} S ON H.DV_HKEY_HUB_CARD = S.DV_HKEY_HUB_CARD
)

SELECT 
    C.CIF_NO,
    C.CUSTOMER_TYPE,
    C.F_NAME,
    C.M_NAME,
    C.L_NAME,
    C.CO_NAME,
    C.POS_CD,
    C.SEX_CD,
    C.D_O_B,
    C.PASS_NO,
    C.PASS_I_DT,
    C.PASS_E_DT,
    C.NOI_CAP_GTTT,
    C.LOAI_GTTT,
    C.SO_THI_THUC,
    C.VISA_ISSUE_DT,
    C.VISA_EXPIRY_DT,
    C.NOI_CAP_THI_THUC,
    C.QUOC_TICH,
    C.LEG_ST,
    COALESCE(A.ADDR, C.RES_ADD_1) AS RES_ADD_1,
    C.RES_CNTRY_CD,
    C.OFF_ADD_2,
    C.OFF_CNTRY_CD,
    C.QUOC_GIA_NUOC_NGOAI,
    C.RES_PH_NO_1,
    C.RES_PH_NO_2,
    C.MOBILE,
    C.EMAIL_ID1,
    C.EMAIL_ID2,
    C.dv_ldt,
    C.dv_src_ldt,
    CASE 
        WHEN COALESCE(V.SCORE, 0) + COALESCE(D.FLAG_DUP_M1, 0) = 0 THEN 1
        ELSE 0
    END AS IS_GOLDEN
FROM cleansed_filtered C
{% else %}
WITH

CIF_VAL_SCORES AS (
    SELECT
        CIF_NO,
        COALESCE(LOAI_GTTT_ERR_CNT, 0) AS LOAI_GTTT,
        COALESCE(PASS_NO_ERR_CNT, 0) AS PASS_NO,
        COALESCE(PASS_E_DT_ERR_CNT, 0) AS PASS_E_DT,
        COALESCE(PASS_I_DT_ERR_CNT, 0) AS PASS_I_DT,
        COALESCE(MOBILE_ERR_CNT, 0) AS MOBILE,
        COALESCE(QUOC_TICH_ERR_CNT, 0) AS QUOC_TICH,
        (COALESCE(LOAI_GTTT_ERR_CNT, 0) + 
         COALESCE(PASS_NO_ERR_CNT, 0) + 
         COALESCE(PASS_E_DT_ERR_CNT, 0) + 
         COALESCE(PASS_I_DT_ERR_CNT, 0) + 
         COALESCE(MOBILE_ERR_CNT, 0) + 
         COALESCE(QUOC_TICH_ERR_CNT, 0)) AS SCORE
    FROM {{ ref('mdm_corecif_validate') }}
),

FLAG_DUPLICATES AS (
    SELECT
        CIF_NO,
        FLAG_DUP_M1
    FROM {{ ref('mdm_corecif_match') }}
),

RANKED_DUPLICATES AS (
    SELECT
        C.CIF_NO,
        C.LOAI_GTTT,
        C.PASS_NO,
        ROW_NUMBER() OVER (
            PARTITION BY C.LOAI_GTTT, C.PASS_NO
            ORDER BY
                COALESCE(V.SCORE, 0) ASC,
                CASE WHEN C.CUSTOMER_TYPE = 'I' THEN 1 ELSE 2 END ASC,
                C.CIF_NO ASC
        ) AS RANKED
    FROM {{ ref('mdm_corecif_cleansed') }} C
    JOIN FLAG_DUPLICATES D 
        ON C.CIF_NO = D.CIF_NO
    LEFT JOIN CIF_VAL_SCORES V 
        ON C.CIF_NO = V.CIF_NO
    WHERE
        D.FLAG_DUP_M1 = 1
        AND C.LOAI_GTTT IS NOT NULL
        AND C.PASS_NO IS NOT NULL
),

CARD_ADDR AS (
    SELECT
        H.CIF_NO,
        S.ADDR
    FROM {{ ref('hub_card') }} H
    LEFT JOIN {{ ref('sat_snp_card') }} S ON H.DV_HKEY_HUB_CARD = S.DV_HKEY_HUB_CARD
)

SELECT 
    C.CIF_NO,
    C.CUSTOMER_TYPE,
    C.F_NAME,
    C.M_NAME,
    C.L_NAME,
    C.CO_NAME,
    C.POS_CD,
    C.SEX_CD,
    C.D_O_B,
    C.PASS_NO,
    C.PASS_I_DT,
    C.PASS_E_DT,
    C.NOI_CAP_GTTT,
    C.LOAI_GTTT,
    C.SO_THI_THUC,
    C.VISA_ISSUE_DT,
    C.VISA_EXPIRY_DT,
    C.NOI_CAP_THI_THUC,
    C.QUOC_TICH,
    C.LEG_ST,
    COALESCE(A.ADDR, C.RES_ADD_1) AS RES_ADD_1,
    C.RES_CNTRY_CD,
    C.OFF_ADD_2,
    C.OFF_CNTRY_CD,
    C.QUOC_GIA_NUOC_NGOAI,
    C.RES_PH_NO_1,
    C.RES_PH_NO_2,
    C.MOBILE,
    C.EMAIL_ID1,
    C.EMAIL_ID2,
    C.dv_ldt,
    C.dv_src_ldt,
    CASE 
        WHEN COALESCE(V.SCORE, 0) + COALESCE(D.FLAG_DUP_M1, 0) = 0 THEN 1
        ELSE 0
    END AS IS_GOLDEN
FROM {{ ref('mdm_corecif_cleansed') }} C
{% endif %}
LEFT JOIN RANKED_DUPLICATES R
    ON C.CIF_NO = R.CIF_NO
LEFT JOIN CIF_VAL_SCORES V
    ON C.CIF_NO = V.CIF_NO
LEFT JOIN FLAG_DUPLICATES D
    ON C.CIF_NO = D.CIF_NO
LEFT JOIN CARD_ADDR A
    ON C.CIF_NO = A.CIF_NO
WHERE
    R.CIF_NO IS NULL OR R.RANKED = 1
