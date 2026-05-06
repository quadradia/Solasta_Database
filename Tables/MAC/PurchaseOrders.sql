/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: PurchaseOrders
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'PurchaseOrders' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
	CREATE TABLE [MAC].[PurchaseOrders]
	(
		[PurchaseOrderID] [bigint] IDENTITY(1,1) NOT NULL,
		[Proxy] [nvarchar](100) NOT NULL,
		[PartKey] [varchar](6) NOT NULL,
		[PurchaseOrderTypeId] [int] NOT NULL,
		[QuoteId] [bigint] NOT NULL,
		[PONumber] [nvarchar](50) NOT NULL,
		[PODate] [date] NOT NULL,
		[VendorName] [nvarchar](255) NULL,
		[TotalAmount] [decimal](18, 2) NULL,
		[Status] [nvarchar](50) NULL,
		[DeliveryDate] [date] NULL,
		[Notes] [nvarchar](max) NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [bigint] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[CreatedById] [bigint] NOT NULL,
		[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
		CONSTRAINT [PK_PurchaseOrders] PRIMARY KEY CLUSTERED
(
	[PurchaseOrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PurchaseOrders_IsActive' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrders] ADD  CONSTRAINT [DF_PurchaseOrders_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PurchaseOrders_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrders] ADD  CONSTRAINT [DF_PurchaseOrders_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PurchaseOrders_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrders] ADD  CONSTRAINT [DF_PurchaseOrders_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PurchaseOrders_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrders] ADD  CONSTRAINT [DF_PurchaseOrders_ModifiedById]  DEFAULT ((0)) FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PurchaseOrders_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrders] ADD  CONSTRAINT [DF_PurchaseOrders_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PurchaseOrders_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrders] ADD  CONSTRAINT [DF_PurchaseOrders_CreatedById]  DEFAULT ((0)) FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PurchaseOrders_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrders] ADD  CONSTRAINT [DF_PurchaseOrders_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PurchaseOrders_Quotes')
ALTER TABLE [MAC].[PurchaseOrders]  WITH CHECK ADD  CONSTRAINT [FK_PurchaseOrders_Quotes] FOREIGN KEY([QuoteId])
REFERENCES [MAC].[Quotes] ([QuoteID])
GO

ALTER TABLE [MAC].[PurchaseOrders] CHECK CONSTRAINT [FK_PurchaseOrders_Quotes]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PurchaseOrders_PurchaseOrderTypes')
ALTER TABLE [MAC].[PurchaseOrders]  WITH CHECK ADD  CONSTRAINT [FK_PurchaseOrders_PurchaseOrderTypes] FOREIGN KEY([PurchaseOrderTypeId])
REFERENCES [MAC].[PurchaseOrderTypes] ([PurchaseOrderTypeID])
GO

ALTER TABLE [MAC].[PurchaseOrders] CHECK CONSTRAINT [FK_PurchaseOrders_PurchaseOrderTypes]
GO
