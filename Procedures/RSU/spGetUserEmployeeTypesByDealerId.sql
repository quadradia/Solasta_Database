DROP PROCEDURE IF EXISTS [RSU].[spGetUserEmployeeTypesByDealerId];
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
CREATE   Procedure [RSU].[spGetUserEmployeeTypesByDealerId]
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
			UET.UserEmployeeTypeID AS Id
            , UET.UserEmployeeTypeName
            , UET.IsActive
            , UET.IsDeleted
            , UET.CreatedById
            , UET.CreatedDate
            , UET.ModifiedById
            , UET.ModifiedDate
		FROM
			[RSU].[UserEmployeeTypes] AS UET WITH(NOLOCK)
		ORDER BY
			UET.UserEmployeeTypeName
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
