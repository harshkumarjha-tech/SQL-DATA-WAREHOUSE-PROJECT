/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
    within the database: 'bronze', 'silver', and 'gold'.

WARNING:
    Running this script will drop the entire 'DataWarehouse' database if it exists.
    All data in the database will be permanently deleted. Proceed with caution
    and ensure you have proper backups before running this script.
*/

-- Switch to the system 'master' database first.
-- In SQL Server, database creation and management commands should be executed 
-- from the master context rather than inside an active user database.
USE master;
GO

-- Check if a database named 'DataWarehouse' already exists in the system catalog
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    -- Change access to one user and instantly sever all other active connections 
    -- to prevent "database is in use" locking errors.
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE; 
    
    -- Permanently delete the database now that it is safely isolated.
    DROP DATABASE DataWarehouse;
END
-- Execute this entire batch of commands before proceeding further.
GO

-- Create the main DataWarehouse database to store all project objects
CREATE DATABASE DataWarehouse;
GO

-- Switch the active query context to the newly created DataWarehouse database
-- so all subsequent objects (schemas, tables, views) are created inside it.
USE DataWarehouse;
GO

-- ============================================================================
-- Create Medallion Architecture Schemas
-- Note: 'GO' is a batch separator in SQL Server. CREATE SCHEMA must be the 
-- first statement in a query batch, so each schema requires its own GO block.
-- ============================================================================

-- 1. Bronze Schema: Holds raw, unprocessed tables loaded as-is from source CSVs
CREATE SCHEMA bronze;
GO

-- 2. Silver Schema: Holds cleansed, standardized, and normalized intermediate tables
CREATE SCHEMA silver;
GO

-- 3. Gold Schema: Holds business-ready Star Schema views (Fact & Dimension) for reporting
CREATE SCHEMA gold;
GO