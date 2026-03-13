/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: Terminations
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Terminations' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[Terminations](
	[TerminationID] [int] IDENTITY(1,1) NOT NULL,
	[UserRecruitId] [int] NOT NULL,
	[TerminationCategoryId] [int] NOT NULL,
	[TeamLocationId] [int] NULL,
	[LastDateWorked] [datetime] NULL,
	[Explanation] [nvarchar](max) NULL,
	[NoticeGiven] [bit] NULL,
	[IntendedLastDay] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Terminations] PRIMARY KEY CLUSTERED 
(
	[TerminationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Terminations_IsActive' AND type = 'D')
ALTER TABLE [RSU].[Terminations] ADD  CONSTRAINT [DF_Terminations_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Terminations_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[Terminations] ADD  CONSTRAINT [DF_Terminations_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Terminations_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[Terminations] ADD  CONSTRAINT [DF_Terminations_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Terminations_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[Terminations] ADD  CONSTRAINT [DF_Terminations_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Terminations_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[Terminations] ADD  CONSTRAINT [DF_Terminations_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Terminations_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[Terminations] ADD  CONSTRAINT [DF_Terminations_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Terminations_TeamLocations')
ALTER TABLE [RSU].[Terminations]  WITH CHECK ADD  CONSTRAINT [FK_Terminations_TeamLocations] FOREIGN KEY([TeamLocationId])
REFERENCES [RSU].[TeamLocations] ([TeamLocationID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Terminations_TerminationCategories')
ALTER TABLE [RSU].[Terminations]  WITH CHECK ADD  CONSTRAINT [FK_Terminations_TerminationCategories] FOREIGN KEY([TerminationCategoryId])
REFERENCES [RSU].[TerminationCategories] ([TerminationCategoryID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Terminations_UserRecruits')
ALTER TABLE [RSU].[Terminations]  WITH CHECK ADD  CONSTRAINT [FK_Terminations_UserRecruits] FOREIGN KEY([UserRecruitId])
REFERENCES [RSU].[UserRecruits] ([UserRecruitID])
GO

ALTER TABLE [RSU].[Terminations] CHECK CONSTRAINT [FK_Terminations_TeamLocations]
GO

ALTER TABLE [RSU].[Terminations] CHECK CONSTRAINT [FK_Terminations_TerminationCategories]
GO

ALTER TABLE [RSU].[Terminations] CHECK CONSTRAINT [FK_Terminations_UserRecruits]
GO
