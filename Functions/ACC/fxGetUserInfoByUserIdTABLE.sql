/******************************************************************************
**		File: fxGetUserInfoByUserIdTABLE.sql
**		Name: fxGetUserInfoByUserIdTABLE
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

DROP FUNCTION IF EXISTS [ACC].[fxGetUserInfoByUserIdTABLE];
GO

CREATE FUNCTION [ACC].[fxGetUserInfoByUserIdTABLE] (
	@UserID UNIQUEIDENTIFIER
)
RETURNS
@ReturnList TABLE
(
    UserID UNIQUEIDENTIFIER
	,
    UserResourceId INT
	,
    FirstName NVARCHAR(50)
	,
    LastName NVARCHAR(50)
	,
    FullName NVARCHAR(100)
	,
    FullNameWithGPID NVARCHAR(150)
	,
    GPEmployeeId NVARCHAR(50)
	,
    Email NVARCHAR(MAX)
	,
    Phone NVARCHAR(25)

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
		(@UserID IS NULL OR U.UserID = @UserID);

    RETURN;
END
GO
