/*******************************************************************************
 * Object Type: Table
 * Schema: ACC
 * Name: Users
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'Users' AND schema_id = SCHEMA_ID('ACC'))
BEGIN
	CREATE TABLE [ACC].[Users]
	(
		[UserID] [uniqueidentifier] NOT NULL,
		[DealerTenantId] [int] NOT NULL,
		[LanguageId] [nvarchar](50) NOT NULL,
		[HRUserId] [int] NULL,
		[GPEmployeeID] [nvarchar](25) NULL,
		[SSID] [uniqueidentifier] NULL,
		[FirstName] [nvarchar](max) NOT NULL,
		[LastName] [nvarchar](max) NOT NULL,
		[Email] [nvarchar](max) NULL,
		[EmailConfirmed] [bit] NOT NULL,
		[Username] [nvarchar](256) NOT NULL,
		[PasswordHash] [nvarchar](max) NULL,
		[SecurityStamp] [nvarchar](max) NULL,
		[PhoneNumber] [nvarchar](max) NULL,
		[PhoneNumberConfirmed] [bit] NOT NULL,
		[TwoFactorEnabled] [bit] NOT NULL,
		[LockoutEndDateUtc] [datetime] NULL,
		[LockoutEnabled] [bit] NOT NULL,
		[AccessFailedCount] [int] NOT NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [uniqueidentifier] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[CreatedById] [uniqueidentifier] NOT NULL,
		[DEX_ROW] [bigint] IDENTITY(1,1) NOT NULL,
		CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_UserID' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_UserID]  DEFAULT (newsequentialid()) FOR [UserID]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_DealerTenantId' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_DealerTenantId]  DEFAULT ((2000)) FOR [DealerTenantId]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_LanguageId' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_LanguageId]  DEFAULT (N'en') FOR [LanguageId]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_FirstName' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_FirstName]  DEFAULT ('NOT SET') FOR [FirstName]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_LastName' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_LastName]  DEFAULT ('NOT SET') FOR [LastName]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_EmailConfirmed' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_EmailConfirmed]  DEFAULT ((0)) FOR [EmailConfirmed]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_PhoneNumberConfirmed' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_PhoneNumberConfirmed]  DEFAULT ((0)) FOR [PhoneNumberConfirmed]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_TwoFactorEnabled' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_TwoFactorEnabled]  DEFAULT ((0)) FOR [TwoFactorEnabled]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_LockoutEnabled' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_LockoutEnabled]  DEFAULT ((0)) FOR [LockoutEnabled]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_AccessFailedCount' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_AccessFailedCount]  DEFAULT ((0)) FOR [AccessFailedCount]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_IsActive' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_IsDeleted' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_ModifiedOn' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_ModifiedOn]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_ModifiedBy' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_ModifiedBy]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_CreatedOn' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_CreatedOn]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Users_CreatedBy' AND type = 'D')
ALTER TABLE [ACC].[Users] ADD  CONSTRAINT [DF_Users_CreatedBy]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Users_DealerTenants')
ALTER TABLE [ACC].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_DealerTenants] FOREIGN KEY([DealerTenantId])
REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Users_Languages')
ALTER TABLE [ACC].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_Languages] FOREIGN KEY([LanguageId])
REFERENCES [MAC].[Languages] ([LanguageID])
GO

ALTER TABLE [ACC].[Users] CHECK CONSTRAINT [FK_Users_DealerTenants]
GO

ALTER TABLE [ACC].[Users] CHECK CONSTRAINT [FK_Users_Languages]
GO
