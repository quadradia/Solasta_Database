DROP PROCEDURE IF EXISTS [RSU].[spUserResourceFullGetByGPEmployeeId];
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
CREATE   Procedure [RSU].[spUserResourceFullGetByGPEmployeeId]
	(
	@GPEmployeeID NVARCHAR(25)
	,
	@IgnoreDealerId BIT = 'False'
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** DECLARATIONS */
	DECLARE @DealerId INT = -1;
	IF (@IgnoreDealerId = 'False') BEGIN
		SELECT @DealerId = DealerTenantId
		FROM [ACC].[fxGetContextUserTable]();
	END;

	PRINT '|** DEALRE ID : ' + CAST(@DealerId AS VARCHAR(20));

	BEGIN TRY
		-- ** STATEMENT
		SELECT
		RU.UserResourceID AS Id
			, RU.*
	FROM
		[RSU].[UserResources] AS RU WITH(NOLOCK)
		INNER JOIN [RSU].[UserEmployeeTypes] AS UET WITH(NOLOCK)
		ON
				(UET.UserEmployeeTypeID = RU.UserEmployeeTypeId)
	WHERE
			(RU.GPEmployeeId = @GPEmployeeID)
		AND ((@IgnoreDealerId = 'True') OR (RU.DealerTenantId = @DealerId))
		AND (RU.IsDeleted = 'False');

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
