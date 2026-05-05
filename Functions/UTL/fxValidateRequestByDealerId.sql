/******************************************************************************
**		File: fxValidateRequestByDealerId.sql
**		Name: fxValidateRequestByDealerId
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
**		Date: 01/05/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	01/05/2017	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [UTL].[fxValidateRequestByDealerId];
GO

CREATE FUNCTION [UTL].[fxValidateRequestByDealerId]
(
	@DealerId INT
)
RETURNS
@ReturnList TABLE
(
    UserId UNIQUEIDENTIFIER
	,
    RoleId UNIQUEIDENTIFIER
	,
    UserIdMasked VARCHAR(50)
	,
    DealerTenantId INT
	,
    FirstName VARCHAR(50)
	,
    LastName VARCHAR(50)
	,
    Email VARCHAR(MAX)
	,
    RoleName VARCHAR(50)
)
WITH SCHEMABINDING
AS
BEGIN
    /** LOCALS */
    DECLARE @UserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserIdMasked VARCHAR(50);

    SET @UserIdMasked = (SELECT 'XXXXXXX-XXXX-XXXX-XXXX-' + RIGHT(CAST(@UserID AS VARCHAR(50)), 12))

    INSERT INTO @ReturnList
        (UserId, RoleId, UserIdMasked, DealerTenantId, FirstName, LastName, Email, RoleName)
    SELECT
        U.UserId
		, UR.RoleId
		, @UserIdMasked
		, U.DealerTenantId
		, U.FirstName
		, U.LastName
		, U.Email
		, R.Name
    FROM
        [ACC].[Users] AS U WITH (NOLOCK)
        INNER JOIN [ACC].[UserRoles] AS UR WITH (NOLOCK)
        ON
			(UR.UserId = U.UserID)
        INNER JOIN [ACC].[Roles] AS R WITH (NOLOCK)
        ON
			(R.RoleID = UR.RoleId)
    WHERE
		(U.DealerTenantId = @DealerId);

    RETURN;
END
GO
