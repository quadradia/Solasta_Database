/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserResourceAddresses
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserResourceAddresses' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserResourceAddresses](
	[UserResourceAddressID] [int] IDENTITY(1,1) NOT NULL,
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
 CONSTRAINT [PK_UserResourceAddresses] PRIMARY KEY CLUSTERED 
(
	[UserResourceAddressID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceAddresses_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserResourceAddresses] ADD  CONSTRAINT [DF_UserResourceAddresses_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceAddresses_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserResourceAddresses] ADD  CONSTRAINT [DF_UserResourceAddresses_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceAddresses_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserResourceAddresses] ADD  CONSTRAINT [DF_UserResourceAddresses_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceAddresses_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserResourceAddresses] ADD  CONSTRAINT [DF_UserResourceAddresses_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceAddresses_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserResourceAddresses] ADD  CONSTRAINT [DF_UserResourceAddresses_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceAddresses_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserResourceAddresses] ADD  CONSTRAINT [DF_UserResourceAddresses_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserResourceAddresses_PoliticalCountries')
ALTER TABLE [RSU].[UserResourceAddresses]  WITH CHECK ADD  CONSTRAINT [FK_UserResourceAddresses_PoliticalCountries] FOREIGN KEY([PoliticalCountryId])
REFERENCES [MAC].[PoliticalCountries] ([PoliticalCountryID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserResourceAddresses_PoliticalStates')
ALTER TABLE [RSU].[UserResourceAddresses]  WITH CHECK ADD  CONSTRAINT [FK_UserResourceAddresses_PoliticalStates] FOREIGN KEY([PoliticalStateId])
REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserResourceAddresses_PoliticalTimeZones')
ALTER TABLE [RSU].[UserResourceAddresses]  WITH CHECK ADD  CONSTRAINT [FK_UserResourceAddresses_PoliticalTimeZones] FOREIGN KEY([PoliticalTimeZoneId])
REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID])
GO

ALTER TABLE [RSU].[UserResourceAddresses] CHECK CONSTRAINT [FK_UserResourceAddresses_PoliticalCountries]
GO

ALTER TABLE [RSU].[UserResourceAddresses] CHECK CONSTRAINT [FK_UserResourceAddresses_PoliticalStates]
GO

ALTER TABLE [RSU].[UserResourceAddresses] CHECK CONSTRAINT [FK_UserResourceAddresses_PoliticalTimeZones]
GO
