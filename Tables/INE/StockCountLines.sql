/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: StockCountLines
 * Description: What was counted for one item (and lot) during a stock count. For a
 *              Serial item, one line per serial unit with CountedQuantity 1 (found) or
 *              0 (missing). Items on hand that have no line are treated as not counted
 *              and are left alone.
 * Dependencies: INE.StockCounts, INE.StockItems, INE.Lots, INE.SerialUnits
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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
GO
