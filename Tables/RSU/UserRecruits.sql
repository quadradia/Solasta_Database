/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserRecruits
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserRecruits' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserRecruits](
	[UserRecruitID] [int] IDENTITY(1,1) NOT NULL,
	[UserResourceId] [int] NOT NULL,
	[UserTypeId] [smallint] NOT NULL,
	[ReportsToId] [int] NULL,
	[UserRecruitAddressId] [int] NULL,
	[DealerId] [int] NOT NULL,
	[SeasonId] [int] NOT NULL,
	[OwnerApprovalId] [int] NULL,
	[TeamId] [int] NULL,
	[PayScaleId] [int] NULL,
	[SchoolId] [smallint] NULL,
	[ShackingUpId] [int] NULL,
	[UserRecruitCohabbitTypeId] [int] NULL,
	[AlternatePayScheduleId] [int] NULL,
	[Location] [nvarchar](50) NULL,
	[OwnerApprovalDate] [datetimeoffset](7) NULL,
	[ManagerApprovalDate] [datetimeoffset](7) NULL,
	[EmergencyName] [nvarchar](50) NULL,
	[EmergencyPhone] [varchar](20) NULL,
	[EmergencyRelationship] [nvarchar](50) NULL,
	[IsRecruiter] [bit] NOT NULL,
	[PreviousSummer] [nvarchar](200) NULL,
	[SignatureDate] [datetimeoffset](7) NULL,
	[HireDate] [datetimeoffset](7) NULL,
	[GPExemptions] [int] NULL,
	[GPW4Allowances] [tinyint] NULL,
	[GPW9Name] [nvarchar](50) NULL,
	[GPW9BusinessName] [nvarchar](100) NULL,
	[GPW9TIN] [varchar](50) NULL,
	[SocialSecCardStatusID] [int] NOT NULL,
	[DriversLicenseStatusID] [int] NOT NULL,
	[W4StatusID] [int] NOT NULL,
	[I9StatusID] [int] NOT NULL,
	[W9StatusID] [int] NOT NULL,
	[SocialSecCardNotes] [nvarchar](250) NULL,
	[DriversLicenseNotes] [nvarchar](250) NULL,
	[W4Notes] [nvarchar](250) NULL,
	[I9Notes] [nvarchar](250) NULL,
	[W9Notes] [nvarchar](250) NULL,
	[EIN] [nvarchar](50) NULL,
	[SUTA] [nvarchar](50) NULL,
	[WorkersComp] [nvarchar](max) NULL,
	[FedFilingStatus] [nvarchar](50) NULL,
	[EICFilingStatus] [nvarchar](50) NULL,
	[TaxWitholdingState] [nvarchar](5) NULL,
	[StateFilingStatus] [nvarchar](50) NULL,
	[GPDependents] [int] NULL,
	[CriminalOffense] [bit] NULL,
	[Offense] [nvarchar](max) NULL,
	[OffenseExplanation] [nvarchar](max) NULL,
	[Rent] [money] NULL,
	[Pet] [money] NULL,
	[Utilities] [money] NULL,
	[Fuel] [money] NULL,
	[Furniture] [money] NULL,
	[CellPhoneCredit] [money] NULL,
	[GasCredit] [money] NULL,
	[RentExempt] [bit] NOT NULL,
	[IsServiceTech] [bit] NOT NULL,
	[StateId] [varchar](4) NULL,
	[CountryId] [nvarchar](10) NULL,
	[StreetAddress] [nvarchar](50) NULL,
	[StreetAddress2] [nvarchar](50) NULL,
	[City] [nvarchar](50) NULL,
	[PostalCode] [nvarchar](10) NULL,
	[CBxSocialSecCard] [bit] NULL,
	[CBxDriversLicense] [bit] NULL,
	[CBxW4] [bit] NULL,
	[CBxI9] [bit] NULL,
	[CBxW9] [bit] NULL,
	[PersonalMultiple] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_UserRecruits] PRIMARY KEY CLUSTERED 
(
	[UserRecruitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruits_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserRecruits] ADD  CONSTRAINT [DF_UserRecruits_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruits_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserRecruits] ADD  CONSTRAINT [DF_UserRecruits_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruits_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruits] ADD  CONSTRAINT [DF_UserRecruits_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruits_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruits] ADD  CONSTRAINT [DF_UserRecruits_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruits_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruits] ADD  CONSTRAINT [DF_UserRecruits_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruits_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruits] ADD  CONSTRAINT [DF_UserRecruits_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruits_Dealers')
ALTER TABLE [RSU].[UserRecruits]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruits_Dealers] FOREIGN KEY([DealerId])
REFERENCES [ACC].[Dealers] ([DealerID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruits_Season')
ALTER TABLE [RSU].[UserRecruits]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruits_Season] FOREIGN KEY([SeasonId])
REFERENCES [RSU].[Seasons] ([SeasonID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruits_Teams')
ALTER TABLE [RSU].[UserRecruits]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruits_Teams] FOREIGN KEY([TeamId])
REFERENCES [RSU].[Teams] ([TeamID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruits_UserRecruitAddresses')
ALTER TABLE [RSU].[UserRecruits]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruits_UserRecruitAddresses] FOREIGN KEY([UserRecruitAddressId])
REFERENCES [RSU].[UserRecruitAddresses] ([UserRecruitAddressID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruits_UserRecruitCohabbitTypes')
ALTER TABLE [RSU].[UserRecruits]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruits_UserRecruitCohabbitTypes] FOREIGN KEY([UserRecruitCohabbitTypeId])
REFERENCES [RSU].[UserRecruitCohabbitTypes] ([UserRecruitCohabbitTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruits_UserResources')
ALTER TABLE [RSU].[UserRecruits]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruits_UserResources] FOREIGN KEY([UserResourceId])
REFERENCES [RSU].[UserResources] ([UserResourceID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruits_UserTypes')
ALTER TABLE [RSU].[UserRecruits]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruits_UserTypes] FOREIGN KEY([UserTypeId])
REFERENCES [RSU].[UserTypes] ([UserTypeID])
GO

ALTER TABLE [RSU].[UserRecruits] CHECK CONSTRAINT [FK_UserRecruits_Dealers]
GO

ALTER TABLE [RSU].[UserRecruits] CHECK CONSTRAINT [FK_UserRecruits_Season]
GO

ALTER TABLE [RSU].[UserRecruits] CHECK CONSTRAINT [FK_UserRecruits_Teams]
GO

ALTER TABLE [RSU].[UserRecruits] CHECK CONSTRAINT [FK_UserRecruits_UserRecruitAddresses]
GO

ALTER TABLE [RSU].[UserRecruits] CHECK CONSTRAINT [FK_UserRecruits_UserRecruitCohabbitTypes]
GO

ALTER TABLE [RSU].[UserRecruits] CHECK CONSTRAINT [FK_UserRecruits_UserResources]
GO

ALTER TABLE [RSU].[UserRecruits] CHECK CONSTRAINT [FK_UserRecruits_UserTypes]
GO
