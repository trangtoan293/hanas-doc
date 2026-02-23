-- ============================================================================
-- Drop All Branches After Merge
-- ============================================================================
-- Purpose: Cleanup branches after successful merge
-- Parameters: ${catalog}, ${branch_name}
-- ============================================================================

-- ============================================================================
-- RAW VAULT - integration schema
-- ============================================================================

-- Hubs
ALTER TABLE ${catalog}.integration.hub_gl DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.hub_customer DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.hub_card DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.hub_branch DROP BRANCH IF EXISTS ${branch_name};

-- Satellites (history)
ALTER TABLE ${catalog}.integration.sat_gl DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_branch DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_customer DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_card DROP BRANCH IF EXISTS ${branch_name};

-- Satellites (snapshot)
ALTER TABLE ${catalog}.integration.sat_snp_gl DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_snp_branch DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_snp_customer DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_snp_card DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_snp_gl_sbv DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_gl_sbv DROP BRANCH IF EXISTS ${branch_name};

-- Satellites (derivative)
ALTER TABLE ${catalog}.integration.sat_der_gl DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_der_branch DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_der_customer DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_der_card DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_der_gl_sbv DROP BRANCH IF EXISTS ${branch_name};

-- Links
ALTER TABLE ${catalog}.integration.lnk_branch_gl DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.lnk_branch_parent DROP BRANCH IF EXISTS ${branch_name};

-- ============================================================================
-- DATA MART - data_mart schema
-- ============================================================================

-- Dimensions
ALTER TABLE ${catalog}.data_mart.dim_branch DROP BRANCH IF EXISTS ${branch_name};

-- Facts
ALTER TABLE ${catalog}.data_mart.fact_dp_detail DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.data_mart.fact_dp_summary DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.data_mart.fact_ln_detail DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.data_mart.fact_ln_summary DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.data_mart.fact_pl_detail DROP BRANCH IF EXISTS ${branch_name};
ALTER TABLE ${catalog}.data_mart.fact_pl_summary DROP BRANCH IF EXISTS ${branch_name};

SELECT 'All branches dropped successfully' AS status;
