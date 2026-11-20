/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: StockItems
 * Description: Anything Solasta stocks: rail track, light pods, controllers, power
 *              supplies, connectors, clips. TrackingMode decides how it is counted:
 *                Quantity  just a number per location (clips, connectors, rail by the foot)
 *                Lot       a number per location per lot/reel/color bin
 *                Serial    one INE.SerialUnits row per physical unit (controllers, gateways)
 *              UnitOfMeasure is ft or each; quantities are DECIMAL(19,4) so footage is exact.
 *              ProductId optionally links to the priced product in MAC.Products.
 *              Variants (20261120_0100_AddINE_PartVariants): an item the customer must pick a
 *              color (or other option) for is a parent catalog entry; each choice is a child row
 *              with ParentStockItemId, VariantName (e.g. Black) and an optional PriceAdder, the
 *              customer-facing extra per unit added to the product price on quotes. Stock lives
 *              on variants only: the INE procedures and line triggers refuse a parent that has
 *              active variants (04190). One level deep (04191); a variant takes its parent's
 *              ProductId (kept in step by tr_StockItems_VariantGuard). Attributes such as
 *              Color = Black live in INE.StockItemVariantAttributes.
 *              Light strands (20261120_2330_AddINE_LightStrandLengths): an item sold as a strand of
 *              pods (pucks) has PodsPerStrand and PodSpacingInches; one strand is
 *              PodsPerStrand x PodSpacingInches long. Both set or both NULL. The light inventory
 *              report turns strands in stock into feet and inches with them.
 * Dependencies: ACC.DealerTenants, MAC.Products, INE.Vendors
 * Migrations: 20261117_1800_CreateINE_InventoryEngineTables, 20261120_0100_AddINE_PartVariants,
 *             20261120_2330_AddINE_LightStrandLengths
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.StockItems', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[StockItems]
    (
        [StockItemID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [ProductId] [int] NULL,
        -- Set on a variant: the parent catalog entry it is a choice of (one level deep).
        [ParentStockItemId] [int] NULL,
        -- Required on a variant: what the customer picks, e.g. Black. Unique per parent.
        [VariantName] [nvarchar](50) NULL,
        -- Customer-facing extra per unit added to the product price on quotes (0 = none).
        [PriceAdder] [decimal](19, 4) NOT NULL CONSTRAINT [DF_StockItems_PriceAdder] DEFAULT ((0)),
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
        -- Light strands only: pods (pucks) on one strand and the distance between them in inches.
        [PodsPerStrand] [int] NULL,
        [PodSpacingInches] [decimal](9, 3) NULL,
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
        CONSTRAINT [FK_StockItems_ParentStockItems] FOREIGN KEY ([ParentStockItemId])
            REFERENCES [INE].[StockItems] ([StockItemID]),
        CONSTRAINT [CK_StockItems_TrackingMode] CHECK ([TrackingMode] IN ('Quantity', 'Lot', 'Serial')),
        CONSTRAINT [CK_StockItems_UnitOfMeasure] CHECK ([UnitOfMeasure] IN ('ft', 'each')),
        -- A serialized unit is one physical thing.
        CONSTRAINT [CK_StockItems_SerialUnit] CHECK ([TrackingMode] <> 'Serial' OR [UnitOfMeasure] = 'each'),
        CONSTRAINT [CK_StockItems_StandardCost] CHECK ([StandardCost] IS NULL OR [StandardCost] >= 0),
        CONSTRAINT [CK_StockItems_ParentNotSelf] CHECK ([ParentStockItemId] IS NULL OR [ParentStockItemId] <> [StockItemID]),
        CONSTRAINT [CK_StockItems_VariantName] CHECK ([ParentStockItemId] IS NULL OR [VariantName] IS NOT NULL),
        CONSTRAINT [CK_StockItems_PriceAdder] CHECK ([PriceAdder] >= 0),
        CONSTRAINT [CK_StockItems_LightStrand] CHECK (([PodsPerStrand] IS NULL AND [PodSpacingInches] IS NULL)
            OR ([PodsPerStrand] > 0 AND [PodSpacingInches] > 0))
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.StockItems') AND [name] = N'UQ_StockItems_DealerTenantId_Sku')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_StockItems_DealerTenantId_Sku]
        ON [INE].[StockItems] ([DealerTenantId], [Sku]);

-- One variant per name under a parent.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.StockItems') AND [name] = N'UQ_StockItems_ParentStockItemId_VariantName')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_StockItems_ParentStockItemId_VariantName]
        ON [INE].[StockItems] ([ParentStockItemId], [VariantName])
        WHERE [ParentStockItemId] IS NOT NULL;
GO
