
{#
    Intermediate Model: int_dim_branch
    Flatten Hub + Sat + Link into a single table for Dim Branch.
    This is where Business Logic resides.
    
    NOTE: Do NOT include valid_from/valid_to here - the dim_scd2_transform macro
    will calculate them based on timestamp_col (DV_SRC_LDT).
#}

WITH hub AS (
    SELECT 
        DV_HKEY_HUB_BRANCH,
        POS_CD AS BRANCH_CODE
    FROM {{ ref('hub_branch') }}
    WHERE POS_CD <> 0  -- Exclude ghost records
),

sat AS (
    SELECT 
        DV_HKEY_HUB_BRANCH,
        STAFF_NUM,
        DV_SRC_LDT,
        DV_LDT
    FROM {{ ref('sat_branch') }}
),

lnk_parent AS (
    SELECT 
        DV_HKEY_HUB_BRANCH,
        DV_HKEY_HUB_BRANCH_PARENT
    FROM {{ ref('lnk_branch_parent') }}
),

hub_parent AS (
    SELECT 
        DV_HKEY_HUB_BRANCH,
        POS_CD AS PARENT_CODE
    FROM {{ ref('hub_branch') }}
)

SELECT 
    h.BRANCH_CODE,
    COALESCE(h.BRANCH_CODE || ' - NAME', '') AS BRANCH_NAME,
    p.PARENT_CODE,
    CASE WHEN p.PARENT_CODE IS NOT NULL THEN p.PARENT_CODE || ' - CN' ELSE '' END AS PARENT_NAME,
    CASE
        WHEN SUBSTR(CAST(p.PARENT_CODE AS STRING), 1, 2) = '11' THEN 'KV MIEN BAC'
        WHEN SUBSTR(CAST(p.PARENT_CODE AS STRING), 1, 2) = '12' THEN 'KV MIEN TRUNG'
        WHEN SUBSTR(CAST(p.PARENT_CODE AS STRING), 1, 2) = '13' THEN 'KV MIEN NAM'
        ELSE 'HOI SO'
    END AS KV_NAME,
    CAST(COALESCE(s.STAFF_NUM, 0) AS INTEGER) AS NBR_STAFF,
    s.DV_SRC_LDT
FROM hub h
LEFT JOIN lnk_parent lp ON h.DV_HKEY_HUB_BRANCH = lp.DV_HKEY_HUB_BRANCH
LEFT JOIN hub_parent p ON lp.DV_HKEY_HUB_BRANCH_PARENT = p.DV_HKEY_HUB_BRANCH
LEFT JOIN sat s ON h.DV_HKEY_HUB_BRANCH = s.DV_HKEY_HUB_BRANCH
