/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserRecruitRegistrations
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserRecruitRegistrations' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserRecruitRegistrations](
	[UserRecruitRegistrationID] [int] IDENTITY(1,1) NOT NULL,
	[UniqueRegistrationId] [uniqueidentifier] NOT NULL,
	[InvitedByUserResourceId] [int] NULL,
	[ExistingUserResourceId] [int] NULL,
	[RegistrationDate] [datetime] NULL,
	[RecruitedByUserResourceId] [int] NULL,
	[UserRecruitAddressId] [int] NULL,
	[SSN] [nvarchar](50) NULL,
	[FirstName] [nvarchar](50) NULL,
	[MiddleName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[PreferredName] [nvarchar](50) NULL,
	[FullName] [nvarchar](101) NULL,
	[UserName] [nvarchar](50) NULL,
	[BirthDate] [datetime] NULL,
	[BirthCity] [nvarchar](50) NULL,
	[BirthState] [nvarchar](50) NULL,
	[BirthCountry] [nvarchar](50) NULL,
	[Sex] [tinyint] NULL,
	[ShirtSize] [tinyint] NULL,
	[HatSize] [tinyint] NULL,
	[DLNumber] [nvarchar](50) NULL,
	[DLState] [nvarchar](50) NULL,
	[DLCountry] [nvarchar](50) NULL,
	[DLExpiration] [nvarchar](50) NULL,
	[Height] [nvarchar](10) NULL,
	[Weight] [nvarchar](10) NULL,
	[EyeColor] [nvarchar](20) NULL,
	[HairColor] [nvarchar](20) NULL,
	[PhoneHome] [nvarchar](25) NULL,
	[PhoneCell] [nvarchar](50) NULL,
	[PhoneCellCarrierID] [smallint] NULL,
	[Email] [nvarchar](100) NULL,
	[UserTypeId] [smallint] NULL,
	[ReportsToID] [int] NULL,
	[CurrentAddressID] [int] NULL,
	[PayScaleID] [int] NULL,
	[SchoolId] [smallint] NULL,
	[HasPet] [bit] NULL,
	[NeedsExtraHousing] [bit] NULL,
	[EmergencyName] [nvarchar](50) NULL,
	[EmergencyPhone] [varchar](20) NULL,
	[EmergencyRelationship] [nvarchar](50) NULL,
	[PreviousSummer] [nvarchar](200) NULL,
	[CriminalOffense] [bit] NULL,
	[Offense] [nvarchar](max) NULL,
	[OffenseExplanation] [nvarchar](max) NULL,
	[StartDate] [datetime] NOT NULL,
	[StartingState] [nvarchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_UserRecruitRegistrations] PRIMARY KEY CLUSTERED 
(
	[UserRecruitRegistrationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitRegistrations_UniqueRegistrationId' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitRegistrations] ADD  CONSTRAINT [DF_UserRecruitRegistrations_UniqueRegistrationId]  DEFAULT (newsequentialid()) FOR [UniqueRegistrationId]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitRegistrations_IsActive_1' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitRegistrations] ADD  CONSTRAINT [DF_UserRecruitRegistrations_IsActive_1]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitRegistrations_IsDeleted_1' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitRegistrations] ADD  CONSTRAINT [DF_UserRecruitRegistrations_IsDeleted_1]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitRegistrations_ModifiedDate_1' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitRegistrations] ADD  CONSTRAINT [DF_UserRecruitRegistrations_ModifiedDate_1]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitRegistrations_ModifiedById_1' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitRegistrations] ADD  CONSTRAINT [DF_UserRecruitRegistrations_ModifiedById_1]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitRegistrations_CreatedDate_1' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitRegistrations] ADD  CONSTRAINT [DF_UserRecruitRegistrations_CreatedDate_1]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitRegistrations_CreatedById_1' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitRegistrations] ADD  CONSTRAINT [DF_UserRecruitRegistrations_CreatedById_1]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruitRegistrations_UserRecruitAddresses')
ALTER TABLE [RSU].[UserRecruitRegistrations]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruitRegistrations_UserRecruitAddresses] FOREIGN KEY([UserRecruitAddressId])
REFERENCES [RSU].[UserRecruitAddresses] ([UserRecruitAddressID])
GO

ALTER TABLE [RSU].[UserRecruitRegistrations] CHECK CONSTRAINT [FK_UserRecruitRegistrations_UserRecruitAddresses]
GO
