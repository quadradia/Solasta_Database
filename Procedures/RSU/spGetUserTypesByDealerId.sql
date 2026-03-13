DROP PROCEDURE IF EXISTS [RSU].[spGetUserTypesByDealerId];
GO

/******************************************************************************
**		File: spAutoACEUtilDropACESPROCS.sql
**		Name: spAutoACEUtilDropACESPROCS
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
**		Date: 04/27/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	04/27/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE   Procedure [RSU].[spGetUserTypesByDealerId]
(
	@DealerId INT = NULL
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** DECLARATIONS */
	DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50);
	SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked FROM [ACC].[fxGetContextUserTable]();

	/** Check for CurbNSign Only */
	DECLARE @CurbNSignGrp VARCHAR(20) = NULL
	IF (EXISTS(SELECT * FROM [CNS].[fxGroupMasterDealersTo2000](@DealerId))) BEGIN
		SET @CurbNSignGrp = 'CURBNSIGNGRP';
	END;
	
	BEGIN TRY
		-- ** STATEMENT
		SELECT
			UET.UserTypeID AS Id
            , UET.UserTypeTeamTypeId
            , UET.UserTypeGroupId
            , UET.UserTypeName
            , UET.SecurityLevel
            , UET.SpawnTypeID
            , UET.RoleLocationID
            , UET.ReportingLevel
            , UET.IsCommissionable
            , UET.IsActive
            , UET.IsDeleted
            , UET.ModifiedDate
            , UET.ModifiedById
            , UET.CreatedDate
            , UET.CreatedById
		FROM
			[RSU].[UserTypes] AS UET WITH(NOLOCK)
		WHERE
			(@CurbNSignGrp IS NULL OR @CurbNSignGrp = UET.UserTypeGroupId)
		ORDER BY
			UET.UserTypeName
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
