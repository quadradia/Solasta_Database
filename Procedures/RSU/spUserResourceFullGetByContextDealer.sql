DROP PROCEDURE IF EXISTS [RSU].[spUserResourceFullGetByContextDealer];
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
**		Date: 02/01/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	02/01/2018	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceFullGetByContextDealer]
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** DECLARATIONS */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		-- ** STATEMENT
		SELECT
			RU.UserResourceID AS Id
			, RU.*
		FROM
			[RSU].[UserResources] AS RU WITH(NOLOCK)
			INNER JOIN [ACC].[Users] AS ACCU WITH(NOLOCK)
			ON
				(ACCU.UserID = RU.UserId)
				AND (ACCU.IsActive = 'True' AND ACCU.IsDeleted = 'False')
			INNER JOIN [RSU].[UserEmployeeTypes] AS UET WITH(NOLOCK)
			ON
				(UET.UserEmployeeTypeID = RU.UserEmployeeTypeId)
		WHERE
			(RU.DealerId = @DealerId)
			AND (RU.IsDeleted = 'False')
		ORDER BY
			RU.FirstName, RU.LastName;

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
