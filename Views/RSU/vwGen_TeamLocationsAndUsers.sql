/******************************************************************************
**		View: [RSU].[vwGen_TeamLocationsAndUsers]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_TeamLocationsAndUsers' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_TeamLocationsAndUsers];
GO

CREATE   VIEW [RSU].[vwGen_TeamLocationsAndUsers]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[TeamLocationsAndUsers].[TeamLocationsAndUserID]
		, [RSU].[TeamLocationsAndUsers].[TeamLocationId]
		, [RSU].[TeamLocationsAndUsers].[UserRecruitId]
		, [RSU].[TeamLocationsAndUsers].[LocationRoleId]
		, [RSU].[TeamLocationsAndUsers].[IsActive]
		, [RSU].[TeamLocationsAndUsers].[ModifiedDate]
		, [RSU].[TeamLocationsAndUsers].[ModifiedById]
		, [RSU].[TeamLocationsAndUsers].[CreatedDate]
		, [RSU].[TeamLocationsAndUsers].[CreatedById]
	FROM
		[RSU].[TeamLocationsAndUsers]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','TeamLocationsAndUsers') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[TeamLocationsAndUsers].CreatedById = AL.UserId))
			AND ([RSU].[TeamLocationsAndUsers].IsDeleted = 'FALSE')

;
GO