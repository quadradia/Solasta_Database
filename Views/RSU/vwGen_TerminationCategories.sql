/******************************************************************************
**		View: [RSU].[vwGen_TerminationCategories]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_TerminationCategories' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_TerminationCategories];
GO

CREATE   VIEW [RSU].[vwGen_TerminationCategories]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[TerminationCategories].[TerminationCategoryID]
		, [RSU].[TerminationCategories].[TerminationTypeId]
		, [RSU].[TerminationCategories].[TerminationCategoryName]
		, [RSU].[TerminationCategories].[RequiresLastDateWorked]
		, [RSU].[TerminationCategories].[RequiresExplanation]
		, [RSU].[TerminationCategories].[RequiresNoticeGiven]
		, [RSU].[TerminationCategories].[RequiresIntendedLastDay]
		, [RSU].[TerminationCategories].[RequiresNewTeamLocationId]
		, [RSU].[TerminationCategories].[ExplanationPrompt]
		, [RSU].[TerminationCategories].[IsActive]
		, [RSU].[TerminationCategories].[CreatedById]
		, [RSU].[TerminationCategories].[CreatedDate]
		, [RSU].[TerminationCategories].[ModifiedById]
		, [RSU].[TerminationCategories].[ModifiedDate]
	FROM
		[RSU].[TerminationCategories]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','TerminationCategories') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[TerminationCategories].IsDeleted = 'FALSE')

;
GO