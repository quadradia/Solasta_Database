/******************************************************************************
**		View: [RSU].[vwGen_Seasons]
**		Desc:
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT *
FROM sys.views
WHERE name = 'vwGen_Seasons' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_Seasons];
GO

CREATE   VIEW [RSU].[vwGen_Seasons]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[Seasons].[SeasonID]
		, [RSU].[Seasons].[PreSeasonID]
		, [RSU].[Seasons].[DealerTenantId]
		, [RSU].[Seasons].[SeasonName]
		, [RSU].[Seasons].[StartDate]
		, [RSU].[Seasons].[EndDate]
		, [RSU].[Seasons].[ShowInHiringManager]
		, [RSU].[Seasons].[IsCurrent]
		, [RSU].[Seasons].[IsVisibleToRecruits]
		, [RSU].[Seasons].[IsInsideSales]
		, [RSU].[Seasons].[IsPreseason]
		, [RSU].[Seasons].[IsSummer]
		, [RSU].[Seasons].[IsExtended]
		, [RSU].[Seasons].[IsYearRound]
		, [RSU].[Seasons].[IsContractor]
		, [RSU].[Seasons].[IsDealer]
		, [RSU].[Seasons].[IsCurbNSign]
		, [RSU].[Seasons].[ExcellentCreditScoreThreshold]
		, [RSU].[Seasons].[PassCreditScoreThreshold]
		, [RSU].[Seasons].[SubCreditScoreThreshold]
		, [RSU].[Seasons].[IsActive]
		, [RSU].[Seasons].[ModifiedDate]
		, [RSU].[Seasons].[ModifiedById]
		, [RSU].[Seasons].[CreatedDate]
		, [RSU].[Seasons].[CreatedById]
	FROM
		[RSU].[Seasons]
		INNER JOIN (SELECT TOP 1
			*
		FROM [GEN].fxGetAccessLevel('Read', 'RSU','Seasons') AS ALIN
		WHERE (ALIN.ReadAccessId >= 1)
		ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[Seasons].CreatedById = AL.UserId))
			AND ([RSU].[Seasons].IsDeleted = 'FALSE')

;
GO