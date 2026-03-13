/******************************************************************************
**		File: fxGetContextUserTable.sql
**		Name: fxGetContextUserTable
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
**		Date: 04/17/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	04/17/2017	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [ACC].[fxGetContextUserTable];
GO

CREATE FUNCTION [ACC].[fxGetContextUserTable]
()
RETURNS
@ReturnList TABLE
(
	UserID UNIQUEIDENTIFIER NOT NULL
	, HRUserId INT NULL
	, GPEmployeeID NVARCHAR(25) NULL
	, UserGuidMasked VARCHAR(50) NOT NULL
	, FirstName NVARCHAR(MAX) NOT NULL
	, LastName NVARCHAR(MAX) NOT NULL
	, Email NVARCHAR(MAX) NULL
	, Username NVARCHAR(256) NULL
	, PhoneNumber NVARCHAR(MAX) NULL
	, DealerId INT NULL
)
WITH SCHEMABINDING
AS
BEGIN
	/** LOCALS */
	DECLARE @UserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGuidMasked VARCHAR(50);

	/** Check that a user was passed */
	IF (@UserID IS NULL) BEGIN
		SET @UserID = 'E6872B58-52B2-415C-A32B-45805F95A70A';
	END

	SET @UserGuidMasked = 'XXXXXXX-XXXX-XXXX-XXXX-' + RIGHT(CAST(@UserID AS VARCHAR(50)), 12);

	INSERT INTO @ReturnList ( UserID, FirstName, LastName, UserGuidMasked ) VALUES (@UserID, '', '', @UserGuidMasked);

	-- ** Get the Dealer Id
	UPDATE RL SET
		RL.DealerId = URS.DealerID
		, RL.HRUserId = URS.HRUserId
		, RL.GPEmployeeID = URS.GPEmployeeID
		, RL.FirstName = URS.FirstName
		, RL.LastName = URS.LastName
		, RL.Email = URS.Email
		, RL.Username = URS.Username
		, RL.PhoneNumber = URS.PhoneNumber
	FROM
		@ReturnList AS RL
		INNER JOIN [ACC].[Users] AS URS WITH(NOLOCK)
		ON
			(URS.UserID = RL.UserID);

	RETURN;
END
GO
