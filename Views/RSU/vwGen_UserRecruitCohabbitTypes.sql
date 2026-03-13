/******************************************************************************
**		View: [RSU].[vwGen_UserRecruitCohabbitTypes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserRecruitCohabbitTypes' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserRecruitCohabbitTypes];
GO

CREATE   VIEW [RSU].[vwGen_UserRecruitCohabbitTypes]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserRecruitCohabbitTypes].[UserRecruitCohabbitTypeID]
		, [RSU].[UserRecruitCohabbitTypes].[UserRecruitCohabbitTypeName]
		, [RSU].[UserRecruitCohabbitTypes].[Rent]
		, [RSU].[UserRecruitCohabbitTypes].[Pet]
		, [RSU].[UserRecruitCohabbitTypes].[Utilities]
		, [RSU].[UserRecruitCohabbitTypes].[GasDeduction]
		, [RSU].[UserRecruitCohabbitTypes].[IsActive]
		, [RSU].[UserRecruitCohabbitTypes].[ModifiedDate]
		, [RSU].[UserRecruitCohabbitTypes].[ModifiedById]
		, [RSU].[UserRecruitCohabbitTypes].[CreatedDate]
		, [RSU].[UserRecruitCohabbitTypes].[CreatedById]
	FROM
		[RSU].[UserRecruitCohabbitTypes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserRecruitCohabbitTypes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserRecruitCohabbitTypes].CreatedById = AL.UserId))
			AND ([RSU].[UserRecruitCohabbitTypes].IsDeleted = 'FALSE')

;
GO