/*
Migration: 20260506_1000_DropCustomerTypes_TypeIdColumn
Author:
Date: 2026-05-06
Description: Drops unused TypeId column and UQ_CustomerTypes_TypeId from MAC.CustomerTypes.
             Reroutes FK_Customers_CustomerTypes to reference CustomerTypeID (PK) instead.
Dependencies: None
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260506_1000_DropCustomerTypes_TypeIdColumn';

    -- Check if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion]
               WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Drop FK on Customers that references UQ_CustomerTypes_TypeId (must go before UQ constraint)
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Customers_CustomerTypes')
    BEGIN
        ALTER TABLE [MAC].[Customers] DROP CONSTRAINT [FK_Customers_CustomerTypes];
    END

    -- Drop unique constraint (must go before dropping the column)
    IF EXISTS (SELECT 1 FROM sys.objects
               WHERE name = 'UQ_CustomerTypes_TypeId'
                 AND parent_object_id = OBJECT_ID('MAC.CustomerTypes'))
    BEGIN
        ALTER TABLE [MAC].[CustomerTypes] DROP CONSTRAINT [UQ_CustomerTypes_TypeId];
    END

    -- Drop the TypeId column
    IF EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('MAC.CustomerTypes')
                 AND name = 'TypeId')
    BEGIN
        ALTER TABLE [MAC].[CustomerTypes] DROP COLUMN [TypeId];
    END

    -- Re-add FK referencing the PK (CustomerTypeID) instead of the dropped TypeId column
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Customers_CustomerTypes')
    BEGIN
        ALTER TABLE [MAC].[Customers] WITH CHECK ADD CONSTRAINT [FK_Customers_CustomerTypes]
            FOREIGN KEY ([CustomerTypeId]) REFERENCES [MAC].[CustomerTypes] ([CustomerTypeID]);
    END

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (@MigrationName, 'Drops TypeId column and UQ_CustomerTypes_TypeId from MAC.CustomerTypes; reroutes FK_Customers_CustomerTypes to CustomerTypeID (PK)');

    COMMIT TRANSACTION;
    PRINT 'Migration 20260506_1000_DropCustomerTypes_TypeIdColumn applied successfully.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR (@ErrMsg, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
ALTER TABLE [MAC].[Customers] DROP CONSTRAINT [FK_Customers_CustomerTypes];
ALTER TABLE [MAC].[CustomerTypes] ADD [TypeId] [int] NOT NULL CONSTRAINT [DF_CustomerTypes_TypeId_Rollback] DEFAULT (0);
ALTER TABLE [MAC].[CustomerTypes] ADD CONSTRAINT [UQ_CustomerTypes_TypeId] UNIQUE ([TypeId]);
ALTER TABLE [MAC].[CustomerTypes] DROP CONSTRAINT [DF_CustomerTypes_TypeId_Rollback];
ALTER TABLE [MAC].[Customers] WITH CHECK ADD CONSTRAINT [FK_Customers_CustomerTypes]
    FOREIGN KEY ([CustomerTypeId]) REFERENCES [MAC].[CustomerTypes] ([TypeId]);
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260506_1000_DropCustomerTypes_TypeIdColumn';
*/
