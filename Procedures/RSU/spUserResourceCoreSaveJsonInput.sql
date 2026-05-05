DROP PROCEDURE IF EXISTS [RSU].[spUserResourceCoreSaveJsonInput];
GO

/******************************************************************************
**		File: spUserResourceCoreSaveJsonInput.sql
**		Name: spUserResourceCoreSaveJsonInput
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
**		Auth: AndrÃ©s Sosa
**		Date: 03/06/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	03/06/2018	AndrÃ©s Sosa		Created By
**
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceCoreSaveJsonInput]
	(
	@JsonInput NVARCHAR(MAX)
)
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
		RAISERROR(N'[30400]:SPROC NOT IMPLEMENTED.  The User Resource Core SAVE has not been implemented yet...', 18, 1);
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
