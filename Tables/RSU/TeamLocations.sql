/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: TeamLocations
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TeamLocations' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[TeamLocations](
	[TeamLocationID] [int] IDENTITY(1,1) NOT NULL,
	[DealerId] [int] NOT NULL,
	[CreatedFromTeamLocationId] [int] NULL,
	[SeasonId] [int] NOT NULL,
	[PoliticalStateId] [varchar](4) NOT NULL,
	[PoliticalTimeZoneId] [int] NOT NULL,
	[GpSalesTerritoryId] [varchar](15) NULL,
	[IvOfficeId] [int] NULL,
	[AeOfficeId] [int] NULL,
	[MarketId] [int] NULL,
	[TeamLocationName] [nvarchar](50) NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[City] [varchar](50) NOT NULL,
	[SiteCodeID] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_TeamLocations] PRIMARY KEY CLUSTERED 
(
	[TeamLocationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocations_IsActive' AND type = 'D')
ALTER TABLE [RSU].[TeamLocations] ADD  CONSTRAINT [DF_TeamLocations_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocations_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[TeamLocations] ADD  CONSTRAINT [DF_TeamLocations_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocations_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[TeamLocations] ADD  CONSTRAINT [DF_TeamLocations_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocations_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[TeamLocations] ADD  CONSTRAINT [DF_TeamLocations_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocations_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[TeamLocations] ADD  CONSTRAINT [DF_TeamLocations_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocations_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[TeamLocations] ADD  CONSTRAINT [DF_TeamLocations_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TeamLocations_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [RSU].[TeamLocations] ADD  CONSTRAINT [DF_TeamLocations_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocations_Dealers')
ALTER TABLE [RSU].[TeamLocations]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocations_Dealers] FOREIGN KEY([DealerId])
REFERENCES [ACC].[Dealers] ([DealerID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocations_PoliticalStates')
ALTER TABLE [RSU].[TeamLocations]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocations_PoliticalStates] FOREIGN KEY([PoliticalStateId])
REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocations_PoliticalTimeZones')
ALTER TABLE [RSU].[TeamLocations]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocations_PoliticalTimeZones] FOREIGN KEY([PoliticalTimeZoneId])
REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TeamLocations_Seasons')
ALTER TABLE [RSU].[TeamLocations]  WITH CHECK ADD  CONSTRAINT [FK_TeamLocations_Seasons] FOREIGN KEY([SeasonId])
REFERENCES [RSU].[Seasons] ([SeasonID])
GO

ALTER TABLE [RSU].[TeamLocations] CHECK CONSTRAINT [FK_TeamLocations_Dealers]
GO

ALTER TABLE [RSU].[TeamLocations] CHECK CONSTRAINT [FK_TeamLocations_PoliticalStates]
GO

ALTER TABLE [RSU].[TeamLocations] CHECK CONSTRAINT [FK_TeamLocations_PoliticalTimeZones]
GO

ALTER TABLE [RSU].[TeamLocations] CHECK CONSTRAINT [FK_TeamLocations_Seasons]
GO
