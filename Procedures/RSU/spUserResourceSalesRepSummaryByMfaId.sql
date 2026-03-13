DROP PROCEDURE IF EXISTS [RSU].[spUserResourceSalesRepSummaryByMfaId];
GO

/******************************************************************************
**		File: spUserResourceSalesRepSummaryByMfaId.sql
**		Name: spUserResourceSalesRepSummaryByMfaId
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
**		Date: 08/31/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	08/31/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceSalesRepSummaryByMfaId]
(
	@MasterFileAccountId VARCHAR(50)
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
	SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		-- ** STATEMENT
		WITH MfaRootCTE AS
		(
			SELECT
				MFA.*
			FROM
				[ACE].[MasterFileAccounts] AS MFA WITH(NOLOCK)
				INNER JOIN [QAL].[Leads] AS L WITH(NOLOCK)
				ON
					(L.LeadID = MFA.LeadId)
			WHERE
				(MFA.MasterFileAccountID = @MasterFileAccountId)
		)
		--SELECT * FROM MfaRootCTE;
		, CmeRootCte AS (
			SELECT TOP 1 
				--CMA.MasAccountCommissionID
                CMA.UserResourceId AS userResourceID
				, URR.UserRecruitID AS userRecruitId
				, UR.GPEmployeeId AS gpEmployeeId
				, UR.FullName AS fullName
				, UR.PhoneCell AS phoneMobile
                --, CMA.MasAccountCommissionTypeId
                --, CMA.MasterFileId
                --, CMA.MasterFileAccountId
                --, CMA.LeadId
                --, CMA.MasAccountId
                , CMA.SeasonId AS seasonId
				, S.SeasonName AS seasonName
                --, CMA.Position
                --, CMA.Percentage
			FROM
				[CME].[MasAccountCommissions] AS CMA WITH(NOLOCK)
				INNER JOIN [RSU].[UserResources] AS UR WITH(NOLOCK)
				ON
					(UR.UserResourceID = CMA.UserResourceId)
				INNER JOIN [RSU].[UserRecruits] AS URR WITH(NOLOCK)
				ON
					(URR.UserResourceId = CMA.UserResourceId)
					AND (URR.SeasonId = CMA.SeasonId)
				INNER JOIN [RSU].[Seasons] AS S WITH(NOLOCK)
				ON
					(S.SeasonID = CMA.SeasonId)
			WHERE
				(CMA.MasterFileAccountId = @MasterFileAccountId)
				AND (CMA.Position = 1)
				AND (CMA.IsDeleted = 'False')
		)
		SELECT
			(SELECT
				RC.*
				, (SELECT
					URR.UserRecruitID AS id
					, URR.UserTypeId AS userTypeId
					, UT.UserTypeGroupId AS userTypeGroupId
					, URR.SeasonId AS seasonId
					, URR.DealerId AS dealerId
					, S.SeasonName AS seasonName
				FROM
					[RSU].[UserRecruits] AS URR WITH(NOLOCK)
					INNER JOIN [RSU].[Seasons] AS S WITH(NOLOCK)
					ON
						(S.SeasonID = URR.SeasonId)
						AND (URR.UserResourceId = RC.userResourceID)
					INNER JOIN [RSU].[UserTypes] AS UT WITH(NOLOCK)
					ON
						(UT.UserTypeID = URR.UserTypeId)
						AND (UT.UserTypeGroupId = 'SALESREPGRP')
				FOR JSON PATH
				) AS contracts
			FROM CmeRootCte AS RC WITH(NOLOCK)
			FOR JSON PATH) AS JsonOutPutMethod
			;
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
