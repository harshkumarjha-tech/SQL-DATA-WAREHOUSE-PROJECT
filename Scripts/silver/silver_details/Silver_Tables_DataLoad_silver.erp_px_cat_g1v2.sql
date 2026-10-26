-- ==============================================================================
-- SECTION 1: DATA EXPLORATION & PROFILING
-- Objective: Clean and load bronze.erp_px_cat_g1v2 into silver.erp_px_cat_g1v2
-- ==============================================================================

-- 1. Check for expected IDs and cross-reference with CRM Product Info
SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT cat_id FROM silver.crm_prd_info;
-- Observation: No need to clean, everything is matching perfectly.

-- 2. Space Check: Identify leading or trailing spaces in text columns
SELECT * 
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);
-- Observation: No spaces found.

-- 3. Data Standardization: Check for inconsistent casing or spelling variations
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;


-- ==============================================================================
-- SECTION 2: TRUNCATE AND LOAD INTO SILVER
-- ==============================================================================

TRUNCATE TABLE silver.erp_px_cat_g1v2;
GO

INSERT INTO silver.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance
)
SELECT 
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;
GO


-- ==============================================================================
-- SECTION 3: DATA VALIDATION
-- ==============================================================================

-- Validate the final load by checking the newly populated Silver table
SELECT * FROM silver.erp_px_cat_g1v2;