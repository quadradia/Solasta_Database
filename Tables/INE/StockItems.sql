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
 * Dependencies: ACC.DealerTenants, MAC.Products, INE.Vendors
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
        [Sku] [nvarchar](30) NOT NULL,
        [Name] [nvarchar](150) NOT NULL,
        [Description] [nvarchar](1000) NULL,
        [Category] [nvarchar](50) NULL,
        [TrackingMode] [varchar](10) NOT NULL CONSTRAINT [DF_StockItems_TrackingMode] DEFAULT ('Quantity'),
        [UnitOfMeasure] [varchar](4) NOT NULL CONSTRAINT [DF_StockItems_UnitOfMeasure] DEFAULT ('each'),
        [ProductId] [int] NULL,
        [DefaultVendorId] [int] NULL,
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
GO
