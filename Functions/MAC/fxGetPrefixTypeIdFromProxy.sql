/******************************************************************************
**		File: fxGetPrefixTypeIdFromProxy.sql
**		Name: fxGetPrefixTypeIdFromProxy
**		Desc: Table-valued function that parses a full Proxy-ID string and returns
**            its component parts along with the resolved TypeId, TableName, and
**            TypeName from MAC.vwTableTypesAndPrefixes.
**
**            Input format:  "MSTR:316BD:E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8"
**            Output:        Prefix="MSTR", PartKey="316BD",
**                           GuidIdentifier="E2CDF52E-...", TypeId=1,
**                           TableName="DealerTenantTypes", TypeName="DealerTenant"
**
**		Return values: TABLE (Prefix, PartKey, GuidIdentifier, TypeId, TableName, TypeName)
**
**		Called by: Stored procedures and queries that need to decode a proxy string
**
**		Parameters:
**		Input							Output
**     ----------					-----------
**      @Proxy  VARCHAR(100)        Prefix NVARCHAR(50)
**                                  PartKey VARCHAR(6)
**                                  GuidIdentifier VARCHAR(50)
**                                  TypeId INT
**                                  TableName NVARCHAR(100)
**                                  TypeName NVARCHAR(100)
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

DROP FUNCTION IF EXISTS [MAC].[fxGetPrefixTypeIdFromProxy];
GO

CREATE FUNCTION [MAC].[fxGetPrefixTypeIdFromProxy] (
    @Proxy VARCHAR(100)
)
RETURNS @Parts TABLE (
    Prefix NVARCHAR(50),
    PartKey VARCHAR(6),
    GuidIdentifier VARCHAR(50),
    TypeId INT,
    TableName NVARCHAR(100),
    TypeName NVARCHAR(100)
)
AS
BEGIN
    DECLARE @Prefix     NVARCHAR(50);
    DECLARE @TypeName   NVARCHAR(100);
    DECLARE @TableName  NVARCHAR(100);
    DECLARE @TypeId     INT;

    -- Extract Prefix (everything before the first colon)
    SET @Prefix = LEFT(@Proxy, CHARINDEX(':', @Proxy) - 1);

    -- Extract PartKey and GuidIdentifier from the remainder
    DECLARE @Remaining    NVARCHAR(100) = SUBSTRING(@Proxy, CHARINDEX(':', @Proxy) + 1, LEN(@Proxy));
    DECLARE @PartKey      NVARCHAR(10)  = LEFT(@Remaining, CHARINDEX(':', @Remaining) - 1);
    DECLARE @GuidIdentifier NVARCHAR(50) = SUBSTRING(@Remaining, CHARINDEX(':', @Remaining) + 1, LEN(@Remaining));

    -- Resolve TypeId, TypeName, and TableName via the central prefix registry view
    SELECT
        @TypeId    = T.[Id]
        , @TypeName  = T.[TypeName]
        , @TableName = T.[TableName]
    FROM
        [MAC].[vwTableTypesAndPrefixes] AS T
    WHERE
        T.[Prefix] = @Prefix;

    INSERT INTO @Parts
        ([Prefix], [PartKey], [GuidIdentifier], [TypeId], [TableName], [TypeName])
    VALUES
        (@Prefix, @PartKey, @GuidIdentifier, @TypeId, @TableName, @TypeName);

    RETURN;
END
GO

/** UNIT TESTING */
-- DECLARE @NuvolUserContectId UNIQUEIDENTIFIER = (SELECT TOP(1) U.UserId
-- FROM [ACC].[Users] AS U WITH (NOLOCK)
--     INNER JOIN [ACC].[UserRoles] AS UR WITH (NOLOCK) ON (UR.UserId = U.UserId)
--     INNER JOIN [ACC].[Roles] AS R WITH (NOLOCK) ON (R.RoleID = UR.RoleId)
--         AND (R.Name = 'CSR User')
-- ORDER BY R.RoleID);
-- EXEC [SEC].[spSetUserContext] @UserId=@NuvolUserContectId;
DECLARE @TestGuid VARCHAR(36) = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
DECLARE @Proxy03 VARCHAR(100) = 'AFST:3176D:' + @TestGuid;

SELECT *
FROM [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy03);