/******************************************************************************
**		View: [RSU].[vwGen_SiteCodes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_SiteCodes' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_SiteCodes];
GO

CREATE   VIEW [RSU].[vwGen_SiteCodes]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[SiteCodes].[SiteCodeID]
		, [RSU].[SiteCodes].[PoliticalStateId]
		, [RSU].[SiteCodes].[SiteCodeValue]
		, [RSU].[SiteCodes].[SiteCodeDescription]
		, [RSU].[SiteCodes].[IsDefault]
		, [RSU].[SiteCodes].[IsActive]
		, [RSU].[SiteCodes].[CreatedById]
		, [RSU].[SiteCodes].[CreatedDate]
		, [RSU].[SiteCodes].[ModifiedById]
		, [RSU].[SiteCodes].[ModifiedDate]
	FROM
		[RSU].[SiteCodes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','SiteCodes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[SiteCodes].IsDeleted = 'FALSE')

;
GO