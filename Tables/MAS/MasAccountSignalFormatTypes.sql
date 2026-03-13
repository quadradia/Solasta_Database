/*******************************************************************************
 * Object Type: Table
 * Schema: MAS
 * Name: MasAccountSignalFormatTypes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MasAccountSignalFormatTypes' AND schema_id = SCHEMA_ID('MAS'))
BEGIN
CREATE TABLE [MAS].[MasAccountSignalFormatTypes](
	[MasAccountSignalFormatTypeID] [smallint] IDENTITY(1,1) NOT NULL,
	[MonitoringStationOperatingSystemId] [varchar](50) NOT NULL,
	[AccountSignalFormatTypeName] [varchar](50) NOT NULL,
	[MsSignalFormatTypeId] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_MasAccountSignalFormatTypes] PRIMARY KEY CLUSTERED 
(
	[MasAccountSignalFormatTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AccountSignalFormatTypes_IsActive' AND type = 'D')
ALTER TABLE [MAS].[MasAccountSignalFormatTypes] ADD  CONSTRAINT [DF_AccountSignalFormatTypes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AccountSignalFormatTypes_IsDeleted' AND type = 'D')
ALTER TABLE [MAS].[MasAccountSignalFormatTypes] ADD  CONSTRAINT [DF_AccountSignalFormatTypes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AccountSignalFormatTypes_ModifiedDate' AND type = 'D')
ALTER TABLE [MAS].[MasAccountSignalFormatTypes] ADD  CONSTRAINT [DF_AccountSignalFormatTypes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AccountSignalFormatTypes_ModifiedById' AND type = 'D')
ALTER TABLE [MAS].[MasAccountSignalFormatTypes] ADD  CONSTRAINT [DF_AccountSignalFormatTypes_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AccountSignalFormatTypes_CreatedDate' AND type = 'D')
ALTER TABLE [MAS].[MasAccountSignalFormatTypes] ADD  CONSTRAINT [DF_AccountSignalFormatTypes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AccountSignalFormatTypes_CreatedById' AND type = 'D')
ALTER TABLE [MAS].[MasAccountSignalFormatTypes] ADD  CONSTRAINT [DF_AccountSignalFormatTypes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AccountSignalFormatTypes_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAS].[MasAccountSignalFormatTypes] ADD  CONSTRAINT [DF_AccountSignalFormatTypes_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AccountSignalFormatTypes_MonitoringStationOperatingSystems')
ALTER TABLE [MAS].[MasAccountSignalFormatTypes]  WITH CHECK ADD  CONSTRAINT [FK_AccountSignalFormatTypes_MonitoringStationOperatingSystems] FOREIGN KEY([MonitoringStationOperatingSystemId])
REFERENCES [MAS].[MonitoringStationOperatingSystems] ([MonitoringStationOperatingSystemID])
GO

ALTER TABLE [MAS].[MasAccountSignalFormatTypes] CHECK CONSTRAINT [FK_AccountSignalFormatTypes_MonitoringStationOperatingSystems]
GO
