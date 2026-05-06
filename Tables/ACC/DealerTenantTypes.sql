/*******************************************************************************
 * Object Type: Table
 * Schema: ACC
 * Name: DealerTenantTypes
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DealerTenantTypes' AND schema_id = SCHEMA_ID('ACC'))
BEGIN
CREATE TABLE [ACC].[DealerTenantTypes](
	[DealerTenantTypeID] [int] IDENTITY(1,1) NOT NULL,
	[Prefix] [varchar](4) NOT NULL,
	[DealerTenantTypeName] [nvarchar](100) NOT NULL,
	[DealerTenantTypeDescription] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [int] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [int] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_DealerTenantTypes] PRIMARY KEY CLUSTERED
(
	[DealerTenantTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TenantTypes_IsActive' AND type = 'D')
ALTER TABLE [ACC].[DealerTenantTypes] ADD  CONSTRAINT [DF_TenantTypes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TenantTypes_IsDeleted' AND type = 'D')
ALTER TABLE [ACC].[DealerTenantTypes] ADD  CONSTRAINT [DF_TenantTypes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TenantTypes_ModifiedDate' AND type = 'D')
ALTER TABLE [ACC].[DealerTenantTypes] ADD  CONSTRAINT [DF_TenantTypes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TenantTypes_ModifiedById' AND type = 'D')
ALTER TABLE [ACC].[DealerTenantTypes] ADD  CONSTRAINT [DF_TenantTypes_ModifiedById]  DEFAULT ((0)) FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TenantTypes_CreatedDate' AND type = 'D')
ALTER TABLE [ACC].[DealerTenantTypes] ADD  CONSTRAINT [DF_TenantTypes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TenantTypes_CreatedById' AND type = 'D')
ALTER TABLE [ACC].[DealerTenantTypes] ADD  CONSTRAINT [DF_TenantTypes_CreatedById]  DEFAULT ((0)) FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TenantTypes_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [ACC].[DealerTenantTypes] ADD  CONSTRAINT [DF_TenantTypes_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO
