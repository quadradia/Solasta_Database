DROP PROCEDURE IF EXISTS [RSU].[spGetUserTypeTeamTypesByDealerId];
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
CREATE   Procedure [RSU].[spGetUserTypeTeamTypesByDealerId]
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
	
	BEGIN TRY
		-- ** STATEMENT
		SELECT
			UTG.UserTypeTeamTypeID AS Id
            , UTG.UserTypeTeamTypeName
            , UTG.ParentId
            , UTG.IsActive
            , UTG.IsDeleted
            , UTG.CreatedById
            , UTG.CreatedDate
            , UTG.ModifiedById
            , UTG.ModifiedDate
		FROM
			[RSU].[UserTypeTeamTypes] AS UTG WITH(NOLOCK)
		ORDER BY
			UTG.UserTypeTeamTypeName
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
