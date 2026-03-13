DROP PROCEDURE IF EXISTS [RSU].[spUserResourceUpdatePassword];
GO

/******************************************************************************
**		File: spUserResourceUpdatePassword.sql
**		Name: spUserResourceUpdatePassword
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
**		Date: 05/18/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	05/18/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceUpdatePassword]
(
	@UserId UNIQUEIDENTIFIER
	, @Password VARCHAR(60)
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	BEGIN TRY
		-- ** DECLARATIONS
		DECLARE @GPEmployeeID NVARCHAR(25);

		-- ** Find Resource
		SELECT @GPEmployeeID = GPEmployeeID FROM [ACC].[Users] WHERE (UserID = @UserId);

		-- ** STATEMENT
		UPDATE [RSU].[UserResources] SET Password = @Password WHERE (UserId = @UserId) AND (GPEmployeeId = @GPEmployeeID);

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
