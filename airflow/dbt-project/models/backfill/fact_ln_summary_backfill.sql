{{ config(
    materialized = 'table',
    file_format='iceberg',
    schema='backfill'
) }}

{#-
    Backfill version of fact_ln_summary
    References fact_ln_detail_backfill instead of fact_ln_detail
-#}

WITH CTE_LN_CURR AS
(
select TT.COB_DATE,
       CAST(TT.ELM_DATE AS DATE) ELM_DATE,
       CAST(TT.ELY_DATE AS DATE) ELY_DATE,
       CAST(TT.DAY_AGO AS DATE) DAY_AGO,
       CAST(TT.BOM_DATE AS DATE) BOM_DATE,
       TT.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       CL.DEBT_GRP,
       CL.LCY_OUTSTND
from {{ ref('fact_ln_detail_backfill') }} CL
JOIN {{ ref('dim_time') }} TT
                        ON CL.COB_DATE = TT.COB_DATE  
)
, CTE_LN_DAGO AS
(
select TT.COB_DATE,
       CAST(TT.ELM_DATE AS DATE) ELM_DATE,
       CAST(TT.ELY_DATE AS DATE) ELY_DATE,
       CAST(TT.DAY_AGO AS DATE) DAY_AGO,
       CAST(TT.BOM_DATE AS DATE) BOM_DATE,
       TT.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       CL.DEBT_GRP,
       CL.LCY_OUTSTND
from {{ ref('fact_ln_detail_backfill') }} CL
JOIN {{ ref('dim_time') }} TT
                        ON CL.COB_DATE = TT.DAY_AGO
)
, CTE_LN_ELM AS
(select TT.COB_DATE,
       CAST(TT.ELM_DATE AS DATE) ELM_DATE,
       CAST(TT.ELY_DATE AS DATE) ELY_DATE,
       CAST(TT.DAY_AGO AS DATE) DAY_AGO,
       CAST(TT.BOM_DATE AS DATE) BOM_DATE,
       TT.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       CL.DEBT_GRP,
       CL.LCY_OUTSTND
from {{ ref('fact_ln_detail_backfill') }} CL
JOIN {{ ref('dim_time') }} TT
                        ON CL.COB_DATE = TT.ELM_DATE
)
, CTE_LN_ELY AS
(select TT.COB_DATE,
       CAST(TT.ELM_DATE AS DATE) ELM_DATE,
       CAST(TT.ELY_DATE AS DATE) ELY_DATE,
       CAST(TT.DAY_AGO AS DATE) DAY_AGO,
       CAST(TT.BOM_DATE AS DATE) BOM_DATE,       
       TT.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       CL.DEBT_GRP,
       CL.LCY_OUTSTND 
from {{ ref('fact_ln_detail_backfill') }} CL
JOIN {{ ref('dim_time') }} TT
                        ON CL.COB_DATE = TT.ELY_DATE
)
,CTE_LN_MTD AS
(
select SS.COB_DATE,
       SS.ELM_DATE,
       SS.ELY_DATE,
       SS.DAY_AGO,
       SS.BOM_DATE,
       SS.DAY_IN_MONTH,
       SS.D_BRANCH_ID,
       SS.CUSTOMER_TYPE,
       SS.ACCOUNT_TYPE,
       SS.DEBT_GRP,
       SUM(SS.LCY_OUTSTND) LCY_OUTSTND
FROM
    (           
    select CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       CL.DEBT_GRP,
       TT.LCY_OUTSTND
    from CTE_LN_CURR CL
    JOIN CTE_LN_CURR TT
               ON TT.COB_DATE BETWEEN CL.BOM_DATE AND CL.COB_DATE  
              AND CL.D_BRANCH_ID = TT.D_BRANCH_ID
              AND CL.CUSTOMER_TYPE=TT.CUSTOMER_TYPE 
              AND CL.ACCOUNT_TYPE=TT.ACCOUNT_TYPE
              AND CL.DEBT_GRP = TT.DEBT_GRP   
    ) SS
GROUP BY
       SS.COB_DATE,
       SS.ELM_DATE,
       SS.ELY_DATE,
       SS.DAY_AGO,
       SS.BOM_DATE,
       SS.DAY_IN_MONTH,
       SS.D_BRANCH_ID,
       SS.CUSTOMER_TYPE,
       SS.ACCOUNT_TYPE,
       SS.DEBT_GRP                    
)
SELECT AA.COB_DATE,
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
       SUM(AA.OUTSTND_TODAY) OUTSTND_TODAY,
       SUM(AA.OUTSTND_DAGO) OUTSTND_DAGO,
       SUM(AA.OUTSTND_ELM) OUTSTND_ELM,
       SUM(AA.OUTSTND_ELY) OUTSTND_ELY,
       SUM(AA.OUTSTND_MTD) OUTSTND_MTD,
       SUM(AA.OUTSTND_MTD)/AA.DAY_IN_MONTH AS AVG_OUTSTND_MTD,
       SUM(AA.NPL_TODAY) NPL_TODAY,       
       SUM(AA.NPL_ELM) NPL_ELM,
       SUM(AA.NPL_ELY) NPL_ELY,
       SUM(AA.OVD_TODAY) OVD_TODAY,
       SUM(AA.OVD_ELM) OVD_ELM,
       SUM(AA.OVD_ELY) OVD_ELY
FROM       
(
    SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       CL.LCY_OUTSTND OUTSTND_TODAY,
       0 AS OUTSTND_DAGO,
       0 AS OUTSTND_ELM,
       0 AS OUTSTND_ELY,
       0 AS OUTSTND_MTD,
       0 AS NPL_TODAY,       
       0 AS NPL_ELM,
       0 AS NPL_ELY,
       0 AS OVD_TODAY,
       0 AS OVD_ELM,
       0 AS OVD_ELY       
   FROM CTE_LN_CURR CL
UNION ALL
SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       0 AS OUTSTND_TODAY,
       CL.LCY_OUTSTND AS OUTSTND_DAGO,
       0 AS OUTSTND_ELM,
       0 AS OUTSTND_ELY,
       0 AS OUTSTND_MTD,
       0 AS NPL_TODAY,       
       0 AS NPL_ELM,
       0 AS NPL_ELY,
       0 AS OVD_TODAY,
       0 AS OVD_ELM,
       0 AS OVD_ELY       
   FROM CTE_LN_DAGO CL   
UNION ALL
SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       0 AS OUTSTND_TODAY,
       0 AS OUTSTND_DAGO,
       CL.LCY_OUTSTND AS OUTSTND_ELM,
       0 AS OUTSTND_ELY,
       0 AS OUTSTND_MTD,
       0 AS NPL_TODAY,       
       0 AS NPL_ELM,
       0 AS NPL_ELY,
       0 AS OVD_TODAY,
       0 AS OVD_ELM,
       0 AS OVD_ELY
   FROM CTE_LN_ELM CL
UNION ALL
SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       0 AS OUTSTND_TODAY,
       0 AS OUTSTND_DAGO,
       0 AS OUTSTND_ELM,
       CL.LCY_OUTSTND AS OUTSTND_ELY,
       0 AS OUTSTND_MTD,
       0 AS NPL_TODAY,       
       0 AS NPL_ELM,
       0 AS NPL_ELY,
       0 AS OVD_TODAY,
       0 AS OVD_ELM,
       0 AS OVD_ELY       
   FROM CTE_LN_ELY CL 
UNION ALL
SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       0 AS OUTSTND_TODAY,
       0 AS OUTSTND_DAGO,
       0 AS OUTSTND_ELM,
       0 AS OUTSTND_ELY,
       CL.LCY_OUTSTND AS OUTSTND_MTD,
       0 AS NPL_TODAY,       
       0 AS NPL_ELM,
       0 AS NPL_ELY,
       0 AS OVD_TODAY,
       0 AS OVD_ELM,
       0 AS OVD_ELY        
   FROM CTE_LN_MTD CL
UNION ALL
SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       0 AS OUTSTND_TODAY,
       0 AS OUTSTND_DAGO,
       0 AS OUTSTND_ELM,
       0 AS OUTSTND_ELY,
       0 AS OUTSTND_MTD,
       CL.LCY_OUTSTND*0.03 NPL_TODAY,       
       0 AS NPL_ELM,
       0 AS NPL_ELY,
       0 AS OVD_TODAY,
       0 AS OVD_ELM,
       0 AS OVD_ELY
   FROM CTE_LN_CURR CL
UNION ALL
SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       0 AS OUTSTND_TODAY,
       0 AS OUTSTND_DAGO,
       0 AS OUTSTND_ELM,
       0 AS OUTSTND_ELY,
       0 AS OUTSTND_MTD,
       0 AS NPL_TODAY,       
       CL.LCY_OUTSTND*0.03 AS NPL_ELM,
       0 AS NPL_ELY,
       0 AS OVD_TODAY,
       0 AS OVD_ELM,
       0 AS OVD_ELY
   FROM CTE_LN_ELM CL
UNION ALL
SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       0 AS OUTSTND_TODAY,
       0 AS OUTSTND_DAGO,
       0 AS OUTSTND_ELM,
       0 AS OUTSTND_ELY,
       0 AS OUTSTND_MTD,
       0 AS NPL_TODAY,       
       0 AS NPL_ELM,
       CL.LCY_OUTSTND*0.03 AS NPL_ELY,
       0 AS OVD_TODAY,
       0 AS OVD_ELM,
       0 AS OVD_ELY       
   FROM CTE_LN_ELY CL   
UNION ALL
SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       0 AS OUTSTND_TODAY,
       0 AS OUTSTND_DAGO,
       0 AS OUTSTND_ELM,
       0 AS OUTSTND_ELY,
       0 AS OUTSTND_MTD,
       0 AS NPL_TODAY,       
       0 AS NPL_ELM,
       0 AS NPL_ELY,
       CL.LCY_OUTSTND*0.05 AS OVD_TODAY,
       0 AS OVD_ELM,
       0 AS OVD_ELY
   FROM CTE_LN_CURR CL
UNION ALL
SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       0 AS OUTSTND_TODAY,
       0 AS OUTSTND_DAGO,
       0 AS OUTSTND_ELM,
       0 AS OUTSTND_ELY,
       0 AS OUTSTND_MTD,
       0 AS NPL_TODAY,       
       0 AS NPL_ELM,
       0 AS NPL_ELY,
       0 AS OVD_TODAY,
       CL.LCY_OUTSTND*0.05 AS OVD_ELM,
       0 AS OVD_ELY
   FROM CTE_LN_ELM CL
UNION ALL
SELECT CL.COB_DATE,
       CL.ELM_DATE,
       CL.ELY_DATE,
       CL.DAY_AGO,
       CL.BOM_DATE,
       CL.DAY_IN_MONTH,
       CL.D_BRANCH_ID,
       CL.CUSTOMER_TYPE,
       CL.ACCOUNT_TYPE,
       0 AS OUTSTND_TODAY,
       0 AS OUTSTND_DAGO,
       0 AS OUTSTND_ELM,
       0 AS OUTSTND_ELY,
       0 AS OUTSTND_MTD,
       0 AS NPL_TODAY,       
       0 AS NPL_ELM,
       0 AS NPL_ELY,
       0 AS OVD_TODAY,
       0 AS OVD_ELM,
       CL.LCY_OUTSTND*0.05 AS OVD_ELY       
   FROM CTE_LN_ELY CL   
)  AA
JOIN {{ ref('dim_branch') }} BB
                       ON BB.D_BRANCH_ID=AA.D_BRANCH_ID
GROUP BY    
        AA.COB_DATE,
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
