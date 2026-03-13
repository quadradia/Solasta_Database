/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserRecruitSeasonGoals
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserRecruitSeasonGoals' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserRecruitSeasonGoals](
	[UserRecruitSeasonGoalID] [int] IDENTITY(1,1) NOT NULL,
	[UserRecruitId] [int] NOT NULL,
	[TotalInstalls] [float] NOT NULL,
	[CancelPercent] [float] NOT NULL,
	[SubPercent] [float] NOT NULL,
	[PassPercent] [float] NOT NULL,
	[PastDuePercent] [float] NOT NULL,
	[BackendHoldPercent] [float] NOT NULL,
	[ActivationWaivePercent] [float] NOT NULL,
	[CommercialPercent] [float] NOT NULL,
	[PointBank] [float] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_UserRecruitSeasonGoals] PRIMARY KEY CLUSTERED 
(
	[UserRecruitSeasonGoalID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitSeasonGoals_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitSeasonGoals] ADD  CONSTRAINT [DF_UserRecruitSeasonGoals_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitSeasonGoals_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitSeasonGoals] ADD  CONSTRAINT [DF_UserRecruitSeasonGoals_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitSeasonGoals_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitSeasonGoals] ADD  CONSTRAINT [DF_UserRecruitSeasonGoals_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitSeasonGoals_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitSeasonGoals] ADD  CONSTRAINT [DF_UserRecruitSeasonGoals_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitSeasonGoals_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitSeasonGoals] ADD  CONSTRAINT [DF_UserRecruitSeasonGoals_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitSeasonGoals_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitSeasonGoals] ADD  CONSTRAINT [DF_UserRecruitSeasonGoals_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruitSeasonGoals_UserRecruits')
ALTER TABLE [RSU].[UserRecruitSeasonGoals]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruitSeasonGoals_UserRecruits] FOREIGN KEY([UserRecruitId])
REFERENCES [RSU].[UserRecruits] ([UserRecruitID])
GO

ALTER TABLE [RSU].[UserRecruitSeasonGoals] CHECK CONSTRAINT [FK_UserRecruitSeasonGoals_UserRecruits]
GO
