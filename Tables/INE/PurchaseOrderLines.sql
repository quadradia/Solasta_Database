/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: PurchaseOrderLines
 * Description: One stock item on a purchase order. QuantityReceived is maintained by
 *              INE.spMovementPost when a Receive movement names the line; receiving
 *              more than was ordered is rejected.
 * Dependencies: INE.PurchaseOrders, INE.StockItems
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.PurchaseOrderLines', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[PurchaseOrderLines]
    (
        [PurchaseOrderLineID] [bigint] IDENTITY(1,1) NOT NULL,
        [PurchaseOrderId] [bigint] NOT NULL,
        [LineNumber] [int] NOT NULL,
        [StockItemId] [int] NOT NULL,
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
GO
