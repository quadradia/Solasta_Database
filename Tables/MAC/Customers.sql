/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: Customers
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Customers' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
CREATE TABLE [MAC].[Customers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Proxy] [varchar](100) NOT NULL,
	[PartKey] [varchar](6) NOT NULL,
	[TypeId] [int] NOT NULL,
	[CustomerName] [nvarchar](255) NOT NULL,
	[ContactPerson] [nvarchar](255) NULL,
	[Email] [nvarchar](255) NULL,
	[Phone] [nvarchar](50) NULL,
	[Address] [nvarchar](500) NULL,
	[City] [nvarchar](100) NULL,
	[State] [nvarchar](50) NULL,
	[ZipCode] [nvarchar](20) NULL,
	[Country] [nvarchar](100) NULL,
	[Notes] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [bigint] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK__Customer__3214EC07AA488884] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_IsActive' AND type = 'D')
ALTER TABLE [MAC].[Customers] ADD  CONSTRAINT [DF_Customers_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[Customers] ADD  CONSTRAINT [DF_Customers_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[Customers] ADD  CONSTRAINT [DF_Customers_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[Customers] ADD  CONSTRAINT [DF_Customers_ModifiedById]  DEFAULT ((0)) FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[Customers] ADD  CONSTRAINT [DF_Customers_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[Customers] ADD  CONSTRAINT [DF_Customers_CreatedById]  DEFAULT ((0)) FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[Customers] ADD  CONSTRAINT [DF_Customers_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK__Customers__TypeI__1AD3FDA4')
ALTER TABLE [MAC].[Customers]  WITH CHECK ADD  CONSTRAINT [FK__Customers__TypeI__1AD3FDA4] FOREIGN KEY([TypeId])
REFERENCES [MAC].[CustomerTypes] ([TypeId])
GO

ALTER TABLE [MAC].[Customers] CHECK CONSTRAINT [FK__Customers__TypeI__1AD3FDA4]
GO
