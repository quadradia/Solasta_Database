/*******************************************************************************
 * Object Type: Table
 * Schema: MAS
 * Name: MasAccountTemplates
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MasAccountTemplates' AND schema_id = SCHEMA_ID('MAS'))
BEGIN
CREATE TABLE [MAS].[MasAccountTemplates](
	[MasAccountTemplateID] [int] IDENTITY(1,1) NOT NULL,
	[DealerId] [int] NOT NULL,
	[AccountSiteTypeId] [varchar](20) NULL,
	[AccountSystemTypeId] [varchar](20) NULL,
	[AccountCellularTypeId] [varchar](20) NULL,
	[AccountPanelTypeId] [varchar](20) NULL,
	[AccountDslSeizureTypeId] [smallint] NULL,
	[AccountSignalFormatTypeId] [smallint] NULL,
	[MonitoringStationOperatingSystemId] [varchar](50) NULL,
	[TemplateName] [nvarchar](50) NOT NULL,
	[PanelCode] [varchar](20) NULL,
	[PanelPhone] [varchar](20) NULL,
	[IsCurrent] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_MasAccountTemplates] PRIMARY KEY CLUSTERED 
(
	[MasAccountTemplateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountTemplates_TemplateName' AND type = 'D')
ALTER TABLE [MAS].[MasAccountTemplates] ADD  CONSTRAINT [DF_MasAccountTemplates_TemplateName]  DEFAULT (N'[Default Template]') FOR [TemplateName]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountTemplates_IsCurrent' AND type = 'D')
ALTER TABLE [MAS].[MasAccountTemplates] ADD  CONSTRAINT [DF_MasAccountTemplates_IsCurrent]  DEFAULT ((0)) FOR [IsCurrent]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountTemplates_IsActive' AND type = 'D')
ALTER TABLE [MAS].[MasAccountTemplates] ADD  CONSTRAINT [DF_MasAccountTemplates_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountTemplates_IsDeleted' AND type = 'D')
ALTER TABLE [MAS].[MasAccountTemplates] ADD  CONSTRAINT [DF_MasAccountTemplates_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountTemplates_ModifiedDate' AND type = 'D')
ALTER TABLE [MAS].[MasAccountTemplates] ADD  CONSTRAINT [DF_MasAccountTemplates_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountTemplates_ModifiedById' AND type = 'D')
ALTER TABLE [MAS].[MasAccountTemplates] ADD  CONSTRAINT [DF_MasAccountTemplates_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountTemplates_CreatedDate' AND type = 'D')
ALTER TABLE [MAS].[MasAccountTemplates] ADD  CONSTRAINT [DF_MasAccountTemplates_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountTemplates_CreatedById' AND type = 'D')
ALTER TABLE [MAS].[MasAccountTemplates] ADD  CONSTRAINT [DF_MasAccountTemplates_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountTemplates_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAS].[MasAccountTemplates] ADD  CONSTRAINT [DF_MasAccountTemplates_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccountTemplates_Dealers')
ALTER TABLE [MAS].[MasAccountTemplates]  WITH CHECK ADD  CONSTRAINT [FK_MasAccountTemplates_Dealers] FOREIGN KEY([DealerId])
REFERENCES [ACC].[Dealers] ([DealerID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccountTemplates_MonitoringStationOperatingSystems')
ALTER TABLE [MAS].[MasAccountTemplates]  WITH CHECK ADD  CONSTRAINT [FK_MasAccountTemplates_MonitoringStationOperatingSystems] FOREIGN KEY([MonitoringStationOperatingSystemId])
REFERENCES [MAS].[MonitoringStationOperatingSystems] ([MonitoringStationOperatingSystemID])
GO

ALTER TABLE [MAS].[MasAccountTemplates] CHECK CONSTRAINT [FK_MasAccountTemplates_Dealers]
GO

ALTER TABLE [MAS].[MasAccountTemplates] CHECK CONSTRAINT [FK_MasAccountTemplates_MonitoringStationOperatingSystems]
GO
