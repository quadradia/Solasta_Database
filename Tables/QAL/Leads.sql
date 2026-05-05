/*******************************************************************************
 * Object Type: Table
 * Schema: QAL
 * Name: Leads
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'Leads' AND schema_id = SCHEMA_ID('QAL'))
BEGIN
	CREATE TABLE [QAL].[Leads]
	(
		[LeadID] [bigint] IDENTITY(1,1) NOT NULL,
		[LeadAddressId] [bigint] NOT NULL,
		[CustomerTypeId] [varchar](20) NOT NULL,
		[MasterFileId] [bigint] NOT NULL,
		[DealerTenantId] [int] NOT NULL,
		[LanguageId] [nvarchar](50) NOT NULL,
		[TeamLocationId] [int] NOT NULL,
		[SeasonId] [int] NOT NULL,
		[SalesRepId] [varchar](10) NOT NULL,
		[LeadSourceId] [int] NOT NULL,
		[LeadDispositionId] [int] NOT NULL,
		[LeadDispositionDateChange] [datetimeoffset](7) NULL,
		[Prefix] [nvarchar](50) NULL,
		[FirstName] [nvarchar](50) NOT NULL,
		[MiddleName] [nvarchar](50) NULL,
		[LastName] [nvarchar](50) NOT NULL,
		[PostFix] [nvarchar](50) NULL,
		[Gender] [nvarchar](10) NOT NULL,
		[SSN] [varchar](50) NULL,
		[DOB] [date] NULL,
		[DL] [nvarchar](30) NULL,
		[DLStateID] [varchar](4) NULL,
		[Email] [nvarchar](256) NULL,
		[PhoneHome] [nvarchar](20) NULL,
		[PhoneWork] [nvarchar](30) NULL,
		[PhoneMobile] [nvarchar](20) NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[CreatedById] [uniqueidentifier] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [uniqueidentifier] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
		CONSTRAINT [PK_Leads] PRIMARY KEY CLUSTERED
(
	[LeadID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Leads_IsActive' AND type = 'D')
ALTER TABLE [QAL].[Leads] ADD  CONSTRAINT [DF_Leads_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Leads_IsDeleted' AND type = 'D')
ALTER TABLE [QAL].[Leads] ADD  CONSTRAINT [DF_Leads_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Leads_CreatedById' AND type = 'D')
ALTER TABLE [QAL].[Leads] ADD  CONSTRAINT [DF_Leads_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Leads_CreatedDate' AND type = 'D')
ALTER TABLE [QAL].[Leads] ADD  CONSTRAINT [DF_Leads_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Leads_ModifiedById' AND type = 'D')
ALTER TABLE [QAL].[Leads] ADD  CONSTRAINT [DF_Leads_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Leads_ModifiedDate' AND type = 'D')
ALTER TABLE [QAL].[Leads] ADD  CONSTRAINT [DF_Leads_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Leads_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [QAL].[Leads] ADD  CONSTRAINT [DF_Leads_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Leads_CustomerTypes')
ALTER TABLE [QAL].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_CustomerTypes] FOREIGN KEY([CustomerTypeId])
REFERENCES [ACE].[CustomerTypes] ([CustomerTypeID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Leads_DealerTenants')
ALTER TABLE [QAL].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_DealerTenants] FOREIGN KEY([DealerTenantId])
REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Leads_Languages')
ALTER TABLE [QAL].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_Languages] FOREIGN KEY([LanguageId])
REFERENCES [MAC].[Languages] ([LanguageID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Leads_LeadAddresses')
ALTER TABLE [QAL].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_LeadAddresses] FOREIGN KEY([LeadAddressId])
REFERENCES [QAL].[LeadAddresses] ([LeadAddressID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Leads_LeadDispositions')
ALTER TABLE [QAL].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_LeadDispositions] FOREIGN KEY([LeadDispositionId])
REFERENCES [QAL].[LeadDispositions] ([LeadDispositionID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Leads_LeadSources')
ALTER TABLE [QAL].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_LeadSources] FOREIGN KEY([LeadSourceId])
REFERENCES [QAL].[LeadSources] ([LeadSourceID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Leads_MasterFiles')
ALTER TABLE [QAL].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_MasterFiles] FOREIGN KEY([MasterFileId])
REFERENCES [ACE].[MasterFiles] ([MasterFileID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Leads_Season')
ALTER TABLE [QAL].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_Season] FOREIGN KEY([SeasonId])
REFERENCES [RSU].[Seasons] ([SeasonID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Leads_TeamLocations')
ALTER TABLE [QAL].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_TeamLocations] FOREIGN KEY([TeamLocationId])
REFERENCES [RSU].[TeamLocations] ([TeamLocationID])
GO

ALTER TABLE [QAL].[Leads] CHECK CONSTRAINT [FK_Leads_CustomerTypes]
GO

ALTER TABLE [QAL].[Leads] CHECK CONSTRAINT [FK_Leads_DealerTenants]
GO

ALTER TABLE [QAL].[Leads] CHECK CONSTRAINT [FK_Leads_Languages]
GO

ALTER TABLE [QAL].[Leads] CHECK CONSTRAINT [FK_Leads_LeadAddresses]
GO

ALTER TABLE [QAL].[Leads] CHECK CONSTRAINT [FK_Leads_LeadDispositions]
GO

ALTER TABLE [QAL].[Leads] CHECK CONSTRAINT [FK_Leads_LeadSources]
GO

ALTER TABLE [QAL].[Leads] CHECK CONSTRAINT [FK_Leads_MasterFiles]
GO

ALTER TABLE [QAL].[Leads] CHECK CONSTRAINT [FK_Leads_Season]
GO

ALTER TABLE [QAL].[Leads] CHECK CONSTRAINT [FK_Leads_TeamLocations]
GO
