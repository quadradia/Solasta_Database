/*******************************************************************************
 * Object Type: Table
 * Schema: ACE
 * Name: CustomerAddresses
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'CustomerAddresses' AND schema_id = SCHEMA_ID('ACE'))
BEGIN
	CREATE TABLE [ACE].[CustomerAddresses]
	(
		[CustomerAddressID] [bigint] IDENTITY(1,1) NOT NULL,
		[LeadAddressId] [bigint] NULL,
		[DealerTenantId] [int] NOT NULL,
		[AddressValidationVendorId] [varchar](20) NOT NULL,
		[AddressValidationStateId] [varchar](5) NOT NULL,
		[PoliticalStateId] [varchar](4) NOT NULL,
		[PoliticalCountryId] [nvarchar](10) NOT NULL,
		[PoliticalTimeZoneId] [int] NOT NULL,
		[AddressTypeId] [varchar](10) NOT NULL,
		[AddressStreetTypeId] [int] NULL,
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
		[PostalCode] [varchar](5) NOT NULL,
		[PlusFour] [varchar](4) NULL,
		[Phone] [varchar](20) NULL,
		[DeliveryPoint] [varchar](2) NULL,
		[CrossStreet] [varchar](50) NULL,
		[Latitude] [float] NOT NULL,
		[Longitude] [float] NOT NULL,
		[CongressionalDistric] [int] NULL,
		[DPV] [bit] NOT NULL,
		[DPVResponse] [char](10) NULL,
		[DPVFootNote] [varchar](50) NULL,
		[CarrierRoute] [varchar](50) NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [uniqueidentifier] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[CreatedById] [uniqueidentifier] NOT NULL,
		[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
		CONSTRAINT [PK_CustomerAddresses] PRIMARY KEY CLUSTERED
(
	[CustomerAddressID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CustomerAddresses_IsActive' AND type = 'D')
ALTER TABLE [ACE].[CustomerAddresses] ADD  CONSTRAINT [DF_CustomerAddresses_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CustomerAddresses_IsDeleted' AND type = 'D')
ALTER TABLE [ACE].[CustomerAddresses] ADD  CONSTRAINT [DF_CustomerAddresses_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CustomerAddresses_ModifiedDate' AND type = 'D')
ALTER TABLE [ACE].[CustomerAddresses] ADD  CONSTRAINT [DF_CustomerAddresses_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CustomerAddresses_ModifiedById' AND type = 'D')
ALTER TABLE [ACE].[CustomerAddresses] ADD  CONSTRAINT [DF_CustomerAddresses_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CustomerAddresses_CreatedDate' AND type = 'D')
ALTER TABLE [ACE].[CustomerAddresses] ADD  CONSTRAINT [DF_CustomerAddresses_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CustomerAddresses_CreatedById' AND type = 'D')
ALTER TABLE [ACE].[CustomerAddresses] ADD  CONSTRAINT [DF_CustomerAddresses_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CustomerAddresses_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [ACE].[CustomerAddresses] ADD  CONSTRAINT [DF_CustomerAddresses_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Addresses_AddressTypes')
ALTER TABLE [ACE].[CustomerAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Addresses_AddressTypes] FOREIGN KEY([AddressTypeId])
REFERENCES [MAC].[AddressTypes] ([AddressTypeID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Addresses_AddressValidationStates')
ALTER TABLE [ACE].[CustomerAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Addresses_AddressValidationStates] FOREIGN KEY([AddressValidationStateId])
REFERENCES [MAC].[AddressValidationStates] ([AddressValidationStateID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Addresses_AddressValidationVendors')
ALTER TABLE [ACE].[CustomerAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Addresses_AddressValidationVendors] FOREIGN KEY([AddressValidationVendorId])
REFERENCES [MAC].[AddressValidationVendors] ([AddressValidationVendorID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Addresses_DealerTenants')
ALTER TABLE [ACE].[CustomerAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Addresses_DealerTenants] FOREIGN KEY([DealerTenantId])
REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Addresses_PoliticalCountries')
ALTER TABLE [ACE].[CustomerAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Addresses_PoliticalCountries] FOREIGN KEY([PoliticalCountryId])
REFERENCES [MAC].[PoliticalCountries] ([PoliticalCountryID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Addresses_PoliticalStates')
ALTER TABLE [ACE].[CustomerAddresses]  WITH CHECK ADD  CONSTRAINT [FK_Addresses_PoliticalStates] FOREIGN KEY([PoliticalStateId])
REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_CustomerAddresses_AddressStreetTypes')
ALTER TABLE [ACE].[CustomerAddresses]  WITH CHECK ADD  CONSTRAINT [FK_CustomerAddresses_AddressStreetTypes] FOREIGN KEY([AddressStreetTypeId])
REFERENCES [MAC].[AddressStreetTypes] ([AddressStreetTypeID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_CustomerAddresses_LeadAddresses')
ALTER TABLE [ACE].[CustomerAddresses]  WITH CHECK ADD  CONSTRAINT [FK_CustomerAddresses_LeadAddresses] FOREIGN KEY([LeadAddressId])
REFERENCES [QAL].[LeadAddresses] ([LeadAddressID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_CustomerAddresses_PoliticalTimeZones')
ALTER TABLE [ACE].[CustomerAddresses]  WITH CHECK ADD  CONSTRAINT [FK_CustomerAddresses_PoliticalTimeZones] FOREIGN KEY([PoliticalTimeZoneId])
REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID])
GO

ALTER TABLE [ACE].[CustomerAddresses] CHECK CONSTRAINT [FK_Addresses_AddressTypes]
GO

ALTER TABLE [ACE].[CustomerAddresses] CHECK CONSTRAINT [FK_Addresses_AddressValidationStates]
GO

ALTER TABLE [ACE].[CustomerAddresses] CHECK CONSTRAINT [FK_Addresses_AddressValidationVendors]
GO

ALTER TABLE [ACE].[CustomerAddresses] CHECK CONSTRAINT [FK_Addresses_DealerTenants]
GO

ALTER TABLE [ACE].[CustomerAddresses] CHECK CONSTRAINT [FK_Addresses_PoliticalCountries]
GO

ALTER TABLE [ACE].[CustomerAddresses] CHECK CONSTRAINT [FK_Addresses_PoliticalStates]
GO

ALTER TABLE [ACE].[CustomerAddresses] CHECK CONSTRAINT [FK_CustomerAddresses_AddressStreetTypes]
GO

ALTER TABLE [ACE].[CustomerAddresses] CHECK CONSTRAINT [FK_CustomerAddresses_LeadAddresses]
GO

ALTER TABLE [ACE].[CustomerAddresses] CHECK CONSTRAINT [FK_CustomerAddresses_PoliticalTimeZones]
GO
