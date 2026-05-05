DROP PROCEDURE IF EXISTS [RSU].[spUserResourceSearchFull];
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
**		Date: 03/20/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	03/20/2017	Andres Sosa		Created By
**
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceSearchFull]
	(
	@DealerId INT
	,
	@PhoneNumber VARCHAR(20) = NULL
	,
	@FirstName NVARCHAR(50) = NULL
	,
	@LastName NVARCHAR(50) = NULL
	,
	@Email NVARCHAR(100) = NULL
	,
	@Street NVARCHAR(50) = NULL
	,
	@UserResourceId INT = NULL
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** DECLARATIONS */
	DECLARE @UserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGuidMasked VARCHAR(50);
	SET @UserGuidMasked = (SELECT 'XXXXXXX-XXXX-XXXX-XXXX-' + RIGHT(CAST(@UserID AS VARCHAR(50)), 12))

	/** BUILD QUERY */
	SELECT
		RSU.*
	FROM
		[RSU].[vwUserResourceFullSearchDataSet] AS RSU WITH(NOLOCK)
		LEFT OUTER JOIN [ACC].[Users] AS U WITH(NOLOCK)
		ON
			(U.UserID = RSU.UserId)
		LEFT OUTER JOIN [RSU].[UserResourceAddresses] AS URA WITH(NOLOCK)
		ON
			(URA.UserResourceAddressID = RSU.UserResourceAddressId)
	WHERE
		(RSU.DealerTenantId = @DealerId)
		AND ((@PhoneNumber IS NULL OR [UTL].[fxRemovePhoneDecorations](RSU.PhoneHome) = [UTL].[fxRemovePhoneDecorations](@PhoneNumber))
		OR (@PhoneNumber IS NULL OR [UTL].[fxRemovePhoneDecorations](RSU.PhoneCell) = [UTL].[fxRemovePhoneDecorations](@PhoneNumber))
		OR (@PhoneNumber IS NULL OR [UTL].[fxRemovePhoneDecorations](U.PhoneNumber) = [UTL].[fxRemovePhoneDecorations](@PhoneNumber)))
		AND (@FirstName IS NULL OR RSU.FirstName LIKE @FirstName + '%')
		AND (@LastName IS NULL OR RSU.LastName LIKE @LastName + '%')
		AND (@Email IS NULL OR RSU.Email LIKE @Email + '%')
		AND (@Street IS NULL OR URA.StreetAddress LIKE @Street +'%')
		AND (@UserResourceId IS NULL OR RSU.Id = @UserResourceId)
		AND (/*U.IsActive = 'True' AND */U.IsDeleted = 'False')
;
END

GO
