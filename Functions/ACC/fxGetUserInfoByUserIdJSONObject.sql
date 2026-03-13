/******************************************************************************
**		File: fxGetUserInfoByUserIdJSONObject.sql
**		Name: fxGetUserInfoByUserIdJSONObject
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

DROP FUNCTION IF EXISTS [ACC].[fxGetUserInfoByUserIdJSONObject];
GO

CREATE FUNCTION [ACC].[fxGetUserInfoByUserIdJSONObject] (
	@UserID UNIQUEIDENTIFIER
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	/** LOCALS */
	DECLARE @Result NVARCHAR(MAX) = NULL;

	SELECT @Result = (
		SELECT
			RT.*
		FROM
			[ACC].[fxGetUserInfoByUserIdJSONTABLE](@UserID) AS RT
		FOR JSON PATH, INCLUDE_NULL_VALUES);

	/** Check for result */
	IF (LEN(@Result) < 4 OR @Result IS NULL) RETURN NULL;

	/** Clean object; Remove [] ...*/
	SET @Result = SUBSTRING(@Result, 2, LEN(@Result) - 2);

	RETURN @Result;
END
GO
