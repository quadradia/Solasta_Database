/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: PoliticalTimeZones
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PoliticalTimeZones' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
CREATE TABLE [MAC].[PoliticalTimeZones](
	[PoliticalTimeZoneID] [int] NOT NULL,
	[PoliticalTimeZoneName] [nvarchar](75) NOT NULL,
	[PresentationString] [nvarchar](75) NOT NULL,
	[MSTimeZoneName] [nvarchar](75) NOT NULL,
	[TimezoneOffset]  AS ([UTL].[fxGetTimeZoneOffSETByTimeZoneId]([RawTimeZoneOffset],[IsDLS],NULL)),
	[RawTimeZoneOffset] [smallint] NOT NULL,
	[TimeZoneOffsetMinutes]  AS ([UTL].[fxGetTimeZoneOffsetMinutesByTimeZoneId]([RawTimeZoneOffsetMinutes],[IsDLS],NULL)),
	[RawTimeZoneOffsetMinutes] [smallint] NOT NULL,
	[TimeZoneOffsetMilSeconds]  AS ([UTL].[fxGetTimeZoneOffsetMilSecondsByTimeZoneId]([RawTimeZoneOffsetMilSeconds],[IsDLS],NULL)),
	[RawTimeZoneOffsetMilSeconds] [int] NOT NULL,
	[SqlTimeZoneOffsetFormat]  AS ([UTL].[fxGetTZHTZMFormatFromTimeZoneMinutes]([RawTimeZoneOffsetMinutes],[IsDLS],NULL)),
	[IsDLS] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_PoliticalTimeZones] PRIMARY KEY CLUSTERED 
(
	[PoliticalTimeZoneID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalTimeZones_IsDLS' AND type = 'D')
ALTER TABLE [MAC].[PoliticalTimeZones] ADD  CONSTRAINT [DF_PoliticalTimeZones_IsDLS]  DEFAULT ((0)) FOR [IsDLS]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalTimeZones_IsActive' AND type = 'D')
ALTER TABLE [MAC].[PoliticalTimeZones] ADD  CONSTRAINT [DF_PoliticalTimeZones_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalTimeZones_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[PoliticalTimeZones] ADD  CONSTRAINT [DF_PoliticalTimeZones_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalTimeZones_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[PoliticalTimeZones] ADD  CONSTRAINT [DF_PoliticalTimeZones_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalTimeZones_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[PoliticalTimeZones] ADD  CONSTRAINT [DF_PoliticalTimeZones_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalTimeZones_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[PoliticalTimeZones] ADD  CONSTRAINT [DF_PoliticalTimeZones_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalTimeZones_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[PoliticalTimeZones] ADD  CONSTRAINT [DF_PoliticalTimeZones_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalTimeZones_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[PoliticalTimeZones] ADD  CONSTRAINT [DF_PoliticalTimeZones_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO
