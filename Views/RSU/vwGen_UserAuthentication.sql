/******************************************************************************
**		View: [RSU].[vwGen_UserAuthentication]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserAuthentication' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserAuthentication];
GO

CREATE   VIEW [RSU].[vwGen_UserAuthentication]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserAuthentication].[UserAuthenticationID]
		, [RSU].[UserAuthentication].[UserResourceId]
		, [RSU].[UserAuthentication].[TokenId]
		, [RSU].[UserAuthentication].[Username]
		, [RSU].[UserAuthentication].[Password]
		, [RSU].[UserAuthentication].[IPAddress]
		, [RSU].[UserAuthentication].[Successfull]
		, [RSU].[UserAuthentication].[Message]
		, [RSU].[UserAuthentication].[IsActive]
		, [RSU].[UserAuthentication].[CreatedById]
		, [RSU].[UserAuthentication].[CreatedDate]
		, [RSU].[UserAuthentication].[ModifiedById]
		, [RSU].[UserAuthentication].[ModifiedDate]
	FROM
		[RSU].[UserAuthentication]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserAuthentication') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[UserAuthentication].IsDeleted = 'FALSE')

;
GO