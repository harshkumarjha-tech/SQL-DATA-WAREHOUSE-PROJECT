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
-- Expectation: No Results. Identifies records completely missing a product ID.
-- ============================================================================
SELECT * 
FROM bronze.crm_prd_info
WHERE prd_id IS NULL
ORDER BY prd_id;

-- ============================================================================
-- 2. Duplicate Check on Primary Key
-- Expectation: No Results. Identifies product IDs appearing more than once.
-- ============================================================================
SELECT 
    prd_id, 
    COUNT(*) AS record_count
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- ============================================================================
-- 3. Composite Key Extraction & Validation
-- Purpose: The raw 'prd_key' contains both the Category ID and the actual Product ID.
-- Logic: 
--   - The first 5 characters represent the Category ID. We extract this using 
--     SUBSTRING. We also REPLACE the dash '-' with an underscore '_' so it 
--     matches the format in the 'bronze.erp_px_cat_g1v2' table.
--   - Everything from character 7 onwards is the actual Product ID, which we 
--     will use later to join with the Sales Details table.
-- ============================================================================
SELECT 
    prd_id,
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,        -- Extracted & formatted Category ID
    SUBSTRING(prd_key, 7, LEN(prd_key))         AS extracted_key, -- Extracted actual Product Key
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info
-- Testing logic: Checking for products that do not exist in the sales table
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) NOT IN (
    SELECT sls_prd_key FROM bronze.crm_sales_details
);

-- ============================================================================
-- 4. Whitespace Check
-- Expectation: No Results. Checks if string columns have hidden leading/trailing spaces.
-- ============================================================================
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- ============================================================================
-- 5. Data Consistency Check (Cost Validation)
-- Purpose: Business rules state costs cannot be negative or NULL.
-- Finding: Negative costs and NULLs exist in the data.
-- Solution: Use a CASE statement to replace negatives and NULLs with 0.
-- ============================================================================
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- ============================================================================
-- 6. Data Standardization (Product Line Abbreviations)
-- Purpose: Map single-letter abbreviations to their full descriptive names based 
-- on business logic provided by the source system experts.
-- ============================================================================
SELECT 
    prd_line,
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line_mapped
FROM bronze.crm_prd_info;

-- ============================================================================
-- 7. Date Correction & Historical Range Fixing (SCD Type 2 Prep)
-- Purpose: The raw start and end dates are invalid (e.g., start dates > end dates, 
-- or overlapping historical ranges for the same product).
-- Solution: 
--   - Keep the original start date.
--   - Use the LEAD() window function to find the *next* start date for that 
--     specific product, and subtract 1 day to create a perfect, non-overlapping 
--     end date for the current record.
--   - CAST everything to DATE to remove unnecessary time components.
-- ============================================================================
SELECT 
    prd_id,
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    CAST(
        LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 
        AS DATE
    ) AS prd_end_dt
FROM bronze.crm_prd_info;


/*
===============================================================================
SECTION 2: DATA CLEANING & TRANSFORMATION SCRIPT
===============================================================================
Script Purpose: 
    This is the final query that applies all the extractions, transformations, 
    data type casting, and date-range fixes discovered in Section 1. This 
    query is ready to be used in an INSERT statement for the Silver layer.
===============================================================================
*/
-- Best Practice: Clear out the silver table before running a full load 
-- to prevent duplicating data if the script is executed multiple times.
TRUNCATE TABLE silver.crm_prd_info;

-- Insert the cleaned and transformed data directly into the Silver table
INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT 
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,  -- Cleaned Category ID
    SUBSTRING(prd_key, 7, LEN(prd_key))         AS prd_key, -- Cleaned Product Key
    prd_nm,
    
    -- Fix negative and NULL costs
    CASE 
        WHEN prd_cost < 0 THEN 0
        WHEN prd_cost IS NULL THEN 0
        ELSE prd_cost
    END AS prd_cost,
    
    -- Map Product Line codes to full names
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line, 
    
    -- Cast start date to DATE format
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    
    -- Calculate the correct End Date using the next Start Date - 1 day
    CAST(
        LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 
        AS DATE 
    ) AS prd_end_dt
FROM bronze.crm_prd_info;