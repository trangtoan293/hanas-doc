{{ config(
    materialized='incremental',
    file_format='iceberg',
    incremental_strategy='insert_overwrite',
    partition_by=['COB_DATE'],
    on_schema_change='sync_all_columns'
) }}

{#
    Fact Table: Deposit Detail (Snapshot by COB_DATE)
    
    Incremental strategy: merge
    - Full refresh: Load tất cả dữ liệu
    - Incremental: Xóa data của COB_DATE hiện tại và insert lại
    
    Optimized: Using AC_NO mapping from get_ac_no_mapping() macro
#}


{% set ac_no_map = get_ac_no_mapping() %}

WITH ref_dates AS (
    SELECT cob_date, run_time, last_run_time
    FROM {{ ref('vw_ref_eod') }}
    {% if var('start_date', none) and var('end_date', none) %}
    WHERE cob_date >= {{ ktl_autovault.timestamp(var('start_date')) }}
      AND cob_date <= {{ ktl_autovault.timestamp(var('end_date')) }}
    {% elif var('cob_date', none) %}
    WHERE cob_date = {{ ktl_autovault.timestamp(var('cob_date')) }}
    {% else %}
    WHERE cob_date = (SELECT MAX(cob_date) FROM {{ ref('vw_ref_eod') }})
    {% endif %}
),

DEDUPLICATED_SAT_GL AS (
    SELECT
        DV_HKEY_HUB_GL,
        CAST(EOD_DATE AS DATE) AS EOD_DATE,
        POS_CD,
        DR_CR_FLG,
        FCY_AMT * NUM_DUPLICATES AS FCY_AMT,
        LCY_AMT * NUM_DUPLICATES AS LCY_AMT
    FROM {{ ref('sat_gl') }}
    {% if is_incremental() %}
    WHERE DV_LDT > (SELECT MAX(last_run_time) FROM ref_dates)
      AND DV_LDT <= (SELECT MAX(run_time) FROM ref_dates)
    {% endif %}
),

CTE_BRANCH_GL_SBV AS (
    SELECT
        CAST(A.EOD_DATE AS DATE) AS EOD_DATE,
        A.POS_CD,
        CASE WHEN A.DR_CR_FLG='C' THEN A.FCY_AMT ELSE -A.FCY_AMT END AS FCY_AMT,
        CASE WHEN A.DR_CR_FLG='C' THEN A.LCY_AMT ELSE -A.LCY_AMT END AS LCY_AMT,
        B.AC_NO,
        C.SBV_GL_SL
    FROM DEDUPLICATED_SAT_GL A
    JOIN {{ ref('hub_gl') }} B ON A.DV_HKEY_HUB_GL = B.DV_HKEY_HUB_GL
    JOIN {{ ref('sat_snp_gl_sbv') }} C ON A.DV_HKEY_HUB_GL = C.DV_HKEY_HUB_GL AND A.POS_CD = C.POS_CD
    WHERE A.POS_CD <> 0
),

-- CTE to classify AC_NO by account type
ac_no_classification AS (
    SELECT 
        AC_NO,
        CASE 
            WHEN {{ ac_no_in_list('AC_NO', ac_no_map.ac_no_dp_kkh_cn) }} THEN 'KKH_CN'
            WHEN {{ ac_no_in_list('AC_NO', ac_no_map.ac_no_dp_ckh_cn) }} THEN 'CKH_CN'
            WHEN {{ ac_no_in_list('AC_NO', ac_no_map.ac_no_dp_kkh_tckt) }} THEN 'KKH_TCKT'
            WHEN {{ ac_no_in_list('AC_NO', ac_no_map.ac_no_dp_ckh_tckt) }} THEN 'CKH_TCKT'
            ELSE NULL
        END AS AC_TYPE
    FROM {{ ref('hub_gl') }}
),

CTE_FACT_DP AS (
    -- Deposit by AC_NO classification
    SELECT
        G.EOD_DATE AS COB_DATE,
        G.POS_CD AS BRANCH_CODE,
        CASE 
            WHEN C.AC_TYPE IN ('KKH_CN', 'CKH_CN') THEN 'CN'
            WHEN C.AC_TYPE IN ('KKH_TCKT', 'CKH_TCKT') THEN 'TCKT'
            ELSE NULL
        END AS CUSTOMER_TYPE,
        CASE 
            WHEN C.AC_TYPE IN ('KKH_CN', 'KKH_TCKT') THEN 'KKH'
            WHEN C.AC_TYPE IN ('CKH_CN', 'CKH_TCKT') THEN 'CKH'
            ELSE NULL
        END AS ACCOUNT_TYPE,
        CASE WHEN SUM(G.FCY_AMT) > 0 THEN SUM(G.FCY_AMT) ELSE 0 END AS FCY_CURR_BALANCE,
        CASE WHEN SUM(G.LCY_AMT) > 0 THEN SUM(G.LCY_AMT) ELSE 0 END AS LCY_CURR_BALANCE
    FROM CTE_BRANCH_GL_SBV G
    JOIN ac_no_classification C ON G.AC_NO = C.AC_NO
    WHERE C.AC_TYPE IS NOT NULL
    GROUP BY G.EOD_DATE, G.POS_CD, C.AC_TYPE

    UNION ALL

    -- GTCG (Giấy tờ có giá) - by SBV_GL prefix
    SELECT
        EOD_DATE AS COB_DATE,
        POS_CD AS BRANCH_CODE,
        'NULL' AS CUSTOMER_TYPE,
        'GTCG' AS ACCOUNT_TYPE,
        CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_CURR_BALANCE,
        CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_CURR_BALANCE
    FROM CTE_BRANCH_GL_SBV
    WHERE SUBSTR(SBV_GL_SL, 1, 2) IN ('43')
    GROUP BY EOD_DATE, POS_CD
)

SELECT
    A.COB_DATE,
    B.D_BRANCH_ID,
    A.BRANCH_CODE,
    A.CUSTOMER_TYPE,
    A.ACCOUNT_TYPE,
    A.FCY_CURR_BALANCE,
    A.LCY_CURR_BALANCE
FROM CTE_FACT_DP A
JOIN {{ ref('dim_branch') }} B 
    ON A.BRANCH_CODE = B.BRANCH_CODE
{% if is_incremental() %}
   AND A.COB_DATE >= B.EFF_FR_DT 
   AND A.COB_DATE <= B.EFF_TO_DT
{% else %}
   AND B.IN_USE_STATUS = 1
{% endif %}