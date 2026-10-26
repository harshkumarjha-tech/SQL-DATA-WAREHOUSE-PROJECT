USE [DataWarehouse];
GO

/*
===============================================================================
KEYWORDS EXPLAINED:
===============================================================================
- LIKE: Used in a WHERE or CASE clause to search for a specified pattern in a 
  column. (e.g., 'NAS%' means any string starting with 'NAS').
- GETDATE(): A system function that returns the current database system date 
  and time. Highly useful for checking if a logged date is in the future.
- IN(): Allows you to specify multiple values in a WHERE or CASE clause, acting 
  as a shorthand for multiple OR conditions.
===============================================================================
*/

/*
===============================================================================
SECTION 1: DATA QUALITY VALIDATION (SILVER LAYER) - erp_cust_az12
===============================================================================
Script Purpose: 
    Run these queries interactively to inspect the cleansed silver data. The goal 
    is to validate that all anomalies (like 'NAS' prefixes, future birthdates, 
    and inconsistent gender formats) were successfully handled during the 
    Bronze-to-Silver transformation process.
===============================================================================
*/

-- ============================================================================
-- 1. Key Formatting Check (Prefix Removal Validation)
-- Expectation: No Results. 
-- Confirms that the arbitrary 'NAS' prefix was successfully stripped from all 
-- customer IDs.
-- ============================================================================
SELECT cid
FROM silver.erp_cust_az12
WHERE cid LIKE 'NAS%';

-- ============================================================================
-- 2. Referential Integrity Check (Mapping ERP to CRM)
-- Expectation: No Results. 
-- Ensures that every cleaned Customer ID from the ERP system actually matches 
-- a valid customer in our main CRM Customer master table.
-- ============================================================================
SELECT *
FROM silver.erp_cust_az12
WHERE cid NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info);

-- ============================================================================
-- 3. Invalid Date Format Check (Birthdates)
-- Expectation: No Results. 
-- Confirms our transformation logic successfully nullified future birthdates 
-- and that no deeply historical garbage dates remain.
-- ============================================================================
SELECT bdate 
FROM silver.erp_cust_az12
WHERE bdate > GETDATE() 
   OR bdate < '1924-01-01';

-- ============================================================================
-- 4. Unmapped Values Check (Gender Validation)
-- Expectation: No Results. 
-- Confirms that none of the raw, unmapped abbreviations (like 'F', 'M') 
-- slipped through into the Silver layer.
-- ============================================================================
SELECT *
FROM silver.erp_cust_az12
WHERE gen NOT IN ('Male', 'Female', 'n/a')
   OR gen IS NULL;

-- ============================================================================
-- 5. Data Standardization Validation (Gender Cardinality)
-- Expectation: Should only return clean, standardized full names: 
-- 'Male', 'Female', or 'n/a'.
-- ============================================================================
SELECT DISTINCT gen 
FROM silver.erp_cust_az12;

-- ============================================================================
-- 6. FULL DATA CHECK
-- Purpose: Quickly review a sample of the overall cleansed dataset.
-- ============================================================================
SELECT * 
FROM silver.erp_cust_az12;