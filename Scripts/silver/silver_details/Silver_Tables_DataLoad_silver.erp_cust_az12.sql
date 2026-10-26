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
SECTION 1: DATA PROFILING & QUALITY CHECKS (erp_cust_az12)
===============================================================================
Script Purpose: 
    Run these queries interactively to inspect the raw ERP customer mapping 
    data, identify anomalies, and determine the transformation rules needed 
    to map this cleanly to the CRM data in the Silver layer.
===============================================================================
*/

-- ============================================================================
-- 1. Key Formatting Check (Identifying Prefixes)
-- Purpose: The ERP system appends an arbitrary 'NAS' prefix to some customer 
--          IDs. We need to strip this out to match the CRM system keys.
-- Logic: If the ID starts with 'NAS', use SUBSTRING to extract everything 
--        from the 4th character onwards.
-- ============================================================================
SELECT 
    cid,
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
        ELSE cid 
    END AS cleaned_cid,
    bdate,
    gen
FROM bronze.erp_cust_az12;

-- ============================================================================
-- 2. Referential Integrity Check (Mapping ERP to CRM)
-- Purpose: Ensures that every cleaned Customer ID from the ERP system actually 
--          exists in our cleaned CRM Customer master table (silver.crm_cust_info).
-- Expectation: No Results (0 rows). If rows return, we have ERP customers 
--              missing from the main CRM system.
-- ============================================================================
SELECT 
    cid,
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
        ELSE cid 
    END AS cleaned_cid,
    bdate,
    gen
FROM bronze.erp_cust_az12
WHERE CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
        ELSE cid 
      END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info);

-- ============================================================================
-- 3. Invalid Date Format Check (Birthdates)
-- Purpose: Birthdates cannot be in the future, and dates too far in the past 
--          (e.g., before 1924) are likely garbage/default data.
-- Expectation: No Results.
-- ============================================================================
SELECT bdate 
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE() 
   OR bdate < '1924-01-01';

-- ============================================================================
-- 4. Testing Date Transformation Logic
-- Purpose: Apply logic to set any impossible future birthdates to NULL.
-- ============================================================================
SELECT 
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
        ELSE cid 
    END AS cid,
    CASE 
        WHEN bdate > GETDATE() THEN NULL 
        ELSE bdate 
    END AS bdate,
    gen
FROM bronze.erp_cust_az12;

-- ============================================================================
-- 5. Data Consistency Check (Low Cardinality for Gender)
-- Purpose: See all unique values to identify inconsistencies (e.g., 'F', 'M', 
--          'Female', 'Male', spaces, or typos).
-- ============================================================================
SELECT DISTINCT gen 
FROM bronze.erp_cust_az12;


/*
===============================================================================
SECTION 2: DATA CLEANING & TRANSFORMATION SCRIPT
===============================================================================
Script Purpose: 
    Truncates the silver erp_cust_az12 table and inserts the cleansed data. 
    Applies all key stripping, date boundary fixes, and categorical 
    standardizations to prepare the ERP customer data for the Silver layer.
===============================================================================
*/

-- Best Practice: Clear out the table before running a full load
TRUNCATE TABLE silver.erp_cust_az12;
GO

INSERT INTO silver.erp_cust_az12 (
    cid,
    bdate,
    gen
)
SELECT
    -- Strip 'NAS' prefix if it exists
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid 
    END AS cid,
    
    -- Nullify future birthdates
    CASE 
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate 
    END AS bdate,
    
    -- Standardize gender values using IN() for multiple matches
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a' 
    END AS gen
FROM bronze.erp_cust_az12;

-- ============================================================================
-- 6. FULL DATA CHECK
-- Purpose: Quickly review a sample of the overall cleansed dataset.
-- ============================================================================
SELECT * FROM silver.erp_cust_az12;