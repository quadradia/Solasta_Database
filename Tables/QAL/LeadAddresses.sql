/*******************************************************************************
 * Object Type: Table
 * Schema: QAL
 * Name: LeadAddresses
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LeadAddresses' AND schema_id = SCHEMA_ID('QAL'))
BEGIN
CREATE TABLE [QAL].[LeadAddresses](
	[LeadAddressID] [bigint] IDENTITY(1,1) NOT NULL,
	[DealerId] [int] NOT NULL,
	[LanguageId] [nvarchar](50) NOT NULL,
	[AddressValidationVendorId] [varchar](20) NOT NULL,
	[AddressValidationStateId] [varchar](5) NOT NULL,
	[PoliticalStateId] [varchar](4) NOT NULL,
	[PoliticalCountryId] [nvarchar](10) NOT NULL,
	[PoliticalTimeZoneId] [int] NOT NULL,
	[AddressTypeId] [varchar](10) NOT NULL,
	[AddressStreetTypeId] [int] NULL,
	[SeasonId] [int] NOT NULL,
	[TeamLocationId] [int] NOT NULL,
	[SalesRepId] [nvarchar](25) NOT NULL,
	[StreetAddress] [nvarchar](50) NOT NULL,
	[StreetAddress2] [nvarchar](50) NULL,
	[StreetNumber] [nvarchar](40) NULL,
	[StreetName] [nvarchar](50) NULL,
	[StreetType] [nvarchar](20) NULL,
	[PreDirectional] [nvarchar](20) NULL,
	[PostDirectional] [nvarchar](20) NULL,
	[Extension] [nvarchar](50) NULL,
	[ExtensionNumber] [nvarchar](50) NULL,
	[County] [nvarchar](50) NULL,
	[CountyCode] [nvarchar](6) NULL,
	[Urbanization] [nvarchar](50) NULL,
	[UrbanizationCode] [nvarchar](3) NULL,
	[City] [nvarchar](50) NOT NULL,
	[PostalCode] [nvarchar](5) NOT NULL,
	[PlusFour] [nvarchar](4) NULL,
	[PostalCodeFull] [varchar](15) NULL,
	[Phone] [varchar](20) NULL,
	[DeliveryPoint] [nvarchar](2) NULL,
	[CrossStreet] [varchar](50) NULL,
	[Latitude] [float] NOT NULL,
	[Longitude] [float] NOT NULL,
	[CongressionalDistric] [int] NULL,
	[DPV] [bit] NOT NULL,
	[DPVResponse] [char](10) NULL,
	[DPVFootnote] [varchar](50) NULL,
	[CarrierRoute] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_LeadAddresses] PRIMARY KEY CLUSTERED 
(
	[LeadAddressID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Address_LanguageId' AND type = 'D')
ALTER TABLE [QAL].[LeadAddresses] ADD  CONSTRAINT [DF_Address_LanguageId]  DEFAULT (N'en') FOR [LanguageId]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAddresses_IsActive' AND type = 'D')
ALTER TABLE [QAL].[LeadAddresses] ADD  CONSTRAINT [DF_LeadAddresses_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAddresses_IsDeleted' AND type = 'D')
ALTER TABLE [QAL].[LeadAddresses] ADD  CONSTRAINT [DF_LeadAddresses_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAddresses_ModifiedDate' AND type = 'D')
ALTER TABLE [QAL].[LeadAddresses] ADD  CONSTRAINT [DF_LeadAddresses_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAddresses_ModifiedById' AND type = 'D')
ALTER TABLE [QAL].[LeadAddresses] ADD  CONSTRAINT [DF_LeadAddresses_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAddresses_CreatedDate' AND type = 'D')
ALTER TABLE [QAL].[LeadAddresses] ADD  CONSTRAINT [DF_LeadAddresses_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAddresses_CreatedById' AND type = 'D')
ALTER TABLE [QAL].[LeadAddresses] ADD  CONSTRAINT [DF_LeadAddresses_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAddresses_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [QAL].[LeadAddresses] ADD  CONSTRAINT [DF_LeadAddresses_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Address_AddressTypes')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Address_AddressTypes] FOREIGN KEY([AddressTypeId])
REFERENCES [MAC].[AddressTypes] ([AddressTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Address_AddressValidationStates')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Address_AddressValidationStates] FOREIGN KEY([AddressValidationStateId])
REFERENCES [MAC].[AddressValidationStates] ([AddressValidationStateID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Address_AddressValidationVendors')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Address_AddressValidationVendors] FOREIGN KEY([AddressValidationVendorId])
REFERENCES [MAC].[AddressValidationVendors] ([AddressValidationVendorID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Address_Dealers')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Address_Dealers] FOREIGN KEY([DealerId])
REFERENCES [ACC].[Dealers] ([DealerID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Address_Languages')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Address_Languages] FOREIGN KEY([LanguageId])
REFERENCES [MAC].[Languages] ([LanguageID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Address_PoliticalCountries')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Address_PoliticalCountries] FOREIGN KEY([PoliticalCountryId])
REFERENCES [MAC].[PoliticalCountries] ([PoliticalCountryID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Address_PoliticalStates')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Address_PoliticalStates] FOREIGN KEY([PoliticalStateId])
REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Address_Season')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Address_Season] FOREIGN KEY([SeasonId])
REFERENCES [RSU].[Seasons] ([SeasonID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Address_TeamLocations')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Address_TeamLocations] FOREIGN KEY([TeamLocationId])
REFERENCES [RSU].[TeamLocations] ([TeamLocationID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_LeadAddresses_AddressStreetTypes')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_LeadAddresses_AddressStreetTypes] FOREIGN KEY([AddressStreetTypeId])
REFERENCES [MAC].[AddressStreetTypes] ([AddressStreetTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_LeadAddresses_PoliticalTimeZones')
ALTER TABLE [QAL].[LeadAddresses]  WITH CHECK ADD  CONSTRAINT [FK_LeadAddresses_PoliticalTimeZones] FOREIGN KEY([PoliticalTimeZoneId])
REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID])
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_Address_AddressTypes]
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_Address_AddressValidationStates]
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_Address_AddressValidationVendors]
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_Address_Dealers]
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_Address_Languages]
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_Address_PoliticalCountries]
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_Address_PoliticalStates]
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_Address_Season]
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_Address_TeamLocations]
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_LeadAddresses_AddressStreetTypes]
GO

ALTER TABLE [QAL].[LeadAddresses] CHECK CONSTRAINT [FK_LeadAddresses_PoliticalTimeZones]
GO
