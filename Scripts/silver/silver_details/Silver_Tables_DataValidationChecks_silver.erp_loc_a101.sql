USE [DataWarehouse];
GO

/*
===============================================================================
KEYWORDS EXPLAINED:
===============================================================================
- COLLATE: Overrides the database's default text sorting and comparison rules 
  for a specific query. 
- SQL_Latin1_General_CP1_CS_AS: A specific collation setting. The critical part 
  here is 'CS' (Case-Sensitive), which forces SQL Server to treat 'UNITED STATES' 
  and 'United States' as completely different strings. 'AS' means Accent-Sensitive.
- LIKE: Used to search for a specified pattern in a column (e.g., '%-%' finds 
  any string containing a hyphen).
- DISTINCT: Returns only unique, non-repeating values from a column.
===============================================================================
*/

/*
===============================================================================
SECTION 1: DATA QUALITY VALIDATION (SILVER LAYER) - erp_loc_a101
===============================================================================
Script Purpose: 
    Run these queries interactively to inspect the cleansed silver data. The goal 
    is to validate that all anomalies (like hyphens in IDs and inconsistent 
    country abbreviations) were successfully handled during the Bronze-to-Silver 
    transformation process.
===============================================================================
*/

-- ============================================================================
-- 1. Key Formatting Check (Hyphen Removal Validation)
-- Expectation: No Results. 
-- Confirms that all hyphens '-' were successfully stripped from the primary 
-- key (cid), ensuring it can map cleanly to the CRM data.
-- ============================================================================
SELECT cid
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';

-- ============================================================================
-- 2. Data Standardization Validation (Country Cardinality)
-- Expectation: Should only return clean, standardized full names (e.g., 
-- 'United States', 'Germany', 'n/a'). There should be no 'US', 'USA', 'DE', 
-- or blank/NULL values.
-- ============================================================================
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

-- ============================================================================
-- 3. Unmapped Values Check (Country Validation)
-- Expectation: No Results. 
-- Confirms that none of the raw, unmapped abbreviations slipped through 
-- into the Silver layer, and no NULL or empty strings exist.
-- Note: COLLATE is used here to force a strict Case-Sensitive search, ensuring 
-- we only flag the all-caps 'UNITED STATES' without accidentally flagging our 
-- newly cleaned 'United States' records.
-- ============================================================================
SELECT *
FROM silver.erp_loc_a101
WHERE cntry COLLATE SQL_Latin1_General_CP1_CS_AS IN ('USA', 'US', 'DE', 'UNITED STATES')
   OR cntry IS NULL
   OR TRIM(cntry) = '';

-- ============================================================================
-- 4. FULL DATA CHECK
-- Purpose: Quickly review a sample of the overall cleansed dataset.
-- ============================================================================
SELECT * 
FROM silver.erp_loc_a101;