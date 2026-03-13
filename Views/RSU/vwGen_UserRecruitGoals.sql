/******************************************************************************
**		View: [RSU].[vwGen_UserRecruitGoals]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserRecruitGoals' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserRecruitGoals];
GO

CREATE   VIEW [RSU].[vwGen_UserRecruitGoals]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserRecruitGoals].[UserRecruitGoalID]
		, [RSU].[UserRecruitGoals].[UserRecruitId]
		, [RSU].[UserRecruitGoals].[NetInstalls]
		, [RSU].[UserRecruitGoals].[ActionPlan]
		, [RSU].[UserRecruitGoals].[IsActive]
		, [RSU].[UserRecruitGoals].[ModifiedDate]
		, [RSU].[UserRecruitGoals].[ModifiedById]
		, [RSU].[UserRecruitGoals].[CreatedDate]
		, [RSU].[UserRecruitGoals].[CreatedById]
	FROM
		[RSU].[UserRecruitGoals]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserRecruitGoals') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserRecruitGoals].CreatedById = AL.UserId))
			AND ([RSU].[UserRecruitGoals].IsDeleted = 'FALSE')

;
GO