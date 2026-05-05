/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserResources
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'UserResources' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
	CREATE TABLE [RSU].[UserResources]
	(
		[UserResourceID] [int] IDENTITY(1000,1) NOT NULL,
		[DealerTenantId] [int] NOT NULL,
		[UserId] [uniqueidentifier] NULL,
		[UserEmployeeTypeId] [varchar](20) NOT NULL,
		[UserResourceAddressId] [int] NULL,
		[RecruitedById] [int] NULL,
		[GPEmployeeId] [nvarchar](25) NOT NULL,
		[RecruitedByDate] [datetimeoffset](7) NOT NULL,
		[FullName] [nvarchar](101) NULL,
		[PublicFullName] [nvarchar](53) NULL,
		[SSN] [nvarchar](50) NULL,
		[FirstName] [nvarchar](50) NULL,
		[MiddleName] [nvarchar](50) NULL,
		[LastName] [nvarchar](50) NULL,
		[PreferredName] [nvarchar](50) NULL,
		[CompanyName] [nvarchar](50) NULL,
		[MaritalStatus] [bit] NULL,
		[SpouseName] [nvarchar](50) NULL,
		[UserName] [nvarchar](256) NOT NULL,
		[Password] [varchar](60) NOT NULL,
		[BirthDate] [datetime] NULL,
		[HomeTown] [nvarchar](50) NULL,
		[BirthCity] [nvarchar](50) NULL,
		[BirthState] [nvarchar](50) NULL,
		[BirthCountry] [nvarchar](50) NULL,
		[Sex] [tinyint] NOT NULL,
		[ShirtSize] [tinyint] NULL,
		[HatSize] [tinyint] NULL,
		[DLNumber] [nvarchar](50) NULL,
		[DLState] [nvarchar](50) NULL,
		[DLCountry] [nvarchar](50) NULL,
		[DLExpiresOn] [datetime] NULL,
		[DLExpiration] [nvarchar](50) NULL,
		[Height] [nvarchar](10) NULL,
		[Weight] [nvarchar](10) NULL,
		[EyeColor] [nvarchar](20) NULL,
		[HairColor] [nvarchar](20) NULL,
		[PhoneHome] [nvarchar](25) NULL,
		[PhoneCell] [nvarchar](50) NULL,
		[PhoneCellCarrierID] [smallint] NULL,
		[PhoneFax] [nvarchar](25) NULL,
		[Email] [nvarchar](100) NULL,
		[CorporateEmail] [nvarchar](100) NULL,
		[TreeLevel] [int] NULL,
		[HasVerifiedAddress] [bit] NOT NULL,
		[RightToWorkExpirationDate] [datetime] NULL,
		[RightToWorkNotes] [nvarchar](250) NULL,
		[RightToWorkStatusID] [int] NULL,
		[IsLocked] [bit] NOT NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [uniqueidentifier] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[CreatedById] [uniqueidentifier] NOT NULL,
		[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
		CONSTRAINT [PK_UserResources] PRIMARY KEY CLUSTERED
(
	[UserResourceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_UserResources_RecruitedDate_1' AND type = 'D')
ALTER TABLE [RSU].[UserResources] ADD  CONSTRAINT [DF_UserResources_RecruitedDate_1]  DEFAULT (sysdatetimeoffset()) FOR [RecruitedByDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_UserResources_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserResources] ADD  CONSTRAINT [DF_UserResources_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_UserResources_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserResources] ADD  CONSTRAINT [DF_UserResources_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_UserResources_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserResources] ADD  CONSTRAINT [DF_UserResources_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_UserResources_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserResources] ADD  CONSTRAINT [DF_UserResources_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_UserResources_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserResources] ADD  CONSTRAINT [DF_UserResources_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_UserResources_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserResources] ADD  CONSTRAINT [DF_UserResources_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_UserResources_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [RSU].[UserResources] ADD  CONSTRAINT [DF_UserResources_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_UserResources_DealerTenants')
ALTER TABLE [RSU].[UserResources]  WITH CHECK ADD  CONSTRAINT [FK_UserResources_DealerTenants] FOREIGN KEY([DealerTenantId])
REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_UserResources_UserEmployeeTypes')
ALTER TABLE [RSU].[UserResources]  WITH CHECK ADD  CONSTRAINT [FK_UserResources_UserEmployeeTypes] FOREIGN KEY([UserEmployeeTypeId])
REFERENCES [RSU].[UserEmployeeTypes] ([UserEmployeeTypeID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_UserResources_UserResourceAddresses')
ALTER TABLE [RSU].[UserResources]  WITH CHECK ADD  CONSTRAINT [FK_UserResources_UserResourceAddresses] FOREIGN KEY([UserResourceAddressId])
REFERENCES [RSU].[UserResourceAddresses] ([UserResourceAddressID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_UserResources_Users')
ALTER TABLE [RSU].[UserResources]  WITH CHECK ADD  CONSTRAINT [FK_UserResources_Users] FOREIGN KEY([UserId])
REFERENCES [ACC].[Users] ([UserID])
GO

ALTER TABLE [RSU].[UserResources] CHECK CONSTRAINT [FK_UserResources_DealerTenants]
GO

ALTER TABLE [RSU].[UserResources] CHECK CONSTRAINT [FK_UserResources_UserEmployeeTypes]
GO

ALTER TABLE [RSU].[UserResources] CHECK CONSTRAINT [FK_UserResources_UserResourceAddresses]
GO

ALTER TABLE [RSU].[UserResources] CHECK CONSTRAINT [FK_UserResources_Users]
GO
