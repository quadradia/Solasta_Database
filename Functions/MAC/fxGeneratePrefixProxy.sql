/******************************************************************************
**		File: fxGeneratePrefixProxy.sql
**		Name: fxGeneratePrefixProxy
**		Desc: Scalar function that returns the Proxy-ID prefix string in the
**            format "Prefix:PartKey:" for a given TypeName and TypeId.
**
**            IMPORTANT: The caller is responsible for appending the GUID segment.
**            This function returns the prefix portion only (with trailing colon).
**
**            Example return value: "MSTR:316BD:"
**            Full proxy after caller appends GUID: "MSTR:316BD:E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8"
**
**            Usage in stored procedures:
**              DECLARE @Proxy VARCHAR(100) =
**                  [MAC].[fxGeneratePrefixProxy]('DealerTenant', @DealerTenantTypeId)
**                  + CAST(NEWID() AS NVARCHAR(36));
**
**		Return values: NVARCHAR(50) — "Prefix:PartKey:" prefix string
**
**		Called by: Any stored procedure that INSERTs into a Proxy-enabled table
**
**		Parameters:
**		Input							Output
**     ----------					-----------
**      @TypeName  VARCHAR(50)      NVARCHAR(50) — "Prefix:PartKey:"
**      @TypeId    INT
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

DROP FUNCTION IF EXISTS [MAC].[fxGeneratePrefixProxy];
GO

CREATE FUNCTION [MAC].[fxGeneratePrefixProxy] (
    @TypeName  VARCHAR(50)
    , @TypeId  INT
)
RETURNS NVARCHAR(50)
AS
BEGIN
    /** LOCALS */
    DECLARE @Result NVARCHAR(50);

    SELECT @Result = [Prefix] + ':' + [PartKey] + ':'
    FROM [MAC].[fxGeneratePrefixParts](@TypeName, @TypeId);

    RETURN @Result;
END
GO
