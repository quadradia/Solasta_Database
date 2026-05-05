DROP PROCEDURE IF EXISTS [RSU].[spUserResourceBySesonId];
GO

/******************************************************************************
**		File: spUserResourceBySesonId.sql
**		Name: spUserResourceBySesonId
**		Desc:
**
**		This template can be customized:
**
**		Return values:
**
**		Called by:
**
**		Parameters:
**		Input							Output
**     ----------						-----------
**
**		Auth: Andres Sosa
**		Date: 09/01/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	09/01/2017	Andres Sosa		Created By
**
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceBySesonId]
	(
	@SeasonId INT = NULL
	,
	@UserTypeGroupId VARCHAR(20) = NULL
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
	SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerTenantId
	FROM [ACC].[fxGetContextUserTable]();

	BEGIN TRY
		-- ** STATEMENT
		WITH
		OnBoardStatusCTE
		AS
		(
			SELECT
				UR.UserRecruitID
				, URS.UserResourceID
				, UR.SeasonId
				, UT.UserTypeName
				, UTTT.UserTypeTeamTypeName
				, UTG.UserTypeGroupName
				, UT.UserTypeGroupId
				, URS.GPEmployeeId
				, URS.FullName
			FROM
				[RSU].[UserRecruits] AS UR WITH(NOLOCK)
				INNER JOIN [RSU].[Seasons] AS S WITH(NOLOCK)
				ON
					(S.SeasonID = @SeasonId)
					AND (S.DealerTenantId = @DealerId)
					AND (S.SeasonID = UR.SeasonId)
					AND (UR.IsActive = 'True')
					AND (UR.IsDeleted = 'False')
				INNER JOIN [RSU].[UserResources] AS URS WITH(NOLOCK)
				ON
					(URS.UserResourceID = UR.UserResourceId)
					AND (URS.IsActive = 'True')
					AND (URS.IsDeleted = 'False')
				INNER JOIN [RSU].[UserTypes] AS UT WITH(NOLOCK)
				ON
					(UT.UserTypeID = UR.UserTypeId)
				INNER JOIN [RSU].[UserTypeTeamTypes] AS UTTT WITH(NOLOCK)
				ON
					(UTTT.UserTypeTeamTypeID = UT.UserTypeTeamTypeId)
				INNER JOIN [RSU].[UserTypeGroups] AS UTG WITH(NOLOCK)
				ON
					(UTG.UserTypeGroupID = UT.UserTypeGroupId)
					AND (@UserTypeGroupId IS NULL OR UT.UserTypeGroupId = @UserTypeGroupId)
		)
	SELECT (
			SELECT
			RT.UserRecruitID AS id
				, RT.UserResourceID AS userResourceId
				, RT.SeasonId AS seasonId
				, RT.UserTypeName AS userTypeName
				, RT.UserTypeTeamTypeName AS userTypeTeamTypeName
				, RT.UserTypeGroupId AS userTypeGroupId
				, RT.UserTypeGroupName AS userTypeGroupName
				, RT.GPEmployeeId AS gPEmployeeId
				, RT.FullName + ' (' + RT.GPEmployeeId + ')' AS fullName
		FROM OnBoardStatusCTE AS RT WITH(NOLOCK)
		ORDER BY
				RT.FullName
		FOR JSON PATH) AS JsonOutPutMethod
		;

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
