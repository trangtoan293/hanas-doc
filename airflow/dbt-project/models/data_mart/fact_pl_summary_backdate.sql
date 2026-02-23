{{ config(
    materialized = 'table',
    file_format='iceberg'
) }}

WITH     CTE_PL_TOTAL AS (
           select   COB_DATE,
                    D_BRANCH_ID,                                      
                    BRANCH_CODE,
                    PL_CODE,
                    sum(LCY_BALANCE) LCY_BALANCE
           from     (select           COB_DATE,
                                      D_BRANCH_ID,                                      
                                      BRANCH_CODE,
                                      PL_CODE,
                                      BAL_TODAY LCY_BALANCE                     
                     from             {{ ref('fact_pl_summary') }} aa
                     where PL_GRP='DETAIL'                       
                     UNION ALL select COB_DATE,
                                      D_BRANCH_ID,                                      
                                      BRANCH_CODE,
                                      PL_CODE,
                                      LCY_OUTSTND as LCY_BALANCE                                      
                     from             {{ ref('fact_pl_detail_backdate') }} aa
                     )
           group by COB_DATE,
                    D_BRANCH_ID,                                      
                    BRANCH_CODE,
                    PL_CODE
        )
        ,CTE_PL_CURR AS
    (
    select TT.COB_DATE,
           CAST(TT.ELM_DATE AS DATE) ELM_DATE,
           CAST(TT.ELY_DATE AS DATE) ELY_DATE,
           CAST(TT.DAY_AGO AS DATE) DAY_AGO,
           CAST(TT.BOM_DATE AS DATE) BOM_DATE,
           TT.DAY_IN_MONTH,
           PL.D_BRANCH_ID,
           PL.PL_CODE,    
           PL.LCY_BALANCE
    from CTE_PL_TOTAL PL
    JOIN {{ ref('dim_time') }} TT
                            ON PL.COB_DATE = TT.COB_DATE                                                     
    )    
    , CTE_PL_DAGO AS
    (
    select TT.COB_DATE,
           CAST(TT.ELM_DATE AS DATE) ELM_DATE,
           CAST(TT.ELY_DATE AS DATE) ELY_DATE,
           CAST(TT.DAY_AGO AS DATE) DAY_AGO,
           CAST(TT.BOM_DATE AS DATE) BOM_DATE,
           TT.DAY_IN_MONTH,
           PL.D_BRANCH_ID,
           PL.PL_CODE, 
           PL.LCY_BALANCE
    from CTE_PL_TOTAL PL
    JOIN {{ ref('dim_time') }} TT
                            ON PL.COB_DATE = TT.DAY_AGO
    WHERE PL.LCY_BALANCE <> 0                      
    )
    , CTE_PL_ELM AS
    (
        select TT.COB_DATE,
           CAST(TT.ELM_DATE AS DATE) ELM_DATE,
           CAST(TT.ELY_DATE AS DATE) ELY_DATE,
           CAST(TT.DAY_AGO AS DATE) DAY_AGO,
           CAST(TT.BOM_DATE AS DATE) BOM_DATE,
           TT.DAY_IN_MONTH,
           PL.D_BRANCH_ID,
           PL.PL_CODE,       
           PL.LCY_BALANCE
    from CTE_PL_TOTAL PL
    JOIN {{ ref('dim_time') }} TT
                            ON PL.COB_DATE = TT.ELM_DATE
WHERE PL.LCY_BALANCE <> 0                          
    )
    , CTE_PL_ELY AS
    (select TT.COB_DATE,
           CAST(TT.ELM_DATE AS DATE) ELM_DATE,
           CAST(TT.ELY_DATE AS DATE) ELY_DATE,
           CAST(TT.DAY_AGO AS DATE) DAY_AGO,
           CAST(TT.BOM_DATE AS DATE) BOM_DATE,       
           TT.DAY_IN_MONTH,
           PL.D_BRANCH_ID,
           PL.PL_CODE,       
           PL.LCY_BALANCE
    from CTE_PL_TOTAL PL
    JOIN {{ ref('dim_time') }} TT
                            ON PL.COB_DATE = TT.ELY_DATE
    WHERE PL.LCY_BALANCE <> 0                             
    )
    , CTE_PL_UNION AS
    (SELECT PL.COB_DATE,
           PL.ELM_DATE,
           PL.ELY_DATE,
           PL.DAY_AGO,
           PL.BOM_DATE,
           PL.DAY_IN_MONTH,
           PL.D_BRANCH_ID,
           PL.PL_CODE,
           PL.LCY_BALANCE BAL_TODAY,
           0 AS BAL_DAGO,
           0 AS BAL_ELM,
           0 AS BAL_ELY     
       FROM CTE_PL_CURR PL
    UNION ALL
    SELECT PL.COB_DATE,
           PL.ELM_DATE,
           PL.ELY_DATE,
           PL.DAY_AGO,
           PL.BOM_DATE,
           PL.DAY_IN_MONTH,
           PL.D_BRANCH_ID,
           PL.PL_CODE,
           0 AS BAL_TODAY,
           PL.LCY_BALANCE AS BAL_DAGO,
           0 AS BAL_ELM,
           0 AS BAL_ELY     
       FROM CTE_PL_DAGO PL   
    UNION ALL
    SELECT PL.COB_DATE,
           PL.ELM_DATE,
           PL.ELY_DATE,
           PL.DAY_AGO,
           PL.BOM_DATE,
           PL.DAY_IN_MONTH,
           PL.D_BRANCH_ID,
           PL.PL_CODE,
           0 AS BAL_TODAY,
           0 AS BAL_DAGO,
           PL.LCY_BALANCE AS BAL_ELM,
           0 AS BAL_ELY       
       FROM CTE_PL_ELM PL
    UNION ALL
    SELECT PL.COB_DATE,
           PL.ELM_DATE,
           PL.ELY_DATE,
           PL.DAY_AGO,
           PL.BOM_DATE,
           PL.DAY_IN_MONTH,
           PL.D_BRANCH_ID,
           PL.PL_CODE,
           0 AS BAL_TODAY,
           0 AS BAL_DAGO,
           0 AS BAL_ELM,
           PL.LCY_BALANCE AS BAL_ELY
       FROM CTE_PL_ELY PL 
    )
    --CHI TIET 7,8
    SELECT AA.COB_DATE,
           AA.ELM_DATE,
           AA.ELY_DATE,
           AA.DAY_AGO,
           AA.BOM_DATE,
           AA.DAY_IN_MONTH,
           AA.D_BRANCH_ID,
           'DETAIL' AS PL_GRP,
           CC.PL_CODE AS PL_CODE,
           CC.PL_NAME AS PL_NAME,
           BB.BRANCH_CODE, 
           BB.BRANCH_NAME,
           BB.PARENT_CODE,
           BB.PARENT_NAME,
           BB.KV_NAME,
           SUM(AA.BAL_TODAY) BAL_TODAY,
           SUM(AA.BAL_DAGO) BAL_DAGO,
           SUM(AA.BAL_ELM) BAL_ELM,
           SUM(AA.BAL_ELY) BAL_ELY,
           MAX(BB.NBR_STAFF) as NBR_STAFF
    FROM CTE_PL_UNION AA
    JOIN {{ ref('dim_branch') }} BB
                           ON BB.D_BRANCH_ID=AA.D_BRANCH_ID
    JOIN {{ ref('dim_pl_item') }} CC
                           ON CC.PL_CODE = AA.PL_CODE    
    WHERE CC.PL_MAIN_CODE IN (7,8,9)                                                     
    GROUP BY     
            AA.COB_DATE,
           AA.ELM_DATE,
           AA.ELY_DATE,
           AA.DAY_AGO,
           AA.BOM_DATE,
           AA.DAY_IN_MONTH,
           AA.D_BRANCH_ID,
           CC.PL_CODE,
           CC.PL_NAME,
           BB.BRANCH_CODE, 
           BB.BRANCH_NAME,
           BB.PARENT_CODE,
           BB.PARENT_NAME,
           BB.KV_NAME              
    UNION ALL
    --TONG 7,8,9
    SELECT AA.COB_DATE,
           AA.ELM_DATE,
           AA.ELY_DATE,
           AA.DAY_AGO,
           AA.BOM_DATE,
           AA.DAY_IN_MONTH,
           AA.D_BRANCH_ID,
           'TOTAL' AS PL_GRP,
           CC.PL_MAIN_CODE AS PL_CODE,
           CC.PL_MAIN_NAME AS PL_NAME,
           BB.BRANCH_CODE, 
           BB.BRANCH_NAME,
           BB.PARENT_CODE,
           BB.PARENT_NAME,
           BB.KV_NAME,
           SUM(AA.BAL_TODAY) BAL_TODAY,
           SUM(AA.BAL_DAGO) BAL_DAGO,
           SUM(AA.BAL_ELM) BAL_ELM,
           SUM(AA.BAL_ELY) BAL_ELY,
           MAX(BB.NBR_STAFF) as NBR_STAFF
    FROM CTE_PL_UNION AA
    JOIN {{ ref('dim_branch') }} BB
                           ON BB.D_BRANCH_ID=AA.D_BRANCH_ID
    JOIN {{ ref('dim_pl_item') }} CC
                           ON CC.PL_CODE = AA.PL_CODE 
    WHERE  CC.PL_MAIN_CODE IN (7,8,9)                                                                             
    GROUP BY    
            AA.COB_DATE,
           AA.ELM_DATE,
           AA.ELY_DATE,
           AA.DAY_AGO,
           AA.BOM_DATE,
           AA.DAY_IN_MONTH,
           AA.D_BRANCH_ID,
           CC.PL_MAIN_CODE,
           CC.PL_MAIN_NAME,
           BB.BRANCH_CODE, 
           BB.BRANCH_NAME,
           BB.PARENT_CODE,
           BB.PARENT_NAME,
           BB.KV_NAME    
    UNION ALL
    --TONG 10 = 7-8-9
    SELECT AA.COB_DATE,
           AA.ELM_DATE,
           AA.ELY_DATE,
           AA.DAY_AGO,
           AA.BOM_DATE,
           AA.DAY_IN_MONTH,
           AA.D_BRANCH_ID,
           'TOTAL' AS PL_GRP,
           10 AS PL_CODE,
           'Lợi nhuận trước thuế' AS PL_NAME,
           BB.BRANCH_CODE, 
           BB.BRANCH_NAME,
           BB.PARENT_CODE,
           BB.PARENT_NAME,
           BB.KV_NAME,
           SUM(CASE WHEN CC.PL_MAIN_CODE =7 THEN AA.BAL_TODAY ELSE -AA.BAL_TODAY END) BAL_TODAY,
           SUM(CASE WHEN CC.PL_MAIN_CODE =7 THEN AA.BAL_DAGO ELSE -AA.BAL_DAGO END) BAL_DAGO,
           SUM(CASE WHEN CC.PL_MAIN_CODE =7 THEN AA.BAL_ELM ELSE -AA.BAL_ELM END) BAL_ELM,
           SUM(CASE WHEN CC.PL_MAIN_CODE =7 THEN AA.BAL_ELY ELSE -AA.BAL_ELY END) BAL_ELY,
           MAX(BB.NBR_STAFF) as NBR_STAFF
    FROM CTE_PL_UNION AA
    JOIN {{ ref('dim_branch') }} BB
                           ON BB.D_BRANCH_ID=AA.D_BRANCH_ID
    JOIN {{ ref('dim_pl_item') }} CC
                           ON CC.PL_CODE = AA.PL_CODE 
    WHERE  CC.PL_MAIN_CODE IN (7,8,9)                                                                             
    GROUP BY    
            AA.COB_DATE,
           AA.ELM_DATE,
           AA.ELY_DATE,
           AA.DAY_AGO,
           AA.BOM_DATE,
           AA.DAY_IN_MONTH,
           AA.D_BRANCH_ID,
           BB.BRANCH_CODE, 
           BB.BRANCH_NAME,
           BB.PARENT_CODE,
           BB.PARENT_NAME,
           BB.KV_NAME