/******************************************************************************
**		File: fxGetResourceInfoTable.sql
**		Name: fxGetResourceInfoTable
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
**		Date: 04/05/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	04/05/2017	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [RSU].[fxGetResourceInfoTable];
GO

CREATE FUNCTION [RSU].[fxGetResourceInfoTable] (
	@GPEmployeeId NVARCHAR(25)
)
RETURNS
@ReturnList TABLE
(
	UserResourceID INT
	, RecruitedByDate DATETIMEOFFSET(7)
	, FullName NVARCHAR(101)
	, PublicFullName NVARCHAR(53)
	, FirstName NVARCHAR(50)
	, MiddleName NVARCHAR(50)
	, LastName NVARCHAR(50)
	, PhoneCell NVARCHAR(50)
	, Email NVARCHAR(100)
)
WITH SCHEMABINDING
AS
BEGIN
	/** LOCALS */
	DECLARE @UserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGuidMasked VARCHAR(50);

	SET @UserGuidMasked = (SELECT 'XXXXXXX-XXXX-XXXX-XXXX-' + RIGHT(CAST(@UserID AS VARCHAR(50)), 12))

	INSERT INTO @ReturnList (
		UserResourceID
		, RecruitedByDate
		, FullName
		, PublicFullName
		, FirstName
		, MiddleName
		, LastName
		, PhoneCell
		, Email
	)
	SELECT
		UR.UserResourceID
		, UR.RecruitedByDate
		, UR.FullName
		, UR.PublicFullName
		, UR.FullName
		, UR.MiddleName
		, UR.LastName
		, UR.PhoneCell
		, UR.Email
	FROM
		[RSU].[UserResources] AS UR WITH(NOLOCK)
	WHERE
		(UR.GPEmployeeId = @GPEmployeeId);

	RETURN;
END
GO
