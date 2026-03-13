/******************************************************************************
**		File: fxGetDaylightSavingsTimeEnd.sql
**		Name: fxGetDaylightSavingsTimeEnd
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

DROP FUNCTION IF EXISTS [UTL].[fxGetDaylightSavingsTimeEnd];
GO

CREATE FUNCTION [UTL].[fxGetDaylightSavingsTimeEnd]
(@Year VARCHAR(4))
RETURNS SMALLDATETIME
AS
BEGIN
    DECLARE @DTSEndWeek SMALLDATETIME

    SET @DTSEndWeek = '11/01/' + CONVERT(VARCHAR, @Year)

    RETURN CASE DATEPART(dw, DATEADD(WEEK, 1, @DTSEndWeek))
		WHEN 1 THEN
		DATEADD(hour,2,@DTSEndWeek)
		WHEN 2 THEN
		DATEADD(hour,146,@DTSEndWeek)
		WHEN 3 THEN
		DATEADD(hour,122,@DTSEndWeek)
		WHEN 4 THEN
		DATEADD(hour,98,@DTSEndWeek)
		WHEN 5 THEN
		DATEADD(hour,74,@DTSEndWeek)
		WHEN 6 THEN
		DATEADD(hour,50,@DTSEndWeek)
		WHEN 7 THEN
		DATEADD(hour,26,@DTSEndWeek)
	end
END
GO
