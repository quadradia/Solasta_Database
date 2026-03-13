/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: SeasonSummerSeasonMaps
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SeasonSummerSeasonMaps' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[SeasonSummerSeasonMaps](
	[SeasonSummerID] [int] NOT NULL,
	[SeasonID] [int] NOT NULL,
 CONSTRAINT [PK_SeasonSummerSeason_Map] PRIMARY KEY CLUSTERED 
(
	[SeasonSummerID] ASC,
	[SeasonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_SeasonSummerSeason_Map_Season')
ALTER TABLE [RSU].[SeasonSummerSeasonMaps]  WITH CHECK ADD  CONSTRAINT [FK_SeasonSummerSeason_Map_Season] FOREIGN KEY([SeasonID])
REFERENCES [RSU].[Seasons] ([SeasonID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_SeasonSummerSeason_Map_SeasonSummers')
ALTER TABLE [RSU].[SeasonSummerSeasonMaps]  WITH CHECK ADD  CONSTRAINT [FK_SeasonSummerSeason_Map_SeasonSummers] FOREIGN KEY([SeasonSummerID])
REFERENCES [RSU].[SeasonSummers] ([SeasonSummerID])
GO

ALTER TABLE [RSU].[SeasonSummerSeasonMaps] CHECK CONSTRAINT [FK_SeasonSummerSeason_Map_Season]
GO

ALTER TABLE [RSU].[SeasonSummerSeasonMaps] CHECK CONSTRAINT [FK_SeasonSummerSeason_Map_SeasonSummers]
GO
