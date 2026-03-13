/******************************************************************************
**		View: [RSU].[vwGen_Teams]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_Teams' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_Teams];
GO

CREATE   VIEW [RSU].[vwGen_Teams]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[Teams].[TeamID]
		, [RSU].[Teams].[Description]
		, [RSU].[Teams].[CreatedFromTeamId]
		, [RSU].[Teams].[TeamLocationId]
		, [RSU].[Teams].[RoleLocationId]
		, [RSU].[Teams].[RegionalManagerRecruitId]
		, [RSU].[Teams].[IsActive]
		, [RSU].[Teams].[ModifiedDate]
		, [RSU].[Teams].[ModifiedById]
		, [RSU].[Teams].[CreatedDate]
		, [RSU].[Teams].[CreatedById]
	FROM
		[RSU].[Teams]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','Teams') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[Teams].CreatedById = AL.UserId))
			AND ([RSU].[Teams].IsDeleted = 'FALSE')

;
GO