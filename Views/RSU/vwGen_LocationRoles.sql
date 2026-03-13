/******************************************************************************
**		View: [RSU].[vwGen_LocationRoles]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_LocationRoles' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_LocationRoles];
GO

CREATE   VIEW [RSU].[vwGen_LocationRoles]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[LocationRoles].[LocationRoleID]
		, [RSU].[LocationRoles].[LocationRoleName]
		, [RSU].[LocationRoles].[IsActive]
		, [RSU].[LocationRoles].[ModifiedDate]
		, [RSU].[LocationRoles].[ModifiedById]
		, [RSU].[LocationRoles].[CreatedDate]
		, [RSU].[LocationRoles].[CreatedById]
	FROM
		[RSU].[LocationRoles]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','LocationRoles') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[LocationRoles].CreatedById = AL.UserId))
			AND ([RSU].[LocationRoles].IsDeleted = 'FALSE')

;
GO