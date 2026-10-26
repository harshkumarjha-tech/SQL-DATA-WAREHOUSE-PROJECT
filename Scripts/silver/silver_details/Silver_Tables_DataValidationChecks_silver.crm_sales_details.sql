USE [DataWarehouse];
GO

/*
===============================================================================
SECTION 1: DATA PROFILING & QUALITY CHECKS (crm_sales_details)
===============================================================================
Script Purpose: 
    Run these queries interactively to inspect the raw bronze sales data, 
    identify anomalies, and determine the transformation rules needed for 
    the Silver layer.
===============================================================================
*/

-- ============================================================================
-- 1. Referential Integrity Check (Product Key)
-- Purpose: "Orphan Check". This asks the database: "Are there any sales 
--          transactions tied to a product that does not exist in our cleaned 
--          product master table?"
-- Expectation: No Results (0 rows). If rows are returned, it means we have 
--              "ghost" products or orphaned sales records. A blank result 
--              means our sales table and product table are perfectly synced.
-- ============================================================================
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,    
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details 
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- ============================================================================
-- 2. Referential Integrity Check (Customer ID)
-- Purpose: Same as above, but checking the Customer dimension. This ensures 
--          every sale is tied to a valid, cleaned customer in our master table.
-- Expectation: No Results.
-- ============================================================================
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,    
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details 
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- ============================================================================
-- 3. Invalid Date Format Check (Order Date)
-- Purpose: Dates are stored as integers (YYYYMMDD). We check for invalid 
--          values like 0, lengths other than 8, or dates wildly out of bounds 
--          (e.g., before 1900 or after 2050). 
-- Expectation: No Results.
-- ============================================================================
SELECT 
    NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM silver.crm_sales_details 
WHERE sls_order_dt <= 0 
   OR LEN(sls_order_dt) != 8 
   OR sls_order_dt > 20500101 
   OR sls_order_dt < 19000101;

   -- this is giving error as datatype chnages to date form int 

-- ============================================================================
-- 4. Invalid Date Format Check (Ship Date)
-- Purpose: Apply the same integer date boundary checks to the Ship Date.
-- Expectation: No Results.
-- ============================================================================
SELECT 
    NULLIF(sls_ship_dt, 0) AS sls_ship_dt
FROM silver.crm_sales_details 
WHERE sls_ship_dt <= 0 
   OR LEN(sls_ship_dt) != 8 
   OR sls_ship_dt > 20500101 
   OR sls_ship_dt < 19000101;

      -- this is giving error as datatype chnages to date form int 

-- ============================================================================
-- 5. Invalid Date Format Check (Due Date)
-- Purpose: Apply the same integer date boundary checks to the Due Date.
-- Expectation: No Results.
-- ============================================================================
SELECT 
    NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM silver.crm_sales_details 
WHERE sls_due_dt <= 0 
   OR LEN(sls_due_dt) != 8 
   OR sls_due_dt > 20500101 
   OR sls_due_dt < 19000101;

      -- this is giving error as datatype chnages to date form int 

-- ============================================================================
-- 6. Logical Date Constraint Check
-- Purpose: Ensure chronological order of events makes sense. A product cannot 
--          be shipped or hit its due date BEFORE it was even ordered.
-- Expectation: No Results.
-- ============================================================================
SELECT * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- ============================================================================
-- 7. Business Logic & Measure Validation (Sales, Quantity, Price)
-- Purpose: Validate the core mathematical equation: Sales = Quantity * Price. 
--          We also check for impossible transaction values like NULLs, zeroes, 
--          or negative numbers across all three columns.
-- Expectation: No Results. 
-- 
-- Resolution Rules (To be implemented in Section 2):
--   - Sol 1: Data issues fixed directly at the source system (Ideal).
--   - Sol 2: Fix in Data Warehouse (Current Approach).
--          Rule A: If Sales is negative, 0, or NULL -> Derive it using (Quantity * Price).
--          Rule B: If Price is 0 or NULL -> Calculate it using (Sales / Quantity).
--          Rule C: If Price is negative -> Convert it to a positive value (using ABS).
-- ============================================================================
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_sales <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0 
ORDER BY sls_sales, sls_quantity, sls_price;

/*
===============================================================================
SECTION 2: DATA CLEANING & TRANSFORMATION SCRIPT
===============================================================================
*/
SELECT * FROM silver.crm_sales_details;