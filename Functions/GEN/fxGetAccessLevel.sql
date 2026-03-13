/******************************************************************************
**		File: fxGetAccessLevel.sql
**		Name: fxGetAccessLevel
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
**		Date: 05/05/2016
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	05/05/2016	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [GEN].[fxGetAccessLevel];
GO

CREATE FUNCTION [GEN].[fxGetAccessLevel]
(
	@CrudAction VARCHAR(20)
	, @SchemaName VARCHAR(50)
	, @TableName VARCHAR(150)
)
RETURNS
@ParsedList table
(
	RoleID UNIQUEIDENTIFIER
	, UserId UNIQUEIDENTIFIER
	, Email NVARCHAR(100)
	, UserFullName NVARCHAR(MAX)
	, RoleName VARCHAR(50)
	, CreateAccessId SMALLINT
	, ReadAccessId SMALLINT
	, UpdateAccessId SMALLINT
	, DeleteAccessId SMALLINT
)
WITH SCHEMABINDING
AS
BEGIN
	/** LOCALS */
	DECLARE @UserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);

	INSERT INTO @ParsedList (
		RoleID
		, UserId
		, Email
		, UserFullName
		, RoleName
		, CreateAccessId
		, ReadAccessId
		, UpdateAccessId
		, DeleteAccessId
	    )
		SELECT
			UR.RoleId
			, UR.UserId
			, USR.Email
			, USR.FirstName + ' ' + USR.LastName
			, ROL.Name AS [RoleName]
			, TAL.CreateAccessLevelId
			, TAL.ReadAccessLevelId
			, TAL.UpdateAccessLevelId
			, TAL.DeleteAccessLevelId
		FROM
			[SEC].[TableAccessLevels] AS TAL WITH (NOLOCK)
			INNER JOIN [ACC].[UserRoles] AS UR WITH (NOLOCK)
			ON
				(UR.RoleId = TAL.RoleId)
			INNER JOIN [ACC].[Users] AS USR WITH (NOLOCK)
			ON
				(USR.UserId = UR.UserId)
			INNER JOIN [ACC].[Roles] AS ROL WITH (NOLOCK)
			ON
				(ROL.RoleID = TAL.RoleId)
		WHERE
			(UR.UserId = @UserID)
			AND (TAL.SchemaName = @SchemaName AND TAL.TableName = @TableName)
			AND ((@CrudAction = 'Create' AND TAL.CreateAccessLevelId > 0)
			OR (@CrudAction = 'Read' AND TAL.ReadAccessLevelId > 0)
			OR (@CrudAction = 'Update' AND TAL.UpdateAccessLevelId > 0)
			OR (@CrudAction = 'Delete' AND TAL.DeleteAccessLevelId > 0));
	RETURN
END
GO
