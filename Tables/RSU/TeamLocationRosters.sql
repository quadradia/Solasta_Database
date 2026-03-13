/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: TeamLocationRosters
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TeamLocationRosters' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[TeamLocationRosters](
	[TeamLocationRosterID] [int] IDENTITY(1,1) NOT NULL,
	[TeamLocationId] [int] NULL,
	[TerminationReasonId] [int] NULL,
	[UserRecruitId] [int] NOT NULL,
	[ArrivalDate] [date] NULL,
	[QuitDate] [date] NULL,
	[Reason] [nvarchar](max) NULL,
	[TerminationType] [nvarchar](50) NULL,
	[Note] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_TeamLocationRosters] PRIMARY KEY CLUSTERED 
(
	[TeamLocationRosterID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationRosters_IsActive' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationRosters] ADD  CONSTRAINT [DF_TeamLocationRosters_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationRosters_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationRosters] ADD  CONSTRAINT [DF_TeamLocationRosters_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationRosters_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationRosters] ADD  CONSTRAINT [DF_TeamLocationRosters_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationRosters_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationRosters] ADD  CONSTRAINT [DF_TeamLocationRosters_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationRosters_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationRosters] ADD  CONSTRAINT [DF_TeamLocationRosters_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationRosters_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationRosters] ADD  CONSTRAINT [DF_TeamLocationRosters_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationRosters_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationRosters] ADD  CONSTRAINT [DF_TeamLocationRosters_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocationRosters_TeamLocations')
ALTER TABLE [RSU].[TeamLocationRosters]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocationRosters_TeamLocations] FOREIGN KEY([TeamLocationId])
REFERENCES [RSU].[TeamLocations] ([TeamLocationID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocationRosters_TerminationReasons')
ALTER TABLE [RSU].[TeamLocationRosters]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocationRosters_TerminationReasons] FOREIGN KEY([TerminationReasonId])
REFERENCES [RSU].[TerminationReasons] ([TerminationReasonID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocationRosters_UserRecruits')
ALTER TABLE [RSU].[TeamLocationRosters]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocationRosters_UserRecruits] FOREIGN KEY([UserRecruitId])
REFERENCES [RSU].[UserRecruits] ([UserRecruitID])
GO

ALTER TABLE [RSU].[TeamLocationRosters] CHECK CONSTRAINT [FK_TeamLocationRosters_TeamLocations]
GO

ALTER TABLE [RSU].[TeamLocationRosters] CHECK CONSTRAINT [FK_TeamLocationRosters_TerminationReasons]
GO

ALTER TABLE [RSU].[TeamLocationRosters] CHECK CONSTRAINT [FK_TeamLocationRosters_UserRecruits]
GO
