/******************************************************************************
**		File: fxGetSeasonByRecruitIdJSON.sql
**		Name: fxGetSeasonByRecruitIdJSON
**		Desc:
**
**		This template can be customized:
**
**		Return values: Table of IDs/Ints
**
**		Called by:
**
**		Parameters:
**		Input							Output
**     ----------					-----------
**
**		Auth: Andrés E. Sosa
**		Date: 01/15/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	01/15/2018	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [RSU].[fxGetSeasonByRecruitIdJSON];
GO

CREATE FUNCTION [RSU].[fxGetSeasonByRecruitIdJSON] (
	@UserRecruitId INT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	/** LOCALS */
	DECLARE @Result NVARCHAR(MAX);

	SELECT
		@Result = (
		SELECT
			URS.SeasonId AS id
			, S.PreSeasonID AS preSeasonID
			, S.DealerTenantId AS dealerId
			, S.SeasonName AS seasonName
			, S.StartDate AS startDate
			, S.EndDate AS endDate
			, S.ShowInHiringManager AS showInHiringManager
			, S.IsCurrent AS isCurrent
			, S.IsVisibleToRecruits AS isVisibleToRecruits
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
			, S.IsDeleted AS isDeleted
			, S.ModifiedDate AS modifiedDate
			, S.ModifiedById AS modifiedById
			, JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](S.ModifiedById), '$') AS modifiedBy
			, S.CreatedDate AS createdDate
			, S.CreatedById AS createdById
			, JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](S.CreatedById), '$') AS createdBy
		FROM
			[RSU].[UserRecruits] AS URS WITH(NOLOCK)
			INNER JOIN [RSU].[Seasons] AS S WITH(NOLOCK)
			ON
				(S.SeasonID = URS.SeasonId)
		WHERE
			(URS.UserRecruitID = @UserRecruitId)
		FOR JSON PATH, INCLUDE_NULL_VALUES);

	/** REMOVE [] */
	SET @Result = SUBSTRING(@Result, 2, LEN(@Result) - 2);

	/** Result */
	RETURN @Result;
END
GO
