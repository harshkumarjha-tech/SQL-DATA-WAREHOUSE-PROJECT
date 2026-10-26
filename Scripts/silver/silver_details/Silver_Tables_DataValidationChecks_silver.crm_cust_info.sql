/*
===============================================================================
SECTION 1: DATA QUALITY VALIDATION (SILVER LAYER)
===============================================================================
Script Purpose: 
    Run these queries interactively to inspect the cleansed silver data. The goal 
    is to validate that all anomalies (duplicates, NULLs, unwanted spaces, and 
    inconsistent text) were successfully handled during the Bronze-to-Silver 
    transformation process.
===============================================================================
*/

-- ============================================================================
-- 1. NULL Check on Primary Key
-- Expectation: No Results. 
-- Confirms that the "IS NOT NULL" filter successfully dropped bad records.
-- ============================================================================
SELECT * 
FROM silver.crm_cust_info
WHERE cst_id IS NULL
ORDER BY cst_id;

-- ============================================================================
-- 2. Duplicate Check on Primary Key
-- Expectation: No Results. 
-- Confirms that the CTE and ROW_NUMBER() logic successfully removed duplicates.
-- ============================================================================
SELECT 
    cst_id, 
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- ============================================================================
-- 3. Verify Resolution of Known Duplicates
-- Purpose: Investigate a previously known duplicate (e.g., ID 29449).
-- Expectation: Only ONE row should remain, containing the most recent 
-- cst_create_date, proving the deduplication logic worked perfectly.
-- ============================================================================
SELECT * 
FROM silver.crm_cust_info
WHERE cst_id = '29449';

-- ============================================================================
-- 4. Whitespace Check
-- Expectation: No Results. 
-- Confirms that the TRIM() function successfully removed hidden leading or 
-- trailing spaces from string columns.
-- ============================================================================
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

-- ============================================================================
-- 5. Data Consistency Check (Low Cardinality Columns)
-- Purpose: See all unique values to confirm standardization.
-- Expectation: Should only return clean, standardized values (e.g., 'Male', 
-- 'Female', 'Single', 'Married', 'n/a') with no obscure abbreviations.
-- ============================================================================
SELECT DISTINCT cst_gndr 
FROM silver.crm_cust_info;

SELECT DISTINCT cst_marital_status 
FROM silver.crm_cust_info;

-- ============================================================================
-- 6. Final Output Check
-- Purpose: Quickly review a sample of the overall cleansed dataset.
-- ============================================================================
SELECT * 
FROM silver.crm_cust_info;