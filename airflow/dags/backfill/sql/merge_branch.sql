-- ============================================================================
-- Merge Backfill Branch to Main (DELETE + INSERT with date range)
-- ============================================================================
-- Purpose: Merge backfill data from branch to main
-- Strategy: DELETE data in main within date range, INSERT from branch
-- This preserves production data outside the backfill range
-- ============================================================================

-- Parameters:
-- ${catalog}: LakeHouse
-- ${branch_name}: backfill_20250210_20250216
-- ${start_date}: 2025-02-10
-- ${end_date}: 2025-02-16

-- ============================================================================
-- RAW VAULT - Satellites (history)
-- ============================================================================

DELETE FROM ${catalog}.integration.sat_gl
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_gl
SELECT * FROM ${catalog}.integration.sat_gl.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_branch
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_branch
SELECT * FROM ${catalog}.integration.sat_branch.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_customer
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_customer
SELECT * FROM ${catalog}.integration.sat_customer.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_card
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_card
SELECT * FROM ${catalog}.integration.sat_card.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

-- ============================================================================
-- RAW VAULT - Satellites (snapshot)
-- ============================================================================

DELETE FROM ${catalog}.integration.sat_snp_gl
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_snp_gl
SELECT * FROM ${catalog}.integration.sat_snp_gl.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_snp_branch
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_snp_branch
SELECT * FROM ${catalog}.integration.sat_snp_branch.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_snp_customer
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_snp_customer
SELECT * FROM ${catalog}.integration.sat_snp_customer.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_snp_card
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_snp_card
SELECT * FROM ${catalog}.integration.sat_snp_card.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_snp_gl_sbv
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_snp_gl_sbv
SELECT * FROM ${catalog}.integration.sat_snp_gl_sbv.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_gl_sbv
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_gl_sbv
SELECT * FROM ${catalog}.integration.sat_gl_sbv.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

-- ============================================================================
-- RAW VAULT - Satellites (derivative)
-- ============================================================================

DELETE FROM ${catalog}.integration.sat_der_gl
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_der_gl
SELECT * FROM ${catalog}.integration.sat_der_gl.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_der_branch
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_der_branch
SELECT * FROM ${catalog}.integration.sat_der_branch.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_der_customer
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_der_customer
SELECT * FROM ${catalog}.integration.sat_der_customer.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_der_card
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_der_card
SELECT * FROM ${catalog}.integration.sat_der_card.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.sat_der_gl_sbv
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.sat_der_gl_sbv
SELECT * FROM ${catalog}.integration.sat_der_gl_sbv.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

-- ============================================================================
-- RAW VAULT - Hubs (insert only new keys from branch)
-- ============================================================================

INSERT INTO ${catalog}.integration.hub_gl
SELECT b.* FROM ${catalog}.integration.hub_gl.branch_${branch_name} b
LEFT JOIN ${catalog}.integration.hub_gl m ON b.DV_HKEY_HUB_GL = m.DV_HKEY_HUB_GL
WHERE m.DV_HKEY_HUB_GL IS NULL;

INSERT INTO ${catalog}.integration.hub_customer
SELECT b.* FROM ${catalog}.integration.hub_customer.branch_${branch_name} b
LEFT JOIN ${catalog}.integration.hub_customer m ON b.DV_HKEY_HUB_CUSTOMER = m.DV_HKEY_HUB_CUSTOMER
WHERE m.DV_HKEY_HUB_CUSTOMER IS NULL;

INSERT INTO ${catalog}.integration.hub_card
SELECT b.* FROM ${catalog}.integration.hub_card.branch_${branch_name} b
LEFT JOIN ${catalog}.integration.hub_card m ON b.DV_HKEY_HUB_CARD = m.DV_HKEY_HUB_CARD
WHERE m.DV_HKEY_HUB_CARD IS NULL;

INSERT INTO ${catalog}.integration.hub_branch
SELECT b.* FROM ${catalog}.integration.hub_branch.branch_${branch_name} b
LEFT JOIN ${catalog}.integration.hub_branch m ON b.DV_HKEY_HUB_BRANCH = m.DV_HKEY_HUB_BRANCH
WHERE m.DV_HKEY_HUB_BRANCH IS NULL;

-- ============================================================================
-- RAW VAULT - Links
-- ============================================================================

DELETE FROM ${catalog}.integration.lnk_branch_gl
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.lnk_branch_gl
SELECT * FROM ${catalog}.integration.lnk_branch_gl.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

---

DELETE FROM ${catalog}.integration.lnk_branch_parent
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

INSERT INTO ${catalog}.integration.lnk_branch_parent
SELECT * FROM ${catalog}.integration.lnk_branch_parent.branch_${branch_name}
WHERE DV_LDT >= TIMESTAMP '${start_date} 00:00:00'
  AND DV_LDT < TIMESTAMP '${end_date} 00:00:00' + INTERVAL 1 DAY;

-- ============================================================================
-- DATA MART - Dimensions
-- ============================================================================

DELETE FROM ${catalog}.data_mart.dim_branch
WHERE EFF_FR_DT >= DATE '${start_date}'
  AND EFF_FR_DT <= DATE '${end_date}';

INSERT INTO ${catalog}.data_mart.dim_branch
SELECT * FROM ${catalog}.data_mart.dim_branch.branch_${branch_name}
WHERE EFF_FR_DT >= DATE '${start_date}'
  AND EFF_FR_DT <= DATE '${end_date}';

-- ============================================================================
-- DATA MART - Facts
-- ============================================================================

DELETE FROM ${catalog}.data_mart.fact_dp_detail
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

INSERT INTO ${catalog}.data_mart.fact_dp_detail
SELECT * FROM ${catalog}.data_mart.fact_dp_detail.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

---

DELETE FROM ${catalog}.data_mart.fact_dp_summary
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

INSERT INTO ${catalog}.data_mart.fact_dp_summary
SELECT * FROM ${catalog}.data_mart.fact_dp_summary.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

---

DELETE FROM ${catalog}.data_mart.fact_ln_detail
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

INSERT INTO ${catalog}.data_mart.fact_ln_detail
SELECT * FROM ${catalog}.data_mart.fact_ln_detail.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

---

DELETE FROM ${catalog}.data_mart.fact_ln_summary
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

INSERT INTO ${catalog}.data_mart.fact_ln_summary
SELECT * FROM ${catalog}.data_mart.fact_ln_summary.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

---

DELETE FROM ${catalog}.data_mart.fact_pl_detail
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

INSERT INTO ${catalog}.data_mart.fact_pl_detail
SELECT * FROM ${catalog}.data_mart.fact_pl_detail.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

---

DELETE FROM ${catalog}.data_mart.fact_pl_summary
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

INSERT INTO ${catalog}.data_mart.fact_pl_summary
SELECT * FROM ${catalog}.data_mart.fact_pl_summary.branch_${branch_name}
WHERE COB_DATE >= DATE '${start_date}'
  AND COB_DATE <= DATE '${end_date}';

SELECT 'Merge completed: DELETE + INSERT within date range' AS status;
