/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: Receipts
 * Description: A delivery that arrived (the packing slip). Its lines are the Receive
 *              movement INE.spMovementPost writes with ReceiptId set. A receipt may be
 *              against a purchase order or not (opening balances, samples, returns
 *              from a customer that never had a PO).
 * Dependencies: ACC.DealerTenants, INE.PurchaseOrders, INE.Locations
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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
GO
