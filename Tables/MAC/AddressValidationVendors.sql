/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: AddressValidationVendors
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AddressValidationVendors' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
CREATE TABLE [MAC].[AddressValidationVendors](
	[AddressValidationVendorID] [varchar](20) NOT NULL,
	[AddressValidationVendorName] [nvarchar](200) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW] [bigint] IDENTITY(1,1) NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_AddressValidationVendors] PRIMARY KEY CLUSTERED 
(
	[AddressValidationVendorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressValidationVendors_IsActive' AND type = 'D')
ALTER TABLE [MAC].[AddressValidationVendors] ADD  CONSTRAINT [DF_AddressValidationVendors_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressValidationVendors_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[AddressValidationVendors] ADD  CONSTRAINT [DF_AddressValidationVendors_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressValidationVendors_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[AddressValidationVendors] ADD  CONSTRAINT [DF_AddressValidationVendors_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressValidationVendors_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[AddressValidationVendors] ADD  CONSTRAINT [DF_AddressValidationVendors_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressValidationVendors_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[AddressValidationVendors] ADD  CONSTRAINT [DF_AddressValidationVendors_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressValidationVendors_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[AddressValidationVendors] ADD  CONSTRAINT [DF_AddressValidationVendors_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AddressValidationVendors_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[AddressValidationVendors] ADD  CONSTRAINT [DF_AddressValidationVendors_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO
