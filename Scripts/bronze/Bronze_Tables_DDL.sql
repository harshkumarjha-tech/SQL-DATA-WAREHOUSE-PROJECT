/*
===============================================================================
DDL Script: Create Bronze Layer Tables
===============================================================================
Script Purpose:
    This script initializes the raw data tables in the 'bronze' schema. 
    It includes a safety check for each Data Definition Language (DDL) statement 
    to drop the table if it already exists before creating a fresh one.
===============================================================================
*/

-- ============================================================================
-- Table: bronze.crm_cust_info
-- Description: Stores raw CRM Customer Information
-- ============================================================================
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE
);
GO

-- ============================================================================
-- Table: bronze.crm_prd_info
-- Description: Stores raw CRM Product Information
-- ============================================================================
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id INT,
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(5),
    prd_start_dt DATETIME,
    prd_end_dt DATETIME
);
GO

-- ============================================================================
-- Table: bronze.crm_sales_details
-- Description: Stores raw CRM Sales Details/Transactions
-- ============================================================================
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,    
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT
);
GO

-- ============================================================================
-- Table: bronze.erp_cust_az12
-- Description: Stores raw ERP Customer Mapping Data
-- ============================================================================
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 ( 
   cid NVARCHAR(50),
   bdate DATE,
   gen NVARCHAR(50)
);
GO

-- ============================================================================
-- Table: bronze.erp_loc_a101
-- Description: Stores raw ERP Location Mapping Data
-- ============================================================================
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101 (
    cid NVARCHAR(50),
    cntry NVARCHAR(50)
);
GO

-- ============================================================================
-- Table: bronze.erp_px_cat_g1v2
-- Description: Stores raw ERP Product Category Data
-- ============================================================================
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id NVARCHAR(50),
    cat NVARCHAR(50),
    subcat NVARCHAR(50),
    maintenance NVARCHAR(50)
);
GO

/*
===============================================================================
Query: View Table Creation Times
===============================================================================
Description:
    This query switches to the 'DataWarehouse' database and retrieves a list 
    of all tables, their parent schemas, and their exact creation timestamps.
    Results are sorted with the newest tables appearing at the top.
===============================================================================
*/

-- Switch context to ensure you are querying the correct database
USE DataWarehouse;
GO

-- Query the system catalogs for table details
SELECT 
    s.name AS schema_name,          -- Shows if it is bronze, silver, or gold
    t.name AS table_name,           -- The actual name of the table
    t.create_date AS creation_time, -- The exact timestamp the table was created
    t.modify_date AS modified_time  -- The timestamp of the last structural change (DDL)
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY t.create_date DESC;        -- Sort descending to see the newest tables first

/* 
When you run a standard script in a single SQL Server session, 
the engine does not process commands in parallel or try to reorder them for efficiency based on table size. 
It strictly reads and executes each statement one by one, 
waiting for the current table to finish building before moving on to the next GO block.
*/