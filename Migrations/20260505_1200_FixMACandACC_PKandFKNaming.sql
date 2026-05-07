/*
Migration: 20260505_1200_FixMACandACC_PKandFKNaming
Author:
Date: 2026-05-05
Description: Enforces the PK/FK column and constraint naming convention across
             MAC schema tables and ACC.DealerTenantTypes.

             Convention:
               PK column     = singular(TableName) + 'ID'  (uppercase)  e.g. CustomerID
               PK constraint = PK_<TableName>
               FK column     = singular(ParentTable) + 'Id' (mixed case) e.g. CustomerId
               FK constraint = FK_<ChildTable>_<ParentTable>

             Approach: All renames use sp_rename only — no DROP/RECREATE needed.
             SQL Server binds FK/PK references to column_id (not name), so all
             existing FK and PK constraints survive column renames automatically.

             Changes:
               ACC.DealerTenantTypes  — rename PK constraint only (column already correct)
               MAC.CustomerTypes      — rename Id → CustomerTypeID, rename PK constraint
               MAC.Customers          — rename Id → CustomerID, TypeId → CustomerTypeId
                                        rename PK and FK constraints
               MAC.EstimateTypes      — rename Id → EstimateTypeID, rename PK constraint
               MAC.Estimates          — rename Id → EstimateID, TypeId → EstimateTypeId
                                        rename PK and FK constraints
               MAC.EstimatePhotoTypes — rename Id → EstimatePhotoTypeID, rename PK constraint
               MAC.EstimatePhotos     — rename Id → EstimatePhotoID, TypeId → EstimatePhotoTypeId
                                        rename PK and FK constraints
               MAC.QuoteTypes         — rename Id → QuoteTypeID, rename PK constraint
               MAC.Quotes             — rename Id → QuoteID, TypeId → QuoteTypeId
                                        rename PK and FK constraints
               MAC.PurchaseOrderTypes — rename Id → PurchaseOrderTypeID, rename PK constraint
               MAC.PurchaseOrders     — rename Id → PurchaseOrderID, TypeId → PurchaseOrderTypeId
                                        rename PK and FK constraints

Dependencies: 20260313_0846_Baseline_ObjectsDeployed
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260505_1200_FixMACandACC_PKandFKNaming';

    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- =========================================================================
    -- PART A: Rename PK constraints (auto-generated → convention names)
    --         sp_rename 'schema.OldName', 'NewName', 'OBJECT'
    -- =========================================================================

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__TenantTy__3214EC07055BDB73')
        EXEC sp_rename 'ACC.PK__TenantTy__3214EC07055BDB73', 'PK_DealerTenantTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__Customer__3214EC07E77477C1')
        EXEC sp_rename 'MAC.PK__Customer__3214EC07E77477C1', 'PK_CustomerTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__Customer__3214EC07AA488884')
        EXEC sp_rename 'MAC.PK__Customer__3214EC07AA488884', 'PK_Customers', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__Estimate__3214EC071C07399D')
        EXEC sp_rename 'MAC.PK__Estimate__3214EC071C07399D', 'PK_EstimateTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__Estimate__3214EC071E5274CD')
        EXEC sp_rename 'MAC.PK__Estimate__3214EC071E5274CD', 'PK_Estimates', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__Estimate__3214EC07A31DBE60')
        EXEC sp_rename 'MAC.PK__Estimate__3214EC07A31DBE60', 'PK_EstimatePhotoTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__Estimate__3214EC0738E92E94')
        EXEC sp_rename 'MAC.PK__Estimate__3214EC0738E92E94', 'PK_EstimatePhotos', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__QuoteTyp__3214EC077CD2B738')
        EXEC sp_rename 'MAC.PK__QuoteTyp__3214EC077CD2B738', 'PK_QuoteTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__Quotes__3214EC079F102B33')
        EXEC sp_rename 'MAC.PK__Quotes__3214EC079F102B33', 'PK_Quotes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__Purchase__3214EC07AE67CAEC')
        EXEC sp_rename 'MAC.PK__Purchase__3214EC07AE67CAEC', 'PK_PurchaseOrderTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__Purchase__3214EC07FE47559C')
        EXEC sp_rename 'MAC.PK__Purchase__3214EC07FE47559C', 'PK_PurchaseOrders', 'OBJECT';

    -- =========================================================================
    -- PART B: Rename PK columns (Id → TableNameID)
    --         sp_rename binds by column_id, so existing PK/FK constraints
    --         automatically reference the renamed column.
    -- =========================================================================

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.CustomerTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.CustomerTypes.Id', 'CustomerTypeID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Customers') AND name = 'Id')
        EXEC sp_rename 'MAC.Customers.Id', 'CustomerID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimateTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.EstimateTypes.Id', 'EstimateTypeID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Estimates') AND name = 'Id')
        EXEC sp_rename 'MAC.Estimates.Id', 'EstimateID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotoTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.EstimatePhotoTypes.Id', 'EstimatePhotoTypeID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotos') AND name = 'Id')
        EXEC sp_rename 'MAC.EstimatePhotos.Id', 'EstimatePhotoID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.QuoteTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.QuoteTypes.Id', 'QuoteTypeID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Quotes') AND name = 'Id')
        EXEC sp_rename 'MAC.Quotes.Id', 'QuoteID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrderTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.PurchaseOrderTypes.Id', 'PurchaseOrderTypeID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrders') AND name = 'Id')
        EXEC sp_rename 'MAC.PurchaseOrders.Id', 'PurchaseOrderID', 'COLUMN';

    -- =========================================================================
    -- PART C: Rename FK (TypeId / other) columns where needed
    -- =========================================================================

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Customers') AND name = 'TypeId')
        EXEC sp_rename 'MAC.Customers.TypeId', 'CustomerTypeId', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Estimates') AND name = 'TypeId')
        EXEC sp_rename 'MAC.Estimates.TypeId', 'EstimateTypeId', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotos') AND name = 'TypeId')
        EXEC sp_rename 'MAC.EstimatePhotos.TypeId', 'EstimatePhotoTypeId', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Quotes') AND name = 'TypeId')
        EXEC sp_rename 'MAC.Quotes.TypeId', 'QuoteTypeId', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrders') AND name = 'TypeId')
        EXEC sp_rename 'MAC.PurchaseOrders.TypeId', 'PurchaseOrderTypeId', 'COLUMN';

    -- =========================================================================
    -- PART D: Rename FK constraints (auto-generated → convention names)
    --         sp_rename 'schema.OldName', 'NewName', 'OBJECT'
    --         No drop/recreate needed — references survive column renames.
    -- =========================================================================

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Customers__TypeI__1AD3FDA4')
        EXEC sp_rename 'MAC.FK__Customers__TypeI__1AD3FDA4', 'FK_Customers_CustomerTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Estimates__Custo__245D67DE')
        EXEC sp_rename 'MAC.FK__Estimates__Custo__245D67DE', 'FK_Estimates_Customers', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Estimates__TypeI__25518C17')
        EXEC sp_rename 'MAC.FK__Estimates__TypeI__25518C17', 'FK_Estimates_EstimateTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__EstimateP__Estim__43D61337')
        EXEC sp_rename 'MAC.FK__EstimateP__Estim__43D61337', 'FK_EstimatePhotos_Estimates', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__EstimateP__TypeI__44CA3770')
        EXEC sp_rename 'MAC.FK__EstimateP__TypeI__44CA3770', 'FK_EstimatePhotos_EstimatePhotoTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Quotes__Estimate__2EDAF651')
        EXEC sp_rename 'MAC.FK__Quotes__Estimate__2EDAF651', 'FK_Quotes_Estimates', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Quotes__TypeId__2FCF1A8A')
        EXEC sp_rename 'MAC.FK__Quotes__TypeId__2FCF1A8A', 'FK_Quotes_QuoteTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__PurchaseO__Quote__395884C4')
        EXEC sp_rename 'MAC.FK__PurchaseO__Quote__395884C4', 'FK_PurchaseOrders_Quotes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__PurchaseO__TypeI__3A4CA8FD')
        EXEC sp_rename 'MAC.FK__PurchaseO__TypeI__3A4CA8FD', 'FK_PurchaseOrders_PurchaseOrderTypes', 'OBJECT';

    -- =========================================================================
    -- Record migration
    -- =========================================================================
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName,
        'Renames PK columns (Id → TableNameID), FK columns (TypeId → TableNameTypeId), ' +
        'PK constraints, and FK constraints across ACC.DealerTenantTypes and all MAC ' +
        'entity tables to follow project naming conventions. Uses sp_rename throughout ' +
        'to preserve all existing FK/PK bindings without drop/recreate.');

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- Reverse FK constraint renames
EXEC sp_rename 'MAC.FK_Customers_CustomerTypes',              'FK__Customers__TypeI__1AD3FDA4',  'OBJECT';
EXEC sp_rename 'MAC.FK_Estimates_Customers',                  'FK__Estimates__Custo__245D67DE',  'OBJECT';
EXEC sp_rename 'MAC.FK_Estimates_EstimateTypes',              'FK__Estimates__TypeI__25518C17',  'OBJECT';
EXEC sp_rename 'MAC.FK_EstimatePhotos_Estimates',             'FK__EstimateP__Estim__43D61337',  'OBJECT';
EXEC sp_rename 'MAC.FK_EstimatePhotos_EstimatePhotoTypes',    'FK__EstimateP__TypeI__44CA3770',  'OBJECT';
EXEC sp_rename 'MAC.FK_Quotes_Estimates',                     'FK__Quotes__Estimate__2EDAF651',  'OBJECT';
EXEC sp_rename 'MAC.FK_Quotes_QuoteTypes',                    'FK__Quotes__TypeId__2FCF1A8A',    'OBJECT';
EXEC sp_rename 'MAC.FK_PurchaseOrders_Quotes',                'FK__PurchaseO__Quote__395884C4',  'OBJECT';
EXEC sp_rename 'MAC.FK_PurchaseOrders_PurchaseOrderTypes',    'FK__PurchaseO__TypeI__3A4CA8FD',  'OBJECT';
-- Reverse PK column renames
EXEC sp_rename 'MAC.CustomerTypes.CustomerTypeID',    'Id', 'COLUMN';
EXEC sp_rename 'MAC.Customers.CustomerID',            'Id', 'COLUMN';
EXEC sp_rename 'MAC.Customers.CustomerTypeId',        'TypeId', 'COLUMN';
EXEC sp_rename 'MAC.EstimateTypes.EstimateTypeID',    'Id', 'COLUMN';
EXEC sp_rename 'MAC.Estimates.EstimateID',            'Id', 'COLUMN';
EXEC sp_rename 'MAC.Estimates.EstimateTypeId',        'TypeId', 'COLUMN';
EXEC sp_rename 'MAC.EstimatePhotoTypes.EstimatePhotoTypeID', 'Id', 'COLUMN';
EXEC sp_rename 'MAC.EstimatePhotos.EstimatePhotoID',  'Id', 'COLUMN';
EXEC sp_rename 'MAC.EstimatePhotos.EstimatePhotoTypeId', 'TypeId', 'COLUMN';
EXEC sp_rename 'MAC.QuoteTypes.QuoteTypeID',          'Id', 'COLUMN';
EXEC sp_rename 'MAC.Quotes.QuoteID',                  'Id', 'COLUMN';
EXEC sp_rename 'MAC.Quotes.QuoteTypeId',              'TypeId', 'COLUMN';
EXEC sp_rename 'MAC.PurchaseOrderTypes.PurchaseOrderTypeID', 'Id', 'COLUMN';
EXEC sp_rename 'MAC.PurchaseOrders.PurchaseOrderID',  'Id', 'COLUMN';
EXEC sp_rename 'MAC.PurchaseOrders.PurchaseOrderTypeId', 'TypeId', 'COLUMN';
-- Reverse PK constraint renames
EXEC sp_rename 'ACC.PK_DealerTenantTypes',    'PK__TenantTy__3214EC07055BDB73', 'OBJECT';
EXEC sp_rename 'MAC.PK_CustomerTypes',        'PK__Customer__3214EC07E77477C1', 'OBJECT';
EXEC sp_rename 'MAC.PK_Customers',            'PK__Customer__3214EC07AA488884', 'OBJECT';
EXEC sp_rename 'MAC.PK_EstimateTypes',        'PK__Estimate__3214EC071C07399D', 'OBJECT';
EXEC sp_rename 'MAC.PK_Estimates',            'PK__Estimate__3214EC071E5274CD', 'OBJECT';
EXEC sp_rename 'MAC.PK_EstimatePhotoTypes',   'PK__Estimate__3214EC07A31DBE60', 'OBJECT';
EXEC sp_rename 'MAC.PK_EstimatePhotos',       'PK__Estimate__3214EC0738E92E94', 'OBJECT';
EXEC sp_rename 'MAC.PK_QuoteTypes',           'PK__QuoteTyp__3214EC077CD2B738', 'OBJECT';
EXEC sp_rename 'MAC.PK_Quotes',               'PK__Quotes__3214EC079F102B33',   'OBJECT';
EXEC sp_rename 'MAC.PK_PurchaseOrderTypes',   'PK__Purchase__3214EC07AE67CAEC', 'OBJECT';
EXEC sp_rename 'MAC.PK_PurchaseOrders',       'PK__Purchase__3214EC07FE47559C', 'OBJECT';
-- Remove SchemaVersion entry
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260505_1200_FixMACandACC_PKandFKNaming';
*/

/*
             Convention:
               PK column  = singular(TableName) + 'ID'  (uppercase)  e.g. CustomerID
               FK column  = singular(ParentTable) + 'Id' (mixed case) e.g. CustomerId

             Changes per table:
               ACC.DealerTenantTypes  — rename PK constraint only (column was already correct)
               MAC.CustomerTypes      — rename Id → CustomerTypeID, fix PK constraint
               MAC.Customers          — rename Id → CustomerID, TypeId → CustomerTypeId
                                        fix PK and FK constraint names
               MAC.EstimateTypes      — rename Id → EstimateTypeID, fix PK constraint
               MAC.Estimates          — rename Id → EstimateID, TypeId → EstimateTypeId
                                        fix PK and FK constraint names
               MAC.EstimatePhotoTypes — rename Id → EstimatePhotoTypeID, fix PK constraint
               MAC.EstimatePhotos     — rename Id → EstimatePhotoID, TypeId → EstimatePhotoTypeId
                                        fix PK constraint
               MAC.QuoteTypes         — rename Id → QuoteTypeID, fix PK constraint
               MAC.Quotes             — rename Id → QuoteID, TypeId → QuoteTypeId
                                        fix PK constraint
               MAC.PurchaseOrderTypes — rename Id → PurchaseOrderTypeID, fix PK constraint
               MAC.PurchaseOrders     — rename Id → PurchaseOrderID, TypeId → PurchaseOrderTypeId
                                        fix PK constraint

Dependencies: 20260313_0846_Baseline_ObjectsDeployed
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260505_1200_FixMACandACC_PKandFKNaming';

    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    DECLARE @pkName NVARCHAR(256);
    DECLARE @sql    NVARCHAR(1000);

    -- =========================================================================
    -- STEP 1: Drop ALL FKs that reference the PK ([Id]) columns being renamed,
    --         plus FKs we are renaming to comply with conventions.
    -- Dropping order: leaf tables first so referenced PKs can be dropped later.
    -- =========================================================================

    -- PurchaseOrders → Quotes.Id  (blocks Quotes PK drop)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__PurchaseO__Quote__395884C4')
        ALTER TABLE [MAC].[PurchaseOrders] DROP CONSTRAINT [FK__PurchaseO__Quote__395884C4];

    -- Quotes → Estimates.Id  (blocks Estimates PK drop)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Quotes__Estimate__2EDAF651')
        ALTER TABLE [MAC].[Quotes] DROP CONSTRAINT [FK__Quotes__Estimate__2EDAF651];

    -- EstimatePhotos → Estimates.Id  (blocks Estimates PK drop)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__EstimateP__Estim__43D61337')
        ALTER TABLE [MAC].[EstimatePhotos] DROP CONSTRAINT [FK__EstimateP__Estim__43D61337];

    -- Estimates → Customers.Id  (blocks Customers PK drop)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Estimates__Custo__245D67DE')
        ALTER TABLE [MAC].[Estimates] DROP CONSTRAINT [FK__Estimates__Custo__245D67DE];

    -- DealerTenants → DealerTenantTypes.DealerTenantTypeID  (blocks DealerTenantTypes PK drop)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_DealerTenants_DealerTenantTypes')
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [FK_DealerTenants_DealerTenantTypes];

    -- Customers → CustomerTypes.TypeId  (rename: FK__Customers__TypeI__... → FK_Customers_CustomerTypes)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Customers__TypeI__1AD3FDA4')
        ALTER TABLE [MAC].[Customers] DROP CONSTRAINT [FK__Customers__TypeI__1AD3FDA4];

    -- =========================================================================
    -- STEP 2: Rename auto-generated FK constraints that reference UQ business
    --         key columns (TypeId → TypeId). No drop needed — sp_rename suffices.
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Estimates__TypeI__25518C17')
        EXEC sp_rename 'MAC.FK__Estimates__TypeI__25518C17', 'FK_Estimates_EstimateTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__EstimateP__TypeI__44CA3770')
        EXEC sp_rename 'MAC.FK__EstimateP__TypeI__44CA3770', 'FK_EstimatePhotos_EstimatePhotoTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Quotes__TypeId__2FCF1A8A')
        EXEC sp_rename 'MAC.FK__Quotes__TypeId__2FCF1A8A', 'FK_Quotes_QuoteTypes', 'OBJECT';

    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__PurchaseO__TypeI__3A4CA8FD')
        EXEC sp_rename 'MAC.FK__PurchaseO__TypeI__3A4CA8FD', 'FK_PurchaseOrders_PurchaseOrderTypes', 'OBJECT';

    -- =========================================================================
    -- STEP 2: ACC.DealerTenantTypes — rename PK constraint only
    --         (column DealerTenantTypeID is already correctly named)
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__TenantTy__3214EC07055BDB73')
    BEGIN
    ALTER TABLE [ACC].[DealerTenantTypes] DROP CONSTRAINT [PK__TenantTy__3214EC07055BDB73];
    ALTER TABLE [ACC].[DealerTenantTypes] ADD CONSTRAINT [PK_DealerTenantTypes]
            PRIMARY KEY CLUSTERED ([DealerTenantTypeID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
END

    -- =========================================================================
    -- STEP 3: MAC.CustomerTypes — rename Id → CustomerTypeID, fix PK
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.CustomerTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.CustomerTypes.Id', 'CustomerTypeID', 'COLUMN';

    -- Drop auto-generated PK (name unknown — find dynamically)
    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'CustomerTypes' AND s.name = 'MAC';

    IF @pkName IS NOT NULL AND @pkName <> 'PK_CustomerTypes'
    BEGIN
    SET @sql = 'ALTER TABLE [MAC].[CustomerTypes] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END

    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_CustomerTypes')
        ALTER TABLE [MAC].[CustomerTypes] ADD CONSTRAINT [PK_CustomerTypes]
            PRIMARY KEY CLUSTERED ([CustomerTypeID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- =========================================================================
    -- STEP 4: MAC.Customers — rename Id → CustomerID, TypeId → CustomerTypeId, fix PK/FK
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Customers') AND name = 'Id')
        EXEC sp_rename 'MAC.Customers.Id', 'CustomerID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Customers') AND name = 'TypeId')
        EXEC sp_rename 'MAC.Customers.TypeId', 'CustomerTypeId', 'COLUMN';

    -- Drop old PK (named PK__Customer__...)
    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK__Customer__3214EC07AA488884')
        ALTER TABLE [MAC].[Customers] DROP CONSTRAINT [PK__Customer__3214EC07AA488884];

    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_Customers')
        ALTER TABLE [MAC].[Customers] ADD CONSTRAINT [PK_Customers]
            PRIMARY KEY CLUSTERED ([CustomerID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- =========================================================================
    -- STEP 6: MAC.EstimateTypes — rename Id → EstimateTypeID, fix PK
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimateTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.EstimateTypes.Id', 'EstimateTypeID', 'COLUMN';

    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'EstimateTypes' AND s.name = 'MAC';

    IF @pkName IS NOT NULL AND @pkName <> 'PK_EstimateTypes'
    BEGIN
    SET @sql = 'ALTER TABLE [MAC].[EstimateTypes] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END

    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_EstimateTypes')
        ALTER TABLE [MAC].[EstimateTypes] ADD CONSTRAINT [PK_EstimateTypes]
            PRIMARY KEY CLUSTERED ([EstimateTypeID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- =========================================================================
    -- STEP 7: MAC.Estimates — rename Id → EstimateID, TypeId → EstimateTypeId, fix PK
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Estimates') AND name = 'Id')
        EXEC sp_rename 'MAC.Estimates.Id', 'EstimateID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Estimates') AND name = 'TypeId')
        EXEC sp_rename 'MAC.Estimates.TypeId', 'EstimateTypeId', 'COLUMN';

    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'Estimates' AND s.name = 'MAC';

    IF @pkName IS NOT NULL AND @pkName <> 'PK_Estimates'
    BEGIN
    SET @sql = 'ALTER TABLE [MAC].[Estimates] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END

    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_Estimates')
        ALTER TABLE [MAC].[Estimates] ADD CONSTRAINT [PK_Estimates]
            PRIMARY KEY CLUSTERED ([EstimateID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- =========================================================================
    -- STEP 8: MAC.EstimatePhotoTypes — rename Id → EstimatePhotoTypeID, fix PK
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotoTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.EstimatePhotoTypes.Id', 'EstimatePhotoTypeID', 'COLUMN';

    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'EstimatePhotoTypes' AND s.name = 'MAC';

    IF @pkName IS NOT NULL AND @pkName <> 'PK_EstimatePhotoTypes'
    BEGIN
    SET @sql = 'ALTER TABLE [MAC].[EstimatePhotoTypes] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END

    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_EstimatePhotoTypes')
        ALTER TABLE [MAC].[EstimatePhotoTypes] ADD CONSTRAINT [PK_EstimatePhotoTypes]
            PRIMARY KEY CLUSTERED ([EstimatePhotoTypeID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- =========================================================================
    -- STEP 9: MAC.EstimatePhotos — rename Id → EstimatePhotoID, TypeId → EstimatePhotoTypeId, fix PK
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotos') AND name = 'Id')
        EXEC sp_rename 'MAC.EstimatePhotos.Id', 'EstimatePhotoID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotos') AND name = 'TypeId')
        EXEC sp_rename 'MAC.EstimatePhotos.TypeId', 'EstimatePhotoTypeId', 'COLUMN';

    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'EstimatePhotos' AND s.name = 'MAC';

    IF @pkName IS NOT NULL AND @pkName <> 'PK_EstimatePhotos'
    BEGIN
    SET @sql = 'ALTER TABLE [MAC].[EstimatePhotos] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END

    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_EstimatePhotos')
        ALTER TABLE [MAC].[EstimatePhotos] ADD CONSTRAINT [PK_EstimatePhotos]
            PRIMARY KEY CLUSTERED ([EstimatePhotoID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- =========================================================================
    -- STEP 10: MAC.QuoteTypes — rename Id → QuoteTypeID, fix PK
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.QuoteTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.QuoteTypes.Id', 'QuoteTypeID', 'COLUMN';

    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'QuoteTypes' AND s.name = 'MAC';

    IF @pkName IS NOT NULL AND @pkName <> 'PK_QuoteTypes'
    BEGIN
    SET @sql = 'ALTER TABLE [MAC].[QuoteTypes] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END

    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_QuoteTypes')
        ALTER TABLE [MAC].[QuoteTypes] ADD CONSTRAINT [PK_QuoteTypes]
            PRIMARY KEY CLUSTERED ([QuoteTypeID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- =========================================================================
    -- STEP 11: MAC.Quotes — rename Id → QuoteID, TypeId → QuoteTypeId, fix PK
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Quotes') AND name = 'Id')
        EXEC sp_rename 'MAC.Quotes.Id', 'QuoteID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Quotes') AND name = 'TypeId')
        EXEC sp_rename 'MAC.Quotes.TypeId', 'QuoteTypeId', 'COLUMN';

    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'Quotes' AND s.name = 'MAC';

    IF @pkName IS NOT NULL AND @pkName <> 'PK_Quotes'
    BEGIN
    SET @sql = 'ALTER TABLE [MAC].[Quotes] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END

    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_Quotes')
        ALTER TABLE [MAC].[Quotes] ADD CONSTRAINT [PK_Quotes]
            PRIMARY KEY CLUSTERED ([QuoteID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- =========================================================================
    -- STEP 12: MAC.PurchaseOrderTypes — rename Id → PurchaseOrderTypeID, fix PK
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrderTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.PurchaseOrderTypes.Id', 'PurchaseOrderTypeID', 'COLUMN';

    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'PurchaseOrderTypes' AND s.name = 'MAC';

    IF @pkName IS NOT NULL AND @pkName <> 'PK_PurchaseOrderTypes'
    BEGIN
    SET @sql = 'ALTER TABLE [MAC].[PurchaseOrderTypes] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END

    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_PurchaseOrderTypes')
        ALTER TABLE [MAC].[PurchaseOrderTypes] ADD CONSTRAINT [PK_PurchaseOrderTypes]
            PRIMARY KEY CLUSTERED ([PurchaseOrderTypeID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- =========================================================================
    -- STEP 13: MAC.PurchaseOrders — rename Id → PurchaseOrderID, TypeId → PurchaseOrderTypeId, fix PK
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrders') AND name = 'Id')
        EXEC sp_rename 'MAC.PurchaseOrders.Id', 'PurchaseOrderID', 'COLUMN';

    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrders') AND name = 'TypeId')
        EXEC sp_rename 'MAC.PurchaseOrders.TypeId', 'PurchaseOrderTypeId', 'COLUMN';

    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'PurchaseOrders' AND s.name = 'MAC';

    IF @pkName IS NOT NULL AND @pkName <> 'PK_PurchaseOrders'
    BEGIN
    SET @sql = 'ALTER TABLE [MAC].[PurchaseOrders] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END

    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_PurchaseOrders')
        ALTER TABLE [MAC].[PurchaseOrders] ADD CONSTRAINT [PK_PurchaseOrders]
            PRIMARY KEY CLUSTERED ([PurchaseOrderID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- =========================================================================
    -- STEP 14: Re-add all dropped FKs with proper convention names.
    --          Column renames are already done above, so use new column names.
    -- =========================================================================

    -- DealerTenants → DealerTenantTypes
    PRINT 'STEP 14a: Adding FK_DealerTenants_DealerTenantTypes';
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_DealerTenants_DealerTenantTypes')
        ALTER TABLE [ACC].[DealerTenants] WITH CHECK
            ADD CONSTRAINT [FK_DealerTenants_DealerTenantTypes] FOREIGN KEY ([DealerTenantTypeId])
            REFERENCES [ACC].[DealerTenantTypes] ([DealerTenantTypeID]);

    -- Customers → CustomerTypes (references UQ business key TypeId)
    PRINT 'STEP 14b: Adding FK_Customers_CustomerTypes';
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Customers_CustomerTypes')
        ALTER TABLE [MAC].[Customers] WITH CHECK
            ADD CONSTRAINT [FK_Customers_CustomerTypes] FOREIGN KEY ([CustomerTypeId])
            REFERENCES [MAC].[CustomerTypes] ([TypeId]);

    -- Estimates → Customers (references renamed PK CustomerID)
    PRINT 'STEP 14c: Adding FK_Estimates_Customers';
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Estimates_Customers')
        ALTER TABLE [MAC].[Estimates] WITH CHECK
            ADD CONSTRAINT [FK_Estimates_Customers] FOREIGN KEY ([CustomerId])
            REFERENCES [MAC].[Customers] ([CustomerID]);

    -- EstimatePhotos → Estimates (references renamed PK EstimateID)
    PRINT 'STEP 14d: Adding FK_EstimatePhotos_Estimates';
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_EstimatePhotos_Estimates')
        ALTER TABLE [MAC].[EstimatePhotos] WITH CHECK
            ADD CONSTRAINT [FK_EstimatePhotos_Estimates] FOREIGN KEY ([EstimateId])
            REFERENCES [MAC].[Estimates] ([EstimateID]);

    -- Quotes → Estimates (references renamed PK EstimateID)
    PRINT 'STEP 14e: Adding FK_Quotes_Estimates';
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Quotes_Estimates')
        ALTER TABLE [MAC].[Quotes] WITH CHECK
            ADD CONSTRAINT [FK_Quotes_Estimates] FOREIGN KEY ([EstimateId])
            REFERENCES [MAC].[Estimates] ([EstimateID]);

    -- PurchaseOrders → Quotes (references renamed PK QuoteID)
    PRINT 'STEP 14f: Adding FK_PurchaseOrders_Quotes';
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_PurchaseOrders_Quotes')
        ALTER TABLE [MAC].[PurchaseOrders] WITH CHECK
            ADD CONSTRAINT [FK_PurchaseOrders_Quotes] FOREIGN KEY ([QuoteId])
            REFERENCES [MAC].[Quotes] ([QuoteID]);

    -- =========================================================================
    -- Record migration
    -- =========================================================================
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName,
        'Renames PK columns (Id → TableNameID) and FK columns (TypeId → TableNameId) across MAC schema ' +
        'tables and fixes auto-generated/unnamed constraint names to follow project conventions.');

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- Reverse column renames (sp_rename)
EXEC sp_rename 'ACC.DealerTenantTypes PK: drop PK_DealerTenantTypes, restore PK__TenantTy__3214EC07055BDB73'
EXEC sp_rename 'MAC.CustomerTypes.CustomerTypeID',   'Id',                 'COLUMN';
EXEC sp_rename 'MAC.Customers.CustomerID',           'Id',                 'COLUMN';
EXEC sp_rename 'MAC.Customers.CustomerTypeId',       'TypeId',             'COLUMN';
EXEC sp_rename 'MAC.EstimateTypes.EstimateTypeID',   'Id',                 'COLUMN';
EXEC sp_rename 'MAC.Estimates.EstimateID',           'Id',                 'COLUMN';
EXEC sp_rename 'MAC.Estimates.EstimateTypeId',       'TypeId',             'COLUMN';
EXEC sp_rename 'MAC.EstimatePhotoTypes.EstimatePhotoTypeID', 'Id',         'COLUMN';
EXEC sp_rename 'MAC.EstimatePhotos.EstimatePhotoID', 'Id',                 'COLUMN';
EXEC sp_rename 'MAC.EstimatePhotos.EstimatePhotoTypeId', 'TypeId',         'COLUMN';
EXEC sp_rename 'MAC.QuoteTypes.QuoteTypeID',         'Id',                 'COLUMN';
EXEC sp_rename 'MAC.Quotes.QuoteID',                 'Id',                 'COLUMN';
EXEC sp_rename 'MAC.Quotes.QuoteTypeId',             'TypeId',             'COLUMN';
EXEC sp_rename 'MAC.PurchaseOrderTypes.PurchaseOrderTypeID', 'Id',         'COLUMN';
EXEC sp_rename 'MAC.PurchaseOrders.PurchaseOrderID', 'Id',                 'COLUMN';
EXEC sp_rename 'MAC.PurchaseOrders.PurchaseOrderTypeId', 'TypeId',         'COLUMN';
-- Then drop new named constraints and restore old ones manually
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260505_1200_FixMACandACC_PKandFKNaming';
*/
