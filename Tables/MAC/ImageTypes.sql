/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: ImageTypes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ImageTypes' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
CREATE TABLE [MAC].[ImageTypes](
	[ImageTypeID] [varchar](20) NOT NULL,
	[ImageTypeName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW] [bigint] IDENTITY(1,1) NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_ImageTypes] PRIMARY KEY CLUSTERED 
(
	[ImageTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_ImageTypes_IsActive' AND type = 'D')
ALTER TABLE [MAC].[ImageTypes] ADD  CONSTRAINT [DF_ImageTypes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_ImageTypes_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[ImageTypes] ADD  CONSTRAINT [DF_ImageTypes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_ImageTypes_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[ImageTypes] ADD  CONSTRAINT [DF_ImageTypes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_ImageTypes_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[ImageTypes] ADD  CONSTRAINT [DF_ImageTypes_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_ImageTypes_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[ImageTypes] ADD  CONSTRAINT [DF_ImageTypes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_ImageTypes_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[ImageTypes] ADD  CONSTRAINT [DF_ImageTypes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_ImageTypes_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[ImageTypes] ADD  CONSTRAINT [DF_ImageTypes_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO
