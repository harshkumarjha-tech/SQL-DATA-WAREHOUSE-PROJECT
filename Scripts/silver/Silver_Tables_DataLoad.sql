/*
===============================================================================
Keywords Explained:
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

===============================================================================
CTE vs. Subquery: Which is Better for Handling Duplicates?
===============================================================================
PERFORMANCE: 
There is ZERO performance difference. The SQL Server engine translates both 
the CTE and the Subquery into the exact same execution plan behind the scenes.

INDUSTRY STANDARD (Winner: CTE):
The CTE (Common Table Expression) is heavily preferred in data engineering and 
analytics over subqueries for these reasons:
1. Readability: CTEs read linearly from top to bottom. Subqueries force you to 
   read code inside-out, which becomes a nightmare when queries get deeply nested.
2. Reusability: You can reference a CTE multiple times in your final SELECT 
   statement. A subquery must be rewritten every time you need it.
3. Debugging: It is much easier to highlight and execute just the SELECT block 
   inside a CTE to test your logic before running the whole script.
===============================================================================
*/

-- ============================================================================
-- Checking for NULLs or Duplicates in Primary Key (cst_id)
-- Expectation: This query should ideally return No Results if data is clean
-- ============================================================================
SELECT * FROM bronze.crm_cust_info;

-- ============================================================================
-- 1. NULL CHECK
-- Looking for any rows where the critical customer ID is missing
-- ============================================================================
SELECT * FROM bronze.crm_cust_info
WHERE cst_id IS NULL
ORDER BY cst_id;

-- ============================================================================
-- 2. DUPLICATES CHECK
-- Counting how many times each cst_id appears. Filtering to show only IDs 
-- that appear more than once (duplicates) or are NULL.
-- ============================================================================
SELECT 
    cst_id, 
    COUNT(*) AS record_count
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- ============================================================================
-- 3. DEEP DIVE ANALYSIS
-- By running the above query, we found duplicates for 6 specific IDs. 
-- We analyze one of them (29449) to understand WHY it is duplicated.
-- Finding: The source system created a new row when a record was updated, 
-- rather than overwriting the old one.
-- ============================================================================
SELECT * FROM bronze.crm_cust_info
WHERE cst_id = '29449';

-- ============================================================================
-- 4A. HANDLING DUPLICATES (THE CTE METHOD - RECOMMENDED)
-- Logic: We partition the data by cst_id and sort by create date descending.
-- The absolute newest record gets ROW_NUMBER = 1. We then filter for only 1s.
-- ============================================================================
WITH latest_row AS ( 
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as latestRowRNK 
    FROM bronze.crm_cust_info
) 
SELECT * 
FROM latest_row 
WHERE latestRowRNK = 1 
  AND cst_id IS NOT NULL;


-- ============================================================================
-- 4B. HANDLING DUPLICATES (THE SUBQUERY METHOD - NOT RECOMMENDED)
-- Logic is identical to the CTE, but it is harder to read as the core logic 
-- is nested inside the FROM clause. Note the alias 'a' required for subqueries.
-- ============================================================================
SELECT * 
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as latestRowRNK 
    FROM bronze.crm_cust_info 
) a
WHERE latestRowRNK = 1 
  AND cst_id IS NOT NULL;