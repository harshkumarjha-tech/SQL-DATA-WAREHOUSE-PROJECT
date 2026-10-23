USE [DataWarehouse];
GO

/*
===============================================================================
KEYWORDS EXPLAINED (NEW FUNCTIONS ADDED):
===============================================================================
- NULLIF(expression1, expression2): Compares two expressions. If they are equal, 
  it returns NULL. If not, it returns expression1. Highly useful for preventing 
  "Divide by Zero" errors (e.g., NULLIF(quantity, 0)).
- CAST(): Converts a value from one data type to another. 
- ABS(): Returns the absolute (positive) value of a number. Converts negative 
  prices into positive ones.
===============================================================================
*/

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
-- Expectation: No Results (0 rows). A blank result means our sales table 
--              and product table are perfectly synced without "ghost" products.
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
FROM bronze.crm_sales_details 
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- ============================================================================
-- 2. Referential Integrity Check (Customer ID)
-- Expectation: No Results. Ensures every sale is tied to a valid customer.
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
FROM bronze.crm_sales_details 
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- ============================================================================
-- 3. Invalid Date Format Checks (Order, Ship, Due Dates)
-- Purpose: Dates are stored as integers (YYYYMMDD). We check for invalid 
--          values like 0, lengths other than 8, or dates wildly out of bounds. 
-- ============================================================================
-- Check Order Date
SELECT NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM bronze.crm_sales_details 
WHERE sls_order_dt <= 0 
   OR LEN(sls_order_dt) != 8 
   OR sls_order_dt > 20500101 
   OR sls_order_dt < 19000101;

-- Check Ship Date
SELECT NULLIF(sls_ship_dt, 0) AS sls_ship_dt
FROM bronze.crm_sales_details 
WHERE sls_ship_dt <= 0 
   OR LEN(sls_ship_dt) != 8 
   OR sls_ship_dt > 20500101 
   OR sls_ship_dt < 19000101;

-- Check Due Date
SELECT NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details 
WHERE sls_due_dt <= 0 
   OR LEN(sls_due_dt) != 8 
   OR sls_due_dt > 20500101 
   OR sls_due_dt < 19000101;

-- ============================================================================
-- 4. Logical Date Constraint Check
-- Expectation: No Results. An order date cannot happen AFTER it was shipped 
--              or after its due date.
-- ============================================================================
SELECT * 
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- ============================================================================
-- 5. Business Logic & Measure Validation (Sales = Quantity * Price)
-- Purpose: Find rows where the core math fails or contains zeroes/negatives.
-- Resolution Rules applied in Section 2:
--   - If Sales is bad -> Derive it using (Quantity * ABS(Price)).
--   - If Price is bad -> Derive it using (Sales / Quantity).
--   - If Price is negative -> Convert to positive.
-- ============================================================================
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
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
Script Purpose: 
    Truncates the silver sales table and inserts the cleansed data. 
    It applies all data type conversions (Integer to Date) and fixes 
    mathematical discrepancies in Sales and Price based on business rules.
===============================================================================
*/

-- Best Practice: Clear out the table before running a full load
TRUNCATE TABLE silver.crm_sales_details;
GO

INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,    
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price 
)
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    
    -- ==========================================
    -- Date Formatting Logic (INT to DATE)
    -- ==========================================
    -- Logic: If the integer date is invalid, missing, or out of bounds, replace 
    -- it with NULL. Otherwise, cast the integer to a string ('YYYYMMDD'), 
    -- then cast that string directly into a SQL DATE data type.
    
    CASE 
        WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 OR sls_order_dt > 20500101 OR sls_order_dt < 19000101 THEN NULL 
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
    END AS sls_order_dt,
    
    CASE 
        WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 OR sls_ship_dt > 20500101 OR sls_ship_dt < 19000101 THEN NULL 
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
    END AS sls_ship_dt,
    
    CASE 
        WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 OR sls_due_dt > 20500101 OR sls_due_dt < 19000101 THEN NULL 
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) 
    END AS sls_due_dt,
    
    -- ==========================================
    -- Business Math Logic (Sales, Quantity, Price)
    -- ==========================================
    
    -- Recalculate Sales if missing, negative, or mathematically incorrect
    CASE 
        WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    
    sls_quantity,
    
    -- Recalculate Price if missing or <= 0. 
    -- NULLIF(sls_quantity, 0) prevents a fatal 'Divide by Zero' system error.
    CASE 
        WHEN sls_price IS NULL OR sls_price <= 0 
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price

FROM bronze.crm_sales_details;