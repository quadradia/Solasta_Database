/******************************************************************************
**		File: fxGetUserInfo.sql
**		Name: fxGetUserInfo
**		Desc:
**
**		This template can be customized:
**
**		Return values: Table of IDs/Ints
**
**		Called by:
**
**		Parameters:
**		Input							Output
**     ----------					-----------
**
**		Auth: Andrés E. Sosa
**		Date: 12/28/2015
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	12/28/2015	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [GEN].[fxGetUserInfo];
GO

CREATE FUNCTION [GEN].[fxGetUserInfo]
()
RETURNS
@ReturnList TABLE
(
	UserID UNIQUEIDENTIFIER
	, UserGuidIDMasked VARCHAR(50)
	, FirstName NVARCHAR(MAX)
	, LastName NVARCHAR(MAX)
	, Email NVARCHAR(256)
	, RoleName NVARCHAR(50)
)
WITH SCHEMABINDING
AS
BEGIN
	/** LOCALS */
	DECLARE @UserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGuidMaked VARCHAR(50);

	SET @UserGuidMaked = (SELECT 'XXXXXXX-XXXX-XXXX-XXXX-' + RIGHT(CAST(@UserID AS VARCHAR(50)), 12))

	INSERT INTO @ReturnList ( UserID, UserGuidIDMasked, FirstName, LastName, Email, RoleName )
	SELECT U.UserID, @UserGuidMaked, U.FirstName, U.LastName, U.Email, R.Name AS [RoleName]
	FROM
		[ACC].[Users] AS U WITH (NOLOCK)
		INNER JOIN [ACC].[UserRoles] AS UR WITH (NOLOCK)
		ON
			(UR.UserId = U.UserId)
		INNER JOIN [ACC].[Roles] AS R WITH (NOLOCK)
		ON
			(R.RoleID = UR.RoleId)
	WHERE
		(U.UserID = @UserID);

	RETURN;
END
GO
