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

DROP FUNCTION IF EXISTS [UTL].[fxGetTimeZoneOffsetMilSecondsByTimeZoneId];
GO

CREATE FUNCTION [UTL].[fxGetTimeZoneOffsetMilSecondsByTimeZoneId]
(
	@TimeZoneOffsetMilSeconds INT
	, @IsDLS BIT = 'False'
	, @CurrentDate SMALLDATETIME = NULL
)
RETURNS INT
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
            SET @TimeZoneOffsetMilSeconds = @TimeZoneOffsetMilSeconds + 360000;
        END
    END

    RETURN @TimeZoneOffsetMilSeconds;
END
GO
