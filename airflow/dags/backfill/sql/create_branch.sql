-- ============================================================================
-- Create Branches for All Backfill Tables
-- ============================================================================
-- Purpose: Create Iceberg branches for isolation during backfill
-- Parameters: ${catalog}, ${branch_name}
-- ============================================================================

-- ============================================================================
-- RAW VAULT - integration schema
-- ============================================================================

-- Hubs
ALTER TABLE ${catalog}.integration.hub_gl CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.hub_customer CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.hub_card CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.hub_branch CREATE BRANCH IF NOT EXISTS ${branch_name};

-- Satellites (history)
ALTER TABLE ${catalog}.integration.sat_gl CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_branch CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_customer CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_card CREATE BRANCH IF NOT EXISTS ${branch_name};

-- Satellites (snapshot)
ALTER TABLE ${catalog}.integration.sat_snp_gl CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_snp_branch CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_snp_customer CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_snp_card CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_snp_gl_sbv CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_gl_sbv CREATE BRANCH IF NOT EXISTS ${branch_name};

-- Satellites (derivative)
ALTER TABLE ${catalog}.integration.sat_der_gl CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_der_branch CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_der_customer CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_der_card CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.sat_der_gl_sbv CREATE BRANCH IF NOT EXISTS ${branch_name};

-- Links
ALTER TABLE ${catalog}.integration.lnk_branch_gl CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.integration.lnk_branch_parent CREATE BRANCH IF NOT EXISTS ${branch_name};

-- ============================================================================
-- DATA MART - data_mart schema
-- ============================================================================

-- Dimensions
ALTER TABLE ${catalog}.data_mart.dim_branch CREATE BRANCH IF NOT EXISTS ${branch_name};

-- Facts
ALTER TABLE ${catalog}.data_mart.fact_dp_detail CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.data_mart.fact_dp_summary CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.data_mart.fact_ln_detail CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.data_mart.fact_ln_summary CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.data_mart.fact_pl_detail CREATE BRANCH IF NOT EXISTS ${branch_name};
ALTER TABLE ${catalog}.data_mart.fact_pl_summary CREATE BRANCH IF NOT EXISTS ${branch_name};

SELECT 'All branches created successfully' AS status;
