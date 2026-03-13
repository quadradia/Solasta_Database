/******************************************************************************
**		File: fxGetTimeZoneOffsetMilSecondsByTimeZoneId.sql
**		Name: fxGetTimeZoneOffsetMilSecondsByTimeZoneId
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

-- NOTE: This function is referenced by computed columns in [MAC].[PoliticalTimeZones].
-- SQL Server prevents DROP or ALTER while that dependency exists.
-- Pattern: only CREATE if it does not already exist.
IF OBJECT_ID('[UTL].[fxGetTimeZoneOffsetMilSecondsByTimeZoneId]', 'FN') IS NULL
    EXEC(N'CREATE FUNCTION [UTL].[fxGetTimeZoneOffsetMilSecondsByTimeZoneId]
(
    @TimeZoneOffsetMilSeconds INT
    , @IsDLS BIT = ''False''
    , @CurrentDate SMALLDATETIME = NULL
)
RETURNS INT
AS
BEGIN
    DECLARE @DLSStart SMALLDATETIME
        , @DLSEnd SMALLDATETIME;

    IF(@CurrentDate IS NULL) BEGIN
        SET @CurrentDate = GETDATE();
    END

    IF (@IsDLS = ''True'') BEGIN
        SET @DLSStart = (SELECT UTL.fxGetDaylightSavingsTimeStart(CONVERT(VARCHAR, DATEPART(YEAR, @CurrentDate))));
        SET @DLSEnd = (SELECT UTL.fxGetDaylightSavingsTimeEnd(CONVERT(VARCHAR, DATEPART(YEAR, @CurrentDate))));

        IF @CurrentDate BETWEEN @DLSStart AND @DLSEnd BEGIN
            SET @TimeZoneOffsetMilSeconds = @TimeZoneOffsetMilSeconds + 360000;
        END
    END

    RETURN @TimeZoneOffsetMilSeconds;
END
');
GO
