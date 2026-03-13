/*******************************************************************************
 * Object Type: Table
 * Schema: ACE
 * Name: Customers
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Customers' AND schema_id = SCHEMA_ID('ACE'))
BEGIN
CREATE TABLE [ACE].[Customers](
	[CustomerID] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerTypeId] [varchar](20) NOT NULL,
	[MasterFileId] [bigint] NOT NULL,
	[DealerId] [int] NOT NULL,
	[CustomerAddressId] [bigint] NULL,
	[LeadId] [bigint] NULL,
	[LanguageId] [nvarchar](50) NOT NULL,
	[Prefix] [nvarchar](50) NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[MiddleName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[Postfix] [nvarchar](50) NULL,
	[BusinessName] [nvarchar](50) NULL,
	[Gender] [nvarchar](10) NOT NULL,
	[PhoneHome] [varchar](20) NULL,
	[PhoneWork] [varchar](30) NULL,
	[PhoneMobile] [varchar](20) NULL,
	[Email] [varchar](256) NULL,
	[DOB] [date] NULL,
	[SSN] [nvarchar](50) NULL,
	[Username] [nvarchar](50) NULL,
	[Password] [nvarchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_Gender' AND type = 'D')
ALTER TABLE [ACE].[Customers] ADD  CONSTRAINT [DF_Customers_Gender]  DEFAULT (N'Male') FOR [Gender]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_IsActive' AND type = 'D')
ALTER TABLE [ACE].[Customers] ADD  CONSTRAINT [DF_Customers_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_IsDeleted' AND type = 'D')
ALTER TABLE [ACE].[Customers] ADD  CONSTRAINT [DF_Customers_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_ModifiedDate' AND type = 'D')
ALTER TABLE [ACE].[Customers] ADD  CONSTRAINT [DF_Customers_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_ModifiedById' AND type = 'D')
ALTER TABLE [ACE].[Customers] ADD  CONSTRAINT [DF_Customers_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_CreatedDate' AND type = 'D')
ALTER TABLE [ACE].[Customers] ADD  CONSTRAINT [DF_Customers_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_CreatedById' AND type = 'D')
ALTER TABLE [ACE].[Customers] ADD  CONSTRAINT [DF_Customers_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Customers_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [ACE].[Customers] ADD  CONSTRAINT [DF_Customers_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customers_CustomerAddresses')
ALTER TABLE [ACE].[Customers]  WITH CHECK ADD  CONSTRAINT [FK_Customers_CustomerAddresses] FOREIGN KEY([CustomerAddressId])
REFERENCES [ACE].[CustomerAddresses] ([CustomerAddressID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customers_CustomerTypes')
ALTER TABLE [ACE].[Customers]  WITH CHECK ADD  CONSTRAINT [FK_Customers_CustomerTypes] FOREIGN KEY([CustomerTypeId])
REFERENCES [ACE].[CustomerTypes] ([CustomerTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customers_Dealers')
ALTER TABLE [ACE].[Customers]  WITH CHECK ADD  CONSTRAINT [FK_Customers_Dealers] FOREIGN KEY([DealerId])
REFERENCES [ACC].[Dealers] ([DealerID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customers_Languages')
ALTER TABLE [ACE].[Customers]  WITH CHECK ADD  CONSTRAINT [FK_Customers_Languages] FOREIGN KEY([LanguageId])
REFERENCES [MAC].[Languages] ([LanguageID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customers_Leads')
ALTER TABLE [ACE].[Customers]  WITH CHECK ADD  CONSTRAINT [FK_Customers_Leads] FOREIGN KEY([LeadId])
REFERENCES [QAL].[Leads] ([LeadID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customers_MasterFiles')
ALTER TABLE [ACE].[Customers]  WITH CHECK ADD  CONSTRAINT [FK_Customers_MasterFiles] FOREIGN KEY([MasterFileId])
REFERENCES [ACE].[MasterFiles] ([MasterFileID])
GO

ALTER TABLE [ACE].[Customers] CHECK CONSTRAINT [FK_Customers_CustomerAddresses]
GO

ALTER TABLE [ACE].[Customers] CHECK CONSTRAINT [FK_Customers_CustomerTypes]
GO

ALTER TABLE [ACE].[Customers] CHECK CONSTRAINT [FK_Customers_Dealers]
GO

ALTER TABLE [ACE].[Customers] CHECK CONSTRAINT [FK_Customers_Languages]
GO

ALTER TABLE [ACE].[Customers] CHECK CONSTRAINT [FK_Customers_Leads]
GO

ALTER TABLE [ACE].[Customers] CHECK CONSTRAINT [FK_Customers_MasterFiles]
GO
