/******************************************************************************
**		View: [RSU].[vwGen_TeamLocationRosters]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_TeamLocationRosters' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_TeamLocationRosters];
GO

CREATE   VIEW [RSU].[vwGen_TeamLocationRosters]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[TeamLocationRosters].[TeamLocationRosterID]
		, [RSU].[TeamLocationRosters].[TeamLocationId]
		, [RSU].[TeamLocationRosters].[TerminationReasonId]
		, [RSU].[TeamLocationRosters].[UserRecruitId]
		, [RSU].[TeamLocationRosters].[ArrivalDate]
		, [RSU].[TeamLocationRosters].[QuitDate]
		, [RSU].[TeamLocationRosters].[Reason]
		, [RSU].[TeamLocationRosters].[TerminationType]
		, [RSU].[TeamLocationRosters].[Note]
		, [RSU].[TeamLocationRosters].[IsActive]
		, [RSU].[TeamLocationRosters].[ModifiedDate]
		, [RSU].[TeamLocationRosters].[ModifiedById]
		, [RSU].[TeamLocationRosters].[CreatedDate]
		, [RSU].[TeamLocationRosters].[CreatedById]
	FROM
		[RSU].[TeamLocationRosters]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','TeamLocationRosters') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[TeamLocationRosters].CreatedById = AL.UserId))
			AND ([RSU].[TeamLocationRosters].IsDeleted = 'FALSE')

;
GO