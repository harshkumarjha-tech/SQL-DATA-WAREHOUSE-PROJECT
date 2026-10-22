-- Switches the active connection to your specific database so you don't 
-- accidentally create this procedure in the 'master' system database.
USE [DataWarehouse]
GO

-- Auto-generated timestamp and tracking comment from SSMS.
/****** Object:  StoredProcedure [Bronze].[load_bronze]    Script Date: 21-10-2026 16:57:21 ******/

-- Enforces strict SQL standards for how NULL values are handled.
-- When ON, comparing a value to NULL using an equals sign (e.g., column = NULL) 
-- will fail. You are forced to write proper syntax (e.g., column IS NULL).
-- Always leave this ON.
SET ANSI_NULLS ON
GO

-- Enforces strict SQL standards for quotation marks.
-- When ON, double quotes (" ") or square brackets ([ ]) are strictly used to wrap 
-- table/column names (identifiers), and single quotes (' ') are strictly used 
-- for text strings. Always leave this ON.
SET QUOTED_IDENTIFIER ON
GO

/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads raw CSV data into the 'bronze' schema tables.
    It includes execution time tracking and error handling to ensure robust 
    data pipeline operations.

Usage:
    EXEC bronze.load_bronze;

Keywords Explained:
    - TRY...CATCH: A structural error-handling block. If any error happens inside 
      the TRY block, the code instantly stops and jumps to the CATCH block to 
      report the error cleanly instead of crashing the whole system.
    - GETDATE(): A system function that captures the exact current date and time.
    - DATEDIFF(): Calculates the difference between two timestamps (e.g., in seconds).
===============================================================================
*/

CREATE OR ALTER PROCEDURE [bronze].[load_bronze] AS
BEGIN
    -- Declare variables to store our timestamps
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    
    BEGIN TRY
        -- Start the overall batch timer
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '================================================';

        -- ============================================================================
        -- 1. LOAD CRM DATA (Source: source_crm folder)
        -- ============================================================================
        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        -- Load: crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Inserting Data Into: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info 
        FROM 'C:\Users\azmod\OneDrive\Documents\GitHub\SQL-DATA-WAREHOUSE-PROJECT\Datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2, 
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------';

        -- Load: crm_prd_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> Inserting Data Into: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info 
        FROM 'C:\Users\azmod\OneDrive\Documents\GitHub\SQL-DATA-WAREHOUSE-PROJECT\Datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2, 
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------';

        -- Load: crm_sales_details
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> Inserting Data Into: bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details 
        FROM 'C:\Users\azmod\OneDrive\Documents\GitHub\SQL-DATA-WAREHOUSE-PROJECT\Datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2, 
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------';

        -- ============================================================================
        -- 2. LOAD ERP DATA (Source: source_erp folder)
        -- ============================================================================
        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';

        -- Load: erp_cust_az12
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;
        
        PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12 
        FROM 'C:\Users\azmod\OneDrive\Documents\GitHub\SQL-DATA-WAREHOUSE-PROJECT\Datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2, 
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------';

        -- Load: erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101 
        FROM 'C:\Users\azmod\OneDrive\Documents\GitHub\SQL-DATA-WAREHOUSE-PROJECT\Datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2, 
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------';

        -- Load: erp_px_cat_g1v2
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2 
        FROM 'C:\Users\azmod\OneDrive\Documents\GitHub\SQL-DATA-WAREHOUSE-PROJECT\Datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2, 
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------';

        -- Stop the overall batch timer
        SET @batch_end_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';

    END TRY
    BEGIN CATCH
        -- If any error happens above, the code instantly jumps here
        PRINT '=========================================';
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST (ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST (ERROR_STATE() AS NVARCHAR);
        PRINT '=========================================';
    END CATCH

END;
GO

-- Execute the stored procedure to load the data
EXEC bronze.load_bronze;