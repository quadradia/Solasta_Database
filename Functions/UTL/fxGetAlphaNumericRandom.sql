/******************************************************************************
**		File: fxGetAlphaNumericRandom.sql
**		Name: fxGetAlphaNumericRandom
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
**		Date: 01/13/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	01/13/2017	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [UTL].[fxGetAlphaNumericRandom];
GO

CREATE FUNCTION [UTL].[fxGetAlphaNumericRandom]
(@Length INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	--** Init
	DECLARE @Result NVARCHAR(MAX) = ''
		, @Counter INT = 0
		, @X CHAR(1);

	-- ** Build
	WHILE (@Counter < @Length) BEGIN
		-- ** Get Char
		SELECT @X=RndChar FROM UTL.vwGenRandomAlpaNumericChar
		-- ** Build
		SELECT
			@Result = @Result + @X

		SET @Counter = @Counter + 1;
	END

	-- ** Return
	RETURN @Result;
END
GO
