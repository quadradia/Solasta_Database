/******************************************************************************
**		View: [RSU].[vwGen_SeasonSummers]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_SeasonSummers' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_SeasonSummers];
GO

CREATE   VIEW [RSU].[vwGen_SeasonSummers]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[SeasonSummers].[SeasonSummerID]
		, [RSU].[SeasonSummers].[SeasonSummerName]
		, [RSU].[SeasonSummers].[IsActive]
		, [RSU].[SeasonSummers].[ModifiedDate]
		, [RSU].[SeasonSummers].[ModifiedById]
		, [RSU].[SeasonSummers].[CreatedDate]
		, [RSU].[SeasonSummers].[CreatedById]
	FROM
		[RSU].[SeasonSummers]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','SeasonSummers') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[SeasonSummers].CreatedById = AL.UserId))
			AND ([RSU].[SeasonSummers].IsDeleted = 'FALSE')

;
GO