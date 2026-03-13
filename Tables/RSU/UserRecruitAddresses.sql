/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserRecruitAddresses
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserRecruitAddresses' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserRecruitAddresses](
	[UserRecruitAddressID] [int] IDENTITY(1,1) NOT NULL,
	[PoliticalStateId] [varchar](4) NOT NULL,
	[PoliticalCountryId] [nvarchar](10) NOT NULL,
	[PoliticalTimeZoneId] [int] NULL,
	[StreetAddress] [nvarchar](50) NOT NULL,
	[StreetAddress2] [nvarchar](50) NULL,
	[City] [nvarchar](50) NOT NULL,
	[PostalCode] [nvarchar](10) NOT NULL,
	[PlusFour] [nvarchar](4) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_UserRecruitAddresses] PRIMARY KEY CLUSTERED 
(
	[UserRecruitAddressID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitAddresses_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitAddresses] ADD  CONSTRAINT [DF_UserRecruitAddresses_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitAddresses_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitAddresses] ADD  CONSTRAINT [DF_UserRecruitAddresses_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitAddresses_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitAddresses] ADD  CONSTRAINT [DF_UserRecruitAddresses_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitAddresses_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitAddresses] ADD  CONSTRAINT [DF_UserRecruitAddresses_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitAddresses_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitAddresses] ADD  CONSTRAINT [DF_UserRecruitAddresses_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserRecruitAddresses_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserRecruitAddresses] ADD  CONSTRAINT [DF_UserRecruitAddresses_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruitAddresses_PoliticalCountries')
ALTER TABLE [RSU].[UserRecruitAddresses]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruitAddresses_PoliticalCountries] FOREIGN KEY([PoliticalCountryId])
REFERENCES [MAC].[PoliticalCountries] ([PoliticalCountryID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruitAddresses_PoliticalStates')
ALTER TABLE [RSU].[UserRecruitAddresses]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruitAddresses_PoliticalStates] FOREIGN KEY([PoliticalStateId])
REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRecruitAddresses_PoliticalTimeZones')
ALTER TABLE [RSU].[UserRecruitAddresses]  WITH CHECK ADD  CONSTRAINT [FK_UserRecruitAddresses_PoliticalTimeZones] FOREIGN KEY([PoliticalTimeZoneId])
REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID])
GO

ALTER TABLE [RSU].[UserRecruitAddresses] CHECK CONSTRAINT [FK_UserRecruitAddresses_PoliticalCountries]
GO

ALTER TABLE [RSU].[UserRecruitAddresses] CHECK CONSTRAINT [FK_UserRecruitAddresses_PoliticalStates]
GO

ALTER TABLE [RSU].[UserRecruitAddresses] CHECK CONSTRAINT [FK_UserRecruitAddresses_PoliticalTimeZones]
GO
