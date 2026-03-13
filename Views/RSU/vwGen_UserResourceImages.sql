/******************************************************************************
**		View: [RSU].[vwGen_UserResourceImages]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserResourceImages' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserResourceImages];
GO

CREATE   VIEW [RSU].[vwGen_UserResourceImages]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserResourceImages].[UserResourceImageID]
		, [RSU].[UserResourceImages].[UserResourceId]
		, [RSU].[UserResourceImages].[ImageTypeId]
		, [RSU].[UserResourceImages].[Size]
		, [RSU].[UserResourceImages].[FileName]
		, [RSU].[UserResourceImages].[Image]
		, [RSU].[UserResourceImages].[IsActive]
		, [RSU].[UserResourceImages].[ModifiedDate]
		, [RSU].[UserResourceImages].[ModifiedById]
		, [RSU].[UserResourceImages].[CreatedDate]
		, [RSU].[UserResourceImages].[CreatedById]
	FROM
		[RSU].[UserResourceImages]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserResourceImages') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserResourceImages].CreatedById = AL.UserId))
			AND ([RSU].[UserResourceImages].IsDeleted = 'FALSE')

;
GO