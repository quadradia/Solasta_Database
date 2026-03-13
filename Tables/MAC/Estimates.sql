/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: Estimates
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Estimates' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
CREATE TABLE [MAC].[Estimates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Proxy] [nvarchar](50) NOT NULL,
	[PartKey] [int] NOT NULL,
	[TypeId] [int] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[EstimateNumber] [nvarchar](50) NOT NULL,
	[EstimateDate] [date] NOT NULL,
	[ProjectName] [nvarchar](255) NULL,
	[ProjectDescription] [nvarchar](max) NULL,
	[TotalAmount] [decimal](18, 2) NULL,
	[Status] [nvarchar](50) NULL,
	[Notes] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [bigint] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Estimates_IsActive' AND type = 'D')
ALTER TABLE [MAC].[Estimates] ADD  CONSTRAINT [DF_Estimates_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Estimates_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[Estimates] ADD  CONSTRAINT [DF_Estimates_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Estimates_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[Estimates] ADD  CONSTRAINT [DF_Estimates_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Estimates_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[Estimates] ADD  CONSTRAINT [DF_Estimates_ModifiedById]  DEFAULT ((0)) FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Estimates_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[Estimates] ADD  CONSTRAINT [DF_Estimates_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Estimates_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[Estimates] ADD  CONSTRAINT [DF_Estimates_CreatedById]  DEFAULT ((0)) FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Estimates_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[Estimates] ADD  CONSTRAINT [DF_Estimates_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK__Estimates__Custo__245D67DE')
ALTER TABLE [MAC].[Estimates]  WITH CHECK ADD  CONSTRAINT [FK__Estimates__Custo__245D67DE] FOREIGN KEY([CustomerId])
REFERENCES [MAC].[Customers] ([Id])
GO

ALTER TABLE [MAC].[Estimates] CHECK CONSTRAINT [FK__Estimates__Custo__245D67DE]
GO
