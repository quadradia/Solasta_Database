/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: AddressTypes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AddressTypes' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
CREATE TABLE [MAC].[AddressTypes](
	[AddressTypeID] [varchar](10) NOT NULL,
	[AddressTypeName] [nvarchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_AddressTypes] PRIMARY KEY CLUSTERED 
(
	[AddressTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressTypes_IsActive' AND type = 'D')
ALTER TABLE [MAC].[AddressTypes] ADD  CONSTRAINT [DF_AddressTypes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressTypes_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[AddressTypes] ADD  CONSTRAINT [DF_AddressTypes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressTypes_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[AddressTypes] ADD  CONSTRAINT [DF_AddressTypes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressTypes_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[AddressTypes] ADD  CONSTRAINT [DF_AddressTypes_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressTypes_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[AddressTypes] ADD  CONSTRAINT [DF_AddressTypes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressTypes_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[AddressTypes] ADD  CONSTRAINT [DF_AddressTypes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO
