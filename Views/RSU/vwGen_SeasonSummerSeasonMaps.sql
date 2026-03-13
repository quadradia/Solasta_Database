/******************************************************************************
**		View: [RSU].[vwGen_SeasonSummerSeasonMaps]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_SeasonSummerSeasonMaps' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_SeasonSummerSeasonMaps];
GO

CREATE   VIEW [RSU].[vwGen_SeasonSummerSeasonMaps]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[SeasonSummerSeasonMaps].[SeasonSummerID]
		, [RSU].[SeasonSummerSeasonMaps].[SeasonID]
	FROM
		[RSU].[SeasonSummerSeasonMaps]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','SeasonSummerSeasonMaps') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))

;
GO