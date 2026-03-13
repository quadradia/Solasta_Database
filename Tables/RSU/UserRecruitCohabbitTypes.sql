/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserRecruitCohabbitTypes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserRecruitCohabbitTypes' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserRecruitCohabbitTypes](
	[UserRecruitCohabbitTypeID] [int] IDENTITY(1,1) NOT NULL,
	[UserRecruitCohabbitTypeName] [nvarchar](50) NOT NULL,
	[Rent] [money] NOT NULL,
	[Pet] [money] NOT NULL,
	[Utilities] [money] NOT NULL,
	[GasDeduction] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_UserRecruitCohabbitTypes] PRIMARY KEY CLUSTERED 
(
	[UserRecruitCohabbitTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitCohabbitTypes_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitCohabbitTypes] ADD  CONSTRAINT [DF_UserRecruitCohabbitTypes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitCohabbitTypes_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitCohabbitTypes] ADD  CONSTRAINT [DF_UserRecruitCohabbitTypes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitCohabbitTypes_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitCohabbitTypes] ADD  CONSTRAINT [DF_UserRecruitCohabbitTypes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitCohabbitTypes_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitCohabbitTypes] ADD  CONSTRAINT [DF_UserRecruitCohabbitTypes_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitCohabbitTypes_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitCohabbitTypes] ADD  CONSTRAINT [DF_UserRecruitCohabbitTypes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitCohabbitTypes_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitCohabbitTypes] ADD  CONSTRAINT [DF_UserRecruitCohabbitTypes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO
