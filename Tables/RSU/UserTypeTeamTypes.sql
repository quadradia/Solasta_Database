/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserTypeTeamTypes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserTypeTeamTypes' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserTypeTeamTypes](
	[UserTypeTeamTypeID] [int] IDENTITY(1,1) NOT NULL,
	[UserTypeTeamTypeName] [varchar](30) NOT NULL,
	[ParentId] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_UserTypeTeamTypes] PRIMARY KEY CLUSTERED 
(
	[UserTypeTeamTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypeTeamTypes_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserTypeTeamTypes] ADD  CONSTRAINT [DF_UserTypeTeamTypes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypeTeamTypes_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserTypeTeamTypes] ADD  CONSTRAINT [DF_UserTypeTeamTypes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypeTeamTypes_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserTypeTeamTypes] ADD  CONSTRAINT [DF_UserTypeTeamTypes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypeTeamTypes_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserTypeTeamTypes] ADD  CONSTRAINT [DF_UserTypeTeamTypes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypeTeamTypes_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserTypeTeamTypes] ADD  CONSTRAINT [DF_UserTypeTeamTypes_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserTypeTeamTypes_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserTypeTeamTypes] ADD  CONSTRAINT [DF_UserTypeTeamTypes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO
