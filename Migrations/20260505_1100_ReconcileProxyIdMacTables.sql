/*
Migration: 20260505_1100_ReconcileProxyIdMacTables
Author: Andres Sosa
Date: 2026-05-05
Description: Reconciles 9 MAC schema tables to conform with the Proxy-ID
             architectural standard (Database Constitution, Article XV).

             Problem: MAC *Types* tables were created with Proxy + PartKey
             columns, which belong only on entity tables. Type tables are the
             SOURCE of the Prefix code — they must carry a Prefix column, not
             a composite proxy identifier.

             Problem: MAC entity tables had PartKey defined as INT. PartKey
             stores hex strings (e.g. "316BD"), not integers.

             Changes applied:

             *Types* tables (5):
               CustomerTypes, EstimateTypes, PurchaseOrderTypes,
               QuoteTypes, EstimatePhotoTypes
               - DROP  [Proxy]   nvarchar(50) NOT NULL  ← wrong on type tables
               - DROP  [PartKey] int          NOT NULL  ← wrong on type tables
               - ADD   [Prefix]  varchar(4)   NOT NULL  ← correct for type tables
               - ADD   CONSTRAINT UQ_[Table]_Prefix UNIQUE ([Prefix])

             Entity tables (4):
               Estimates, PurchaseOrders, Quotes, EstimatePhotos
               - ALTER COLUMN [PartKey]  int → varchar(6) NOT NULL

             Precondition: All 9 tables contain 0 rows (verified 2026-05-05).
             No DEFAULT constraints exist on any affected Proxy or PartKey column.

Dependencies: 20260313_0845_Baseline_Schemas
              20260505_1000_AddProxyIdFoundation
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260505_1100_ReconcileProxyIdMacTables';

    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- =========================================================================
    -- *Types* Tables: DROP Proxy + PartKey, ADD Prefix VARCHAR(4) + UNIQUE
    -- =========================================================================

    -- CustomerTypes
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.CustomerTypes') AND name = 'Proxy')
        ALTER TABLE [MAC].[CustomerTypes] DROP COLUMN [Proxy];
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.CustomerTypes') AND name = 'PartKey')
        ALTER TABLE [MAC].[CustomerTypes] DROP COLUMN [PartKey];
    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.CustomerTypes') AND name = 'Prefix')
        ALTER TABLE [MAC].[CustomerTypes] ADD [Prefix] [varchar](4) NOT NULL;
    IF NOT EXISTS (SELECT 1
FROM sys.objects
WHERE name = 'UQ_CustomerTypes_Prefix' AND type = 'UQ')
        ALTER TABLE [MAC].[CustomerTypes] ADD CONSTRAINT [UQ_CustomerTypes_Prefix] UNIQUE ([Prefix]);
    PRINT 'Reconciled MAC.CustomerTypes';

    -- EstimateTypes
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimateTypes') AND name = 'Proxy')
        ALTER TABLE [MAC].[EstimateTypes] DROP COLUMN [Proxy];
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimateTypes') AND name = 'PartKey')
        ALTER TABLE [MAC].[EstimateTypes] DROP COLUMN [PartKey];
    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimateTypes') AND name = 'Prefix')
        ALTER TABLE [MAC].[EstimateTypes] ADD [Prefix] [varchar](4) NOT NULL;
    IF NOT EXISTS (SELECT 1
FROM sys.objects
WHERE name = 'UQ_EstimateTypes_Prefix' AND type = 'UQ')
        ALTER TABLE [MAC].[EstimateTypes] ADD CONSTRAINT [UQ_EstimateTypes_Prefix] UNIQUE ([Prefix]);
    PRINT 'Reconciled MAC.EstimateTypes';

    -- PurchaseOrderTypes
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrderTypes') AND name = 'Proxy')
        ALTER TABLE [MAC].[PurchaseOrderTypes] DROP COLUMN [Proxy];
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrderTypes') AND name = 'PartKey')
        ALTER TABLE [MAC].[PurchaseOrderTypes] DROP COLUMN [PartKey];
    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrderTypes') AND name = 'Prefix')
        ALTER TABLE [MAC].[PurchaseOrderTypes] ADD [Prefix] [varchar](4) NOT NULL;
    IF NOT EXISTS (SELECT 1
FROM sys.objects
WHERE name = 'UQ_PurchaseOrderTypes_Prefix' AND type = 'UQ')
        ALTER TABLE [MAC].[PurchaseOrderTypes] ADD CONSTRAINT [UQ_PurchaseOrderTypes_Prefix] UNIQUE ([Prefix]);
    PRINT 'Reconciled MAC.PurchaseOrderTypes';

    -- QuoteTypes
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.QuoteTypes') AND name = 'Proxy')
        ALTER TABLE [MAC].[QuoteTypes] DROP COLUMN [Proxy];
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.QuoteTypes') AND name = 'PartKey')
        ALTER TABLE [MAC].[QuoteTypes] DROP COLUMN [PartKey];
    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.QuoteTypes') AND name = 'Prefix')
        ALTER TABLE [MAC].[QuoteTypes] ADD [Prefix] [varchar](4) NOT NULL;
    IF NOT EXISTS (SELECT 1
FROM sys.objects
WHERE name = 'UQ_QuoteTypes_Prefix' AND type = 'UQ')
        ALTER TABLE [MAC].[QuoteTypes] ADD CONSTRAINT [UQ_QuoteTypes_Prefix] UNIQUE ([Prefix]);
    PRINT 'Reconciled MAC.QuoteTypes';

    -- EstimatePhotoTypes
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotoTypes') AND name = 'Proxy')
        ALTER TABLE [MAC].[EstimatePhotoTypes] DROP COLUMN [Proxy];
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotoTypes') AND name = 'PartKey')
        ALTER TABLE [MAC].[EstimatePhotoTypes] DROP COLUMN [PartKey];
    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotoTypes') AND name = 'Prefix')
        ALTER TABLE [MAC].[EstimatePhotoTypes] ADD [Prefix] [varchar](4) NOT NULL;
    IF NOT EXISTS (SELECT 1
FROM sys.objects
WHERE name = 'UQ_EstimatePhotoTypes_Prefix' AND type = 'UQ')
        ALTER TABLE [MAC].[EstimatePhotoTypes] ADD CONSTRAINT [UQ_EstimatePhotoTypes_Prefix] UNIQUE ([Prefix]);
    PRINT 'Reconciled MAC.EstimatePhotoTypes';

    -- =========================================================================
    -- Entity Tables: ALTER PartKey INT → VARCHAR(6)
    -- =========================================================================

    IF EXISTS (
        SELECT 1
FROM sys.columns AS c
    INNER JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('MAC.Estimates') AND c.name = 'PartKey' AND ty.name = 'int'
    )
        ALTER TABLE [MAC].[Estimates] ALTER COLUMN [PartKey] [varchar](6) NOT NULL;
    PRINT 'Reconciled MAC.Estimates (PartKey → varchar(6))';

    IF EXISTS (
        SELECT 1
FROM sys.columns AS c
    INNER JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('MAC.PurchaseOrders') AND c.name = 'PartKey' AND ty.name = 'int'
    )
        ALTER TABLE [MAC].[PurchaseOrders] ALTER COLUMN [PartKey] [varchar](6) NOT NULL;
    PRINT 'Reconciled MAC.PurchaseOrders (PartKey → varchar(6))';

    IF EXISTS (
        SELECT 1
FROM sys.columns AS c
    INNER JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('MAC.Quotes') AND c.name = 'PartKey' AND ty.name = 'int'
    )
        ALTER TABLE [MAC].[Quotes] ALTER COLUMN [PartKey] [varchar](6) NOT NULL;
    PRINT 'Reconciled MAC.Quotes (PartKey → varchar(6))';

    IF EXISTS (
        SELECT 1
FROM sys.columns AS c
    INNER JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('MAC.EstimatePhotos') AND c.name = 'PartKey' AND ty.name = 'int'
    )
        ALTER TABLE [MAC].[EstimatePhotos] ALTER COLUMN [PartKey] [varchar](6) NOT NULL;
    PRINT 'Reconciled MAC.EstimatePhotos (PartKey → varchar(6))';

    -- =========================================================================
    -- Record migration
    -- =========================================================================
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (
        @MigrationName,
        'Reconciles 9 MAC tables with Proxy-ID standard: drops Proxy+PartKey from 5 *Types* tables, adds Prefix VARCHAR(4) NOT NULL + UNIQUE constraint; alters PartKey INT → VARCHAR(6) on 4 entity tables.'
    );

    COMMIT TRANSACTION;
    PRINT 'Migration 20260505_1100_ReconcileProxyIdMacTables applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
----------------
-- *Types* tables: remove Prefix + UNIQUE, restore Proxy + PartKey
ALTER TABLE [MAC].[CustomerTypes]       DROP CONSTRAINT [UQ_CustomerTypes_Prefix];
ALTER TABLE [MAC].[CustomerTypes]       DROP COLUMN [Prefix];
ALTER TABLE [MAC].[CustomerTypes]       ADD [Proxy] [nvarchar](50) NOT NULL, [PartKey] [int] NOT NULL;

ALTER TABLE [MAC].[EstimateTypes]       DROP CONSTRAINT [UQ_EstimateTypes_Prefix];
ALTER TABLE [MAC].[EstimateTypes]       DROP COLUMN [Prefix];
ALTER TABLE [MAC].[EstimateTypes]       ADD [Proxy] [nvarchar](50) NOT NULL, [PartKey] [int] NOT NULL;

ALTER TABLE [MAC].[PurchaseOrderTypes]  DROP CONSTRAINT [UQ_PurchaseOrderTypes_Prefix];
ALTER TABLE [MAC].[PurchaseOrderTypes]  DROP COLUMN [Prefix];
ALTER TABLE [MAC].[PurchaseOrderTypes]  ADD [Proxy] [nvarchar](50) NOT NULL, [PartKey] [int] NOT NULL;

ALTER TABLE [MAC].[QuoteTypes]          DROP CONSTRAINT [UQ_QuoteTypes_Prefix];
ALTER TABLE [MAC].[QuoteTypes]          DROP COLUMN [Prefix];
ALTER TABLE [MAC].[QuoteTypes]          ADD [Proxy] [nvarchar](50) NOT NULL, [PartKey] [int] NOT NULL;

ALTER TABLE [MAC].[EstimatePhotoTypes]  DROP CONSTRAINT [UQ_EstimatePhotoTypes_Prefix];
ALTER TABLE [MAC].[EstimatePhotoTypes]  DROP COLUMN [Prefix];
ALTER TABLE [MAC].[EstimatePhotoTypes]  ADD [Proxy] [nvarchar](50) NOT NULL, [PartKey] [int] NOT NULL;

-- Entity tables: revert PartKey to int
ALTER TABLE [MAC].[Estimates]       ALTER COLUMN [PartKey] [int] NOT NULL;
ALTER TABLE [MAC].[PurchaseOrders]  ALTER COLUMN [PartKey] [int] NOT NULL;
ALTER TABLE [MAC].[Quotes]          ALTER COLUMN [PartKey] [int] NOT NULL;
ALTER TABLE [MAC].[EstimatePhotos]  ALTER COLUMN [PartKey] [int] NOT NULL;

DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260505_1100_ReconcileProxyIdMacTables';
*/

/*
TEST QUERIES:
-------------
-- *Types* tables should have Prefix VARCHAR(4), no Proxy or PartKey
SELECT t.name AS TableName, c.name AS ColumnName, ty.name AS DataType, c.max_length
FROM sys.columns AS c
INNER JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
INNER JOIN sys.tables AS t ON t.object_id = c.object_id
INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = 'MAC'
  AND t.name IN ('CustomerTypes','EstimateTypes','PurchaseOrderTypes','QuoteTypes','EstimatePhotoTypes')
  AND c.name IN ('Proxy','PartKey','Prefix')
ORDER BY t.name, c.column_id;

-- Entity tables should have PartKey VARCHAR(6)
SELECT t.name AS TableName, c.name AS ColumnName, ty.name AS DataType, c.max_length
FROM sys.columns AS c
INNER JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
INNER JOIN sys.tables AS t ON t.object_id = c.object_id
INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = 'MAC'
  AND t.name IN ('Estimates','PurchaseOrders','Quotes','EstimatePhotos')
  AND c.name IN ('Proxy','PartKey')
ORDER BY t.name, c.column_id;

-- UNIQUE constraints on *Types* tables
SELECT t.name AS TableName, o.name AS ConstraintName
FROM sys.objects AS o
INNER JOIN sys.tables AS t ON t.object_id = o.parent_object_id
INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = 'MAC' AND o.type = 'UQ'
  AND o.name LIKE '%Prefix%'
ORDER BY t.name;
*/
