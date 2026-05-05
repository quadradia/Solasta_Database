/*******************************************************************************
 * Object Type: Table
 * Schema: QAL
 * Name: LeadSources
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'LeadSources' AND schema_id = SCHEMA_ID('QAL'))
BEGIN
	CREATE TABLE [QAL].[LeadSources]
	(
		[LeadSourceID] [int] IDENTITY(1,1) NOT NULL,
		[DealerTenantId] [int] NOT NULL,
		[LeadSourceName] [nvarchar](50) NOT NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [uniqueidentifier] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[CreatedById] [uniqueidentifier] NOT NULL,
		[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
		CONSTRAINT [PK_LeadSources] PRIMARY KEY CLUSTERED
(
	[LeadSourceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_LeadSources_IsActive' AND type = 'D')
ALTER TABLE [QAL].[LeadSources] ADD  CONSTRAINT [DF_LeadSources_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_LeadSources_IsDeleted' AND type = 'D')
ALTER TABLE [QAL].[LeadSources] ADD  CONSTRAINT [DF_LeadSources_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_LeadSources_ModifiedDate' AND type = 'D')
ALTER TABLE [QAL].[LeadSources] ADD  CONSTRAINT [DF_LeadSources_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_LeadSources_ModifiedById' AND type = 'D')
ALTER TABLE [QAL].[LeadSources] ADD  CONSTRAINT [DF_LeadSources_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_LeadSources_CreatedDate' AND type = 'D')
ALTER TABLE [QAL].[LeadSources] ADD  CONSTRAINT [DF_LeadSources_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_LeadSources_CreatedById' AND type = 'D')
ALTER TABLE [QAL].[LeadSources] ADD  CONSTRAINT [DF_LeadSources_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_LeadSources_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [QAL].[LeadSources] ADD  CONSTRAINT [DF_LeadSources_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_LeadSources_DealerTenants')
ALTER TABLE [QAL].[LeadSources]  WITH CHECK ADD  CONSTRAINT [FK_LeadSources_DealerTenants] FOREIGN KEY([DealerTenantId])
REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
GO

ALTER TABLE [QAL].[LeadSources] CHECK CONSTRAINT [FK_LeadSources_DealerTenants]
GO
