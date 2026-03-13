/******************************************************************************
**		File: fxSplitStringList.sql
**		Name: fxSplitStringList
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

DROP FUNCTION IF EXISTS [UTL].[fxSplitStringList];
GO

CREATE FUNCTION [UTL].[fxSplitStringList]
(
	@IDList NVARCHAR(MAX)
)
RETURNS
@ParsedList TABLE
(
    ID NVARCHAR(100) NULL
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
                    (@ID)
            --Use Appropriate conversion
            END
            SET @IDList = RIGHT(@IDList, LEN(@IDList) - @Pos)
            SET @Pos = CHARINDEX(',', @IDList, 1)

        END;
    END;

    /** RETURN RESULT */
    RETURN;
END
GO
