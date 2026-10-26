USE [DataWarehouse];
GO

/*
===============================================================================
KEYWORDS EXPLAINED:
===============================================================================
- REPLACE(): Swaps specific characters in a string with new ones (e.g., 
  swapping a dash '-' for a blank string '').
- IN(): Allows you to specify multiple values in a WHERE or CASE clause, acting 
  as a shorthand for multiple OR conditions.
===============================================================================
*/

/*
===============================================================================
SECTION 1: DATA PROFILING & QUALITY CHECKS (erp_loc_a101)
===============================================================================
Script Purpose: 
    Run these queries interactively to inspect the raw ERP location mapping 
    data, identify anomalies, and determine the transformation rules needed 
    to map this cleanly to the Silver layer.
===============================================================================
*/

-- ============================================================================
-- 1. Key Formatting Check (Identifying Hyphens)
-- Purpose: We found data with a hyphen '-' in the primary key (cid). This 
--          needs to be stripped out so it can connect smoothly with the 
--          crm_cust_info table later.
-- ============================================================================
SELECT cid
FROM bronze.erp_loc_a101
WHERE cid LIKE '%-%';

-- ============================================================================
-- 2. Data Consistency Check (Country Cardinality)
-- Purpose: Check all unique values in the cntry column to identify different 
--          spellings, abbreviations, blanks, or NULLs.
-- ============================================================================
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;

-- ============================================================================
-- 3. Testing Data Standardization Logic
-- Purpose: Revalidate the transformation logic side-by-side against the old 
--          column to ensure 'USA', 'US', 'DE', and blanks are mapping correctly.
-- ============================================================================
SELECT DISTINCT
    cntry AS old_cntry,
    CASE 
        WHEN UPPER(TRIM(cntry)) IN ('USA', 'US', 'UNITED STATES') THEN 'United States'
        WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'
        ELSE TRIM(cntry) 
    END AS new_cntry
FROM bronze.erp_loc_a101
ORDER BY old_cntry;


/*
===============================================================================
SECTION 2: DATA CLEANING & TRANSFORMATION SCRIPT
===============================================================================
Script Purpose: 
    Truncates the silver erp_loc_a101 table and inserts the cleansed data. 
    Applies hyphen removal on the primary key and standardizes the country names.
===============================================================================
*/

-- Best Practice: Clear out the table before running a full load
TRUNCATE TABLE silver.erp_loc_a101;
GO

INSERT INTO silver.erp_loc_a101 (
    cid,
    cntry
)
SELECT 
    -- REPLACE automatically ignores strings without a hyphen.
    REPLACE(TRIM(cid), '-', '') AS cid,

    -- Standardize country codes and handle missing data
    CASE 
        WHEN UPPER(TRIM(cntry)) IN ('USA', 'US', 'UNITED STATES') THEN 'United States'
        WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'
        ELSE TRIM(cntry) 
    END AS cntry
FROM bronze.erp_loc_a101;

-- ============================================================================
-- 4. FULL DATA CHECK
-- Purpose: Quickly review a sample of the overall cleansed dataset.
-- ============================================================================
SELECT * FROM silver.erp_loc_a101;
