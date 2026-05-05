/******************************************************************************
**		File: fxCreateGpEmployeeNumberNxN.sql
**		Name: fxCreateGpEmployeeNumberNxN
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
**		Date: 01/21/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	01/21/2017	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [UTL].[fxCreateGpEmployeeNumberNxN];
GO

CREATE FUNCTION [UTL].[fxCreateGpEmployeeNumberNxN]
(
	@FirstName NVARCHAR(50)
	, @LastName NVARCHAR(50)
	, @DealerId INT
	, @AlphaLength SMALLINT
	, @NumberLength SMALLINT
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE	@Result VARCHAR(50) = ''
		, @IsDone BIT = 'False'
		, @PostFixNumber SMALLINT = 1
		, @Counter INT = 1;

	WHILE (@IsDone = 'False') BEGIN
		--** Look for GpNumber
		IF (LEN(@LastName) >= @AlphaLength) BEGIN
			SET @Result = SUBSTRING(@LastName, 1, @AlphaLength);
		END ELSE IF (LEN(@LastName) + LEN(@FirstName) < @AlphaLength) BEGIN
			SET @Result = @LastName + @FirstName + [UTL].[fxGetAlphaNumericRandom](@AlphaLength - (LEN(@LastName) + LEN(@FirstName)));
		END ELSE IF (LEN(@LastName) < @AlphaLength) BEGIN
			SET @Result = @LastName + SUBSTRING(@FirstName, 1, @AlphaLength - LEN(@LastName));
		END

		SELECT @PostFixNumber = COUNT(*) + 1
		FROM [RSU].[UserResources]
		WHERE (DealerTenantId = @DealerId AND GPEmployeeId LIKE @Result + '%');

		SET @Result = @Result + REPLICATE('0', @NumberLength-LEN(CAST(@PostFixNumber AS VARCHAR))) + CAST(@PostFixNumber AS VARCHAR);

		-- ** UPPER CASE IT ALL
		SET @Result = UPPER(@Result);

		SET @IsDone = 'True';
	END

	RETURN @Result;
END
GO
