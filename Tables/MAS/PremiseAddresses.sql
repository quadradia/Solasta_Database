/*******************************************************************************
 * Object Type: Table
 * Schema: MAS
 * Name: PremiseAddresses
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'PremiseAddresses' AND schema_id = SCHEMA_ID('MAS'))
BEGIN
	CREATE TABLE [MAS].[PremiseAddresses]
	(
		[PremiseAddressID] [bigint] IDENTITY(1,1) NOT NULL,
		[LeadAddressId] [bigint] NULL,
		[DealerTenantId] [int] NOT NULL,
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
		CONSTRAINT [PK_PremiseAddresses] PRIMARY KEY CLUSTERED
(
	[PremiseAddressID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PremiseAddresses_LanguageId' AND type = 'D')
ALTER TABLE [MAS].[PremiseAddresses] ADD  CONSTRAINT [DF_PremiseAddresses_LanguageId]  DEFAULT (N'en') FOR [LanguageId]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PremiseAddresses_IsActive' AND type = 'D')
ALTER TABLE [MAS].[PremiseAddresses] ADD  CONSTRAINT [DF_PremiseAddresses_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PremiseAddresses_IsDeleted' AND type = 'D')
ALTER TABLE [MAS].[PremiseAddresses] ADD  CONSTRAINT [DF_PremiseAddresses_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PremiseAddresses_ModifiedDate' AND type = 'D')
ALTER TABLE [MAS].[PremiseAddresses] ADD  CONSTRAINT [DF_PremiseAddresses_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PremiseAddresses_ModifiedById' AND type = 'D')
ALTER TABLE [MAS].[PremiseAddresses] ADD  CONSTRAINT [DF_PremiseAddresses_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PremiseAddresses_CreatedDate' AND type = 'D')
ALTER TABLE [MAS].[PremiseAddresses] ADD  CONSTRAINT [DF_PremiseAddresses_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PremiseAddresses_CreatedById' AND type = 'D')
ALTER TABLE [MAS].[PremiseAddresses] ADD  CONSTRAINT [DF_PremiseAddresses_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PremiseAddresses_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAS].[PremiseAddresses] ADD  CONSTRAINT [DF_PremiseAddresses_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_AddressStreetTypes')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_AddressStreetTypes] FOREIGN KEY([AddressStreetTypeId])
REFERENCES [MAC].[AddressStreetTypes] ([AddressStreetTypeID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_AddressTypes')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_AddressTypes] FOREIGN KEY([AddressTypeId])
REFERENCES [MAC].[AddressTypes] ([AddressTypeID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_AddressValidationStates')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_AddressValidationStates] FOREIGN KEY([AddressValidationStateId])
REFERENCES [MAC].[AddressValidationStates] ([AddressValidationStateID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_AddressValidationVendors')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_AddressValidationVendors] FOREIGN KEY([AddressValidationVendorId])
REFERENCES [MAC].[AddressValidationVendors] ([AddressValidationVendorID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_DealerTenants')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_DealerTenants] FOREIGN KEY([DealerTenantId])
REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_Languages')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_Languages] FOREIGN KEY([LanguageId])
REFERENCES [MAC].[Languages] ([LanguageID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_LeadAddresses')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_LeadAddresses] FOREIGN KEY([LeadAddressId])
REFERENCES [QAL].[LeadAddresses] ([LeadAddressID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_PoliticalCountries')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_PoliticalCountries] FOREIGN KEY([PoliticalCountryId])
REFERENCES [MAC].[PoliticalCountries] ([PoliticalCountryID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_PoliticalStates')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_PoliticalStates] FOREIGN KEY([PoliticalStateId])
REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_PoliticalTimeZones')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_PoliticalTimeZones] FOREIGN KEY([PoliticalTimeZoneId])
REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_Seasons')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_Seasons] FOREIGN KEY([SeasonId])
REFERENCES [RSU].[Seasons] ([SeasonID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_TeamLocations')
ALTER TABLE [MAS].[PremiseAddresses]  WITH CHECK ADD  CONSTRAINT [FK_PremiseAddresses_TeamLocations] FOREIGN KEY([TeamLocationId])
REFERENCES [RSU].[TeamLocations] ([TeamLocationID])
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_AddressStreetTypes]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_AddressTypes]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_AddressValidationStates]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_AddressValidationVendors]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_DealerTenants]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_Languages]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_LeadAddresses]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_PoliticalCountries]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_PoliticalStates]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_PoliticalTimeZones]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_Seasons]
GO

ALTER TABLE [MAS].[PremiseAddresses] CHECK CONSTRAINT [FK_PremiseAddresses_TeamLocations]
GO
