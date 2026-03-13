/*******************************************************************************
 * Object Type: Table
 * Schema: MAS
 * Name: MonitoringStations
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MonitoringStations' AND schema_id = SCHEMA_ID('MAS'))
BEGIN
CREATE TABLE [MAS].[MonitoringStations](
	[MonitoringStationID] [varchar](50) NOT NULL,
	[MonitoringStationName] [nvarchar](150) NOT NULL,
	[ContactPhoneNumber] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
	[DEX_ROW] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_MonitoringStations] PRIMARY KEY CLUSTERED 
(
	[MonitoringStationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MonitoringStations_ContactPhoneNumber' AND type = 'D')
ALTER TABLE [MAS].[MonitoringStations] ADD  CONSTRAINT [DF_MonitoringStations_ContactPhoneNumber]  DEFAULT ('[NOT YET SET]') FOR [ContactPhoneNumber]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MonitoringStations_IsActive' AND type = 'D')
ALTER TABLE [MAS].[MonitoringStations] ADD  CONSTRAINT [DF_MonitoringStations_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MonitoringStations_IsDeleted' AND type = 'D')
ALTER TABLE [MAS].[MonitoringStations] ADD  CONSTRAINT [DF_MonitoringStations_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MonitoringStations_ModifiedDate' AND type = 'D')
ALTER TABLE [MAS].[MonitoringStations] ADD  CONSTRAINT [DF_MonitoringStations_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MonitoringStations_ModifiedById' AND type = 'D')
ALTER TABLE [MAS].[MonitoringStations] ADD  CONSTRAINT [DF_MonitoringStations_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MonitoringStations_CreatedDate' AND type = 'D')
ALTER TABLE [MAS].[MonitoringStations] ADD  CONSTRAINT [DF_MonitoringStations_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MonitoringStations_CreatedById' AND type = 'D')
ALTER TABLE [MAS].[MonitoringStations] ADD  CONSTRAINT [DF_MonitoringStations_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MonitoringStations_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAS].[MonitoringStations] ADD  CONSTRAINT [DF_MonitoringStations_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO
