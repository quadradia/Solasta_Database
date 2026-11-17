/*
Migration: 20261117_1800_CreateINE_InventoryEngineTables
Author: Andres Sosa
Date: 2026-11-17
Description: Creates the INE (Inventory Engine) schema, adapted from the legacy NVL9_MAIN INE
             design (docs/legacy-ine/INE-Inventory-Engine.md) for Solasta Lighting:
               reference   INE.LocationTypes, INE.MovementTypes (seeded, fixed IDs)
               master      INE.Vendors, INE.Locations, INE.StockItems, INE.StockLevels, INE.Lots
               buying      INE.PurchaseOrders, INE.PurchaseOrderLines, INE.Receipts
               ledger      INE.Movements, INE.MovementLines (append-only)
               projections INE.StockBalances, INE.SerialUnits
               planning    INE.Allocations (stock reserved for a lead/job)
               counting    INE.StockCounts, INE.StockCountLines
             Stock items are tracked by Quantity, Lot or Serial; quantities are DECIMAL(19,4) so
             rail footage is exact. Seeds a MAIN warehouse for the Solasta Lighting tenant.
             The procedures, views and triggers that post to these tables are in
             20261117_1810_CreateINE_InventoryEngineProcedures.
Dependencies:
  ACC.DealerTenants, ACC.Users, QAL.Leads, MAC.Products, MAC.PoliticalStates
Rollback:
  Roll back 20261117_1810_CreateINE_InventoryEngineProcedures first, then:
  DROP TABLE [INE].[StockBalances];
  DROP TABLE [INE].[MovementLines];
  DROP TABLE [INE].[Movements];
  DROP TABLE [INE].[Allocations];
  DROP TABLE [INE].[StockCountLines];
  DROP TABLE [INE].[StockCounts];
  DROP TABLE [INE].[SerialUnits];
  DROP TABLE [INE].[Receipts];
  DROP TABLE [INE].[PurchaseOrderLines];
  DROP TABLE [INE].[PurchaseOrders];
  DROP TABLE [INE].[Lots];
  DROP TABLE [INE].[StockLevels];
  DROP TABLE [INE].[StockItems];
  DROP TABLE [INE].[Locations];
  DROP TABLE [INE].[Vendors];
  DROP TABLE [INE].[MovementTypes];
  DROP TABLE [INE].[LocationTypes];
  DROP SCHEMA [INE];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_1800_CreateINE_InventoryEngineTables';
Expected impact: New schema and tables only; no existing object changes.
*/

-- Filtered indexes require these; sqlcmd defaults QUOTED_IDENTIFIER to OFF.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261117_1800_CreateINE_InventoryEngineTables';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL OR OBJECT_ID(N'ACC.Users', N'U') IS NULL
       OR OBJECT_ID(N'QAL.Leads', N'U') IS NULL OR OBJECT_ID(N'MAC.Products', N'U') IS NULL
       OR OBJECT_ID(N'MAC.PoliticalStates', N'U') IS NULL
        THROW 50001, 'INE requires ACC.DealerTenants, ACC.Users, QAL.Leads, MAC.Products and MAC.PoliticalStates.', 1;

    IF SCHEMA_ID(N'INE') IS NULL
        EXEC (N'CREATE SCHEMA [INE] AUTHORIZATION [dbo]');

    ---------------------------------------------------------------------------
    -- INE.LocationTypes
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.LocationTypes', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[LocationTypes]
        (
            [LocationTypeID] [int] NOT NULL,
            -- Warehouse, Vehicle, Staging, Job, Vendor
            [Code] [varchar](20) NOT NULL,
            [Name] [nvarchar](100) NOT NULL,
            [Description] [nvarchar](500) NULL,
            [IsStockHolding] [bit] NOT NULL CONSTRAINT [DF_LocationTypes_IsStockHolding] DEFAULT ((1)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_LocationTypes_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_LocationTypes_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_LocationTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_LocationTypes_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_LocationTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_LocationTypes_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_LocationTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_LocationTypes] PRIMARY KEY CLUSTERED ([LocationTypeID] ASC),
            CONSTRAINT [UQ_LocationTypes_Code] UNIQUE ([Code])
        );
    END;

    ---------------------------------------------------------------------------
    -- INE.MovementTypes
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.MovementTypes', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[MovementTypes]
        (
            [MovementTypeID] [int] NOT NULL,
            -- Receive, Transfer, IssueToJob, ReturnFromJob, ReturnToVendor, AdjustIn, AdjustOut, Scrap, Reversal
            [Code] [varchar](20) NOT NULL,
            [Name] [nvarchar](100) NOT NULL,
            [Description] [nvarchar](500) NULL,
            -- 1 = stock leaves FromLocationId; 1 = stock arrives at ToLocationId.
            -- (Reversal has both 0: its ends mirror the movement it reverses.)
            [RequiresFrom] [bit] NOT NULL,
            [RequiresTo] [bit] NOT NULL,
            -- The location type required at each end (INE.LocationTypes.Code); NULL means any
            -- stock-holding location (Warehouse, Vehicle, Staging).
            [FromLocationTypeCode] [varchar](20) NULL,
            [ToLocationTypeCode] [varchar](20) NULL,
            [RequiresLead] [bit] NOT NULL CONSTRAINT [DF_MovementTypes_RequiresLead] DEFAULT ((0)),
            [SortOrder] [int] NOT NULL CONSTRAINT [DF_MovementTypes_SortOrder] DEFAULT ((0)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_MovementTypes_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_MovementTypes_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MovementTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MovementTypes_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MovementTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MovementTypes_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MovementTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_MovementTypes] PRIMARY KEY CLUSTERED ([MovementTypeID] ASC),
            CONSTRAINT [UQ_MovementTypes_Code] UNIQUE ([Code])
        );
    END;

    ---------------------------------------------------------------------------
    -- INE.Vendors
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.Vendors', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[Vendors]
        (
            [VendorID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [PoliticalStateId] [varchar](4) NULL,
            -- Short code shown on POs, unique per tenant.
            [Code] [nvarchar](20) NOT NULL,
            [Name] [nvarchar](150) NOT NULL,
            [ContactName] [nvarchar](100) NULL,
            [Email] [nvarchar](256) NULL,
            [Phone] [nvarchar](30) NULL,
            [Website] [nvarchar](256) NULL,
            [StreetAddress] [nvarchar](100) NULL,
            [StreetAddress2] [nvarchar](100) NULL,
            [City] [nvarchar](100) NULL,
            [PostalCode] [nvarchar](15) NULL,
            -- Typical days from order to delivery; feeds reorder suggestions.
            [LeadTimeDays] [int] NULL,
            [PaymentTerms] [nvarchar](50) NULL,
            [Notes] [nvarchar](2000) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Vendors_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Vendors_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Vendors_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Vendors_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Vendors_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Vendors_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Vendors_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Vendors] PRIMARY KEY CLUSTERED ([VendorID] ASC),
            CONSTRAINT [FK_Vendors_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Vendors_PoliticalStates] FOREIGN KEY ([PoliticalStateId])
                REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID]),
            CONSTRAINT [CK_Vendors_LeadTimeDays] CHECK ([LeadTimeDays] IS NULL OR [LeadTimeDays] >= 0)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.Vendors') AND [name] = N'UQ_Vendors_DealerTenantId_Code')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Vendors_DealerTenantId_Code]
            ON [INE].[Vendors] ([DealerTenantId], [Code]);

    ---------------------------------------------------------------------------
    -- INE.Locations
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.Locations', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[Locations]
        (
            [LocationID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [LocationTypeId] [int] NOT NULL,
            -- Vehicle: the installer who holds the stock.
            [UserId] [uniqueidentifier] NULL,
            -- Job: the lead the stock was issued to.
            [LeadId] [bigint] NULL,
            -- Vendor: the supplier stock is returned to.
            [VendorId] [int] NULL,
            [PoliticalStateId] [varchar](4) NULL,
            -- Short code, unique per tenant, e.g. MAIN, VAN-03, JOB-1042.
            [Code] [nvarchar](30) NOT NULL,
            [Name] [nvarchar](150) NOT NULL,
            [StreetAddress] [nvarchar](100) NULL,
            [StreetAddress2] [nvarchar](100) NULL,
            [City] [nvarchar](100) NULL,
            [PostalCode] [nvarchar](15) NULL,
            [Notes] [nvarchar](2000) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Locations_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Locations_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Locations_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Locations_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Locations_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Locations_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Locations_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Locations] PRIMARY KEY CLUSTERED ([LocationID] ASC),
            CONSTRAINT [FK_Locations_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Locations_LocationTypes] FOREIGN KEY ([LocationTypeId])
                REFERENCES [INE].[LocationTypes] ([LocationTypeID]),
            CONSTRAINT [FK_Locations_Users] FOREIGN KEY ([UserId])
                REFERENCES [ACC].[Users] ([UserID]),
            CONSTRAINT [FK_Locations_Leads] FOREIGN KEY ([LeadId])
                REFERENCES [QAL].[Leads] ([LeadID]),
            CONSTRAINT [FK_Locations_Vendors] FOREIGN KEY ([VendorId])
                REFERENCES [INE].[Vendors] ([VendorID]),
            CONSTRAINT [FK_Locations_PoliticalStates] FOREIGN KEY ([PoliticalStateId])
                REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID])
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.Locations') AND [name] = N'UQ_Locations_DealerTenantId_Code')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Locations_DealerTenantId_Code]
            ON [INE].[Locations] ([DealerTenantId], [Code]);

    -- One job location per lead.
    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.Locations') AND [name] = N'UQ_Locations_LeadId')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Locations_LeadId]
            ON [INE].[Locations] ([LeadId])
            WHERE [LeadId] IS NOT NULL;

    ---------------------------------------------------------------------------
    -- INE.StockItems
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.StockItems', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[StockItems]
        (
            [StockItemID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [ProductId] [int] NULL,
            [DefaultVendorId] [int] NULL,
            [Sku] [nvarchar](30) NOT NULL,
            [Name] [nvarchar](150) NOT NULL,
            [Description] [nvarchar](1000) NULL,
            [Category] [nvarchar](50) NULL,
            [TrackingMode] [varchar](10) NOT NULL CONSTRAINT [DF_StockItems_TrackingMode] DEFAULT ('Quantity'),
            [UnitOfMeasure] [varchar](4) NOT NULL CONSTRAINT [DF_StockItems_UnitOfMeasure] DEFAULT ('each'),
            [VendorSku] [nvarchar](50) NULL,
            -- Last known cost per unit of measure; receipts record the actual cost on each line.
            [StandardCost] [decimal](19, 4) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_StockItems_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_StockItems_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockItems_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockItems_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockItems_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockItems_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockItems_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_StockItems] PRIMARY KEY CLUSTERED ([StockItemID] ASC),
            CONSTRAINT [FK_StockItems_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_StockItems_Products] FOREIGN KEY ([ProductId])
                REFERENCES [MAC].[Products] ([ProductID]),
            CONSTRAINT [FK_StockItems_Vendors] FOREIGN KEY ([DefaultVendorId])
                REFERENCES [INE].[Vendors] ([VendorID]),
            CONSTRAINT [CK_StockItems_TrackingMode] CHECK ([TrackingMode] IN ('Quantity', 'Lot', 'Serial')),
            CONSTRAINT [CK_StockItems_UnitOfMeasure] CHECK ([UnitOfMeasure] IN ('ft', 'each')),
            -- A serialized unit is one physical thing.
            CONSTRAINT [CK_StockItems_SerialUnit] CHECK ([TrackingMode] <> 'Serial' OR [UnitOfMeasure] = 'each'),
            CONSTRAINT [CK_StockItems_StandardCost] CHECK ([StandardCost] IS NULL OR [StandardCost] >= 0)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.StockItems') AND [name] = N'UQ_StockItems_DealerTenantId_Sku')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_StockItems_DealerTenantId_Sku]
            ON [INE].[StockItems] ([DealerTenantId], [Sku]);

    ---------------------------------------------------------------------------
    -- INE.StockLevels
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.StockLevels', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[StockLevels]
        (
            [StockLevelID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [StockItemId] [int] NOT NULL,
            [LocationId] [int] NOT NULL,
            [ReorderPoint] [decimal](19, 4) NOT NULL,
            [MaximumQuantity] [decimal](19, 4) NOT NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_StockLevels_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_StockLevels_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockLevels_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockLevels_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockLevels_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockLevels_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockLevels_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_StockLevels] PRIMARY KEY CLUSTERED ([StockLevelID] ASC),
            CONSTRAINT [FK_StockLevels_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_StockLevels_StockItems] FOREIGN KEY ([StockItemId])
                REFERENCES [INE].[StockItems] ([StockItemID]),
            CONSTRAINT [FK_StockLevels_Locations] FOREIGN KEY ([LocationId])
                REFERENCES [INE].[Locations] ([LocationID]),
            CONSTRAINT [CK_StockLevels_Quantities] CHECK ([ReorderPoint] >= 0 AND [MaximumQuantity] >= [ReorderPoint])
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.StockLevels') AND [name] = N'UQ_StockLevels_StockItemId_LocationId')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_StockLevels_StockItemId_LocationId]
            ON [INE].[StockLevels] ([StockItemId], [LocationId]);

    ---------------------------------------------------------------------------
    -- INE.Lots
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.Lots', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[Lots]
        (
            [LotID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [StockItemId] [int] NOT NULL,
            [LotNumber] [nvarchar](50) NOT NULL,
            [ManufacturedDate] [date] NULL,
            [ExpirationDate] [date] NULL,
            [Notes] [nvarchar](1000) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Lots_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Lots_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Lots_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Lots_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Lots_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Lots_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Lots_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Lots] PRIMARY KEY CLUSTERED ([LotID] ASC),
            CONSTRAINT [FK_Lots_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Lots_StockItems] FOREIGN KEY ([StockItemId])
                REFERENCES [INE].[StockItems] ([StockItemID])
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.Lots') AND [name] = N'UQ_Lots_StockItemId_LotNumber')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Lots_StockItemId_LotNumber]
            ON [INE].[Lots] ([StockItemId], [LotNumber]);

    ---------------------------------------------------------------------------
    -- INE.PurchaseOrders
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.PurchaseOrders', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[PurchaseOrders]
        (
            [PurchaseOrderID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [VendorId] [int] NOT NULL,
            -- Where the order is delivered (a Warehouse or Staging location).
            [ShipToLocationId] [int] NOT NULL,
            [PONumber] [nvarchar](30) NOT NULL,
            [Status] [varchar](20) NOT NULL CONSTRAINT [DF_PurchaseOrders_Status] DEFAULT ('Draft'),
            [OrderDate] [date] NOT NULL CONSTRAINT [DF_PurchaseOrders_OrderDate] DEFAULT (CONVERT([date], SYSDATETIMEOFFSET())),
            [ExpectedDate] [date] NULL,
            [VendorReference] [nvarchar](50) NULL,
            [ShippingAmount] [decimal](19, 4) NOT NULL CONSTRAINT [DF_PurchaseOrders_ShippingAmount] DEFAULT ((0)),
            [TaxAmount] [decimal](19, 4) NOT NULL CONSTRAINT [DF_PurchaseOrders_TaxAmount] DEFAULT ((0)),
            [Notes] [nvarchar](2000) NULL,
            [SubmittedDate] [datetimeoffset](7) NULL,
            [ClosedDate] [datetimeoffset](7) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_PurchaseOrders_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_PurchaseOrders_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PurchaseOrders_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PurchaseOrders_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PurchaseOrders_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PurchaseOrders_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PurchaseOrders_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_PurchaseOrders] PRIMARY KEY CLUSTERED ([PurchaseOrderID] ASC),
            CONSTRAINT [FK_PurchaseOrders_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_PurchaseOrders_Vendors] FOREIGN KEY ([VendorId])
                REFERENCES [INE].[Vendors] ([VendorID]),
            CONSTRAINT [FK_PurchaseOrders_Locations] FOREIGN KEY ([ShipToLocationId])
                REFERENCES [INE].[Locations] ([LocationID]),
            CONSTRAINT [CK_PurchaseOrders_Status]
                CHECK ([Status] IN ('Draft', 'Submitted', 'PartiallyReceived', 'Received', 'Closed', 'Cancelled')),
            CONSTRAINT [CK_PurchaseOrders_Amounts] CHECK ([ShippingAmount] >= 0 AND [TaxAmount] >= 0)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.PurchaseOrders') AND [name] = N'UQ_PurchaseOrders_DealerTenantId_PONumber')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_PurchaseOrders_DealerTenantId_PONumber]
            ON [INE].[PurchaseOrders] ([DealerTenantId], [PONumber]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.PurchaseOrders') AND [name] = N'IX_PurchaseOrders_DealerTenantId_Status')
        CREATE NONCLUSTERED INDEX [IX_PurchaseOrders_DealerTenantId_Status]
            ON [INE].[PurchaseOrders] ([DealerTenantId], [Status])
            INCLUDE ([VendorId], [ShipToLocationId], [ExpectedDate]);

    ---------------------------------------------------------------------------
    -- INE.PurchaseOrderLines
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.PurchaseOrderLines', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[PurchaseOrderLines]
        (
            [PurchaseOrderLineID] [bigint] IDENTITY(1,1) NOT NULL,
            [PurchaseOrderId] [bigint] NOT NULL,
            [StockItemId] [int] NOT NULL,
            [LineNumber] [int] NOT NULL,
            [QuantityOrdered] [decimal](19, 4) NOT NULL,
            [QuantityReceived] [decimal](19, 4) NOT NULL CONSTRAINT [DF_PurchaseOrderLines_QuantityReceived] DEFAULT ((0)),
            [UnitCost] [decimal](19, 4) NOT NULL CONSTRAINT [DF_PurchaseOrderLines_UnitCost] DEFAULT ((0)),
            [Notes] [nvarchar](500) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_PurchaseOrderLines_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_PurchaseOrderLines_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PurchaseOrderLines_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PurchaseOrderLines_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PurchaseOrderLines_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PurchaseOrderLines_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PurchaseOrderLines_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_PurchaseOrderLines] PRIMARY KEY CLUSTERED ([PurchaseOrderLineID] ASC),
            CONSTRAINT [FK_PurchaseOrderLines_PurchaseOrders] FOREIGN KEY ([PurchaseOrderId])
                REFERENCES [INE].[PurchaseOrders] ([PurchaseOrderID]),
            CONSTRAINT [FK_PurchaseOrderLines_StockItems] FOREIGN KEY ([StockItemId])
                REFERENCES [INE].[StockItems] ([StockItemID]),
            CONSTRAINT [CK_PurchaseOrderLines_QuantityOrdered] CHECK ([QuantityOrdered] > 0),
            CONSTRAINT [CK_PurchaseOrderLines_QuantityReceived]
                CHECK ([QuantityReceived] >= 0 AND [QuantityReceived] <= [QuantityOrdered]),
            CONSTRAINT [CK_PurchaseOrderLines_UnitCost] CHECK ([UnitCost] >= 0)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.PurchaseOrderLines') AND [name] = N'UQ_PurchaseOrderLines_PurchaseOrderId_LineNumber')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_PurchaseOrderLines_PurchaseOrderId_LineNumber]
            ON [INE].[PurchaseOrderLines] ([PurchaseOrderId], [LineNumber]);

    ---------------------------------------------------------------------------
    -- INE.Receipts
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.Receipts', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[Receipts]
        (
            [ReceiptID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [PurchaseOrderId] [bigint] NULL,
            [LocationId] [int] NOT NULL,
            [PackingSlipNumber] [nvarchar](50) NULL,
            [ReceivedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Receipts_ReceivedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [Notes] [nvarchar](2000) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Receipts_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Receipts_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Receipts_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Receipts_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Receipts_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Receipts_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Receipts_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Receipts] PRIMARY KEY CLUSTERED ([ReceiptID] ASC),
            CONSTRAINT [FK_Receipts_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Receipts_PurchaseOrders] FOREIGN KEY ([PurchaseOrderId])
                REFERENCES [INE].[PurchaseOrders] ([PurchaseOrderID]),
            CONSTRAINT [FK_Receipts_Locations] FOREIGN KEY ([LocationId])
                REFERENCES [INE].[Locations] ([LocationID])
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.Receipts') AND [name] = N'IX_Receipts_PurchaseOrderId')
        CREATE NONCLUSTERED INDEX [IX_Receipts_PurchaseOrderId]
            ON [INE].[Receipts] ([PurchaseOrderId])
            WHERE [PurchaseOrderId] IS NOT NULL;

    ---------------------------------------------------------------------------
    -- INE.SerialUnits
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.SerialUnits', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[SerialUnits]
        (
            [SerialUnitID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [StockItemId] [int] NOT NULL,
            [LotId] [int] NULL,
            [CurrentLocationId] [int] NULL,
            -- The PO line it was bought on, when there was one.
            [PurchaseOrderLineId] [bigint] NULL,
            [SerialNumber] [nvarchar](60) NOT NULL,
            [Status] [varchar](10) NOT NULL CONSTRAINT [DF_SerialUnits_Status] DEFAULT ('InStock'),
            [UnitCost] [decimal](19, 4) NULL,
            [ReceivedDate] [datetimeoffset](7) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_SerialUnits_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_SerialUnits_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_SerialUnits_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SerialUnits_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_SerialUnits_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SerialUnits_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_SerialUnits_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_SerialUnits] PRIMARY KEY CLUSTERED ([SerialUnitID] ASC),
            CONSTRAINT [FK_SerialUnits_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_SerialUnits_StockItems] FOREIGN KEY ([StockItemId])
                REFERENCES [INE].[StockItems] ([StockItemID]),
            CONSTRAINT [FK_SerialUnits_Lots] FOREIGN KEY ([LotId])
                REFERENCES [INE].[Lots] ([LotID]),
            CONSTRAINT [FK_SerialUnits_Locations] FOREIGN KEY ([CurrentLocationId])
                REFERENCES [INE].[Locations] ([LocationID]),
            CONSTRAINT [FK_SerialUnits_PurchaseOrderLines] FOREIGN KEY ([PurchaseOrderLineId])
                REFERENCES [INE].[PurchaseOrderLines] ([PurchaseOrderLineID]),
            CONSTRAINT [CK_SerialUnits_Status]
                CHECK ([Status] IN ('InStock', 'Installed', 'Returned', 'Scrapped', 'Missing', 'Voided')),
            CONSTRAINT [CK_SerialUnits_CurrentLocationId]
                CHECK (([Status] IN ('Scrapped', 'Missing', 'Voided') AND [CurrentLocationId] IS NULL)
                       OR ([Status] IN ('InStock', 'Installed', 'Returned') AND [CurrentLocationId] IS NOT NULL))
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.SerialUnits') AND [name] = N'UQ_SerialUnits_StockItemId_SerialNumber')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_SerialUnits_StockItemId_SerialNumber]
            ON [INE].[SerialUnits] ([StockItemId], [SerialNumber]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.SerialUnits') AND [name] = N'IX_SerialUnits_DealerTenantId_SerialNumber')
        CREATE NONCLUSTERED INDEX [IX_SerialUnits_DealerTenantId_SerialNumber]
            ON [INE].[SerialUnits] ([DealerTenantId], [SerialNumber]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.SerialUnits') AND [name] = N'IX_SerialUnits_CurrentLocationId')
        CREATE NONCLUSTERED INDEX [IX_SerialUnits_CurrentLocationId]
            ON [INE].[SerialUnits] ([CurrentLocationId], [StockItemId])
            WHERE [CurrentLocationId] IS NOT NULL;

    ---------------------------------------------------------------------------
    -- INE.StockCounts
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.StockCounts', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[StockCounts]
        (
            [StockCountID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [LocationId] [int] NOT NULL,
            [Status] [varchar](10) NOT NULL CONSTRAINT [DF_StockCounts_Status] DEFAULT ('Open'),
            [CountDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCounts_CountDate] DEFAULT (SYSDATETIMEOFFSET()),
            [PostedDate] [datetimeoffset](7) NULL,
            [Notes] [nvarchar](2000) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_StockCounts_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_StockCounts_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCounts_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockCounts_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCounts_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockCounts_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCounts_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_StockCounts] PRIMARY KEY CLUSTERED ([StockCountID] ASC),
            CONSTRAINT [FK_StockCounts_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_StockCounts_Locations] FOREIGN KEY ([LocationId])
                REFERENCES [INE].[Locations] ([LocationID]),
            CONSTRAINT [CK_StockCounts_Status] CHECK ([Status] IN ('Open', 'Posted', 'Cancelled'))
        );
    END;

    ---------------------------------------------------------------------------
    -- INE.StockCountLines
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.StockCountLines', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[StockCountLines]
        (
            [StockCountLineID] [bigint] IDENTITY(1,1) NOT NULL,
            [StockCountId] [bigint] NOT NULL,
            [StockItemId] [int] NOT NULL,
            [LotId] [int] NULL,
            [SerialUnitId] [bigint] NULL,
            [CountedQuantity] [decimal](19, 4) NOT NULL,
            -- On-hand at posting time, filled in by INE.spStockCountPost.
            [ExpectedQuantity] [decimal](19, 4) NULL,
            [Notes] [nvarchar](500) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_StockCountLines_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_StockCountLines_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCountLines_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockCountLines_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCountLines_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockCountLines_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCountLines_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_StockCountLines] PRIMARY KEY CLUSTERED ([StockCountLineID] ASC),
            CONSTRAINT [FK_StockCountLines_StockCounts] FOREIGN KEY ([StockCountId])
                REFERENCES [INE].[StockCounts] ([StockCountID]),
            CONSTRAINT [FK_StockCountLines_StockItems] FOREIGN KEY ([StockItemId])
                REFERENCES [INE].[StockItems] ([StockItemID]),
            CONSTRAINT [FK_StockCountLines_Lots] FOREIGN KEY ([LotId])
                REFERENCES [INE].[Lots] ([LotID]),
            CONSTRAINT [FK_StockCountLines_SerialUnits] FOREIGN KEY ([SerialUnitId])
                REFERENCES [INE].[SerialUnits] ([SerialUnitID]),
            CONSTRAINT [CK_StockCountLines_CountedQuantity] CHECK ([CountedQuantity] >= 0),
            CONSTRAINT [CK_StockCountLines_Serial] CHECK ([SerialUnitId] IS NULL OR [CountedQuantity] IN (0, 1))
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.StockCountLines') AND [name] = N'IX_StockCountLines_StockCountId')
        CREATE NONCLUSTERED INDEX [IX_StockCountLines_StockCountId]
            ON [INE].[StockCountLines] ([StockCountId], [StockItemId]);

    ---------------------------------------------------------------------------
    -- INE.Allocations
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.Allocations', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[Allocations]
        (
            [AllocationID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [LeadId] [bigint] NOT NULL,
            [StockItemId] [int] NOT NULL,
            [LocationId] [int] NOT NULL,
            [LotId] [int] NULL,
            [QuantityAllocated] [decimal](19, 4) NOT NULL,
            [QuantityIssued] [decimal](19, 4) NOT NULL CONSTRAINT [DF_Allocations_QuantityIssued] DEFAULT ((0)),
            [Status] [varchar](10) NOT NULL CONSTRAINT [DF_Allocations_Status] DEFAULT ('Open'),
            [NeededByDate] [date] NULL,
            [Notes] [nvarchar](500) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Allocations_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Allocations_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Allocations_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Allocations_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Allocations_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Allocations_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Allocations_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Allocations] PRIMARY KEY CLUSTERED ([AllocationID] ASC),
            CONSTRAINT [FK_Allocations_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Allocations_Leads] FOREIGN KEY ([LeadId])
                REFERENCES [QAL].[Leads] ([LeadID]),
            CONSTRAINT [FK_Allocations_StockItems] FOREIGN KEY ([StockItemId])
                REFERENCES [INE].[StockItems] ([StockItemID]),
            CONSTRAINT [FK_Allocations_Locations] FOREIGN KEY ([LocationId])
                REFERENCES [INE].[Locations] ([LocationID]),
            CONSTRAINT [FK_Allocations_Lots] FOREIGN KEY ([LotId])
                REFERENCES [INE].[Lots] ([LotID]),
            CONSTRAINT [CK_Allocations_Quantities]
                CHECK ([QuantityAllocated] > 0 AND [QuantityIssued] >= 0 AND [QuantityIssued] <= [QuantityAllocated]),
            CONSTRAINT [CK_Allocations_Status] CHECK ([Status] IN ('Open', 'Fulfilled', 'Cancelled'))
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.Allocations') AND [name] = N'IX_Allocations_LeadId')
        CREATE NONCLUSTERED INDEX [IX_Allocations_LeadId]
            ON [INE].[Allocations] ([LeadId], [Status]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.Allocations') AND [name] = N'IX_Allocations_Open')
        CREATE NONCLUSTERED INDEX [IX_Allocations_Open]
            ON [INE].[Allocations] ([LocationId], [StockItemId], [LotId])
            INCLUDE ([QuantityAllocated], [QuantityIssued])
            WHERE [Status] = 'Open';

    ---------------------------------------------------------------------------
    -- INE.Movements
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.Movements', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[Movements]
        (
            [MovementID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [MovementTypeId] [int] NOT NULL,
            [FromLocationId] [int] NULL,
            [ToLocationId] [int] NULL,
            -- The job the stock went to or came back from.
            [LeadId] [bigint] NULL,
            [ReceiptId] [bigint] NULL,
            [StockCountId] [bigint] NULL,
            [ReversesMovementId] [bigint] NULL,
            [MovementDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Movements_MovementDate] DEFAULT (SYSDATETIMEOFFSET()),
            -- RMA number, transfer slip, work order, ...
            [Reference] [nvarchar](50) NULL,
            [Notes] [nvarchar](2000) NULL,
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Movements_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Movements_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Movements_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Movements] PRIMARY KEY CLUSTERED ([MovementID] ASC),
            CONSTRAINT [FK_Movements_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Movements_MovementTypes] FOREIGN KEY ([MovementTypeId])
                REFERENCES [INE].[MovementTypes] ([MovementTypeID]),
            CONSTRAINT [FK_Movements_Locations_From] FOREIGN KEY ([FromLocationId])
                REFERENCES [INE].[Locations] ([LocationID]),
            CONSTRAINT [FK_Movements_Locations_To] FOREIGN KEY ([ToLocationId])
                REFERENCES [INE].[Locations] ([LocationID]),
            CONSTRAINT [FK_Movements_Leads] FOREIGN KEY ([LeadId])
                REFERENCES [QAL].[Leads] ([LeadID]),
            CONSTRAINT [FK_Movements_Receipts] FOREIGN KEY ([ReceiptId])
                REFERENCES [INE].[Receipts] ([ReceiptID]),
            CONSTRAINT [FK_Movements_StockCounts] FOREIGN KEY ([StockCountId])
                REFERENCES [INE].[StockCounts] ([StockCountID]),
            CONSTRAINT [FK_Movements_Movements] FOREIGN KEY ([ReversesMovementId])
                REFERENCES [INE].[Movements] ([MovementID]),
            CONSTRAINT [CK_Movements_Locations]
                CHECK (([FromLocationId] IS NOT NULL OR [ToLocationId] IS NOT NULL)
                       AND ([FromLocationId] IS NULL OR [ToLocationId] IS NULL OR [FromLocationId] <> [ToLocationId]))
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.Movements') AND [name] = N'IX_Movements_DealerTenantId_MovementDate')
        CREATE NONCLUSTERED INDEX [IX_Movements_DealerTenantId_MovementDate]
            ON [INE].[Movements] ([DealerTenantId], [MovementDate] DESC)
            INCLUDE ([MovementTypeId], [FromLocationId], [ToLocationId]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.Movements') AND [name] = N'IX_Movements_LeadId')
        CREATE NONCLUSTERED INDEX [IX_Movements_LeadId]
            ON [INE].[Movements] ([LeadId])
            WHERE [LeadId] IS NOT NULL;

    -- At most one reversal per movement.
    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.Movements') AND [name] = N'UQ_Movements_ReversesMovementId')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Movements_ReversesMovementId]
            ON [INE].[Movements] ([ReversesMovementId])
            WHERE [ReversesMovementId] IS NOT NULL;

    ---------------------------------------------------------------------------
    -- INE.MovementLines
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.MovementLines', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[MovementLines]
        (
            [MovementLineID] [bigint] IDENTITY(1,1) NOT NULL,
            [MovementId] [bigint] NOT NULL,
            [StockItemId] [int] NOT NULL,
            [LotId] [int] NULL,
            [SerialUnitId] [bigint] NULL,
            -- Receive: the PO line this fills.
            [PurchaseOrderLineId] [bigint] NULL,
            -- IssueToJob: the allocation this consumes.
            [AllocationId] [bigint] NULL,
            [Quantity] [decimal](19, 4) NOT NULL,
            [UnitCost] [decimal](19, 4) NULL,
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MovementLines_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MovementLines_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MovementLines_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_MovementLines] PRIMARY KEY CLUSTERED ([MovementLineID] ASC),
            CONSTRAINT [FK_MovementLines_Movements] FOREIGN KEY ([MovementId])
                REFERENCES [INE].[Movements] ([MovementID]),
            CONSTRAINT [FK_MovementLines_StockItems] FOREIGN KEY ([StockItemId])
                REFERENCES [INE].[StockItems] ([StockItemID]),
            CONSTRAINT [FK_MovementLines_Lots] FOREIGN KEY ([LotId])
                REFERENCES [INE].[Lots] ([LotID]),
            CONSTRAINT [FK_MovementLines_SerialUnits] FOREIGN KEY ([SerialUnitId])
                REFERENCES [INE].[SerialUnits] ([SerialUnitID]),
            CONSTRAINT [FK_MovementLines_PurchaseOrderLines] FOREIGN KEY ([PurchaseOrderLineId])
                REFERENCES [INE].[PurchaseOrderLines] ([PurchaseOrderLineID]),
            CONSTRAINT [FK_MovementLines_Allocations] FOREIGN KEY ([AllocationId])
                REFERENCES [INE].[Allocations] ([AllocationID]),
            CONSTRAINT [CK_MovementLines_Quantity] CHECK ([Quantity] > 0),
            CONSTRAINT [CK_MovementLines_Serial] CHECK ([SerialUnitId] IS NULL OR [Quantity] = 1),
            CONSTRAINT [CK_MovementLines_UnitCost] CHECK ([UnitCost] IS NULL OR [UnitCost] >= 0)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.MovementLines') AND [name] = N'IX_MovementLines_MovementId')
        CREATE NONCLUSTERED INDEX [IX_MovementLines_MovementId]
            ON [INE].[MovementLines] ([MovementId]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.MovementLines') AND [name] = N'IX_MovementLines_SerialUnitId')
        CREATE NONCLUSTERED INDEX [IX_MovementLines_SerialUnitId]
            ON [INE].[MovementLines] ([SerialUnitId], [MovementId])
            WHERE [SerialUnitId] IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.MovementLines') AND [name] = N'IX_MovementLines_StockItemId')
        CREATE NONCLUSTERED INDEX [IX_MovementLines_StockItemId]
            ON [INE].[MovementLines] ([StockItemId], [MovementId])
            INCLUDE ([LotId], [Quantity]);

    ---------------------------------------------------------------------------
    -- INE.StockBalances
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'INE.StockBalances', N'U') IS NULL
    BEGIN
        CREATE TABLE [INE].[StockBalances]
        (
            [StockBalanceID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [LocationId] [int] NOT NULL,
            [StockItemId] [int] NOT NULL,
            [LotId] [int] NULL,
            [LastMovementId] [bigint] NULL,
            [QuantityOnHand] [decimal](19, 4) NOT NULL CONSTRAINT [DF_StockBalances_QuantityOnHand] DEFAULT ((0)),
            [QuantityAllocated] [decimal](19, 4) NOT NULL CONSTRAINT [DF_StockBalances_QuantityAllocated] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockBalances_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockBalances_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockBalances_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_StockBalances] PRIMARY KEY CLUSTERED ([StockBalanceID] ASC),
            CONSTRAINT [FK_StockBalances_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_StockBalances_Locations] FOREIGN KEY ([LocationId])
                REFERENCES [INE].[Locations] ([LocationID]),
            CONSTRAINT [FK_StockBalances_StockItems] FOREIGN KEY ([StockItemId])
                REFERENCES [INE].[StockItems] ([StockItemID]),
            CONSTRAINT [FK_StockBalances_Lots] FOREIGN KEY ([LotId])
                REFERENCES [INE].[Lots] ([LotID]),
            CONSTRAINT [FK_StockBalances_Movements] FOREIGN KEY ([LastMovementId])
                REFERENCES [INE].[Movements] ([MovementID]),
            CONSTRAINT [CK_StockBalances_QuantityOnHand] CHECK ([QuantityOnHand] >= 0),
            CONSTRAINT [CK_StockBalances_QuantityAllocated]
                CHECK ([QuantityAllocated] >= 0 AND [QuantityAllocated] <= [QuantityOnHand])
        );
    END;

    -- One row per location, item and lot (a unique index treats NULL LotId as one value).
    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.StockBalances') AND [name] = N'UQ_StockBalances_LocationId_StockItemId_LotId')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_StockBalances_LocationId_StockItemId_LotId]
            ON [INE].[StockBalances] ([LocationId], [StockItemId], [LotId])
            INCLUDE ([QuantityOnHand], [QuantityAllocated]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.StockBalances') AND [name] = N'IX_StockBalances_StockItemId')
        CREATE NONCLUSTERED INDEX [IX_StockBalances_StockItemId]
            ON [INE].[StockBalances] ([StockItemId], [LocationId])
            INCLUDE ([LotId], [QuantityOnHand], [QuantityAllocated]);

    ---------------------------------------------------------------------------
    -- Seed data
    ---------------------------------------------------------------------------
    MERGE INTO [INE].[LocationTypes] AS T
    USING (VALUES
        (1, 'Warehouse', N'Warehouse', N'A building or yard where stock is kept.', 1),
        (2, 'Vehicle', N'Vehicle', N'An installer''s truck or van; stock there is on hand but out in the field.', 1),
        (3, 'Staging', N'Staging Area', N'Where a job''s materials are kitted before they go out.', 1),
        (4, 'Job', N'Job Site', N'A customer''s installation (one per lead). Stock issued here is installed, not on hand.', 0),
        (5, 'Vendor', N'Vendor', N'A supplier that stock is returned to.', 0)
    ) AS S ([LocationTypeID], [Code], [Name], [Description], [IsStockHolding])
    ON T.[LocationTypeID] = S.[LocationTypeID]
    WHEN MATCHED THEN UPDATE SET T.[Code] = S.[Code], T.[Name] = S.[Name], T.[Description] = S.[Description],
        T.[IsStockHolding] = S.[IsStockHolding], T.[ModifiedDate] = SYSDATETIMEOFFSET()
    WHEN NOT MATCHED THEN INSERT ([LocationTypeID], [Code], [Name], [Description], [IsStockHolding])
        VALUES (S.[LocationTypeID], S.[Code], S.[Name], S.[Description], S.[IsStockHolding]);
    -- From/To rule NULL = any stock-holding location (Warehouse, Vehicle, Staging).
    MERGE INTO [INE].[MovementTypes] AS T
    USING (VALUES
        (1, 'Receive', N'Receive', N'Stock arrives from a vendor (posted with a receipt).', 0, 1, NULL, NULL, 0, 10),
        (2, 'Transfer', N'Transfer', N'Stock moves between warehouses, vehicles and staging areas.', 1, 1, NULL, NULL, 0, 20),
        (3, 'IssueToJob', N'Issue to Job', N'Stock goes out to a customer''s job and is installed.', 1, 1, NULL, 'Job', 1, 30),
        (4, 'ReturnFromJob', N'Return from Job', N'Unused or removed stock comes back from a job.', 1, 1, 'Job', NULL, 1, 40),
        (5, 'ReturnToVendor', N'Return to Vendor', N'Defective or excess stock goes back to a supplier (Reference = RMA number).', 1, 1, NULL, 'Vendor', 0, 50),
        (6, 'AdjustIn', N'Adjust In', N'Stock found or an opening balance.', 0, 1, NULL, NULL, 0, 60),
        (7, 'AdjustOut', N'Adjust Out', N'Stock that cannot be found.', 1, 0, NULL, NULL, 0, 70),
        (8, 'Scrap', N'Scrap', N'Damaged stock written off.', 1, 0, NULL, NULL, 0, 80),
        (9, 'Reversal', N'Reversal', N'Undoes an earlier movement; its ends mirror the original (INE.spMovementReverse).', 0, 0, NULL, NULL, 0, 90)
    ) AS S ([MovementTypeID], [Code], [Name], [Description], [RequiresFrom], [RequiresTo], [FromLocationTypeCode], [ToLocationTypeCode], [RequiresLead], [SortOrder])
    ON T.[MovementTypeID] = S.[MovementTypeID]
    WHEN MATCHED THEN UPDATE SET T.[Code] = S.[Code], T.[Name] = S.[Name], T.[Description] = S.[Description],
        T.[RequiresFrom] = S.[RequiresFrom], T.[RequiresTo] = S.[RequiresTo], T.[FromLocationTypeCode] = S.[FromLocationTypeCode],
        T.[ToLocationTypeCode] = S.[ToLocationTypeCode], T.[RequiresLead] = S.[RequiresLead], T.[SortOrder] = S.[SortOrder],
        T.[ModifiedDate] = SYSDATETIMEOFFSET()
    WHEN NOT MATCHED THEN INSERT ([MovementTypeID], [Code], [Name], [Description], [RequiresFrom], [RequiresTo],
        [FromLocationTypeCode], [ToLocationTypeCode], [RequiresLead], [SortOrder])
        VALUES (S.[MovementTypeID], S.[Code], S.[Name], S.[Description], S.[RequiresFrom], S.[RequiresTo],
        S.[FromLocationTypeCode], S.[ToLocationTypeCode], S.[RequiresLead], S.[SortOrder]);
    -- The Solasta Lighting tenant starts with one warehouse.
    DECLARE @SolastaTenantId INT = (SELECT [DealerTenantID] FROM [ACC].[DealerTenants]
                                    WHERE [Proxy] = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6');
    IF @SolastaTenantId IS NULL
        PRINT 'Solasta Lighting tenant not found; skipping the MAIN warehouse seed.';
    ELSE IF NOT EXISTS (SELECT 1 FROM [INE].[Locations] WHERE [DealerTenantId] = @SolastaTenantId AND [Code] = N'MAIN')
        INSERT INTO [INE].[Locations] ([DealerTenantId], [LocationTypeId], [Code], [Name])
        VALUES (@SolastaTenantId, 1, N'MAIN', N'Main Warehouse');

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Create the INE inventory engine schema and tables and seed location and movement types',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
