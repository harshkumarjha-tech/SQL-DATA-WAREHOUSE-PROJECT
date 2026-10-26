-- ==============================================================================
-- SECTION 3: DATA VALIDATION (SILVER TIER)
-- Objective: Confirm the data was loaded correctly and remains clean in Silver
-- ==============================================================================

-- 1. Row Count Check: Ensure all rows from Bronze successfully made it to Silver
SELECT 
    (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2) AS Bronze_Row_Count,
    (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2) AS Silver_Row_Count;

-- 2. Space Check Validation: Verify no leading/trailing spaces exist in the Silver table
SELECT * 
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

-- 3. Data Standardization Validation: Review the distinct values actually loaded into Silver
SELECT DISTINCT cat FROM silver.erp_px_cat_g1v2;
SELECT DISTINCT subcat FROM silver.erp_px_cat_g1v2;
SELECT DISTINCT maintenance FROM silver.erp_px_cat_g1v2;

-- 4. Final Sanity Check: Preview the top rows of the Silver table
SELECT TOP 10 * FROM silver.erp_px_cat_g1v2;