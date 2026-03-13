/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: PurchaseOrderTypes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrderTypes' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
CREATE TABLE [MAC].[PurchaseOrderTypes](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Proxy] [nvarchar](50) NOT NULL,
	[PartKey] [int] NOT NULL,
	[TypeId] [int] NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [int] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [int] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON),
 CONSTRAINT [UQ_PurchaseOrderTypes_TypeId] UNIQUE NONCLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PurchaseOrderTypes_IsActive' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrderTypes] ADD  CONSTRAINT [DF_PurchaseOrderTypes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PurchaseOrderTypes_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrderTypes] ADD  CONSTRAINT [DF_PurchaseOrderTypes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PurchaseOrderTypes_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrderTypes] ADD  CONSTRAINT [DF_PurchaseOrderTypes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PurchaseOrderTypes_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrderTypes] ADD  CONSTRAINT [DF_PurchaseOrderTypes_ModifiedById]  DEFAULT ((0)) FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PurchaseOrderTypes_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrderTypes] ADD  CONSTRAINT [DF_PurchaseOrderTypes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PurchaseOrderTypes_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrderTypes] ADD  CONSTRAINT [DF_PurchaseOrderTypes_CreatedById]  DEFAULT ((0)) FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PurchaseOrderTypes_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[PurchaseOrderTypes] ADD  CONSTRAINT [DF_PurchaseOrderTypes_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO
