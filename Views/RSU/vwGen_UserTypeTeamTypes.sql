/******************************************************************************
**		View: [RSU].[vwGen_UserTypeTeamTypes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserTypeTeamTypes' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserTypeTeamTypes];
GO

CREATE   VIEW [RSU].[vwGen_UserTypeTeamTypes]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserTypeTeamTypes].[UserTypeTeamTypeID]
		, [RSU].[UserTypeTeamTypes].[UserTypeTeamTypeName]
		, [RSU].[UserTypeTeamTypes].[ParentId]
		, [RSU].[UserTypeTeamTypes].[IsActive]
		, [RSU].[UserTypeTeamTypes].[CreatedById]
		, [RSU].[UserTypeTeamTypes].[CreatedDate]
		, [RSU].[UserTypeTeamTypes].[ModifiedById]
		, [RSU].[UserTypeTeamTypes].[ModifiedDate]
	FROM
		[RSU].[UserTypeTeamTypes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserTypeTeamTypes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[UserTypeTeamTypes].IsDeleted = 'FALSE')

;
GO