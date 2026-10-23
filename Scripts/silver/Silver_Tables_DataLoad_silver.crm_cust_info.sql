USE [DataWarehouse];
GO

/*
===============================================================================
KEYWORDS EXPLAINED:
===============================================================================
- IS NULL / IS NOT NULL: Used to test for empty (NULL) values. Standard operators 
  like '=' do not work with NULLs.
- GROUP BY: Groups rows that have the exact same values into summary rows, 
  typically used alongside aggregate functions like COUNT().
- HAVING: Acts exactly like a WHERE clause, but it is used to filter records 
  AFTER they have been grouped by the GROUP BY clause.
- WITH: The keyword used to define a Common Table Expression (CTE), creating 
  a temporary named result set that only exists for the duration of the query.
- ROW_NUMBER(): A window function that assigns a sequential integer (1, 2, 3...) 
  to each row based on your sorting rules.
- OVER(): Defines the specific "window" or set of rows that the ROW_NUMBER() 
  function should operate on.
- PARTITION BY: Divides your data into subsets (in this case, grouping by cst_id) 
  so that ROW_NUMBER() restarts its count back to 1 for every new customer ID.
- TRIM(): Removes unwanted leading and trailing spaces from a text string.
- UPPER(): Converts all letters in a text string to uppercase.
- CASE: Acts like an IF-THEN-ELSE statement to evaluate conditions and return 
  specific values based on those conditions.
===============================================================================
*/

/*
===============================================================================
SECTION 1: DATA PROFILING & QUALITY CHECKS
===============================================================================
Script Purpose: 
    Run these queries interactively to inspect the raw bronze data, identify 
    anomalies (like duplicates, NULLs, spaces, or bad text), and determine the 
    transformation rules needed for the Silver layer.
===============================================================================
*/

-- ============================================================================
-- 1. NULL Check on Primary Key
-- Expectation: No Results. Identifies records completely missing a customer ID.
-- ============================================================================
SELECT * 
FROM bronze.crm_cust_info
WHERE cst_id IS NULL
ORDER BY cst_id;

-- ============================================================================
-- 2. Duplicate Check on Primary Key
-- Expectation: No Results. Identifies customer IDs appearing more than once.
-- ============================================================================
SELECT 
    cst_id, 
    COUNT(*) AS record_count
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- ============================================================================
-- 3. Deep Dive Analysis into Duplicates
-- Purpose: Investigate a known duplicate (e.g., ID 29449) to find the root cause.
-- Finding: The source system created a new row when a record was updated. 
-- Solution: Keep the record with the most recent cst_create_date.
-- ============================================================================
SELECT * 
FROM bronze.crm_cust_info
WHERE cst_id = '29449';

-- ============================================================================
-- 4. Whitespace Check
-- Expectation: No Results. Checks if string columns have hidden leading/trailing spaces.
-- ============================================================================
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

-- ============================================================================
-- 5. Data Consistency Check (Low Cardinality Columns)
-- Purpose: See all unique values to identify inconsistencies (e.g., 'F', 'Female', 'M').
-- ============================================================================
SELECT DISTINCT cst_gndr 
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status 
FROM bronze.crm_cust_info;

/*
===============================================================================
SECTION 2: DATA CLEANING & TRANSFORMATION SCRIPT
===============================================================================
Script Purpose: 
    This is the final script that applies all fixes discovered in Section 1. 
    It deduplicates records, drops NULL keys, trims spaces, and standardizes 
    categorical data into readable formats, inserting the clean data into Silver.

CTE vs. Subquery Context:
    We use a CTE (Common Table Expression) here because it is the industry 
    standard. While a subquery performs exactly the same, CTEs read linearly 
    (top-to-bottom), are highly readable, and can be easily tested block-by-block.
===============================================================================
*/

-- Best Practice: Clear out the silver table before running a full load 
-- to prevent duplicating data if the script is executed multiple times.
TRUNCATE TABLE silver.crm_cust_info;
GO

-- Step 1: Assign row numbers to find the most recently updated record per customer
WITH crm_cust_info_cleaned AS ( 
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY cst_id 
            ORDER BY cst_create_date DESC
        ) as latestRowRNK 
    FROM bronze.crm_cust_info
) 
-- Step 2: Insert the cleaned, deduplicated data directly into the Silver table
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status, -- Note: Spelled 'material' to match your original DDL
    cst_gndr,
    cst_create_date
)
SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname)  AS cst_lastname,
    
    -- Standardize Marital Status values
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS cst_marital_status,
    
    -- Standardize Gender values
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr,
    
    cst_create_date -- Already a DATE data type in the Bronze DDL, no conversion needed

FROM crm_cust_info_cleaned 
WHERE latestRowRNK = 1    -- Drops old duplicate records
  AND cst_id IS NOT NULL; -- Drops invalid blank records