-- ============================================================================
-- Delete Vault Data on Branch (backfill date range)
-- ============================================================================
-- Purpose: Clear vault data within backfill date range before rebuild
-- Target: Iceberg branch (not main)
-- ============================================================================

-- Parameters (injected by Spark job):
-- ${catalog}: LakeHouse
-- ${schema}: integration
-- ${branch_name}: backfill_20250210_20250216
-- ${start_date}: 2025-02-10
-- ${end_date}: 2025-02-16

-- ============================================================================
-- SATELLITES (History) - Delete by DV_LDT within date range
-- ============================================================================

DELETE FROM ${catalog}.${schema}.sat_gl.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_branch.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_customer.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_card.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

-- ============================================================================
-- SATELLITES (Snapshot) - Delete by DV_LDT within date range
-- ============================================================================

DELETE FROM ${catalog}.${schema}.sat_snp_gl.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_snp_branch.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_snp_customer.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_snp_card.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_snp_gl_sbv.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_gl_sbv.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

-- ============================================================================
-- SATELLITES (Derivative) - Delete by DV_LDT within date range
-- ============================================================================

DELETE FROM ${catalog}.${schema}.sat_der_gl.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_der_branch.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_der_customer.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_der_card.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.sat_der_gl_sbv.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

-- ============================================================================
-- LINKS - Delete by DV_LDT within date range
-- ============================================================================

DELETE FROM ${catalog}.${schema}.lnk_branch_gl.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

DELETE FROM ${catalog}.${schema}.lnk_branch_parent.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

SELECT 'Delete vault on branch completed' AS status;
