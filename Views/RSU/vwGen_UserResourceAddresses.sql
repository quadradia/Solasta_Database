/******************************************************************************
**		View: [RSU].[vwGen_UserResourceAddresses]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserResourceAddresses' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserResourceAddresses];
GO

CREATE   VIEW [RSU].[vwGen_UserResourceAddresses]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserResourceAddresses].[UserResourceAddressID]
		, [RSU].[UserResourceAddresses].[PoliticalStateId]
		, [RSU].[UserResourceAddresses].[PoliticalCountryId]
		, [RSU].[UserResourceAddresses].[PoliticalTimeZoneId]
		, [RSU].[UserResourceAddresses].[StreetAddress]
		, [RSU].[UserResourceAddresses].[StreetAddress2]
		, [RSU].[UserResourceAddresses].[City]
		, [RSU].[UserResourceAddresses].[PostalCode]
		, [RSU].[UserResourceAddresses].[PlusFour]
		, [RSU].[UserResourceAddresses].[IsActive]
		, [RSU].[UserResourceAddresses].[ModifiedDate]
		, [RSU].[UserResourceAddresses].[ModifiedById]
		, [RSU].[UserResourceAddresses].[CreatedDate]
		, [RSU].[UserResourceAddresses].[CreatedById]
	FROM
		[RSU].[UserResourceAddresses]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserResourceAddresses') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserResourceAddresses].CreatedById = AL.UserId))
			AND ([RSU].[UserResourceAddresses].IsDeleted = 'FALSE')

;
GO