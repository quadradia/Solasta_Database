/******************************************************************************
**		View: [RSU].[vwGen_UserTypeGroups]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserTypeGroups' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserTypeGroups];
GO

CREATE   VIEW [RSU].[vwGen_UserTypeGroups]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserTypeGroups].[UserTypeGroupID]
		, [RSU].[UserTypeGroups].[UserTypeGroupName]
		, [RSU].[UserTypeGroups].[IsActive]
		, [RSU].[UserTypeGroups].[ModifiedDate]
		, [RSU].[UserTypeGroups].[ModifiedById]
		, [RSU].[UserTypeGroups].[CreatedDate]
		, [RSU].[UserTypeGroups].[CreatedById]
	FROM
		[RSU].[UserTypeGroups]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserTypeGroups') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserTypeGroups].CreatedById = AL.UserId))
			AND ([RSU].[UserTypeGroups].IsDeleted = 'FALSE')

;
GO