

{#
    Intermediate Model: int_fact_ln
    Prepare Loan data from Raw Vault for Fact Detail.
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

-- Classify loan accounts
ac_classification AS (
    SELECT 
        AC_NO,
        CASE 
            WHEN {{ ac_no_in_list('AC_NO', ac_no_map.ac_no_ln_ngan_han_cn) }} THEN 'NGAN_HAN_CN'
            WHEN {{ ac_no_in_list('AC_NO', ac_no_map.ac_no_ln_trung_dai_han_cn) }} THEN 'TRUNG_DAI_HAN_CN'
            WHEN {{ ac_no_in_list('AC_NO', ac_no_map.ac_no_ln_ngan_han_tckt) }} THEN 'NGAN_HAN_TCKT'
            WHEN {{ ac_no_in_list('AC_NO', ac_no_map.ac_no_ln_trung_dai_han_tckt) }} THEN 'TRUNG_DAI_HAN_TCKT'
            ELSE NULL
        END AS AC_TYPE,
        CASE 
            WHEN {{ ac_no_in_list('AC_NO', ac_no_map.ac_no_loan_npl) }} THEN 'NPL'
            WHEN {{ ac_no_in_list('AC_NO', ac_no_map.ac_no_loan_n2) }} THEN 'N2'
            ELSE 'N1'
        END AS DEBT_GRP
    FROM {{ ref('hub_gl') }}
)

SELECT
    g.COB_DATE,
    g.BRANCH_CODE,
    CASE 
        WHEN c.AC_TYPE LIKE '%_CN' THEN 'CN'
        WHEN c.AC_TYPE LIKE '%_TCKT' THEN 'TCKT'
        ELSE NULL
    END AS CUSTOMER_TYPE,
    CASE 
        WHEN c.AC_TYPE LIKE 'NGAN_HAN%' THEN 'NGAN HAN'
        WHEN c.AC_TYPE LIKE 'TRUNG_DAI_HAN%' THEN 'TRUNG DAI HAN'
        ELSE NULL
    END AS ACCOUNT_TYPE,
    c.DEBT_GRP,
    CASE WHEN SUM(g.FCY_AMT) > 0 THEN SUM(g.FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
    CASE WHEN SUM(g.LCY_AMT) > 0 THEN SUM(g.LCY_AMT) ELSE 0 END AS LCY_OUTSTND,
    MAX(g.DV_LDT) AS DV_LDT
FROM branch_gl g
JOIN ac_classification c ON g.AC_NO = c.AC_NO
WHERE c.AC_TYPE IS NOT NULL
GROUP BY g.COB_DATE, g.BRANCH_CODE, c.AC_TYPE, c.DEBT_GRP
