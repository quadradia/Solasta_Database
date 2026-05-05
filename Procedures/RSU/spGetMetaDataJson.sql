DROP PROCEDURE IF EXISTS [RSU].[spGetMetaDataJson];
GO

/******************************************************************************
**		File: spGetMetaDataJson.sql
**		Name: spGetMetaDataJson
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
**		Date: 08/30/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	08/30/2017	Andres Sosa		Created By
**
*******************************************************************************/
CREATE   Procedure [RSU].[spGetMetaDataJson]
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
		UserEmployeeTypesCTE
		AS
		(
			SELECT
				UTTT.UserEmployeeTypeID AS id
                , UTTT.UserEmployeeTypeName AS userEmployeeTypeName
                , UTTT.IsActive AS isActive
                , UTTT.IsDeleted AS isDeleted
			FROM
				[RSU].[UserEmployeeTypes] AS UTTT WITH(NOLOCK)
		)
		--SELECT * FROM UserTypeTeamTypeCTE;
		,
		UserTypesCte
		AS
		(
			SELECT
				UT.UserTypeID AS id
                , UT.UserTypeTeamTypeId AS userTypeTeamTypeId
                , UT.UserTypeGroupId AS userTypeGroupId
                , UT.UserTypeName AS userTypeName
                , UT.SecurityLevel AS securityLevel
                , UT.SpawnTypeID AS spawnTypeId
                , UT.RoleLocationID AS roleLocationId
                , UT.ReportingLevel AS reportingLevel
                , UT.IsCommissionable AS isCommissionable
                , UT.IsActive AS isActive
                , UT.IsDeleted AS isDeleted
			FROM
				[RSU].[UserTypes] AS UT
		)
		--SELECT * FROM UserTypesCte;
		,
		UserTypeGroupsCte
		AS
		(
			SELECT
				UTG.UserTypeGroupID AS id
                , UTG.UserTypeGroupName AS userTypeGroupName
                , UTG.IsActive AS isActive
                , UTG.IsDeleted AS isDeleted
			FROM
				[RSU].[UserTypeGroups] AS UTG WITH(NOLOCK)
		)
		--SELECT * FROM UserTypeGroupsCte;
		,
		UserTypeTeamTypesCte
		AS
		(
			SELECT
				UT.UserTypeTeamTypeID AS id
                , UT.UserTypeTeamTypeName AS userTypeTeamTypeName
                , UT.ParentId AS parentId
                , UT.IsActive AS isActive
                , UT.IsDeleted AS isDeleted
			FROM
				[RSU].[UserTypeTeamTypes] AS UT WITH(NOLOCK)
		)
		--SELECT * FROM UserTypeTeamTypesCte;
		,
		SeasonsCte
		AS
		(
			SELECT
				S.SeasonID AS id
                , S.PreSeasonID AS preSeasonId
                , S.SeasonName AS seasonName
                , S.StartDate AS startDate
                , S.EndDate AS endDate
                , S.ShowInHiringManager AS showInHiringManager
                , S.IsCurrent AS isCurrent
                , S.IsVisibleToRecruits AS iIsVisibleToRecruits
                , S.IsInsideSales AS isInsideSales
                , S.IsPreseason AS isPreseason
                , S.IsSummer AS isSummer
                , S.IsExtended AS isExtended
                , S.IsYearRound AS isYearRound
                , S.IsContractor AS isContractor
                , S.IsDealer AS isDealer
                , S.ExcellentCreditScoreThreshold AS excellentCreditScoreThreshold
                , S.PassCreditScoreThreshold AS passCreditScoreThreshold
                , S.SubCreditScoreThreshold AS subCreditScoreThreshold
                , S.IsActive AS isActive
			FROM
				[RSU].[Seasons] AS S WITH(NOLOCK)
			WHERE
				(S.DealerTenantId = @DealerId)
				AND (S.IsDeleted = 'False')
		)
	SELECT
		(SELECT
			(SELECT *
			FROM UserEmployeeTypesCTE
			ORDER BY UserEmployeeTypesCTE.userEmployeeTypeName
			FOR JSON PATH) AS [userEmployeeTypes]
				, (SELECT *
			FROM UserTypesCte
			ORDER BY UserTypesCte.userTypeName
			FOR JSON PATH) AS [userTypes]
				, (SELECT *
			FROM UserTypeGroupsCte
			ORDER BY UserTypeGroupsCte.userTypeGroupName
			FOR JSON PATH) AS [userTypeGroups]
				, (SELECT *
			FROM userTypeTeamTypesCte
			ORDER BY UserTypeTeamTypesCte.userTypeTeamTypeName
			FOR JSON PATH) AS [userTypeTeamTypes]
				, (SELECT *
			FROM SeasonsCte
			ORDER BY SeasonsCte.seasonName
			FOR JSON PATH) AS [seasons]
		FOR JSON PATH) AS [JsonOutPutMethod];
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
