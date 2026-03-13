/******************************************************************************
**		File: fxSplitStringListOfINT.sql
**		Name: fxSplitStringListOfINT
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
**		Date: 03/20/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	03/20/2017	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [UTL].[fxSplitStringListOfINT];
GO

CREATE FUNCTION [UTL].[fxSplitStringListOfINT]
(
	@IDList NVARCHAR(MAX)
)
RETURNS
@ParsedList TABLE
(
    ID INT
)
AS
BEGIN
    DECLARE @ID NVARCHAR(100), @Pos int

    SET @IDList = LTRIM(RTRIM(@IDList))+ ','
    SET @Pos = CHARINDEX(',', @IDList, 1)

    IF REPLACE(@IDList, ',', '') <> ''
	BEGIN
        WHILE @Pos > 0
		BEGIN
            SET @ID = LTRIM(RTRIM(LEFT(@IDList, @Pos - 1)))
            IF @ID <> ''
			BEGIN
                INSERT INTO @ParsedList
                    (ID)
                VALUES
                    (CAST(@ID AS INT))
            --Use Appropriate conversion
            END
            SET @IDList = RIGHT(@IDList, LEN(@IDList) - @Pos)
            SET @Pos = CHARINDEX(',', @IDList, 1)

        END
    END
    RETURN
END
GO
