/******************************************************************************
**		View: [RSU].[vwGen_TeamLocationStateMappings]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_TeamLocationStateMappings' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_TeamLocationStateMappings];
GO

CREATE   VIEW [RSU].[vwGen_TeamLocationStateMappings]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[TeamLocationStateMappings].[TeamLocationStateMappingID]
		, [RSU].[TeamLocationStateMappings].[TeamLocationId]
		, [RSU].[TeamLocationStateMappings].[SeasonId]
		, [RSU].[TeamLocationStateMappings].[PoliticalStateId]
		, [RSU].[TeamLocationStateMappings].[IsActive]
		, [RSU].[TeamLocationStateMappings].[ModifiedDate]
		, [RSU].[TeamLocationStateMappings].[ModifiedById]
		, [RSU].[TeamLocationStateMappings].[CreatedDate]
		, [RSU].[TeamLocationStateMappings].[CreatedById]
	FROM
		[RSU].[TeamLocationStateMappings]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','TeamLocationStateMappings') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[TeamLocationStateMappings].CreatedById = AL.UserId))
			AND ([RSU].[TeamLocationStateMappings].IsDeleted = 'FALSE')

;
GO