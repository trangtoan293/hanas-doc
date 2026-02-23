
{#
    Intermediate Model: int_fact_dp
    Prepare Deposit data from Raw Vault for Fact Detail.
    This is where Business Logic (Account classification, Amount calculation) resides.
    
    NOTE: No incremental logic here. Incremental filtering is handled by the final model/macro.
#}

{% set ac_no_map = get_ac_no_mapping() %}

WITH sat_gl_base AS (
    SELECT
        DV_HKEY_HUB_GL,
        CAST(EOD_DATE AS DATE) AS COB_DATE,
        POS_CD AS BRANCH_CODE,
        DR_CR_FLG,
        FCY_AMT * NUM_DUPLICATES AS FCY_AMT,
        LCY_AMT * NUM_DUPLICATES AS LCY_AMT,
        DV_LDT
    FROM {{ ref('sat_gl') }}
),

hub_gl AS (
    SELECT 
        DV_HKEY_HUB_GL,
        AC_NO
    FROM {{ ref('hub_gl') }}
),

sat_snp_gl_sbv AS (
    SELECT
        DV_HKEY_HUB_GL,
        POS_CD,
        SBV_GL_SL
    FROM {{ ref('sat_snp_gl_sbv') }}
),

-- Join and calculate amounts
branch_gl AS (
    SELECT
        g.COB_DATE,
        g.BRANCH_CODE,
        g.DV_LDT,
        CASE WHEN g.DR_CR_FLG='C' THEN g.FCY_AMT ELSE -g.FCY_AMT END AS FCY_AMT,
        CASE WHEN g.DR_CR_FLG='C' THEN g.LCY_AMT ELSE -g.LCY_AMT END AS LCY_AMT,
        h.AC_NO,
        sbv.SBV_GL_SL
    FROM sat_gl_base g
    JOIN hub_gl h ON g.DV_HKEY_HUB_GL = h.DV_HKEY_HUB_GL
    JOIN sat_snp_gl_sbv sbv ON g.DV_HKEY_HUB_GL = sbv.DV_HKEY_HUB_GL AND g.BRANCH_CODE = sbv.POS_CD
    WHERE g.BRANCH_CODE <> 0
),

-- Classify accounts
ac_classification AS (
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

-- Main Deposit Logic
dp_main AS (
    SELECT
        g.COB_DATE,
        g.BRANCH_CODE,
        CASE 
            WHEN c.AC_TYPE IN ('KKH_CN', 'CKH_CN') THEN 'CN'
            WHEN c.AC_TYPE IN ('KKH_TCKT', 'CKH_TCKT') THEN 'TCKT'
            ELSE NULL
        END AS CUSTOMER_TYPE,
        CASE 
            WHEN c.AC_TYPE IN ('KKH_CN', 'KKH_TCKT') THEN 'KKH'
            WHEN c.AC_TYPE IN ('CKH_CN', 'CKH_TCKT') THEN 'CKH'
            ELSE NULL
        END AS ACCOUNT_TYPE,
        CASE WHEN SUM(g.FCY_AMT) > 0 THEN SUM(g.FCY_AMT) ELSE 0 END AS FCY_CURR_BALANCE,
        CASE WHEN SUM(g.LCY_AMT) > 0 THEN SUM(g.LCY_AMT) ELSE 0 END AS LCY_CURR_BALANCE,
        MAX(g.DV_LDT) AS DV_LDT
    FROM branch_gl g
    JOIN ac_classification c ON g.AC_NO = c.AC_NO
    WHERE c.AC_TYPE IS NOT NULL
    GROUP BY g.COB_DATE, g.BRANCH_CODE, c.AC_TYPE
),

-- GTCG (Giấy tờ có giá) Logic
dp_gtcg AS (
    SELECT
        g.COB_DATE,
        g.BRANCH_CODE,
        NULL AS CUSTOMER_TYPE,
        'GTCG' AS ACCOUNT_TYPE,
        CASE WHEN SUM(g.FCY_AMT) > 0 THEN SUM(g.FCY_AMT) ELSE 0 END AS FCY_CURR_BALANCE,
        CASE WHEN SUM(g.LCY_AMT) > 0 THEN SUM(g.LCY_AMT) ELSE 0 END AS LCY_CURR_BALANCE,
        MAX(g.DV_LDT) AS DV_LDT
    FROM branch_gl g
    WHERE SUBSTR(g.SBV_GL_SL, 1, 2) IN ('43')
    GROUP BY g.COB_DATE, g.BRANCH_CODE
)

SELECT * FROM dp_main
UNION ALL
SELECT * FROM dp_gtcg
