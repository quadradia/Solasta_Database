/******************************************************************************
**		File: fxGetUserInfoByUserResourceIdTABLE.sql
**		Name: fxGetUserInfoByUserResourceIdTABLE
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
**		Date: 02/12/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	02/12/2018	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [ACC].[fxGetUserInfoByUserResourceIdTABLE];
GO

CREATE FUNCTION [ACC].[fxGetUserInfoByUserResourceIdTABLE] (
	@UserResourceID INT
)
RETURNS
@ReturnList TABLE
(
	UserID UNIQUEIDENTIFIER
	, UserResourceId INT
	, FirstName NVARCHAR(50)
	, LastName NVARCHAR(50)
	, FullName NVARCHAR(100)
	, FullNameWithGPID NVARCHAR(150)
	, GPEmployeeId NVARCHAR(50)
	, Email NVARCHAR(MAX)
	, Phone NVARCHAR(25)

)
AS
BEGIN
	/** LOCALS */
	INSERT INTO @ReturnList

	SELECT
		U.UserID
        , U.UserResourceID
        , U.FirstName
        , U.LastName
        , U.FullName
        , U.FullNameWithGPID
        , U.GPEmployeeId
		, U.Email
		, U.Phone
	FROM
		[ACC].[vwUserSummaryInfo] AS U WITH(NOLOCK)
	WHERE
		(U.UserResourceID = @UserResourceID);

	RETURN;
END
GO
