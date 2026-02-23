-- ============================================================================
-- Backfill Fix Data Script Template
-- ============================================================================
-- Purpose: Fix source data errors before rebuilding vault/mart
-- Usage: Customize this script for each backfill scenario
-- ============================================================================

-- Example 1: Fix DR_CR_FLG swap error in GL table
-- UPDATE LakeHouse.landing.gl_poc_streaming
-- SET DR_CR_FLG = CASE 
--     WHEN DR_CR_FLG = 'D' THEN 'C'
--     WHEN DR_CR_FLG = 'C' THEN 'D'
--     ELSE DR_CR_FLG
-- END
-- WHERE EOD_DATE >= '${start_date}'
--   AND EOD_DATE <= '${end_date}';

-- Example 2: Fix incorrect branch code
-- UPDATE LakeHouse.landing.branch_streaming
-- SET POS_CD = '001'
-- WHERE POS_CD = '999'
--   AND EOD_DATE >= '${start_date}';

-- ============================================================================
-- ADD YOUR FIX SCRIPTS BELOW
-- ============================================================================

-- TODO: Add fix scripts for current backfill scenario

SELECT 'Fix data script completed' AS status;
