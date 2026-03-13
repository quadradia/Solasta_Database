/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: TerminationCategories
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TerminationCategories' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[TerminationCategories](
	[TerminationCategoryID] [int] IDENTITY(1,1) NOT NULL,
	[TerminationTypeId] [int] NOT NULL,
	[TerminationCategoryName] [nvarchar](50) NOT NULL,
	[RequiresLastDateWorked] [bit] NOT NULL,
	[RequiresExplanation] [bit] NOT NULL,
	[RequiresNoticeGiven] [bit] NOT NULL,
	[RequiresIntendedLastDay] [bit] NOT NULL,
	[RequiresNewTeamLocationId] [bit] NOT NULL,
	[ExplanationPrompt] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_TerminationCategories] PRIMARY KEY CLUSTERED 
(
	[TerminationCategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationCategories_IsActive' AND type = 'D')
ALTER TABLE [RSU].[TerminationCategories] ADD  CONSTRAINT [DF_TerminationCategories_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationCategories_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[TerminationCategories] ADD  CONSTRAINT [DF_TerminationCategories_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationCategories_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[TerminationCategories] ADD  CONSTRAINT [DF_TerminationCategories_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationCategories_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[TerminationCategories] ADD  CONSTRAINT [DF_TerminationCategories_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationCategories_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[TerminationCategories] ADD  CONSTRAINT [DF_TerminationCategories_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationCategories_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[TerminationCategories] ADD  CONSTRAINT [DF_TerminationCategories_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TerminationCategories_TerminationTypes')
ALTER TABLE [RSU].[TerminationCategories]  WITH CHECK ADD  CONSTRAINT [FK_TerminationCategories_TerminationTypes] FOREIGN KEY([TerminationTypeId])
REFERENCES [RSU].[TerminationTypes] ([TerminationTypeID])
GO

ALTER TABLE [RSU].[TerminationCategories] CHECK CONSTRAINT [FK_TerminationCategories_TerminationTypes]
GO
