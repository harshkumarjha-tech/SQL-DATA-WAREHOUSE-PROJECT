/*
===============================================================================
Script Purpose: Initialize Data Warehouse Database and Schemas
-------------------------------------------------------------------------------
Description:
    This script creates a new database named 'DataWarehouse' after switching 
    to the system 'master' database. Once the database is created, it sets up 
    three foundational schemas: 'bronze', 'silver', and 'gold', following the 
    Medallion Architecture design pattern.
===============================================================================
*/

-- Switch to the system 'master' database first.
-- In SQL Server, database creation and management commands should be executed 
-- from the master context rather than inside an active user database.
USE master;
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