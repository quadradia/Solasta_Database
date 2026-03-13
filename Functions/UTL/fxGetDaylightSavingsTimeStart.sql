/******************************************************************************
**		File: fxGetDaylightSavingsTimeStart.sql
**		Name: fxGetDaylightSavingsTimeStart
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
**		Date: 10/22/2016
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	10/22/2016	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [UTL].[fxGetDaylightSavingsTimeStart];
GO

CREATE FUNCTION [UTL].[fxGetDaylightSavingsTimeStart]
(@Year VARCHAR(4))
RETURNS SMALLDATETIME
AS
BEGIN
    DECLARE @DTSStartWeek SMALLDATETIME
    SET @DTSStartWeek = '03/01/' + CONVERT(VARCHAR,@Year)

    RETURN  CASE DATEPART(dw,@DTSStartWeek)
		WHEN 1 THEN
			DATEADD(hour,170,@DTSStartWeek)
		WHEN 2 THEN
			DATEADD(hour,314,@DTSStartWeek)
		WHEN 3 THEN
			dateadd(hour,290,@DTSStartWeek)
		WHEN 4 THEN
			dateadd(hour,266,@DTSStartWeek)
		WHEN 5 THEN
			dateadd(hour,242,@DTSStartWeek)
		WHEN 6 THEN
			dateadd(hour,218,@DTSStartWeek)
		WHEN 7 THEN
			DATEADD(hour,194,@DTSStartWeek)
	end
END
GO
