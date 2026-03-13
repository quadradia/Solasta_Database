/******************************************************************************
**		File: fxGetTimeZoneOffsetMinutesByTimeZoneId.sql
**		Name: fxGetTimeZoneOffsetMinutesByTimeZoneId
**		Desc:
**
**		Reference: https://www.mssqltips.com/sqlservertip/1372/daylight-savings-time-functions-in-sql-server/
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
**		Date: 01/24/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	01/24/2017	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [UTL].[fxGetTimeZoneOffsetMinutesByTimeZoneId];
GO

CREATE FUNCTION [UTL].[fxGetTimeZoneOffsetMinutesByTimeZoneId]
(
	@TimeZoneOffsetMinutes SMALLINT
	, @IsDLS BIT = 'False'
	, @CurrentDate SMALLDATETIME = NULL
)
RETURNS SMALLINT
AS
BEGIN
    /** Declarations */
    DECLARE @DLSStart SMALLDATETIME
		, @DLSEnd SMALLDATETIME;

    /** Initialize */
    IF(@CurrentDate IS NULL) BEGIN
        SET @CurrentDate = GETDATE();
    END

    -- ** Check if we have to do a DLS conversion
    IF (@IsDLS = 'True') BEGIN
        SET @DLSStart = (SELECT UTL.fxGetDaylightSavingsTimeStart(CONVERT(VARCHAR, DATEPART(YEAR, @CurrentDate))));
        SET @DLSEnd = (SELECT UTL.fxGetDaylightSavingsTimeEnd(CONVERT(VARCHAR, DATEPART(YEAR, @CurrentDate))));

        IF @CurrentDate BETWEEN @DLSStart AND @DLSEnd BEGIN
            SET @TimeZoneOffsetMinutes = @TimeZoneOffsetMinutes + 60;
        END
    END

    RETURN @TimeZoneOffsetMinutes;
END
GO
