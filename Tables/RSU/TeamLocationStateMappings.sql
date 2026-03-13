/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: TeamLocationStateMappings
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TeamLocationStateMappings' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[TeamLocationStateMappings](
	[TeamLocationStateMappingID] [int] IDENTITY(1,1) NOT NULL,
	[TeamLocationId] [int] NOT NULL,
	[SeasonId] [int] NOT NULL,
	[PoliticalStateId] [varchar](4) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_TeamLocationStateMappings] PRIMARY KEY CLUSTERED 
(
	[TeamLocationStateMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationStateMappings_IsActive' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationStateMappings] ADD  CONSTRAINT [DF_TeamLocationStateMappings_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationStateMappings_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationStateMappings] ADD  CONSTRAINT [DF_TeamLocationStateMappings_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationStateMappings_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationStateMappings] ADD  CONSTRAINT [DF_TeamLocationStateMappings_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationStateMappings_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationStateMappings] ADD  CONSTRAINT [DF_TeamLocationStateMappings_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationStateMappings_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationStateMappings] ADD  CONSTRAINT [DF_TeamLocationStateMappings_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationStateMappings_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationStateMappings] ADD  CONSTRAINT [DF_TeamLocationStateMappings_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationStateMappings_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationStateMappings] ADD  CONSTRAINT [DF_TeamLocationStateMappings_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocationStateMappings_PoliticalStates')
ALTER TABLE [RSU].[TeamLocationStateMappings]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocationStateMappings_PoliticalStates] FOREIGN KEY([PoliticalStateId])
REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocationStateMappings_Season')
ALTER TABLE [RSU].[TeamLocationStateMappings]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocationStateMappings_Season] FOREIGN KEY([SeasonId])
REFERENCES [RSU].[Seasons] ([SeasonID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocationStateMappings_TeamLocations')
ALTER TABLE [RSU].[TeamLocationStateMappings]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocationStateMappings_TeamLocations] FOREIGN KEY([TeamLocationId])
REFERENCES [RSU].[TeamLocations] ([TeamLocationID])
GO

ALTER TABLE [RSU].[TeamLocationStateMappings] CHECK CONSTRAINT [FK_TeamLocationStateMappings_PoliticalStates]
GO

ALTER TABLE [RSU].[TeamLocationStateMappings] CHECK CONSTRAINT [FK_TeamLocationStateMappings_Season]
GO

ALTER TABLE [RSU].[TeamLocationStateMappings] CHECK CONSTRAINT [FK_TeamLocationStateMappings_TeamLocations]
GO
