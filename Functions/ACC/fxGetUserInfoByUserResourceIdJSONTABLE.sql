/******************************************************************************
**		File: fxGetUserInfoByUserResourceIdJSONTABLE.sql
**		Name: fxGetUserInfoByUserResourceIdJSONTABLE
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
**		Date: 08/08/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	08/08/2017	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [ACC].[fxGetUserInfoByUserResourceIdJSONTABLE];
GO

CREATE FUNCTION [ACC].[fxGetUserInfoByUserResourceIdJSONTABLE] (
	@UserResourceID INT
)
RETURNS
@ReturnList TABLE
(
	userID UNIQUEIDENTIFIER
	, userResourceId INT
	, firstName NVARCHAR(50)
	, lastName NVARCHAR(50)
	, fullName NVARCHAR(100)
	, fullNameWithGPID NVARCHAR(150)
	, gPEmployeeId NVARCHAR(50)
	, email NVARCHAR(MAX)
	, phone NVARCHAR(25)
)
AS
BEGIN
	/** LOCALS */
	INSERT INTO @ReturnList
	SELECT
		RT.UserID
        , RT.UserResourceId
        , RT.FirstName
        , RT.LastName
        , RT.FullName
        , RT.FullNameWithGPID
        , RT.GPEmployeeId
		, RT.Email
		, RT.Phone
	FROM
		[ACC].[fxGetUserInfoByUserResourceIdTABLE](@UserResourceID) AS RT;
	RETURN;
END
GO
