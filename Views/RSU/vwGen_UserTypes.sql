/******************************************************************************
**		View: [RSU].[vwGen_UserTypes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserTypes' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserTypes];
GO

CREATE   VIEW [RSU].[vwGen_UserTypes]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserTypes].[UserTypeID]
		, [RSU].[UserTypes].[UserTypeTeamTypeId]
		, [RSU].[UserTypes].[UserTypeGroupId]
		, [RSU].[UserTypes].[UserTypeName]
		, [RSU].[UserTypes].[SecurityLevel]
		, [RSU].[UserTypes].[SpawnTypeId]
		, [RSU].[UserTypes].[RoleLocationId]
		, [RSU].[UserTypes].[ReportingLevel]
		, [RSU].[UserTypes].[IsCommissionable]
		, [RSU].[UserTypes].[IsActive]
		, [RSU].[UserTypes].[ModifiedDate]
		, [RSU].[UserTypes].[ModifiedById]
		, [RSU].[UserTypes].[CreatedDate]
		, [RSU].[UserTypes].[CreatedById]
	FROM
		[RSU].[UserTypes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserTypes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserTypes].CreatedById = AL.UserId))
			AND ([RSU].[UserTypes].IsDeleted = 'FALSE')

;
GO