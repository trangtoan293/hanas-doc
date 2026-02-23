{{ config(
    materialized = 'table',
    file_format='iceberg'
) }}

WITH     CTE_DP_TOTAL AS (
           select   COB_DATE,
                    D_BRANCH_ID,
                    CUSTOMER_TYPE,
                    ACCOUNT_TYPE,
                    BRANCH_CODE,
                    sum(LCY_CURR_BALANCE) LCY_CURR_BALANCE
           from     (select           COB_DATE,
                                      D_BRANCH_ID,
                                      COALESCE(CUSTOMER_TYPE, 'NA') CUSTOMER_TYPE,
                                      ACCOUNT_TYPE,
                                      BRANCH_CODE,
                                      BAL_TODAY LCY_CURR_BALANCE
                     from             {{ ref('fact_dp_summary') }} aa
                     UNION ALL select COB_DATE,
                                      D_BRANCH_ID,
                                      COALESCE(CUSTOMER_TYPE, 'NA') CUSTOMER_TYPE,
                                      ACCOUNT_TYPE,
                                      BRANCH_CODE,
                                      LCY_CURR_BALANCE
                     from             {{ ref('fact_dp_detail_backdate') }}
                     )
           group by COB_DATE,
                    D_BRANCH_ID,
                    CUSTOMER_TYPE,
                    ACCOUNT_TYPE,
                    BRANCH_CODE
        )
        ,CTE_DP_CURR AS 
        (
           select TT.COB_DATE,
                  CAST(TT.ELM_DATE AS DATE) ELM_DATE,
                  CAST(TT.ELY_DATE AS DATE) ELY_DATE,
                  CAST(TT.DAY_AGO AS DATE) DAY_AGO,
                  CAST(TT.BOM_DATE AS DATE) BOM_DATE,
                  TT.DAY_IN_MONTH,
                  DP.D_BRANCH_ID,
                  DP.CUSTOMER_TYPE,
                  DP.ACCOUNT_TYPE,
                  DP.LCY_CURR_BALANCE
           from   CTE_DP_TOTAL DP
           JOIN   {{ ref('dim_time') }} TT
           ON     DP.COB_DATE = TT.COB_DATE
        )
        ,
         CTE_DP_DAGO AS (
           select TT.COB_DATE,
                  CAST(TT.ELM_DATE AS DATE) ELM_DATE,
                  CAST(TT.ELY_DATE AS DATE) ELY_DATE,
                  CAST(TT.DAY_AGO AS DATE) DAY_AGO,
                  CAST(TT.BOM_DATE AS DATE) BOM_DATE,
                  TT.DAY_IN_MONTH,
                  DP.D_BRANCH_ID,
                  DP.CUSTOMER_TYPE,
                  DP.ACCOUNT_TYPE,
                  DP.LCY_CURR_BALANCE
           from   CTE_DP_TOTAL DP
           JOIN   {{ ref('dim_time') }} TT
           ON     DP.COB_DATE = TT.DAY_AGO)
        ,
         CTE_DP_ELM AS 
        (
           select TT.COB_DATE,
                  CAST(TT.ELM_DATE AS DATE) ELM_DATE,
                  CAST(TT.ELY_DATE AS DATE) ELY_DATE,
                  CAST(TT.DAY_AGO AS DATE) DAY_AGO,
                  CAST(TT.BOM_DATE AS DATE) BOM_DATE,
                  TT.DAY_IN_MONTH,
                  DP.D_BRANCH_ID,
                  DP.CUSTOMER_TYPE,
                  DP.ACCOUNT_TYPE,
                  DP.LCY_CURR_BALANCE
           from   CTE_DP_TOTAL DP
           JOIN   {{ ref('dim_time') }} TT
           ON     DP.COB_DATE = TT.ELM_DATE
        ),
         CTE_DP_ELY AS 
        (
           select TT.COB_DATE,
                  CAST(TT.ELM_DATE AS DATE) ELM_DATE,
                  CAST(TT.ELY_DATE AS DATE) ELY_DATE,
                  CAST(TT.DAY_AGO AS DATE) DAY_AGO,
                  CAST(TT.BOM_DATE AS DATE) BOM_DATE,
                  TT.DAY_IN_MONTH,
                  DP.D_BRANCH_ID,
                  DP.CUSTOMER_TYPE,
                  DP.ACCOUNT_TYPE,
                  DP.LCY_CURR_BALANCE
           from   CTE_DP_TOTAL DP
           JOIN   {{ ref('dim_time') }} TT
           ON     DP.COB_DATE = TT.ELY_DATE
        ),
         CTE_DP_MTD AS 
        (
           select   SS.COB_DATE,
                    SS.ELM_DATE,
                    SS.ELY_DATE,
                    SS.DAY_AGO,
                    SS.BOM_DATE,
                    SS.DAY_IN_MONTH,
                    SS.D_BRANCH_ID,
                    SS.CUSTOMER_TYPE,
                    SS.ACCOUNT_TYPE,
                    SUM(SS.LCY_CURR_BALANCE) LCY_CURR_BALANCE
           FROM     (select DP.COB_DATE,
                            DP.ELM_DATE,
                            DP.ELY_DATE,
                            DP.DAY_AGO,
                            DP.BOM_DATE,
                            DP.DAY_IN_MONTH,
                            DP.D_BRANCH_ID,
                            DP.CUSTOMER_TYPE,
                            DP.ACCOUNT_TYPE,
                            TT.LCY_CURR_BALANCE
                     from   CTE_DP_CURR DP
                     JOIN   CTE_DP_CURR TT
                     ON     TT.COB_DATE BETWEEN DP.BOM_DATE AND
                            DP.COB_DATE AND
                            DP.D_BRANCH_ID = TT.D_BRANCH_ID AND
                            DP.CUSTOMER_TYPE = TT.CUSTOMER_TYPE AND
                            DP.ACCOUNT_TYPE = TT.ACCOUNT_TYPE
                    ) SS
           GROUP BY SS.COB_DATE,
                    SS.ELM_DATE,
                    SS.ELY_DATE,
                    SS.DAY_AGO,
                    SS.BOM_DATE,
                    SS.DAY_IN_MONTH,
                    SS.D_BRANCH_ID,
                    SS.CUSTOMER_TYPE,
                    SS.ACCOUNT_TYPE
        )         
SELECT   AA.COB_DATE,
         AA.ELM_DATE,
         AA.ELY_DATE,
         AA.DAY_AGO,
         AA.BOM_DATE,
         AA.DAY_IN_MONTH,
         AA.D_BRANCH_ID,
         AA.CUSTOMER_TYPE,
         AA.ACCOUNT_TYPE,
         BB.BRANCH_CODE,
         BB.BRANCH_NAME,
         BB.PARENT_CODE,
         BB.PARENT_NAME,
         BB.KV_NAME,
         SUM(AA.BAL_TODAY) BAL_TODAY,
         SUM(AA.BAL_DAGO) BAL_DAGO,
         SUM(AA.BAL_ELM) BAL_ELM,
         SUM(AA.BAL_ELY) BAL_ELY,
         SUM(AA.BAL_MTD) BAL_MTD,
         SUM(AA.BAL_MTD) / AA.DAY_IN_MONTH AS AVG_BAL_MTD
FROM     (SELECT           DP.COB_DATE,
                           DP.ELM_DATE,
                           DP.ELY_DATE,
                           DP.DAY_AGO,
                           DP.BOM_DATE,
                           DP.DAY_IN_MONTH,
                           DP.D_BRANCH_ID,
                           DP.CUSTOMER_TYPE,
                           DP.ACCOUNT_TYPE,
                           DP.LCY_CURR_BALANCE BAL_TODAY,
                           0 AS BAL_DAGO,
                           0 AS BAL_ELM,
                           0 AS BAL_ELY,
                           0 AS BAL_MTD
          FROM             CTE_DP_CURR DP
          UNION ALL SELECT DP.COB_DATE,
                           DP.ELM_DATE,
                           DP.ELY_DATE,
                           DP.DAY_AGO,
                           DP.BOM_DATE,
                           DP.DAY_IN_MONTH,
                           DP.D_BRANCH_ID,
                           DP.CUSTOMER_TYPE,
                           DP.ACCOUNT_TYPE,
                           0 AS BAL_TODAY,
                           DP.LCY_CURR_BALANCE AS BAL_DAGO,
                           0 AS BAL_ELM,
                           0 AS BAL_ELY,
                           0 AS BAL_MTD
          FROM             CTE_DP_DAGO DP
          UNION ALL SELECT DP.COB_DATE,
                           DP.ELM_DATE,
                           DP.ELY_DATE,
                           DP.DAY_AGO,
                           DP.BOM_DATE,
                           DP.DAY_IN_MONTH,
                           DP.D_BRANCH_ID,
                           DP.CUSTOMER_TYPE,
                           DP.ACCOUNT_TYPE,
                           0 AS BAL_TODAY,
                           0 AS BAL_DAGO,
                           DP.LCY_CURR_BALANCE AS BAL_ELM,
                           0 AS BAL_ELY,
                           0 AS BAL_MTD
          FROM             CTE_DP_ELM DP
          UNION ALL SELECT DP.COB_DATE,
                           DP.ELM_DATE,
                           DP.ELY_DATE,
                           DP.DAY_AGO,
                           DP.BOM_DATE,
                           DP.DAY_IN_MONTH,
                           DP.D_BRANCH_ID,
                           DP.CUSTOMER_TYPE,
                           DP.ACCOUNT_TYPE,
                           0 AS BAL_TODAY,
                           0 AS BAL_DAGO,
                           0 AS BAL_ELM,
                           DP.LCY_CURR_BALANCE AS BAL_ELY,
                           0 AS BAL_MTD
          FROM             CTE_DP_ELY DP
          UNION ALL SELECT DP.COB_DATE,
                           DP.ELM_DATE,
                           DP.ELY_DATE,
                           DP.DAY_AGO,
                           DP.BOM_DATE,
                           DP.DAY_IN_MONTH,
                           DP.D_BRANCH_ID,
                           DP.CUSTOMER_TYPE,
                           DP.ACCOUNT_TYPE,
                           0 AS BAL_TODAY,
                           0 AS BAL_DAGO,
                           0 AS BAL_ELM,
                           0 AS BAL_ELY,
                           DP.LCY_CURR_BALANCE AS BAL_MTD
          FROM             CTE_DP_MTD DP
         ) AA
JOIN     {{ ref('dim_branch') }} BB
ON       BB.D_BRANCH_ID = AA.D_BRANCH_ID
GROUP BY AA.COB_DATE,
         AA.ELM_DATE,
         AA.ELY_DATE,
         AA.DAY_AGO,
         AA.BOM_DATE,
         AA.DAY_IN_MONTH,
         AA.D_BRANCH_ID,
         AA.CUSTOMER_TYPE,
         AA.ACCOUNT_TYPE,
         BB.BRANCH_CODE,
         BB.BRANCH_NAME,
         BB.PARENT_CODE,
         BB.PARENT_NAME,
         BB.KV_NAME