/*******************************************************************************
 * Object Type: Table
 * Schema: ACC
 * Name: DealerTenants
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DealerTenants' AND schema_id = SCHEMA_ID('ACC'))
BEGIN
CREATE TABLE [ACC].[DealerTenants](
	[DealerTenantID] [int] IDENTITY(1,1) NOT NULL,
	[DealerTenantTypeId] [int] NOT NULL,
	[Proxy] [varchar](100) NOT NULL,
	[PartKey] [varchar](6) NOT NULL,
	[DealerTenantName] [nvarchar](100) NOT NULL,
	[DealerTenantDescription] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [int] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [int] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Tenants] PRIMARY KEY CLUSTERED 
(
	[DealerTenantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Tenants_IsActive' AND type = 'D')
ALTER TABLE [ACC].[DealerTenants] ADD  CONSTRAINT [DF_Tenants_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Tenants_IsDeleted' AND type = 'D')
ALTER TABLE [ACC].[DealerTenants] ADD  CONSTRAINT [DF_Tenants_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Tenants_ModifiedDate' AND type = 'D')
ALTER TABLE [ACC].[DealerTenants] ADD  CONSTRAINT [DF_Tenants_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Tenants_ModifiedById' AND type = 'D')
ALTER TABLE [ACC].[DealerTenants] ADD  CONSTRAINT [DF_Tenants_ModifiedById]  DEFAULT ((0)) FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Tenants_CreatedDate' AND type = 'D')
ALTER TABLE [ACC].[DealerTenants] ADD  CONSTRAINT [DF_Tenants_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Tenants_CreatedById' AND type = 'D')
ALTER TABLE [ACC].[DealerTenants] ADD  CONSTRAINT [DF_Tenants_CreatedById]  DEFAULT ((0)) FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Tenants_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [ACC].[DealerTenants] ADD  CONSTRAINT [DF_Tenants_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DealerTenants_DealerTenantTypes')
ALTER TABLE [ACC].[DealerTenants]  WITH CHECK ADD  CONSTRAINT [FK_DealerTenants_DealerTenantTypes] FOREIGN KEY([DealerTenantTypeId])
REFERENCES [ACC].[DealerTenantTypes] ([DealerTenantTypeID])
GO

ALTER TABLE [ACC].[DealerTenants] CHECK CONSTRAINT [FK_DealerTenants_DealerTenantTypes]
GO
