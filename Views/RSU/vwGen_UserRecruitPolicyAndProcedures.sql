/******************************************************************************
**		View: [RSU].[vwGen_UserRecruitPolicyAndProcedures]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserRecruitPolicyAndProcedures' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserRecruitPolicyAndProcedures];
GO

CREATE   VIEW [RSU].[vwGen_UserRecruitPolicyAndProcedures]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserRecruitPolicyAndProcedures].[UserRecruitPolicyAndProcedureID]
		, [RSU].[UserRecruitPolicyAndProcedures].[UserRecruitId]
		, [RSU].[UserRecruitPolicyAndProcedures].[IsActive]
		, [RSU].[UserRecruitPolicyAndProcedures].[ModifiedDate]
		, [RSU].[UserRecruitPolicyAndProcedures].[ModifiedById]
		, [RSU].[UserRecruitPolicyAndProcedures].[CreatedDate]
		, [RSU].[UserRecruitPolicyAndProcedures].[CreatedById]
	FROM
		[RSU].[UserRecruitPolicyAndProcedures]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserRecruitPolicyAndProcedures') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserRecruitPolicyAndProcedures].CreatedById = AL.UserId))
			AND ([RSU].[UserRecruitPolicyAndProcedures].IsDeleted = 'FALSE')

;
GO