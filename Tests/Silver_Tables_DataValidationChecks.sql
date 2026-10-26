/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schema. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

USE [DataWarehouse];
GO

-- ============================================================================
-- TABLE: silver.crm_cust_info
-- ============================================================================
PRINT 'Checking silver.crm_cust_info...';

-- 1. Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    cst_id,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- 2. Whitespace Check
-- Expectation: No Results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- 3. Data Standardization & Consistency Check
-- Expectation: Only clean values ('Male', 'Female', 'n/a', 'Single', 'Married')
SELECT DISTINCT cst_gndr 
FROM silver.crm_cust_info;

SELECT DISTINCT cst_marital_status 
FROM silver.crm_cust_info;


-- ============================================================================
-- TABLE: silver.crm_prd_info
-- ============================================================================
PRINT 'Checking silver.crm_prd_info...';

-- 1. Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    prd_id,
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- 2. Whitespace Check
-- Expectation: No Results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- 3. Data Consistency Check (Cost Validation)
-- Expectation: No Results (No negative costs or NULLs should remain)
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- 4. Date Correction & Historical Range Validation
-- Expectation: No Results (End date should not be before Start date)
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- ============================================================================
-- TABLE: silver.crm_sales_details
-- ============================================================================
PRINT 'Checking silver.crm_sales_details...';

-- 1. Referential Integrity (Orphan Check - Product Key)
-- Expectation: No Results
SELECT sls_ord_num, sls_prd_key
FROM silver.crm_sales_details 
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- 2. Referential Integrity (Orphan Check - Customer ID)
-- Expectation: No Results
SELECT sls_ord_num, sls_cust_id
FROM silver.crm_sales_details 
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- 3. Invalid Date Format Check 
-- Note: Corrected for Silver Layer. Since dates were cast from INT to DATE during 
-- the Silver load, we now check for bounds using standard SQL DATE strings rather 
-- than LEN() or <= 0 integer logic.
-- Expectation: No Results
SELECT sls_order_dt 
FROM silver.crm_sales_details 
WHERE sls_order_dt > '2050-01-01' OR sls_order_dt < '1900-01-01';

SELECT sls_ship_dt 
FROM silver.crm_sales_details 
WHERE sls_ship_dt > '2050-01-01' OR sls_ship_dt < '1900-01-01';

SELECT sls_due_dt 
FROM silver.crm_sales_details 
WHERE sls_due_dt > '2050-01-01' OR sls_due_dt < '1900-01-01';

-- 4. Logical Date Constraint Check
-- Expectation: No Results (Order cannot happen after shipping or due date)
SELECT * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- 5. Business Math Validation (Sales = Quantity * Price)
-- Expectation: No Results (All equations should be perfectly balanced in Silver)
SELECT sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_sales <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0;


-- ============================================================================
-- TABLE: silver.erp_cust_az12
-- ============================================================================
PRINT 'Checking silver.erp_cust_az12...';

-- 1. Key Formatting Check (Prefix Removal Validation)
-- Expectation: No Results ('NAS' prefix should be gone)
SELECT cid
FROM silver.erp_cust_az12
WHERE cid LIKE 'NAS%';

-- 2. Invalid Date Format Check (Birthdates)
-- Expectation: No Results (No future dates)
SELECT bdate 
FROM silver.erp_cust_az12
WHERE bdate > GETDATE() 
   OR bdate < '1900-01-01';

-- 3. Data Standardization Validation (Gender Cardinality)
-- Expectation: Should only return 'Male', 'Female', or 'n/a'
SELECT DISTINCT gen 
FROM silver.erp_cust_az12;


-- ============================================================================
-- TABLE: silver.erp_loc_a101
-- ============================================================================
PRINT 'Checking silver.erp_loc_a101...';

-- 1. Key Formatting Check (Hyphen Removal Validation)
-- Expectation: No Results
SELECT cid
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';

-- 2. Data Standardization Validation (Country Cardinality)
-- Expectation: No Results (Raw abbreviations should be converted)
SELECT *
FROM silver.erp_loc_a101
WHERE cntry COLLATE SQL_Latin1_General_CP1_CS_AS IN ('USA', 'US', 'DE', 'UNITED STATES')
   OR cntry IS NULL
   OR TRIM(cntry) = '';


-- ============================================================================
-- TABLE: silver.erp_px_cat_g1v2
-- ============================================================================
PRINT 'Checking silver.erp_px_cat_g1v2...';

-- 1. Space Check Validation
-- Expectation: No Results
SELECT * 
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

-- 2. Row Count Parity Check (Bronze vs Silver)
-- Expectation: Both numbers should be identical
SELECT 
    (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2) AS Bronze_Row_Count,
    (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2) AS Silver_Row_Count;