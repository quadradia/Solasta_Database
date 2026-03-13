/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserTypes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserTypes' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserTypes](
	[UserTypeID] [smallint] IDENTITY(1,1) NOT NULL,
	[UserTypeTeamTypeId] [int] NOT NULL,
	[UserTypeGroupId] [varchar](20) NOT NULL,
	[UserTypeName] [varchar](30) NOT NULL,
	[SecurityLevel] [tinyint] NOT NULL,
	[SpawnTypeId] [int] NOT NULL,
	[RoleLocationId] [int] NOT NULL,
	[ReportingLevel] [int] NOT NULL,
	[IsCommissionable] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_UserTypes] PRIMARY KEY CLUSTERED 
(
	[UserTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypes_UserTypeGroupId' AND type = 'D')
ALTER TABLE [RSU].[UserTypes] ADD  CONSTRAINT [DF_UserTypes_UserTypeGroupId]  DEFAULT ('SALESREPGRP') FOR [UserTypeGroupId]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserType_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserTypes] ADD  CONSTRAINT [DF_UserType_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserType_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserTypes] ADD  CONSTRAINT [DF_UserType_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypes_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserTypes] ADD  CONSTRAINT [DF_UserTypes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypes_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserTypes] ADD  CONSTRAINT [DF_UserTypes_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypes_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserTypes] ADD  CONSTRAINT [DF_UserTypes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypes_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserTypes] ADD  CONSTRAINT [DF_UserTypes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypes_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [RSU].[UserTypes] ADD  CONSTRAINT [DF_UserTypes_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserType_UserTypeTeamTypes')
ALTER TABLE [RSU].[UserTypes]  WITH CHECK ADD  CONSTRAINT [FK_UserType_UserTypeTeamTypes] FOREIGN KEY([UserTypeTeamTypeId])
REFERENCES [RSU].[UserTypeTeamTypes] ([UserTypeTeamTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserTypes_UserTypeGroups')
ALTER TABLE [RSU].[UserTypes]  WITH CHECK ADD  CONSTRAINT [FK_UserTypes_UserTypeGroups] FOREIGN KEY([UserTypeGroupId])
REFERENCES [RSU].[UserTypeGroups] ([UserTypeGroupID])
GO

ALTER TABLE [RSU].[UserTypes] CHECK CONSTRAINT [FK_UserType_UserTypeTeamTypes]
GO

ALTER TABLE [RSU].[UserTypes] CHECK CONSTRAINT [FK_UserTypes_UserTypeGroups]
GO
