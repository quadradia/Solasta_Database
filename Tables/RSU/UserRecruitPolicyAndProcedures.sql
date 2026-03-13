/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserRecruitPolicyAndProcedures
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserRecruitPolicyAndProcedures' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserRecruitPolicyAndProcedures](
	[UserRecruitPolicyAndProcedureID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserRecruitId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_UserRecruitPolicyAndProcedures] PRIMARY KEY CLUSTERED 
(
	[UserRecruitPolicyAndProcedureID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitPolicyAndProcedures_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitPolicyAndProcedures] ADD  CONSTRAINT [DF_UserRecruitPolicyAndProcedures_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitPolicyAndProcedures_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitPolicyAndProcedures] ADD  CONSTRAINT [DF_UserRecruitPolicyAndProcedures_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitPolicyAndProcedures_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitPolicyAndProcedures] ADD  CONSTRAINT [DF_UserRecruitPolicyAndProcedures_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitPolicyAndProcedures_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitPolicyAndProcedures] ADD  CONSTRAINT [DF_UserRecruitPolicyAndProcedures_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitPolicyAndProcedures_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitPolicyAndProcedures] ADD  CONSTRAINT [DF_UserRecruitPolicyAndProcedures_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitPolicyAndProcedures_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitPolicyAndProcedures] ADD  CONSTRAINT [DF_UserRecruitPolicyAndProcedures_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruitPolicyAndProcedures_UserRecruits')
ALTER TABLE [RSU].[UserRecruitPolicyAndProcedures]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruitPolicyAndProcedures_UserRecruits] FOREIGN KEY([UserRecruitId])
REFERENCES [RSU].[UserRecruits] ([UserRecruitID])
GO

ALTER TABLE [RSU].[UserRecruitPolicyAndProcedures] CHECK CONSTRAINT [FK_UserRecruitPolicyAndProcedures_UserRecruits]
GO
