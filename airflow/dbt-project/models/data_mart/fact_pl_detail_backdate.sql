{{ config(
    materialized = 'table',
    file_format='iceberg'
) }}

with
gl_sbv as (
    select distinct
        sbv_gl_sl,
        pos_cd,
        ac_no as bank_ac
    from {{ ref('sat_snp_gl_sbv') }} s
    left join {{ ref('hub_gl') }} h on s.dv_hkey_hub_gl = h.dv_hkey_hub_gl
),

gl_poc_backdate as (
    select
        cast(EOD_DATE as DATE) as EOD_DATE,
        cast(value_date as DATE) as value_date,
        pos_cd,
        AC_NO,
        DR_CR_FLG,
        LCY_AMT,
        FCY_AMT
    from {{ source('landing', 'gl_poc_backdate') }}
),

CTE_BRANCH_GL_SBV AS (
           select     COB_DATE as EOD_DATE,
                      poc_bd.pos_cd,
                      AC_NO,
                      DR_CR_FLG,
                      CASE WHEN DR_CR_FLG = 'C' THEN cast(poc_bd.FCY_AMT as DECIMAL) ELSE - cast(poc_bd.FCY_AMT as DECIMAL) END AS FCY_AMT,
                      CASE WHEN DR_CR_FLG = 'C' THEN cast(poc_bd.LCY_AMT as DECIMAL) ELSE - cast(poc_bd.LCY_AMT as DECIMAL) END AS LCY_AMT,
                      SBV_GL_SL
           from       gl_poc_backdate poc_bd
           cross join {{ ref('dim_time') }} dt
           join       gl_sbv
           on         poc_bd.AC_NO = gl_sbv.bank_ac and
                      poc_bd.pos_cd = gl_sbv.pos_cd
           where      1 = 1 and
                      dt.cob_date between poc_bd.value_date and LAST_DAY(poc_bd.value_date) and
                      poc_bd.pos_cd <> 0),
         FACT_PL AS (
           SELECT           EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.1' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('70') AND
                            SUBSTR(SBV_GL_SL, 1, 4) NOT IN ('7060')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.1' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            AC_NO IN (
                              '9446027046',
                              '9409117045',
                              '9409407043')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.1' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) < 0 THEN - SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) < 0 THEN - SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('80')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.2' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('71')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.2' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) < 0 THEN - SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) < 0 THEN - SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            AC_NO IN (
                              '9446027046',
                              '9409117045',
                              '9409407043',
                              '9400297045',
                              '9421007049',
                              '9421337049')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.2' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) < 0 THEN - SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) < 0 THEN - SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('81')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.2' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) < 0 THEN - SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) < 0 THEN - SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            AC_NO IN ('9346137049')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.2' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) < 0 THEN - SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) < 0 THEN - SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            AC_NO IN (
                              '9334227042',
                              '9334237045')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.3' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('72')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.3' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) < 0 THEN - SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) < 0 THEN - SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('82')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.4' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('74')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.4' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) < 0 THEN - SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) < 0 THEN - SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('84') AND
                            SUBSTR(SBV_GL_SL, 1, 3) NOT IN ('849')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.4' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) < 0 THEN - SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) < 0 THEN - SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            AC_NO IN (
                              '9418987046',
                              '9420287048',
                              '9420297041')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.5' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            AC_NO IN (
                              '9418987046',
                              '9421347042',
                              '9422207042',
                              '9422607040',
                              '9422917044',
                              '9422918409',
                              '9422927047',
                              '9422947043',
                              '9422957046',
                              '9422987045',
                              '9422997048',
                              '9423807043')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.5' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) < 0 THEN - SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) < 0 THEN - SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('89') OR
                            SUBSTR(SBV_GL_SL, 1, 3) IN ('849')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '7.6' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('78')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '8.1' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 2) IN ('85')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '8.2' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            AC_NO IN (
                              '9300307048',
                              '9330147045',
                              '9330167041',
                              '9330087040',
                              '9326007047',
                              '9326017040',
                              '9330027042',
                              '9333167048',
                              '9330017049',
                              '9330107043',
                              '9330077047',
                              '9345337044',
                              '9345327041',
                              '9330137042',
                              '9330277041',
                              '9330287044',
                              '9330297047',
                              '9300957045',
                              '9300917043',
                              '9300927046',
                              '9300937049',
                              '9300947042',
                              '9330317040',
                              '9330937048',
                              '9330267048',
                              '9333707042',
                              '9326027043',
                              '9330007046')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '8.3' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            (SUBSTR(SBV_GL_SL, 1, 2) IN (
                               '83',
                               '86',
                               '87') OR
                             SUBSTR(SBV_GL_SL, 1, 4) IN ('8826')) AND
                            SUBSTR(SBV_GL_SL, 1, 4) NOT IN ('8330')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '8.4' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 4) IN ('8830')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '9.1' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) > 0 THEN SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) > 0 THEN SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            SUBSTR(SBV_GL_SL, 1, 3) IN ('882')
           GROUP BY         EOD_DATE,
                            POS_CD
           UNION ALL SELECT EOD_DATE AS COB_DATE,
                            POS_CD AS BRANCH_CODE,
                            '9.1' AS PL_CODE,
                            CASE WHEN SUM(FCY_AMT) < 0 THEN - SUM(FCY_AMT) ELSE 0 END AS FCY_OUTSTND,
                            CASE WHEN SUM(LCY_AMT) < 0 THEN - SUM(LCY_AMT) ELSE 0 END AS LCY_OUTSTND
           FROM             CTE_BRANCH_GL_SBV
           WHERE            AC_NO IN (
                              '9422074181',
                              '9422127041',
                              '9422167043',
                              '9422177046',
                              '9422217045',
                              '9422227048',
                              '9422247044',
                              '9422307049',
                              '9422314184',
                              '9422317042',
                              '9422484182',
                              '9422507043',
                              '9423027043',
                              '9423907040',
                              '9423917043')
           GROUP BY         EOD_DATE,
                            POS_CD)
SELECT   A.COB_DATE,
         B.D_BRANCH_ID,
         A.BRANCH_CODE,
         A.PL_CODE,
         sum(A.FCY_OUTSTND) as FCY_OUTSTND,
         sum(A.LCY_OUTSTND) as LCY_OUTSTND
FROM     FACT_PL A
JOIN     {{ ref('dim_branch') }} B
ON       A.BRANCH_CODE = B.BRANCH_CODE
group by A.COB_DATE,
         B.D_BRANCH_ID,
         A.BRANCH_CODE,
         A.PL_CODE