/******************************************************************************
**		File: fxGetPartKey.sql
**		Name: fxGetPartKey
**		Desc: Returns a 5-character hexadecimal partition key derived from the
**            current year and month. Used as the PartKey segment in Proxy-ID
**            composite identifiers (format: Prefix:PartKey:GUID).
**
**            Algorithm:
**              1. Concatenate YYYY + MM as a string (e.g., "202605")
**              2. Cast to INT (202605)
**              3. Convert to 4-byte VARBINARY then to hex string ("0x000316BD")
**              4. Strip the "0x000" prefix to return the 5-char result ("316BD")
**
**		Return values: VARCHAR(6) hex partition key (e.g., "316BD" for May 2026)
**
**		Called by: MAC.fxGeneratePrefixParts
**
**		Parameters:
**		Input							Output
**     ----------					-----------
**      (none)                      VARCHAR(6) PartKey
**
**		Auth: Andres E. Sosa
**		Date: 2026-05-05
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:				Description:
**	-----------	---------------		-------------------------------------------
**	2026-05-05	Andres E. Sosa		Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [UTL].[fxGetPartKey];
GO

CREATE FUNCTION [UTL].[fxGetPartKey] ()
RETURNS VARCHAR(6)
AS
BEGIN
    /** LOCALS */
    DECLARE @Year    VARCHAR(4);
    DECLARE @Month   VARCHAR(2);
    DECLARE @StrValue  VARCHAR(10);
    DECLARE @HexValue  VARCHAR(10);
    DECLARE @Number    INT;

    /** Capture Year and Month */
    SET @Year  = CAST(YEAR(GETDATE()) AS VARCHAR(4));
    SET @Month = RIGHT('0' + CAST(MONTH(GETDATE()) AS VARCHAR(2)), 2);

    /** Concatenate Year and Month (e.g. "202605") */
    SET @StrValue = @Year + @Month;

    /** Cast to INT */
    SET @Number = CAST(@StrValue AS INT);

    /** Convert the number to VARBINARY then to hex string (e.g. "0x000316BD") */
    SET @HexValue = CONVERT(VARCHAR(10), CONVERT(VARBINARY(4), @Number), 1);

    /** Strip "0x000" prefix to return 5-char hex result (e.g. "316BD") */
    RETURN REPLACE(@HexValue, '0x000', '');
END
GO
