/*******************************************************************************
 * Object Type: Table
 * Schema: MAS
 * Name: MasAccounts
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MasAccounts' AND schema_id = SCHEMA_ID('MAS'))
BEGIN
CREATE TABLE [MAS].[MasAccounts](
	[MasAccountID] [bigint] NOT NULL,
	[PremiseAddressId] [bigint] NULL,
	[CustomerAddressId] [bigint] NULL,
	[PrimaryIndustryNumberId] [bigint] NULL,
	[SecondaryIndustryNumberId] [bigint] NULL,
	[MasAccountSiteTypeId] [varchar](20) NULL,
	[MasAccountSystemTypeId] [varchar](20) NULL,
	[MasAccountCellularTypeId] [varchar](20) NULL,
	[MasAccountPanelTypeId] [varchar](20) NULL,
	[MasAccountDslSeizureTypeId] [smallint] NULL,
	[MasAccountSignalFormatTypeId] [smallint] NULL,
	[MasAccountTemplateId] [int] NULL,
	[MonitoringStationOperatingSystemId] [varchar](50) NULL,
	[TechId] [varchar](10) NULL,
	[MasAccountSubmitId] [bigint] NULL,
	[FundingSourceId] [int] NULL,
	[MasAccountName] [nvarchar](150) NOT NULL,
	[MasAccountDescription] [nvarchar](max) NULL,
	[PanelCode] [varchar](50) NULL,
	[PanelPhone] [varchar](30) NULL,
	[PanelLocation] [varchar](50) NULL,
	[TransformerLocation] [varchar](50) NULL,
	[Privacy] [bit] NOT NULL,
	[AccountPassword] [nvarchar](100) NULL,
	[DispatchMessage] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW] [bigint] IDENTITY(1,1) NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_MasAccounts] PRIMARY KEY CLUSTERED 
(
	[MasAccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccounts_Privacy' AND type = 'D')
ALTER TABLE [MAS].[MasAccounts] ADD  CONSTRAINT [DF_MasAccounts_Privacy]  DEFAULT ((0)) FOR [Privacy]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccounts_IsActive' AND type = 'D')
ALTER TABLE [MAS].[MasAccounts] ADD  CONSTRAINT [DF_MasAccounts_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccounts_IsDeleted' AND type = 'D')
ALTER TABLE [MAS].[MasAccounts] ADD  CONSTRAINT [DF_MasAccounts_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccounts_ModifiedDate' AND type = 'D')
ALTER TABLE [MAS].[MasAccounts] ADD  CONSTRAINT [DF_MasAccounts_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccounts_ModifiedById' AND type = 'D')
ALTER TABLE [MAS].[MasAccounts] ADD  CONSTRAINT [DF_MasAccounts_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccounts_CreatedDate' AND type = 'D')
ALTER TABLE [MAS].[MasAccounts] ADD  CONSTRAINT [DF_MasAccounts_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccounts_CreatedById' AND type = 'D')
ALTER TABLE [MAS].[MasAccounts] ADD  CONSTRAINT [DF_MasAccounts_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccounts_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAS].[MasAccounts] ADD  CONSTRAINT [DF_MasAccounts_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_CustomerAddresses')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_CustomerAddresses] FOREIGN KEY([CustomerAddressId])
REFERENCES [ACE].[CustomerAddresses] ([CustomerAddressID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_FundingSources')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_FundingSources] FOREIGN KEY([FundingSourceId])
REFERENCES [FNE].[FundingSources] ([FundingSourceID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_MasAccountCellularTypes')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_MasAccountCellularTypes] FOREIGN KEY([MasAccountCellularTypeId])
REFERENCES [MAS].[MasAccountCellularTypes] ([MasAccountCellularTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_MasAccountDslSeizureTypes')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_MasAccountDslSeizureTypes] FOREIGN KEY([MasAccountDslSeizureTypeId])
REFERENCES [MAS].[MasAccountDslSeizureTypes] ([MasAccountDslSeizureTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_MasAccountPanelTypes')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_MasAccountPanelTypes] FOREIGN KEY([MasAccountPanelTypeId])
REFERENCES [MAS].[MasAccountPanelTypes] ([MasAccountPanelTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_MasAccountSignalFormatTypes')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_MasAccountSignalFormatTypes] FOREIGN KEY([MasAccountSignalFormatTypeId])
REFERENCES [MAS].[MasAccountSignalFormatTypes] ([MasAccountSignalFormatTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_MasAccountSiteTypes')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_MasAccountSiteTypes] FOREIGN KEY([MasAccountSiteTypeId])
REFERENCES [MAS].[MasAccountSiteTypes] ([MasAccountSiteTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_MasAccountSystemTypes')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_MasAccountSystemTypes] FOREIGN KEY([MasAccountSystemTypeId])
REFERENCES [MAS].[MasAccountSystemTypes] ([MasAccountSystemTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_MasAccountTemplates')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_MasAccountTemplates] FOREIGN KEY([MasAccountTemplateId])
REFERENCES [MAS].[MasAccountTemplates] ([MasAccountTemplateID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_MonitoringStationOperatingSystems')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_MonitoringStationOperatingSystems] FOREIGN KEY([MonitoringStationOperatingSystemId])
REFERENCES [MAS].[MonitoringStationOperatingSystems] ([MonitoringStationOperatingSystemID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccounts_PremiseAddresses')
ALTER TABLE [MAS].[MasAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasAccounts_PremiseAddresses] FOREIGN KEY([PremiseAddressId])
REFERENCES [MAS].[PremiseAddresses] ([PremiseAddressID])
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_CustomerAddresses]
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_FundingSources]
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_MasAccountCellularTypes]
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_MasAccountDslSeizureTypes]
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_MasAccountPanelTypes]
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_MasAccountSignalFormatTypes]
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_MasAccountSiteTypes]
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_MasAccountSystemTypes]
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_MasAccountTemplates]
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_MonitoringStationOperatingSystems]
GO

ALTER TABLE [MAS].[MasAccounts] CHECK CONSTRAINT [FK_MasAccounts_PremiseAddresses]
GO
