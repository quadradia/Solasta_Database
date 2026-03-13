/******************************************************************************
**		View: [RSU].[vwGen_Terminations]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_Terminations' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_Terminations];
GO

CREATE   VIEW [RSU].[vwGen_Terminations]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[Terminations].[TerminationID]
		, [RSU].[Terminations].[UserRecruitId]
		, [RSU].[Terminations].[TerminationCategoryId]
		, [RSU].[Terminations].[TeamLocationId]
		, [RSU].[Terminations].[LastDateWorked]
		, [RSU].[Terminations].[Explanation]
		, [RSU].[Terminations].[NoticeGiven]
		, [RSU].[Terminations].[IntendedLastDay]
		, [RSU].[Terminations].[IsActive]
		, [RSU].[Terminations].[CreatedById]
		, [RSU].[Terminations].[CreatedDate]
		, [RSU].[Terminations].[ModifiedById]
		, [RSU].[Terminations].[ModifiedDate]
	FROM
		[RSU].[Terminations]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','Terminations') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[Terminations].IsDeleted = 'FALSE')

;
GO