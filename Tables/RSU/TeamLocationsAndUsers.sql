/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: TeamLocationsAndUsers
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TeamLocationsAndUsers' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[TeamLocationsAndUsers](
	[TeamLocationsAndUserID] [int] IDENTITY(1,1) NOT NULL,
	[TeamLocationId] [int] NOT NULL,
	[UserRecruitId] [int] NOT NULL,
	[LocationRoleId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_TeamLocationsAndUsers_1] PRIMARY KEY CLUSTERED 
(
	[TeamLocationsAndUserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationsAndUsers_IsActive' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationsAndUsers] ADD  CONSTRAINT [DF_TeamLocationsAndUsers_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationsAndUsers_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationsAndUsers] ADD  CONSTRAINT [DF_TeamLocationsAndUsers_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationsAndUsers_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationsAndUsers] ADD  CONSTRAINT [DF_TeamLocationsAndUsers_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationsAndUsers_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationsAndUsers] ADD  CONSTRAINT [DF_TeamLocationsAndUsers_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationsAndUsers_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationsAndUsers] ADD  CONSTRAINT [DF_TeamLocationsAndUsers_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationsAndUsers_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationsAndUsers] ADD  CONSTRAINT [DF_TeamLocationsAndUsers_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocationsAndUsers_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [RSU].[TeamLocationsAndUsers] ADD  CONSTRAINT [DF_TeamLocationsAndUsers_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocationsAndUsers_LocationRoles')
ALTER TABLE [RSU].[TeamLocationsAndUsers]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocationsAndUsers_LocationRoles] FOREIGN KEY([LocationRoleId])
REFERENCES [RSU].[LocationRoles] ([LocationRoleID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocationsAndUsers_TeamLocations')
ALTER TABLE [RSU].[TeamLocationsAndUsers]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocationsAndUsers_TeamLocations] FOREIGN KEY([TeamLocationId])
REFERENCES [RSU].[TeamLocations] ([TeamLocationID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocationsAndUsers_UserRecruits')
ALTER TABLE [RSU].[TeamLocationsAndUsers]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocationsAndUsers_UserRecruits] FOREIGN KEY([UserRecruitId])
REFERENCES [RSU].[UserRecruits] ([UserRecruitID])
GO

ALTER TABLE [RSU].[TeamLocationsAndUsers] CHECK CONSTRAINT [FK_TeamLocationsAndUsers_LocationRoles]
GO

ALTER TABLE [RSU].[TeamLocationsAndUsers] CHECK CONSTRAINT [FK_TeamLocationsAndUsers_TeamLocations]
GO

ALTER TABLE [RSU].[TeamLocationsAndUsers] CHECK CONSTRAINT [FK_TeamLocationsAndUsers_UserRecruits]
GO
