/******************************************************************************
**		View: [RSU].[vwGen_TeamLocations]
**		Desc:
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT *
FROM sys.views
WHERE name = 'vwGen_TeamLocations' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_TeamLocations];
GO

CREATE   VIEW [RSU].[vwGen_TeamLocations]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[TeamLocations].[TeamLocationID]
		, [RSU].[TeamLocations].[DealerTenantId]
		, [RSU].[TeamLocations].[CreatedFromTeamLocationId]
		, [RSU].[TeamLocations].[SeasonId]
		, [RSU].[TeamLocations].[PoliticalStateId]
		, [RSU].[TeamLocations].[PoliticalTimeZoneId]
		, [RSU].[TeamLocations].[GpSalesTerritoryId]
		, [RSU].[TeamLocations].[IvOfficeId]
		, [RSU].[TeamLocations].[AeOfficeId]
		, [RSU].[TeamLocations].[MarketId]
		, [RSU].[TeamLocations].[TeamLocationName]
		, [RSU].[TeamLocations].[Description]
		, [RSU].[TeamLocations].[City]
		, [RSU].[TeamLocations].[SiteCodeID]
		, [RSU].[TeamLocations].[IsActive]
		, [RSU].[TeamLocations].[ModifiedDate]
		, [RSU].[TeamLocations].[ModifiedById]
		, [RSU].[TeamLocations].[CreatedDate]
		, [RSU].[TeamLocations].[CreatedById]
	FROM
		[RSU].[TeamLocations]
		INNER JOIN (SELECT TOP 1
			*
		FROM [GEN].fxGetAccessLevel('Read', 'RSU','TeamLocations') AS ALIN
		WHERE (ALIN.ReadAccessId >= 1)
		ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[TeamLocations].CreatedById = AL.UserId))
			AND ([RSU].[TeamLocations].IsDeleted = 'FALSE')

;
GO