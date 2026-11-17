/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: PurchaseOrders
 * Description: An order for stock from a vendor, delivered to one location. Status is
 *              stored and moved only by INE.spPurchaseOrderSetStatus and receiving:
 *                Draft -> Submitted -> PartiallyReceived -> Received -> Closed
 *                Draft or Submitted -> Cancelled
 *              (This is separate from MAC.PurchaseOrders, which belongs to quotes.)
 * Dependencies: ACC.DealerTenants, INE.Vendors, INE.Locations
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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
GO
