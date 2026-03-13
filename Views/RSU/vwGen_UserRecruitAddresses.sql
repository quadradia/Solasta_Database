/******************************************************************************
**		View: [RSU].[vwGen_UserRecruitAddresses]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserRecruitAddresses' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserRecruitAddresses];
GO

CREATE   VIEW [RSU].[vwGen_UserRecruitAddresses]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserRecruitAddresses].[UserRecruitAddressID]
		, [RSU].[UserRecruitAddresses].[PoliticalStateId]
		, [RSU].[UserRecruitAddresses].[PoliticalCountryId]
		, [RSU].[UserRecruitAddresses].[PoliticalTimeZoneId]
		, [RSU].[UserRecruitAddresses].[StreetAddress]
		, [RSU].[UserRecruitAddresses].[StreetAddress2]
		, [RSU].[UserRecruitAddresses].[City]
		, [RSU].[UserRecruitAddresses].[PostalCode]
		, [RSU].[UserRecruitAddresses].[PlusFour]
		, [RSU].[UserRecruitAddresses].[IsActive]
		, [RSU].[UserRecruitAddresses].[ModifiedDate]
		, [RSU].[UserRecruitAddresses].[ModifiedById]
		, [RSU].[UserRecruitAddresses].[CreatedDate]
		, [RSU].[UserRecruitAddresses].[CreatedById]
	FROM
		[RSU].[UserRecruitAddresses]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserRecruitAddresses') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserRecruitAddresses].CreatedById = AL.UserId))
			AND ([RSU].[UserRecruitAddresses].IsDeleted = 'FALSE')

;
GO