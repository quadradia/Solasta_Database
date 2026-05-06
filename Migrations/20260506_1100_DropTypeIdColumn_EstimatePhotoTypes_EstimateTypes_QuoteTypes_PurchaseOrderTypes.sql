/*
Migration: 20260506_1100_DropTypeIdColumn_EstimatePhotoTypes_EstimateTypes_QuoteTypes_PurchaseOrderTypes
Author:
Date: 2026-05-06
Description: Drops the unused TypeId column (and its UQ constraint) from four MAC *Types tables.
             Reroutes the four FKs that referenced TypeId to instead reference each table's PK column.
             Also adds the missing FK definitions for EstimatePhotos, Quotes, and PurchaseOrders.
Dependencies: 20260506_1000_DropCustomerTypes_TypeIdColumn
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260506_1100_DropTypeIdColumn_EstimatePhotoTypes_EstimateTypes_QuoteTypes_PurchaseOrderTypes';

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- =========================================================================
    -- EstimatePhotoTypes: drop FK, drop UQ, drop column, re-add FK to PK
    -- =========================================================================
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_EstimatePhotos_EstimatePhotoTypes')
        ALTER TABLE [MAC].[EstimatePhotos] DROP CONSTRAINT [FK_EstimatePhotos_EstimatePhotoTypes];

    IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UQ_EstimatePhotoTypes_TypeId' AND parent_object_id = OBJECT_ID('MAC.EstimatePhotoTypes'))
        ALTER TABLE [MAC].[EstimatePhotoTypes] DROP CONSTRAINT [UQ_EstimatePhotoTypes_TypeId];

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('MAC.EstimatePhotoTypes') AND name = 'TypeId')
        ALTER TABLE [MAC].[EstimatePhotoTypes] DROP COLUMN [TypeId];

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_EstimatePhotos_EstimatePhotoTypes')
        ALTER TABLE [MAC].[EstimatePhotos] WITH CHECK ADD CONSTRAINT [FK_EstimatePhotos_EstimatePhotoTypes]
            FOREIGN KEY ([EstimatePhotoTypeId]) REFERENCES [MAC].[EstimatePhotoTypes] ([EstimatePhotoTypeID]);

    -- =========================================================================
    -- EstimateTypes: drop FK, drop UQ, drop column, re-add FK to PK
    -- =========================================================================
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Estimates_EstimateTypes')
        ALTER TABLE [MAC].[Estimates] DROP CONSTRAINT [FK_Estimates_EstimateTypes];

    IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UQ_EstimateTypes_TypeId' AND parent_object_id = OBJECT_ID('MAC.EstimateTypes'))
        ALTER TABLE [MAC].[EstimateTypes] DROP CONSTRAINT [UQ_EstimateTypes_TypeId];

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('MAC.EstimateTypes') AND name = 'TypeId')
        ALTER TABLE [MAC].[EstimateTypes] DROP COLUMN [TypeId];

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Estimates_EstimateTypes')
        ALTER TABLE [MAC].[Estimates] WITH CHECK ADD CONSTRAINT [FK_Estimates_EstimateTypes]
            FOREIGN KEY ([EstimateTypeId]) REFERENCES [MAC].[EstimateTypes] ([EstimateTypeID]);

    -- =========================================================================
    -- QuoteTypes: drop FK, drop UQ, drop column, re-add FK to PK
    -- =========================================================================
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Quotes_QuoteTypes')
        ALTER TABLE [MAC].[Quotes] DROP CONSTRAINT [FK_Quotes_QuoteTypes];

    IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UQ_QuoteTypes_TypeId' AND parent_object_id = OBJECT_ID('MAC.QuoteTypes'))
        ALTER TABLE [MAC].[QuoteTypes] DROP CONSTRAINT [UQ_QuoteTypes_TypeId];

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('MAC.QuoteTypes') AND name = 'TypeId')
        ALTER TABLE [MAC].[QuoteTypes] DROP COLUMN [TypeId];

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Quotes_QuoteTypes')
        ALTER TABLE [MAC].[Quotes] WITH CHECK ADD CONSTRAINT [FK_Quotes_QuoteTypes]
            FOREIGN KEY ([QuoteTypeId]) REFERENCES [MAC].[QuoteTypes] ([QuoteTypeID]);

    -- =========================================================================
    -- PurchaseOrderTypes: drop FK, drop UQ, drop column, re-add FK to PK
    -- =========================================================================
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PurchaseOrders_PurchaseOrderTypes')
        ALTER TABLE [MAC].[PurchaseOrders] DROP CONSTRAINT [FK_PurchaseOrders_PurchaseOrderTypes];

    IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UQ_PurchaseOrderTypes_TypeId' AND parent_object_id = OBJECT_ID('MAC.PurchaseOrderTypes'))
        ALTER TABLE [MAC].[PurchaseOrderTypes] DROP CONSTRAINT [UQ_PurchaseOrderTypes_TypeId];

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('MAC.PurchaseOrderTypes') AND name = 'TypeId')
        ALTER TABLE [MAC].[PurchaseOrderTypes] DROP COLUMN [TypeId];

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PurchaseOrders_PurchaseOrderTypes')
        ALTER TABLE [MAC].[PurchaseOrders] WITH CHECK ADD CONSTRAINT [FK_PurchaseOrders_PurchaseOrderTypes]
            FOREIGN KEY ([PurchaseOrderTypeId]) REFERENCES [MAC].[PurchaseOrderTypes] ([PurchaseOrderTypeID]);

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (@MigrationName, 'Drops TypeId column from EstimatePhotoTypes, EstimateTypes, QuoteTypes, PurchaseOrderTypes; reroutes FKs to PK columns');

    COMMIT TRANSACTION;
    PRINT 'Migration 20260506_1100_DropTypeIdColumn_EstimatePhotoTypes_EstimateTypes_QuoteTypes_PurchaseOrderTypes applied successfully.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR (@ErrMsg, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- Re-add TypeId columns and UQ constraints, drop re-added FKs, restore original FKs referencing TypeId.
-- EstimatePhotoTypes
ALTER TABLE [MAC].[EstimatePhotos] DROP CONSTRAINT [FK_EstimatePhotos_EstimatePhotoTypes];
ALTER TABLE [MAC].[EstimatePhotoTypes] ADD [TypeId] [int] NOT NULL CONSTRAINT [DF_EPT_TypeId_RB] DEFAULT (0);
ALTER TABLE [MAC].[EstimatePhotoTypes] ADD CONSTRAINT [UQ_EstimatePhotoTypes_TypeId] UNIQUE ([TypeId]);
ALTER TABLE [MAC].[EstimatePhotoTypes] DROP CONSTRAINT [DF_EPT_TypeId_RB];
ALTER TABLE [MAC].[EstimatePhotos] WITH CHECK ADD CONSTRAINT [FK_EstimatePhotos_EstimatePhotoTypes] FOREIGN KEY ([EstimatePhotoTypeId]) REFERENCES [MAC].[EstimatePhotoTypes] ([TypeId]);
-- (Repeat pattern for EstimateTypes, QuoteTypes, PurchaseOrderTypes)
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260506_1100_DropTypeIdColumn_EstimatePhotoTypes_EstimateTypes_QuoteTypes_PurchaseOrderTypes';
*/
