/******************************************************************************
**		File: fxGetTZHTZMFormatFromTimeZoneMinutes.sql
**		Name: fxGetTZHTZMFormatFromTimeZoneMinutes
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
**		Date: 03/17/2016
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	03/17/2016	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [UTL].[fxGetTZHTZMFormatFromTimeZoneMinutes];
GO

CREATE FUNCTION [UTL].[fxGetTZHTZMFormatFromTimeZoneMinutes](
	@TimeZoneOffsetMinutes SMALLINT
	, @IsDLS BIT = 'False'
	, @CurrentDate SMALLDATETIME = NULL
)
RETURNS VARCHAR(8)
AS
BEGIN
    /** INITIALIZE */
    SET @TimeZoneOffsetMinutes = [UTL].[fxGetTimeZoneOffsetMinutesByTimeZoneId](@TimeZoneOffsetMinutes, @IsDLS, NULL);

    /** DECLARATIONS */
    DECLARE @Result VARCHAR(8)
		, @Hours VARCHAR(4) = CAST(ABS(@TimeZoneOffsetMinutes)/60 AS VARCHAR)
		, @Mints VARCHAR(4) = CAST(ABS(@TimeZoneOffsetMinutes%60) AS VARCHAR)
		, @Signs VARCHAR(1) = CASE WHEN @TimeZoneOffsetMinutes < 0 THEN '-' ELSE '+' END;

    /** INITIALIZE */
    SET @Hours = CASE WHEN LEN(@Hours) = 1 THEN '0' + @Hours ELSE @Hours END;
    SET @Mints = CASE WHEN LEN(@Mints) = 1 THEN '0' + @Mints ELSE @Mints END;

    /** BUILD RESULT */
    SET @Result = @Signs + @Hours + ':' + @Mints

    /** RETURN */
    RETURN @Result;
END
GO
