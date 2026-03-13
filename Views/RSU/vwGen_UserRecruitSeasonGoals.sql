/******************************************************************************
**		View: [RSU].[vwGen_UserRecruitSeasonGoals]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserRecruitSeasonGoals' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserRecruitSeasonGoals];
GO

CREATE   VIEW [RSU].[vwGen_UserRecruitSeasonGoals]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserRecruitSeasonGoals].[UserRecruitSeasonGoalID]
		, [RSU].[UserRecruitSeasonGoals].[UserRecruitId]
		, [RSU].[UserRecruitSeasonGoals].[TotalInstalls]
		, [RSU].[UserRecruitSeasonGoals].[CancelPercent]
		, [RSU].[UserRecruitSeasonGoals].[SubPercent]
		, [RSU].[UserRecruitSeasonGoals].[PassPercent]
		, [RSU].[UserRecruitSeasonGoals].[PastDuePercent]
		, [RSU].[UserRecruitSeasonGoals].[BackendHoldPercent]
		, [RSU].[UserRecruitSeasonGoals].[ActivationWaivePercent]
		, [RSU].[UserRecruitSeasonGoals].[CommercialPercent]
		, [RSU].[UserRecruitSeasonGoals].[PointBank]
		, [RSU].[UserRecruitSeasonGoals].[IsActive]
		, [RSU].[UserRecruitSeasonGoals].[ModifiedDate]
		, [RSU].[UserRecruitSeasonGoals].[ModifiedById]
		, [RSU].[UserRecruitSeasonGoals].[CreatedDate]
		, [RSU].[UserRecruitSeasonGoals].[CreatedById]
	FROM
		[RSU].[UserRecruitSeasonGoals]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserRecruitSeasonGoals') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserRecruitSeasonGoals].CreatedById = AL.UserId))
			AND ([RSU].[UserRecruitSeasonGoals].IsDeleted = 'FALSE')

;
GO