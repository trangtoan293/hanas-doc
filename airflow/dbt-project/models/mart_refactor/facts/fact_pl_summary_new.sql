{{
    config(
        materialized='incremental',
        file_format='iceberg',
        incremental_strategy='insert_overwrite',
        partition_by=['COB_DATE'],
        on_schema_change='sync_all_columns'
    )
}}

{#
    Fact: fact_pl_summary (Daily Summary - P&L)
    
    Refactored to match Legacy Logic:
    1.  Hierarchical Aggregation (Detail, Total 7/8/9, Total 10).
    2.  Accumulation Logic for Group 8 (Expenses).
    3.  Complex Union Structure.
    
    NOTE: Logic implies traversing history for Accumulation.
#}

WITH dim_time AS (
    SELECT * FROM {{ ref('dim_time') }}
),

dim_branch AS (
    SELECT * FROM {{ ref('dim_branch_new') }} WHERE IN_USE_STATUS = 1
),

dim_pl_item AS (
    SELECT * FROM {{ ref('dim_pl_item') }}
),

source_detail AS (
    SELECT * FROM {{ ref('fact_pl_detail_new') }}
),

-- logic for LCY_BALANCE calculation (Accumulation for Group 8)
CTE_PL_CURR_RAW AS (
    SELECT 
        f.COB_DATE,
        f.D_BRANCH_ID,
        f.PL_CODE,
        f.LCY_OUTSTND
    FROM source_detail f
),

CTE_PL_CURR AS (
    -- Special handling for 31/12/2024 (Snapshot)
    SELECT 
        t.COB_DATE,
        t.ELM_DATE, t.ELY_DATE, t.DAY_AGO, t.BOM_DATE, t.DAY_IN_MONTH,
        f.D_BRANCH_ID,
        f.PL_CODE,    
        f.LCY_OUTSTND,   
        f.LCY_OUTSTND AS LCY_BALANCE
    FROM CTE_PL_CURR_RAW f
    JOIN dim_time t ON f.COB_DATE = t.COB_DATE
    WHERE t.COB_DATE = CAST('2024-12-31' AS DATE)
    
    UNION ALL
    
    -- Accumulation for other dates
    -- Note: This window function runs over the entire loaded dataset.
    SELECT 
        t.COB_DATE,
        t.ELM_DATE, t.ELY_DATE, t.DAY_AGO, t.BOM_DATE, t.DAY_IN_MONTH,
        f.D_BRANCH_ID,
        f.PL_CODE,    
        f.LCY_OUTSTND,   
        SUM(f.LCY_OUTSTND) OVER (PARTITION BY f.D_BRANCH_ID, f.PL_CODE ORDER BY t.COB_DATE) AS LCY_BALANCE
    FROM CTE_PL_CURR_RAW f
    JOIN dim_time t ON f.COB_DATE = t.COB_DATE
    WHERE t.COB_DATE <> CAST('2024-12-31' AS DATE)
),

CTE_PL_DAGO AS (
    SELECT 
        t.COB_DATE,
        t.ELM_DATE, t.ELY_DATE, t.DAY_AGO, t.BOM_DATE, t.DAY_IN_MONTH,
        pl.D_BRANCH_ID,
        pl.PL_CODE, 
        pl.LCY_OUTSTND,      
        pl.LCY_BALANCE
    FROM CTE_PL_CURR pl
    JOIN dim_time t ON pl.COB_DATE = t.DAY_AGO
    WHERE pl.LCY_BALANCE <> 0
),

CTE_PL_ELM AS (
    SELECT 
        t.COB_DATE,
        t.ELM_DATE, t.ELY_DATE, t.DAY_AGO, t.BOM_DATE, t.DAY_IN_MONTH,
        pl.D_BRANCH_ID,
        pl.PL_CODE,       
        pl.LCY_OUTSTND,      
        pl.LCY_BALANCE
    FROM CTE_PL_CURR pl
    JOIN dim_time t ON pl.COB_DATE = t.ELM_DATE
    WHERE pl.LCY_BALANCE <> 0
),

CTE_PL_ELY AS (
    SELECT 
        t.COB_DATE,
        t.ELM_DATE, t.ELY_DATE, t.DAY_AGO, t.BOM_DATE, t.DAY_IN_MONTH,
        pl.D_BRANCH_ID,
        pl.PL_CODE,       
        pl.LCY_OUTSTND,      
        pl.LCY_BALANCE
    FROM CTE_PL_CURR pl
    JOIN dim_time t ON pl.COB_DATE = t.ELY_DATE
    WHERE pl.LCY_BALANCE <> 0
),

CTE_PL_UNION AS (
    SELECT 
        COB_DATE, ELM_DATE, ELY_DATE, DAY_AGO, BOM_DATE, DAY_IN_MONTH,
        D_BRANCH_ID, PL_CODE,
        CASE WHEN SUBSTR(PL_CODE, 1, 1) = '8' THEN LCY_BALANCE ELSE LCY_OUTSTND END AS BAL_TODAY,
        0 AS BAL_DAGO, 0 AS BAL_ELM, 0 AS BAL_ELY     
    FROM CTE_PL_CURR
    
    UNION ALL
    
    SELECT 
        COB_DATE, ELM_DATE, ELY_DATE, DAY_AGO, BOM_DATE, DAY_IN_MONTH,
        D_BRANCH_ID, PL_CODE,
        0 AS BAL_TODAY,
        CASE WHEN SUBSTR(PL_CODE, 1, 1) = '8' THEN LCY_BALANCE ELSE LCY_OUTSTND END AS BAL_DAGO,
        0 AS BAL_ELM, 0 AS BAL_ELY     
    FROM CTE_PL_DAGO
    
    UNION ALL
    
    SELECT 
        COB_DATE, ELM_DATE, ELY_DATE, DAY_AGO, BOM_DATE, DAY_IN_MONTH,
        D_BRANCH_ID, PL_CODE,
        0 AS BAL_TODAY, 0 AS BAL_DAGO,
        CASE WHEN SUBSTR(PL_CODE, 1, 1) = '8' THEN LCY_BALANCE ELSE LCY_OUTSTND END AS BAL_ELM,
        0 AS BAL_ELY       
    FROM CTE_PL_ELM
    
    UNION ALL
    
    SELECT 
        COB_DATE, ELM_DATE, ELY_DATE, DAY_AGO, BOM_DATE, DAY_IN_MONTH,
        D_BRANCH_ID, PL_CODE,
        0 AS BAL_TODAY, 0 AS BAL_DAGO, 0 AS BAL_ELM,
        LCY_BALANCE AS BAL_ELY
    FROM CTE_PL_ELY 
),

-- Final Aggregation 1: Detail 7, 8
FINAL_DETAIL AS (
    SELECT 
        AA.COB_DATE, AA.ELM_DATE, AA.ELY_DATE, AA.DAY_AGO, AA.BOM_DATE, AA.DAY_IN_MONTH,
        AA.D_BRANCH_ID,
        'DETAIL' AS PL_GRP,
        CC.PL_CODE AS PL_CODE,
        CC.PL_NAME AS PL_NAME,
        BB.BRANCH_CODE, BB.BRANCH_NAME, BB.PARENT_CODE, BB.PARENT_NAME, BB.KV_NAME,
        SUM(AA.BAL_TODAY) AS BAL_TODAY,
        SUM(AA.BAL_DAGO) AS BAL_DAGO,
        SUM(AA.BAL_ELM) AS BAL_ELM,
        SUM(AA.BAL_ELY) AS BAL_ELY,
        MAX(BB.NBR_STAFF) as NBR_STAFF
    FROM CTE_PL_UNION AA
    JOIN dim_branch BB ON BB.D_BRANCH_ID = AA.D_BRANCH_ID
    JOIN dim_pl_item CC ON CC.PL_CODE = AA.PL_CODE    
    WHERE CC.PL_MAIN_CODE IN (7, 8, 9)
    GROUP BY AA.COB_DATE, AA.ELM_DATE, AA.ELY_DATE, AA.DAY_AGO, AA.BOM_DATE, AA.DAY_IN_MONTH,
             AA.D_BRANCH_ID, CC.PL_CODE, CC.PL_NAME,
             BB.BRANCH_CODE, BB.BRANCH_NAME, BB.PARENT_CODE, BB.PARENT_NAME, BB.KV_NAME
),

-- Final Aggregation 2: Total 7, 8, 9
FINAL_TOTAL AS (
    SELECT 
        AA.COB_DATE, AA.ELM_DATE, AA.ELY_DATE, AA.DAY_AGO, AA.BOM_DATE, AA.DAY_IN_MONTH,
        AA.D_BRANCH_ID,
        'TOTAL' AS PL_GRP,
        CAST(CC.PL_MAIN_CODE AS STRING) AS PL_CODE,
        CC.PL_MAIN_NAME AS PL_NAME,
        BB.BRANCH_CODE, BB.BRANCH_NAME, BB.PARENT_CODE, BB.PARENT_NAME, BB.KV_NAME,
        SUM(AA.BAL_TODAY) AS BAL_TODAY,
        SUM(AA.BAL_DAGO) AS BAL_DAGO,
        SUM(AA.BAL_ELM) AS BAL_ELM,
        SUM(AA.BAL_ELY) AS BAL_ELY,
        MAX(BB.NBR_STAFF) as NBR_STAFF
    FROM CTE_PL_UNION AA
    JOIN dim_branch BB ON BB.D_BRANCH_ID = AA.D_BRANCH_ID
    JOIN dim_pl_item CC ON CC.PL_CODE = AA.PL_CODE 
    WHERE CC.PL_MAIN_CODE IN (7, 8, 9)
    GROUP BY AA.COB_DATE, AA.ELM_DATE, AA.ELY_DATE, AA.DAY_AGO, AA.BOM_DATE, AA.DAY_IN_MONTH,
             AA.D_BRANCH_ID, CC.PL_MAIN_CODE, CC.PL_MAIN_NAME,
             BB.BRANCH_CODE, BB.BRANCH_NAME, BB.PARENT_CODE, BB.PARENT_NAME, BB.KV_NAME  
),

-- Final Aggregation 3: Net Profit (10)
FINAL_NET_PROFIT AS (
    SELECT 
        AA.COB_DATE, AA.ELM_DATE, AA.ELY_DATE, AA.DAY_AGO, AA.BOM_DATE, AA.DAY_IN_MONTH,
        AA.D_BRANCH_ID,
        'TOTAL' AS PL_GRP,
        '10' AS PL_CODE,
        'Lợi nhuận trước thuế' AS PL_NAME,
        BB.BRANCH_CODE, BB.BRANCH_NAME, BB.PARENT_CODE, BB.PARENT_NAME, BB.KV_NAME,
        SUM(CASE WHEN CC.PL_MAIN_CODE = 7 THEN AA.BAL_TODAY ELSE -AA.BAL_TODAY END) AS BAL_TODAY,
        SUM(CASE WHEN CC.PL_MAIN_CODE = 7 THEN AA.BAL_DAGO ELSE -AA.BAL_DAGO END) AS BAL_DAGO,
        SUM(CASE WHEN CC.PL_MAIN_CODE = 7 THEN AA.BAL_ELM ELSE -AA.BAL_ELM END) AS BAL_ELM,
        SUM(CASE WHEN CC.PL_MAIN_CODE = 7 THEN AA.BAL_ELY ELSE -AA.BAL_ELY END) AS BAL_ELY,
        MAX(BB.NBR_STAFF) as NBR_STAFF
    FROM CTE_PL_UNION AA
    JOIN dim_branch BB ON BB.D_BRANCH_ID = AA.D_BRANCH_ID
    JOIN dim_pl_item CC ON CC.PL_CODE = AA.PL_CODE 
    WHERE CC.PL_MAIN_CODE IN (7, 8, 9)
    GROUP BY AA.COB_DATE, AA.ELM_DATE, AA.ELY_DATE, AA.DAY_AGO, AA.BOM_DATE, AA.DAY_IN_MONTH,
             AA.D_BRANCH_ID,
             BB.BRANCH_CODE, BB.BRANCH_NAME, BB.PARENT_CODE, BB.PARENT_NAME, BB.KV_NAME
)

SELECT * FROM FINAL_DETAIL
UNION ALL
SELECT * FROM FINAL_TOTAL
UNION ALL
SELECT * FROM FINAL_NET_PROFIT
