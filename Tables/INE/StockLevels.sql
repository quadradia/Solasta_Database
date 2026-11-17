/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: StockLevels
 * Description: Reorder rules for a stock item at a location. When available stock plus
 *              stock on open POs falls to ReorderPoint or below, INE.vwReorderSuggestions
 *              suggests ordering up to MaximumQuantity.
 * Dependencies: INE.StockItems, INE.Locations
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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
GO
