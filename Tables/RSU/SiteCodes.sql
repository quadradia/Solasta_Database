/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: SiteCodes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SiteCodes' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[SiteCodes](
	[SiteCodeID] [int] IDENTITY(1,1) NOT NULL,
	[PoliticalStateId] [varchar](4) NOT NULL,
	[SiteCodeValue] [nvarchar](50) NOT NULL,
	[SiteCodeDescription] [nvarchar](255) NULL,
	[IsDefault] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_SiteCodes] PRIMARY KEY CLUSTERED 
(
	[SiteCodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_SiteCodes_IsActive' AND type = 'D')
ALTER TABLE [RSU].[SiteCodes] ADD  CONSTRAINT [DF_SiteCodes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_SiteCodes_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[SiteCodes] ADD  CONSTRAINT [DF_SiteCodes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_SiteCodes_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[SiteCodes] ADD  CONSTRAINT [DF_SiteCodes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_SiteCodes_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[SiteCodes] ADD  CONSTRAINT [DF_SiteCodes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_SiteCodes_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[SiteCodes] ADD  CONSTRAINT [DF_SiteCodes_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_SiteCodes_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[SiteCodes] ADD  CONSTRAINT [DF_SiteCodes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_SiteCodes_PoliticalStates')
ALTER TABLE [RSU].[SiteCodes]  WITH CHECK ADD  CONSTRAINT [FK_SiteCodes_PoliticalStates] FOREIGN KEY([PoliticalStateId])
REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID])
GO

ALTER TABLE [RSU].[SiteCodes] CHECK CONSTRAINT [FK_SiteCodes_PoliticalStates]
GO
