{{ config(
    materialized='incremental',
    file_format='iceberg',
    unique_key='D_BRANCH_ID',
    incremental_strategy='merge',
    merge_update_columns=['EFF_TO_DT', 'IN_USE_STATUS'],
    on_schema_change='sync_all_columns'
) }}

{#
    SCD Type 2 Dimension Table for Branch
    
    Business Key: POS_CD
    Surrogate Key: D_BRANCH_ID = SHA256(POS_CD + EFF_FR_DT)
    
    Backfill Support (v4):
    - Supports date range: var('start_date') + var('end_date') OR single var('cob_date')
    - Uses Window Functions for efficient processing
#}

-- =============================================================================
-- STEP 1: Get date range to process
-- =============================================================================
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

-- =============================================================================
-- STEP 2: Build sat_branch validity periods using Window Functions
-- =============================================================================
sat_with_validity AS (
    SELECT 
        s.*,
        s.DV_SRC_LDT AS valid_from,
        COALESCE(
            LEAD(s.DV_SRC_LDT) OVER (PARTITION BY s.DV_HKEY_HUB_BRANCH ORDER BY s.DV_SRC_LDT),
            TIMESTAMP('9999-12-31 23:59:59')
        ) AS valid_to
    FROM {{ ref('sat_branch') }} s
),

-- =============================================================================
-- STEP 3: Get snapshot for each date in ref_dates
-- =============================================================================
sat_snapshots_by_date AS (
    SELECT 
        rd.cob_date,
        rd.run_time,
        h.POS_CD AS BRANCH_CODE,
        COALESCE(h.POS_CD || ' - NAME', '') AS BRANCH_NAME,
        p.POS_CD AS PARENT_CODE,
        CASE WHEN p.POS_CD IS NOT NULL THEN p.POS_CD || ' - CN' ELSE '' END AS PARENT_NAME,
        CASE
            WHEN SUBSTR(CAST(p.POS_CD AS STRING), 1, 2) = '11' THEN 'KV MIEN BAC'
            WHEN SUBSTR(CAST(p.POS_CD AS STRING), 1, 2) = '12' THEN 'KV MIEN TRUNG'
            WHEN SUBSTR(CAST(p.POS_CD AS STRING), 1, 2) = '13' THEN 'KV MIEN NAM'
            ELSE 'HOI SO'
        END AS KV_NAME,
        CAST(COALESCE(s.STAFF_NUM, 0) AS INTEGER) AS NBR_STAFF,
        s.DV_SRC_LDT,
        s.DV_LDT,
        -- Fix G: Use COALESCE for all parts of hash
        SHA2(CONCAT(
            COALESCE(h.POS_CD || ' - NAME', ''), '|',
            COALESCE(CAST(p.POS_CD AS STRING), ''), '|',
            CASE
                WHEN SUBSTR(CAST(p.POS_CD AS STRING), 1, 2) = '11' THEN 'KV MIEN BAC'
                WHEN SUBSTR(CAST(p.POS_CD AS STRING), 1, 2) = '12' THEN 'KV MIEN TRUNG'
                WHEN SUBSTR(CAST(p.POS_CD AS STRING), 1, 2) = '13' THEN 'KV MIEN NAM'
                ELSE 'HOI SO'
            END, '|',
            CAST(COALESCE(s.STAFF_NUM, 0) AS STRING)
        ), 256) AS attr_hash
    FROM ref_dates rd
    JOIN {{ ref('hub_branch') }} h ON h.POS_CD <> 0
    LEFT JOIN {{ ref('lnk_branch_parent') }} lp ON h.DV_HKEY_HUB_BRANCH = lp.DV_HKEY_HUB_BRANCH
    LEFT JOIN {{ ref('hub_branch') }} p ON lp.DV_HKEY_HUB_BRANCH_PARENT = p.DV_HKEY_HUB_BRANCH
    LEFT JOIN sat_with_validity s 
        ON h.DV_HKEY_HUB_BRANCH = s.DV_HKEY_HUB_BRANCH
       AND rd.run_time >= s.valid_from 
       AND rd.run_time < s.valid_to
)

{% if is_incremental() %}
-- =============================================================================
-- INCREMENTAL/BACKFILL MODE
-- =============================================================================

-- Get existing dim state (active records before start of backfill range)
, existing_dim_state AS (
    SELECT 
        BRANCH_CODE,
        SHA2(CONCAT(
            COALESCE(BRANCH_NAME, ''), '|',
            COALESCE(CAST(PARENT_CODE AS STRING), ''), '|',
            COALESCE(KV_NAME, ''), '|',
            CAST(COALESCE(NBR_STAFF, 0) AS STRING)
        ), 256) AS existing_hash,
        EFF_FR_DT AS existing_eff_fr_dt,
        D_BRANCH_ID AS existing_sk
    FROM {{ this }}
    WHERE IN_USE_STATUS = 1
      AND EFF_FR_DT < (SELECT MIN(cob_date) FROM ref_dates)
)

-- Detect changes comparing with previous day OR existing dim
, changes_detected AS (
    SELECT 
        s.*,
        ex.existing_hash,
        ex.existing_sk,
        ex.existing_eff_fr_dt,
        COALESCE(
            LAG(s.attr_hash) OVER (PARTITION BY s.BRANCH_CODE ORDER BY s.cob_date),
            ex.existing_hash
        ) AS prev_hash,
        CASE WHEN LAG(s.cob_date) OVER (PARTITION BY s.BRANCH_CODE ORDER BY s.cob_date) IS NULL 
             THEN 1 ELSE 0 END AS is_first_day,
        CASE 
            WHEN LAG(s.attr_hash) OVER (PARTITION BY s.BRANCH_CODE ORDER BY s.cob_date) IS NULL 
                 AND ex.existing_hash IS NULL THEN 'NEW'
            WHEN s.attr_hash <> COALESCE(
                LAG(s.attr_hash) OVER (PARTITION BY s.BRANCH_CODE ORDER BY s.cob_date),
                ex.existing_hash
            ) THEN 'CHANGED'
            ELSE 'SAME'
        END AS change_type
    FROM sat_snapshots_by_date s
    LEFT JOIN existing_dim_state ex ON s.BRANCH_CODE = ex.BRANCH_CODE
)

-- Identify branches where first day is SAME (need to extend existing record)
, branches_with_no_change_at_start AS (
    SELECT DISTINCT BRANCH_CODE, existing_sk, existing_eff_fr_dt
    FROM changes_detected
    WHERE is_first_day = 1 
      AND change_type = 'SAME'
      AND existing_sk IS NOT NULL
)

-- Keep only NEW/CHANGED records
, changes_only AS (
    SELECT * FROM changes_detected
    WHERE change_type IN ('NEW', 'CHANGED')
)

-- Get first change date per branch (for linking EFF_TO_DT)
, first_change_per_branch AS (
    SELECT 
        BRANCH_CODE,
        MIN(cob_date) AS first_change_date
    FROM changes_only
    GROUP BY BRANCH_CODE
)

-- Get records that exist AFTER backfill range (to link EFF_TO_DT)
, next_existing_records AS (
    SELECT 
        BRANCH_CODE,
        MIN(EFF_FR_DT) AS next_eff_fr_dt
    FROM {{ this }}
    WHERE EFF_FR_DT > (SELECT MAX(cob_date) FROM ref_dates)
    GROUP BY BRANCH_CODE
)

-- New/Changed records from backfill
, new_records AS (
    SELECT
        SHA2(CONCAT(CAST(c.BRANCH_CODE AS STRING), '|', CAST(CAST(c.cob_date AS DATE) AS STRING)), 256) AS D_BRANCH_ID,
        CAST(c.cob_date AS DATE) AS EFF_FR_DT,
        COALESCE(
            DATE_SUB(LEAD(c.cob_date) OVER (PARTITION BY c.BRANCH_CODE ORDER BY c.cob_date), 1),
            DATE_SUB(nx.next_eff_fr_dt, 1),
            TO_DATE('9999-12-31')
        ) AS EFF_TO_DT,
        CASE 
            WHEN LEAD(c.cob_date) OVER (PARTITION BY c.BRANCH_CODE ORDER BY c.cob_date) IS NULL 
                 AND nx.next_eff_fr_dt IS NULL THEN 1 
            ELSE 0 
        END AS IN_USE_STATUS,
        c.DV_LDT AS LAST_MODIFY_TIME,
        c.BRANCH_CODE,
        c.BRANCH_NAME,
        c.PARENT_CODE,
        c.PARENT_NAME,
        c.KV_NAME,
        c.NBR_STAFF
    FROM changes_only c
    LEFT JOIN next_existing_records nx ON c.BRANCH_CODE = nx.BRANCH_CODE
)

-- Close existing records ONLY if there's a change AND NOT in extended_records
, records_to_close AS (
    SELECT 
        ex.existing_sk AS D_BRANCH_ID,
        d.EFF_FR_DT,
        DATE_SUB(fc.first_change_date, 1) AS EFF_TO_DT,
        0 AS IN_USE_STATUS,
        d.LAST_MODIFY_TIME,
        d.BRANCH_CODE,
        d.BRANCH_NAME,
        d.PARENT_CODE,
        d.PARENT_NAME,
        d.KV_NAME,
        d.NBR_STAFF
    FROM existing_dim_state ex
    JOIN {{ this }} d ON ex.existing_sk = d.D_BRANCH_ID
    JOIN first_change_per_branch fc ON ex.BRANCH_CODE = fc.BRANCH_CODE
    -- Exclude branches that are in extended_records (first day SAME)
    WHERE ex.BRANCH_CODE NOT IN (SELECT BRANCH_CODE FROM branches_with_no_change_at_start)
)

-- Extend existing records if first days are SAME
, extended_records AS (
    SELECT 
        nc.existing_sk AS D_BRANCH_ID,
        d.EFF_FR_DT,
        COALESCE(
            DATE_SUB(fc.first_change_date, 1),
            DATE_SUB(nx.next_eff_fr_dt, 1),
            TO_DATE('9999-12-31')
        ) AS EFF_TO_DT,
        CASE 
            WHEN fc.first_change_date IS NULL AND nx.next_eff_fr_dt IS NULL THEN 1 
            ELSE 0 
        END AS IN_USE_STATUS,
        d.LAST_MODIFY_TIME,
        d.BRANCH_CODE,
        d.BRANCH_NAME,
        d.PARENT_CODE,
        d.PARENT_NAME,
        d.KV_NAME,
        d.NBR_STAFF
    FROM branches_with_no_change_at_start nc
    JOIN {{ this }} d ON nc.existing_sk = d.D_BRANCH_ID
    LEFT JOIN first_change_per_branch fc ON nc.BRANCH_CODE = fc.BRANCH_CODE
    LEFT JOIN next_existing_records nx ON nc.BRANCH_CODE = nx.BRANCH_CODE
)

-- =============================================================================
-- Detect deleted branches using Window Function
-- =============================================================================
-- Step 1: Cross join all active dim records with all dates to find gaps
, dim_branch_date_grid AS (
    SELECT 
        d.D_BRANCH_ID,
        d.EFF_FR_DT,
        d.BRANCH_CODE,
        d.BRANCH_NAME,
        d.PARENT_CODE,
        d.PARENT_NAME,
        d.KV_NAME,
        d.NBR_STAFF,
        d.LAST_MODIFY_TIME,
        rd.cob_date
    FROM {{ this }} d
    CROSS JOIN ref_dates rd
    WHERE d.IN_USE_STATUS = 1
      AND d.EFF_FR_DT < (SELECT MIN(cob_date) FROM ref_dates)
      -- Exclude branches already handled by records_to_close or extended_records
      AND d.BRANCH_CODE NOT IN (SELECT BRANCH_CODE FROM records_to_close)
      AND d.BRANCH_CODE NOT IN (SELECT BRANCH_CODE FROM extended_records)
)

-- Step 2: Left join with snapshots to find NULL (missing) dates
, dim_with_sat_status AS (
    SELECT 
        g.*,
        CASE WHEN s.BRANCH_CODE IS NULL THEN 1 ELSE 0 END AS is_missing
    FROM dim_branch_date_grid g
    LEFT JOIN sat_snapshots_by_date s 
        ON g.BRANCH_CODE = s.BRANCH_CODE 
       AND g.cob_date = s.cob_date
)

-- Step 3: Use Window Function to find first missing date per branch
, first_missing_date AS (
    SELECT 
        D_BRANCH_ID,
        EFF_FR_DT,
        BRANCH_CODE,
        BRANCH_NAME,
        PARENT_CODE,
        PARENT_NAME,
        KV_NAME,
        NBR_STAFF,
        LAST_MODIFY_TIME,
        MIN(CASE WHEN is_missing = 1 THEN cob_date END) AS first_missing_cob_date
    FROM dim_with_sat_status
    GROUP BY D_BRANCH_ID, EFF_FR_DT, BRANCH_CODE, BRANCH_NAME, PARENT_CODE, 
             PARENT_NAME, KV_NAME, NBR_STAFF, LAST_MODIFY_TIME
)

-- Step 4: Final deleted branches CTE
, deleted_branches AS (
    SELECT 
        D_BRANCH_ID,
        EFF_FR_DT,
        DATE_SUB(first_missing_cob_date, 1) AS EFF_TO_DT,
        0 AS IN_USE_STATUS,
        LAST_MODIFY_TIME,
        BRANCH_CODE,
        BRANCH_NAME,
        PARENT_CODE,
        PARENT_NAME,
        KV_NAME,
        NBR_STAFF
    FROM first_missing_date
    WHERE first_missing_cob_date IS NOT NULL
)

-- Output: UNION all record types with deduplication
, all_changes AS (
    SELECT * FROM new_records
    UNION ALL
    SELECT * FROM records_to_close
    UNION ALL
    SELECT * FROM extended_records
    UNION ALL
    SELECT * FROM deleted_branches
)
-- Deduplicate to prevent MERGE_CARDINALITY_VIOLATION
-- Priority: new_records > records_to_close > extended_records > deleted_branches
, deduplicated_changes AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY D_BRANCH_ID ORDER BY IN_USE_STATUS DESC, EFF_TO_DT DESC) AS rn
    FROM all_changes
)
SELECT 
    D_BRANCH_ID, EFF_FR_DT, EFF_TO_DT, IN_USE_STATUS, LAST_MODIFY_TIME,
    BRANCH_CODE, BRANCH_NAME, PARENT_CODE, PARENT_NAME, KV_NAME, NBR_STAFF
FROM deduplicated_changes
WHERE rn = 1

{% else %}
-- =============================================================================
-- FULL REFRESH MODE: Load all with active status
-- EFF_FR_DT = '1900-01-01' to allow joining with all historical transactions
-- =============================================================================
SELECT
    SHA2(CONCAT(CAST(BRANCH_CODE AS STRING), '|', CAST(CAST(cob_date AS DATE) AS STRING)), 256) AS D_BRANCH_ID,
    TO_DATE('1900-01-01') AS EFF_FR_DT,
    TO_DATE('9999-12-31') AS EFF_TO_DT,
    1 AS IN_USE_STATUS,
    DV_LDT AS LAST_MODIFY_TIME,
    BRANCH_CODE,
    BRANCH_NAME,
    PARENT_CODE,
    PARENT_NAME,
    KV_NAME,
    NBR_STAFF
FROM sat_snapshots_by_date
WHERE cob_date = (SELECT MAX(cob_date) FROM ref_dates)

{% endif %}