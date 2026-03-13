/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserRecruitGoals
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserRecruitGoals' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserRecruitGoals](
	[UserRecruitGoalID] [int] IDENTITY(1,1) NOT NULL,
	[UserRecruitId] [int] NOT NULL,
	[NetInstalls] [int] NOT NULL,
	[ActionPlan] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_UserRecruitGoals] PRIMARY KEY CLUSTERED 
(
	[UserRecruitGoalID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitGoals_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitGoals] ADD  CONSTRAINT [DF_UserRecruitGoals_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitGoals_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitGoals] ADD  CONSTRAINT [DF_UserRecruitGoals_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitGoals_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitGoals] ADD  CONSTRAINT [DF_UserRecruitGoals_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitGoals_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitGoals] ADD  CONSTRAINT [DF_UserRecruitGoals_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitGoals_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitGoals] ADD  CONSTRAINT [DF_UserRecruitGoals_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitGoals_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitGoals] ADD  CONSTRAINT [DF_UserRecruitGoals_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruitGoals_UserRecruits')
ALTER TABLE [RSU].[UserRecruitGoals]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruitGoals_UserRecruits] FOREIGN KEY([UserRecruitId])
REFERENCES [RSU].[UserRecruits] ([UserRecruitID])
GO

ALTER TABLE [RSU].[UserRecruitGoals] CHECK CONSTRAINT [FK_UserRecruitGoals_UserRecruits]
GO
