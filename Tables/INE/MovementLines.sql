/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: MovementLines
 * Description: The items and quantities of a movement. Quantity is always positive; the
 *              movement's from/to locations give the direction. A Serial item has one
 *              line per unit with Quantity 1. Append-only, like INE.Movements.
 * Dependencies: INE.Movements, INE.StockItems, INE.Lots, INE.SerialUnits,
 *               INE.PurchaseOrderLines, INE.Allocations
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.MovementLines', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[MovementLines]
    (
        [MovementLineID] [bigint] IDENTITY(1,1) NOT NULL,
        [MovementId] [bigint] NOT NULL,
        [StockItemId] [int] NOT NULL,
        [LotId] [int] NULL,
        [SerialUnitId] [bigint] NULL,
        [Quantity] [decimal](19, 4) NOT NULL,
        [UnitCost] [decimal](19, 4) NULL,
        -- Receive: the PO line this fills.
        [PurchaseOrderLineId] [bigint] NULL,
        -- IssueToJob: the allocation this consumes.
        [AllocationId] [bigint] NULL,
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
GO
