/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: Teams
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Teams' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[Teams](
	[TeamID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[CreatedFromTeamId] [int] NULL,
	[TeamLocationId] [int] NOT NULL,
	[RoleLocationId] [int] NULL,
	[RegionalManagerRecruitId] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Teams] PRIMARY KEY CLUSTERED 
(
	[TeamID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Teams_IsActive' AND type = 'D')
ALTER TABLE [RSU].[Teams] ADD  CONSTRAINT [DF_Teams_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Teams_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[Teams] ADD  CONSTRAINT [DF_Teams_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Teams_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[Teams] ADD  CONSTRAINT [DF_Teams_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Teams_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[Teams] ADD  CONSTRAINT [DF_Teams_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Teams_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[Teams] ADD  CONSTRAINT [DF_Teams_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Teams_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[Teams] ADD  CONSTRAINT [DF_Teams_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Teams_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [RSU].[Teams] ADD  CONSTRAINT [DF_Teams_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO
