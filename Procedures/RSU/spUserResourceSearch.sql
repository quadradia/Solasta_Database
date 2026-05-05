DROP PROCEDURE IF EXISTS [RSU].[spUserResourceSearch];
GO

/******************************************************************************
**		File: spAutoGenUtilDropGenSPROCS.sql
**		Name: spAutoGenUtilDropGenSPROCS
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
**		Date: 11/15/2016
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	11/15/2016	Andres Sosa		Created By
**
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceSearch]
	(
	@GpEmployeeId NVARCHAR(25)
	,
	@UserTypeGroupId VARCHAR(20)
	,
	@DealerId INT = 2000
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** DECLARATIONS */
	DECLARE @UserResourceID INT = (SELECT TOP(1)
		UserResourceID
	FROM [RSU].[UserResources]
	WHERE (GPEmployeeId = @GpEmployeeId) AND (DealerTenantId = @DealerId) AND (IsDeleted = 'False')
	ORDER BY GPEmployeeId)
		, @UserGUID NVARCHAR(MAX);

	/** CHECK Dealer Scope */
	IF (NOT EXISTS(SELECT TOP(1)
		1
	FROM [UTL].[fxValidateRequestByDealerId](@DealerId))) BEGIN
		--** Check that there is a user
		SELECT @UserGUID = UserGuidIDMasked
		FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50200]:Invalid DealerId on UserId "%s" request on SPROC "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'RSU.spUserResourceSearch');

		RETURN -1;
	END

	-- ** Check for Sales
	SELECT
		(SELECT TOP(1)
			RU.UserResourceID
			, RU.UserId AS userId
			, RU.GPEmployeeId AS gpEmployeeId
			, RU.FullName AS fullName
			, RU.PhoneCell AS phoneMobile
			, ISNULL(RR.UserRecruitID, 0) AS userRecruitId
			, ISNULL(RR.SeasonId, 0) AS seasonId
			, S.SeasonName
			, (SELECT DISTINCT
				SC.SeasonID AS id
				, SC.SeasonID AS seasonID
				, UTC.UserTypeGroupId
				, SC.PreSeasonID AS preSeasonID
				, SC.DealerTenantId AS dealerId
				, SC.SeasonName AS seasonName
				, SC.StartDate AS startDate
				, SC.EndDate AS endDate
				, SC.ShowInHiringManager AS showInHiringManager
				, SC.IsCurrent AS isCurrent
				, SC.IsVisibleToRecruits AS isVisibleToRecruits
				, SC.IsInsideSales AS isInsideSales
				, SC.IsPreseason AS isPreseason
				, SC.IsSummer AS isSummer
				, SC.IsExtended AS isExtended
				, SC.IsYearRound AS isYearRound
				, SC.IsContractor AS isContractor
				, SC.IsDealer AS isDealer
				, SC.ExcellentCreditScoreThreshold AS excellentCreditScoreThreshold
				, SC.PassCreditScoreThreshold AS passCreditScoreThreshold
				, SC.SubCreditScoreThreshold AS subCreditScoreThreshold
				, URC.IsActive AS isActive
				, URC.IsDeleted AS isDeleted
				, SC.ModifiedDate AS modifiedDate
				, SC.ModifiedById AS modifiedById
				, SC.CreatedDate AS createdDate
				, SC.CreatedById AS createdById
			FROM
				[RSU].[UserRecruits] AS URC WITH(NOLOCK)
				INNER JOIN [RSU].[UserTypes] AS UTC WITH (NOLOCK)
				ON
						(URC.UserResourceId = RU.UserResourceID)
					AND (UTC.UserTypeID = URC.UserTypeId)
					AND (URC.IsDeleted = 'False')
					AND (@UserTypeGroupId IS NULL OR UTC.UserTypeGroupId = @UserTypeGroupId)
				INNER JOIN [RSU].[Seasons] AS SC WITH(NOLOCK)
				ON
						(SC.SeasonID = URC.SeasonId)
			--WHERE (S.SeasonID = RR.SeasonId)
			FOR JSON PATH) AS [contracts]
		FROM
			[RSU].[UserResources] AS RU WITH (NOLOCK)
			INNER JOIN [ACC].[Users] AS ACCU WITH(NOLOCK)
			ON
				(ACCU.UserID = RU.UserId)
				AND (ACCU.IsActive = 'True' AND ACCU.IsDeleted = 'False')
			INNER JOIN [RSU].[UserRecruits] AS RR WITH (NOLOCK)
			ON
				(RR.UserResourceId = RU.UserResourceID)
				AND (RU.IsActive = 'True' AND RU.IsDeleted = 'False')
				AND (RR.IsActive = 'True' AND RR.IsDeleted = 'False')
				AND (RU.DealerTenantId = @DealerId)
				AND (RU.UserResourceID = @UserResourceID)
			INNER JOIN [RSU].[UserTypes] AS UT WITH (NOLOCK)
			ON
				(UT.UserTypeID = RR.UserTypeId)
				AND (@UserTypeGroupId IS NULL OR UT.UserTypeGroupId = @UserTypeGroupId)
			LEFT OUTER JOIN [RSU].[Seasons] AS S WITH (NOLOCK)
			ON
				(S.SeasonID = RR.SeasonId)
		FOR JSON PATH) AS [JsonOutPutMethod];
END

GO
