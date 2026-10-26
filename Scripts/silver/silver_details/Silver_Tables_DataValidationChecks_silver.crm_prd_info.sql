USE [DataWarehouse];
GO

/*
===============================================================================
KEYWORDS EXPLAINED (NEW FUNCTIONS ADDED):
===============================================================================
- SUBSTRING(expression, start, length): Extracts a specific portion of a 
  text string. (e.g., SUBSTRING(prd_key, 1, 5) gets the first 5 characters).
- REPLACE(string_expression, string_pattern, string_replacement): Swaps 
  specific characters in a string with new ones. (e.g., REPLACE(cat_id, '-', '_')).
- LEN(string_expression): Returns the total number of characters in a string.
  (e.g., LEN(prd_key)).
- LEAD(return_value [,offset] [,default]): A window function that looks "forward" 
  to fetch a value from the next row in your partitioned dataset. This is always 
  paired with an OVER() clause. (e.g., LEAD(prd_start_dt) OVER(...)).
- CAST(expression AS data_type): Converts a value from one data type to 
  another. (e.g., CAST(prd_start_dt AS DATE) strips the time off a DATETIME).
===============================================================================
*/

/*
===============================================================================
SECTION 1: DATA QUALITY VALIDATION (SILVER LAYER)
===============================================================================
Script Purpose: 
    Run these queries interactively to inspect the cleansed silver data. The goal 
    is to validate that all anomalies (duplicates, NULLs, unwanted spaces, 
    incorrect date ranges, and unmapped text) were successfully handled during 
    the Bronze-to-Silver transformation process.
===============================================================================
*/

-- ============================================================================
-- 1. NULL Check on Primary Key
-- Expectation: No Results. 
-- Confirms that no records are completely missing a product ID.
-- ============================================================================
SELECT * 
FROM silver.crm_prd_info
WHERE prd_id IS NULL
ORDER BY prd_id;

-- ============================================================================
-- 2. Duplicate Check on Primary Key
-- Expectation: No Results. 
-- Confirms that product IDs do not appear more than once.
-- ============================================================================
SELECT 
    prd_id, 
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- ============================================================================
-- 3. Composite Key Extraction Validation
-- Expectation: No Results. 
-- In the Silver layer, 'cat_id' and 'prd_key' are already split. We can check 
-- for blank strings to ensure our SUBSTRING and REPLACE logic worked correctly.
-- ============================================================================
SELECT *
FROM silver.crm_prd_info
WHERE cat_id IS NULL OR TRIM(cat_id) = '' 
   OR prd_key IS NULL OR TRIM(prd_key) = '';

-- ============================================================================
-- 4. Whitespace Check
-- Expectation: No Results. 
-- Confirms that the TRIM() function successfully removed hidden leading or 
-- trailing spaces from the product name column.
-- ============================================================================
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- ============================================================================
-- 5. Data Consistency Check (Cost Validation)
-- Expectation: No Results. 
-- Confirms our CASE statement successfully replaced negative costs and NULLs 
-- with 0.
-- ============================================================================
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- ============================================================================
-- 6. Data Standardization Validation (Product Line Abbreviations)
-- Expectation: Should only return full, readable names ('Mountain', 'Road', 
-- 'Other Sales', 'Touring', 'n/a') instead of the raw single-letter codes.
-- ============================================================================
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- ============================================================================
-- 7. Date Correction & Historical Range Validation
-- Expectation: No Results. 
-- Confirms that our LEAD() logic fixed the overlapping dates, meaning no 
-- end date should ever be earlier than a start date.
-- ============================================================================
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- ============================================================================
-- 8. FULL DATA CHECK
-- Purpose: Quickly review a sample of the overall cleansed dataset.
-- ============================================================================
SELECT * 
FROM silver.crm_prd_info;