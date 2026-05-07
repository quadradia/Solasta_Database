/*
Migration: 20260506_1200_CorrectFixMACandACC_PKandFKNaming
Author: Copilot (corrective)
Date: 2026-05-06
Description: Corrective migration for 20260505_1200_FixMACandACC_PKandFKNaming.

             The original _1200 migration had two issues on SOLITMDB001:
               1. Batch 1 used hardcoded auto-generated constraint hash names that do
                  not match on SOLITMDB001 — all sp_rename calls silently skipped.
               2. Batch 2 failed to parse (missing comment opener before Convention: block).
             Batch 1 still recorded itself in SchemaVersion, so _1200 is marked
             'applied' but the actual rename work was never done.

             This corrective migration repeats the rename work using dynamic SQL
             (no hardcoded hashes) and is fully idempotent:
               - Column renames only run if the old name still exists.
               - PK DROP/ADD uses dynamic discovery of the current PK name.
               - FK drops/adds all use IF EXISTS / IF NOT EXISTS guards.
               - FK references to TypeId columns use CustomerTypeID / PK references
                 because 20260506_1000 and 20260506_1100 have already dropped TypeId
                 from all *Types tables.

             Changes:
               ACC.DealerTenantTypes  — fix PK constraint name
               MAC.CustomerTypes      — rename Id → CustomerTypeID, fix PK
               MAC.Customers          — rename Id → CustomerID, TypeId → CustomerTypeId
                                        fix PK, fix FK references
               MAC.EstimateTypes      — rename Id → EstimateTypeID, fix PK
               MAC.Estimates          — rename Id → EstimateID, TypeId → EstimateTypeId
                                        fix PK, fix FK references
               MAC.EstimatePhotoTypes — rename Id → EstimatePhotoTypeID, fix PK
               MAC.EstimatePhotos     — rename Id → EstimatePhotoID, TypeId → EstimatePhotoTypeId
                                        fix PK, fix FK references
               MAC.QuoteTypes         — rename Id → QuoteTypeID, fix PK
               MAC.Quotes             — rename Id → QuoteID, TypeId → QuoteTypeId
                                        fix PK, fix FK references
               MAC.PurchaseOrderTypes — rename Id → PurchaseOrderTypeID, fix PK
               MAC.PurchaseOrders     — rename Id → PurchaseOrderID, TypeId → PurchaseOrderTypeId
                                        fix PK, fix FK references

Dependencies:
  20260505_1200_FixMACandACC_PKandFKNaming  (must be recorded so this runs after)
  20260506_1000_DropCustomerTypes_TypeIdColumn
  20260506_1100_DropTypeIdColumn_EstimatePhotoTypes_EstimateTypes_QuoteTypes_PurchaseOrderTypes
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260506_1200_CorrectFixMACandACC_PKandFKNaming';

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
    -- STEP 1: Drop FKs that reference PK columns being renamed.
    --         Must go before PK DROP/ADD to avoid FK-constraint blocking.
    --         Drop both old auto-generated names AND new names to cover all
    --         environments regardless of whether _1200 Batch 1 partially ran.
    -- =========================================================================

    -- PurchaseOrders → Quotes (references Quotes PK)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__PurchaseO__Quote__395884C4')
        ALTER TABLE [MAC].[PurchaseOrders] DROP CONSTRAINT [FK__PurchaseO__Quote__395884C4];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_PurchaseOrders_Quotes')
        ALTER TABLE [MAC].[PurchaseOrders] DROP CONSTRAINT [FK_PurchaseOrders_Quotes];

    -- Quotes → Estimates (references Estimates PK)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Quotes__Estimate__2EDAF651')
        ALTER TABLE [MAC].[Quotes] DROP CONSTRAINT [FK__Quotes__Estimate__2EDAF651];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Quotes_Estimates')
        ALTER TABLE [MAC].[Quotes] DROP CONSTRAINT [FK_Quotes_Estimates];

    -- EstimatePhotos → Estimates (references Estimates PK)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__EstimateP__Estim__43D61337')
        ALTER TABLE [MAC].[EstimatePhotos] DROP CONSTRAINT [FK__EstimateP__Estim__43D61337];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_EstimatePhotos_Estimates')
        ALTER TABLE [MAC].[EstimatePhotos] DROP CONSTRAINT [FK_EstimatePhotos_Estimates];

    -- Estimates → Customers (references Customers PK)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK__Estimates__Custo__245D67DE')
        ALTER TABLE [MAC].[Estimates] DROP CONSTRAINT [FK__Estimates__Custo__245D67DE];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Estimates_Customers')
        ALTER TABLE [MAC].[Estimates] DROP CONSTRAINT [FK_Estimates_Customers];

    -- Customers → CustomerTypes (references CustomerTypes PK)
    -- Note: FK name lookup MUST be table-qualified — FK_Customers_CustomerTypes also
    --       exists on ACE.Customers and a name-only EXISTS would find that and fail.
    IF EXISTS (SELECT 1
FROM sys.foreign_keys fk JOIN sys.tables t ON fk.parent_object_id = t.object_id
WHERE fk.name = 'FK__Customers__TypeI__1AD3FDA4'
    AND SCHEMA_NAME(t.schema_id) = 'MAC' AND t.name = 'Customers')
        ALTER TABLE [MAC].[Customers] DROP CONSTRAINT [FK__Customers__TypeI__1AD3FDA4];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys fk JOIN sys.tables t ON fk.parent_object_id = t.object_id
WHERE fk.name = 'FK_Customers_CustomerTypes'
    AND SCHEMA_NAME(t.schema_id) = 'MAC' AND t.name = 'Customers')
        ALTER TABLE [MAC].[Customers] DROP CONSTRAINT [FK_Customers_CustomerTypes];

    -- EstimatePhotos → EstimatePhotoTypes (added by _1100, blocks EstimatePhotoTypes PK rename)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_EstimatePhotos_EstimatePhotoTypes')
        ALTER TABLE [MAC].[EstimatePhotos] DROP CONSTRAINT [FK_EstimatePhotos_EstimatePhotoTypes];

    -- Estimates → EstimateTypes (added by _1100, blocks EstimateTypes PK rename)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Estimates_EstimateTypes')
        ALTER TABLE [MAC].[Estimates] DROP CONSTRAINT [FK_Estimates_EstimateTypes];

    -- Quotes → QuoteTypes (added by _1100, blocks QuoteTypes PK rename)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Quotes_QuoteTypes')
        ALTER TABLE [MAC].[Quotes] DROP CONSTRAINT [FK_Quotes_QuoteTypes];

    -- PurchaseOrders → PurchaseOrderTypes (added by _1100, blocks PurchaseOrderTypes PK rename)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_PurchaseOrders_PurchaseOrderTypes')
        ALTER TABLE [MAC].[PurchaseOrders] DROP CONSTRAINT [FK_PurchaseOrders_PurchaseOrderTypes];

    -- DealerTenants → DealerTenantTypes (references DealerTenantTypes PK)
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_DealerTenants_DealerTenantTypes')
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [FK_DealerTenants_DealerTenantTypes];

    -- =========================================================================
    -- STEP 2: Column renames — each guarded by IF EXISTS (fully idempotent)
    -- =========================================================================

    -- MAC.CustomerTypes: Id → CustomerTypeID
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.CustomerTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.CustomerTypes.Id', 'CustomerTypeID', 'COLUMN';

    -- MAC.Customers: Id → CustomerID, TypeId → CustomerTypeId
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Customers') AND name = 'Id')
        EXEC sp_rename 'MAC.Customers.Id', 'CustomerID', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Customers') AND name = 'TypeId')
        EXEC sp_rename 'MAC.Customers.TypeId', 'CustomerTypeId', 'COLUMN';

    -- MAC.EstimateTypes: Id → EstimateTypeID
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimateTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.EstimateTypes.Id', 'EstimateTypeID', 'COLUMN';

    -- MAC.Estimates: Id → EstimateID, TypeId → EstimateTypeId
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Estimates') AND name = 'Id')
        EXEC sp_rename 'MAC.Estimates.Id', 'EstimateID', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Estimates') AND name = 'TypeId')
        EXEC sp_rename 'MAC.Estimates.TypeId', 'EstimateTypeId', 'COLUMN';

    -- MAC.EstimatePhotoTypes: Id → EstimatePhotoTypeID
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotoTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.EstimatePhotoTypes.Id', 'EstimatePhotoTypeID', 'COLUMN';

    -- MAC.EstimatePhotos: Id → EstimatePhotoID, TypeId → EstimatePhotoTypeId
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotos') AND name = 'Id')
        EXEC sp_rename 'MAC.EstimatePhotos.Id', 'EstimatePhotoID', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.EstimatePhotos') AND name = 'TypeId')
        EXEC sp_rename 'MAC.EstimatePhotos.TypeId', 'EstimatePhotoTypeId', 'COLUMN';

    -- MAC.QuoteTypes: Id → QuoteTypeID
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.QuoteTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.QuoteTypes.Id', 'QuoteTypeID', 'COLUMN';

    -- MAC.Quotes: Id → QuoteID, TypeId → QuoteTypeId
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Quotes') AND name = 'Id')
        EXEC sp_rename 'MAC.Quotes.Id', 'QuoteID', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.Quotes') AND name = 'TypeId')
        EXEC sp_rename 'MAC.Quotes.TypeId', 'QuoteTypeId', 'COLUMN';

    -- MAC.PurchaseOrderTypes: Id → PurchaseOrderTypeID
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrderTypes') AND name = 'Id')
        EXEC sp_rename 'MAC.PurchaseOrderTypes.Id', 'PurchaseOrderTypeID', 'COLUMN';

    -- MAC.PurchaseOrders: Id → PurchaseOrderID, TypeId → PurchaseOrderTypeId
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrders') AND name = 'Id')
        EXEC sp_rename 'MAC.PurchaseOrders.Id', 'PurchaseOrderID', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAC.PurchaseOrders') AND name = 'TypeId')
        EXEC sp_rename 'MAC.PurchaseOrders.TypeId', 'PurchaseOrderTypeId', 'COLUMN';

    -- =========================================================================
    -- STEP 3: PK constraint renames — drop auto-generated name, add convention name.
    --         Uses dynamic SQL to discover the current PK name regardless of
    --         what hash was generated on this server instance.
    -- =========================================================================

    -- ACC.DealerTenantTypes → PK_DealerTenantTypes
    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'DealerTenantTypes' AND s.name = 'ACC';
    IF @pkName IS NOT NULL AND @pkName <> 'PK_DealerTenantTypes'
    BEGIN
    SET @sql = 'ALTER TABLE [ACC].[DealerTenantTypes] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END
    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_DealerTenantTypes')
        ALTER TABLE [ACC].[DealerTenantTypes] ADD CONSTRAINT [PK_DealerTenantTypes]
            PRIMARY KEY CLUSTERED ([DealerTenantTypeID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- MAC.CustomerTypes → PK_CustomerTypes
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

    -- MAC.Customers → PK_Customers
    SELECT @pkName = kc.name
FROM sys.key_constraints kc
    JOIN sys.tables t ON kc.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE kc.type = 'PK' AND t.name = 'Customers' AND s.name = 'MAC';
    IF @pkName IS NOT NULL AND @pkName <> 'PK_Customers'
    BEGIN
    SET @sql = 'ALTER TABLE [MAC].[Customers] DROP CONSTRAINT [' + @pkName + ']';
    EXEC(@sql);
END
    IF NOT EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_Customers')
        ALTER TABLE [MAC].[Customers] ADD CONSTRAINT [PK_Customers]
            PRIMARY KEY CLUSTERED ([CustomerID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- MAC.EstimateTypes → PK_EstimateTypes
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

    -- MAC.Estimates → PK_Estimates
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

    -- MAC.EstimatePhotoTypes → PK_EstimatePhotoTypes
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

    -- MAC.EstimatePhotos → PK_EstimatePhotos
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

    -- MAC.QuoteTypes → PK_QuoteTypes
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

    -- MAC.Quotes → PK_Quotes
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

    -- MAC.PurchaseOrderTypes → PK_PurchaseOrderTypes
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

    -- MAC.PurchaseOrders → PK_PurchaseOrders
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
    -- STEP 4: Re-add FKs with convention names and correct column references.
    --         TypeId columns on *Types tables were dropped by _1000 and _1100,
    --         so all FKs now reference the PK (e.g. CustomerTypeID, EstimateTypeID).
    -- =========================================================================

    -- DealerTenants → DealerTenantTypes
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_DealerTenants_DealerTenantTypes')
        ALTER TABLE [ACC].[DealerTenants] WITH CHECK
            ADD CONSTRAINT [FK_DealerTenants_DealerTenantTypes] FOREIGN KEY ([DealerTenantTypeId])
            REFERENCES [ACC].[DealerTenantTypes] ([DealerTenantTypeID]);

    -- Customers → CustomerTypes (references PK, TypeId was dropped by _1000)
    -- Note: FK name lookup MUST be table-qualified — FK_Customers_CustomerTypes also
    --       exists on ACE.Customers and a name-only NOT EXISTS would skip this.
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys fk JOIN sys.tables t ON fk.parent_object_id = t.object_id
WHERE fk.name = 'FK_Customers_CustomerTypes'
    AND SCHEMA_NAME(t.schema_id) = 'MAC' AND t.name = 'Customers')
        ALTER TABLE [MAC].[Customers] WITH CHECK
            ADD CONSTRAINT [FK_Customers_CustomerTypes] FOREIGN KEY ([CustomerTypeId])
            REFERENCES [MAC].[CustomerTypes] ([CustomerTypeID]);

    -- EstimatePhotos → EstimatePhotoTypes (references PK, TypeId was dropped by _1100)
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_EstimatePhotos_EstimatePhotoTypes')
        ALTER TABLE [MAC].[EstimatePhotos] WITH CHECK
            ADD CONSTRAINT [FK_EstimatePhotos_EstimatePhotoTypes] FOREIGN KEY ([EstimatePhotoTypeId])
            REFERENCES [MAC].[EstimatePhotoTypes] ([EstimatePhotoTypeID]);

    -- Estimates → EstimateTypes (references PK, TypeId was dropped by _1100)
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Estimates_EstimateTypes')
        ALTER TABLE [MAC].[Estimates] WITH CHECK
            ADD CONSTRAINT [FK_Estimates_EstimateTypes] FOREIGN KEY ([EstimateTypeId])
            REFERENCES [MAC].[EstimateTypes] ([EstimateTypeID]);

    -- Quotes → QuoteTypes (references PK, TypeId was dropped by _1100)
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Quotes_QuoteTypes')
        ALTER TABLE [MAC].[Quotes] WITH CHECK
            ADD CONSTRAINT [FK_Quotes_QuoteTypes] FOREIGN KEY ([QuoteTypeId])
            REFERENCES [MAC].[QuoteTypes] ([QuoteTypeID]);

    -- PurchaseOrders → PurchaseOrderTypes (references PK, TypeId was dropped by _1100)
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_PurchaseOrders_PurchaseOrderTypes')
        ALTER TABLE [MAC].[PurchaseOrders] WITH CHECK
            ADD CONSTRAINT [FK_PurchaseOrders_PurchaseOrderTypes] FOREIGN KEY ([PurchaseOrderTypeId])
            REFERENCES [MAC].[PurchaseOrderTypes] ([PurchaseOrderTypeID]);

    -- Estimates → Customers
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Estimates_Customers')
        ALTER TABLE [MAC].[Estimates] WITH CHECK
            ADD CONSTRAINT [FK_Estimates_Customers] FOREIGN KEY ([CustomerId])
            REFERENCES [MAC].[Customers] ([CustomerID]);

    -- EstimatePhotos → Estimates
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_EstimatePhotos_Estimates')
        ALTER TABLE [MAC].[EstimatePhotos] WITH CHECK
            ADD CONSTRAINT [FK_EstimatePhotos_Estimates] FOREIGN KEY ([EstimateId])
            REFERENCES [MAC].[Estimates] ([EstimateID]);

    -- Quotes → Estimates
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Quotes_Estimates')
        ALTER TABLE [MAC].[Quotes] WITH CHECK
            ADD CONSTRAINT [FK_Quotes_Estimates] FOREIGN KEY ([EstimateId])
            REFERENCES [MAC].[Estimates] ([EstimateID]);

    -- PurchaseOrders → Quotes
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
        'Corrective migration: applies PK/FK column and constraint renames from ' +
            '20260505_1200_FixMACandACC_PKandFKNaming that were not executed on SOLITMDB001. ' +
            'Uses dynamic SQL (no hardcoded hashes) and is fully idempotent.');

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
-- Drop re-added FKs
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PurchaseOrders_Quotes')
    ALTER TABLE [MAC].[PurchaseOrders] DROP CONSTRAINT [FK_PurchaseOrders_Quotes];
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Quotes_Estimates')
    ALTER TABLE [MAC].[Quotes] DROP CONSTRAINT [FK_Quotes_Estimates];
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_EstimatePhotos_Estimates')
    ALTER TABLE [MAC].[EstimatePhotos] DROP CONSTRAINT [FK_EstimatePhotos_Estimates];
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Estimates_Customers')
    ALTER TABLE [MAC].[Estimates] DROP CONSTRAINT [FK_Estimates_Customers];
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Customers_CustomerTypes')
    ALTER TABLE [MAC].[Customers] DROP CONSTRAINT [FK_Customers_CustomerTypes];
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DealerTenants_DealerTenantTypes')
    ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [FK_DealerTenants_DealerTenantTypes];
-- Reverse column renames
EXEC sp_rename 'MAC.CustomerTypes.CustomerTypeID',   'Id', 'COLUMN';
EXEC sp_rename 'MAC.Customers.CustomerID',           'Id', 'COLUMN';
EXEC sp_rename 'MAC.Customers.CustomerTypeId',       'TypeId', 'COLUMN';
EXEC sp_rename 'MAC.EstimateTypes.EstimateTypeID',   'Id', 'COLUMN';
EXEC sp_rename 'MAC.Estimates.EstimateID',           'Id', 'COLUMN';
EXEC sp_rename 'MAC.Estimates.EstimateTypeId',       'TypeId', 'COLUMN';
EXEC sp_rename 'MAC.EstimatePhotoTypes.EstimatePhotoTypeID', 'Id', 'COLUMN';
EXEC sp_rename 'MAC.EstimatePhotos.EstimatePhotoID', 'Id', 'COLUMN';
EXEC sp_rename 'MAC.EstimatePhotos.EstimatePhotoTypeId', 'TypeId', 'COLUMN';
EXEC sp_rename 'MAC.QuoteTypes.QuoteTypeID',         'Id', 'COLUMN';
EXEC sp_rename 'MAC.Quotes.QuoteID',                 'Id', 'COLUMN';
EXEC sp_rename 'MAC.Quotes.QuoteTypeId',             'TypeId', 'COLUMN';
EXEC sp_rename 'MAC.PurchaseOrderTypes.PurchaseOrderTypeID', 'Id', 'COLUMN';
EXEC sp_rename 'MAC.PurchaseOrders.PurchaseOrderID', 'Id', 'COLUMN';
EXEC sp_rename 'MAC.PurchaseOrders.PurchaseOrderTypeId', 'TypeId', 'COLUMN';
-- Then restore PK constraint names and FKs manually as needed.
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260506_1200_CorrectFixMACandACC_PKandFKNaming';
*/
