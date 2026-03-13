DROP PROCEDURE IF EXISTS [RSU].[spGetUserTypeGroupsByDealerId];
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
CREATE   Procedure [RSU].[spGetUserTypeGroupsByDealerId]
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
			UTG.UserTypeGroupID AS Id
            , UTG.UserTypeGroupName
            , UTG.IsActive
            , UTG.IsDeleted
            , UTG.ModifiedDate
            , UTG.ModifiedById
            , UTG.CreatedDate
            , UTG.CreatedById
		FROM
			[RSU].[UserTypeGroups] AS UTG WITH(NOLOCK)
		ORDER BY
			UTG.UserTypeGroupName
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
