-- ============================================================================
-- Delete Data Mart Data on Branch (backfill date range)
-- ============================================================================
-- Purpose: Clear data mart data within backfill date range before rebuild
-- Target: Iceberg branch (not main)
-- ============================================================================

-- Parameters (injected by Spark job):
-- ${catalog}: LakeHouse
-- ${schema}: data_mart
-- ${branch_name}: backfill_20250210_20250216
-- ${start_date}: 2025-02-10
-- ${end_date}: 2025-02-16

-- ============================================================================
-- DIMENSION - dim_branch (SCD Type 2)
-- ============================================================================

DELETE FROM ${catalog}.${schema}.dim_branch.branch_${branch_name}
WHERE EFF_FR_DT >= DATE '${start_date}'
  AND EFF_FR_DT <= DATE '${end_date}';

-- ============================================================================
-- FACT TABLES - Delete by COB_DATE within date range
-- ============================================================================

DELETE FROM ${catalog}.${schema}.fact_dp_detail.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

DELETE FROM ${catalog}.${schema}.fact_dp_summary.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

DELETE FROM ${catalog}.${schema}.fact_ln_detail.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

DELETE FROM ${catalog}.${schema}.fact_ln_summary.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

DELETE FROM ${catalog}.${schema}.fact_pl_detail.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

DELETE FROM ${catalog}.${schema}.fact_pl_summary.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

SELECT 'Delete data mart on branch completed' AS status;
