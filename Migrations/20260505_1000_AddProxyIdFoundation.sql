/*
Migration: 20260505_1000_AddProxyIdFoundation
Author: Andres Sosa
Date: 2026-05-05
Description: Creates the five Proxy-ID infrastructure objects that must exist
             before any entity table can generate or parse Proxy-ID composite
             identifiers (format: Prefix:PartKey:GUID).

             Objects created:
               1. [UTL].[fxGetPartKey]              — Scalar function
                  Returns the hex-encoded year+month PartKey (e.g. "316BD").

               2. [MAC].[vwTableTypesAndPrefixes]    — View
                  Central prefix registry. UNION of all *Types tables that
                  participate in the Proxy-ID pattern.

               3. [MAC].[fxGeneratePrefixParts]      — Table-valued function
                  Returns (Prefix, PartKey) for a given TypeName + TypeId.

               4. [MAC].[fxGeneratePrefixProxy]      — Scalar function
                  Returns "Prefix:PartKey:" for a given TypeName + TypeId.
                  Caller appends CAST(NEWID() AS NVARCHAR(36)).

               5. [MAC].[fxGetPrefixTypeIdFromProxy] — Table-valued function
                  Parses a full proxy string back to its component parts and
                  resolves TypeId / TypeName via vwTableTypesAndPrefixes.

             Initial coverage: ACC.DealerTenantTypes (prefixes: MSTR, QUAD).
             All other entities will be added incrementally as features grow.

Dependencies: 20260313_0845_Baseline_Schemas (MAC schema must exist)
              ACC.DealerTenantTypes must exist and have Prefix column
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260505_1000_AddProxyIdFoundation';

    -- Check if already applied
    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- =========================================================================
    -- Prerequisite checks
    -- =========================================================================
    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'UTL')
        RAISERROR('Schema UTL does not exist. Run baseline schema migration first.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'MAC')
        RAISERROR('Schema MAC does not exist. Run baseline schema migration first.', 16, 1);

    IF NOT EXISTS (
        SELECT 1
FROM sys.tables AS t
    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = 'ACC' AND t.name = 'DealerTenantTypes'
    )
        RAISERROR('Table ACC.DealerTenantTypes does not exist. Run baseline deployment first.', 16, 1);

    IF NOT EXISTS (
        SELECT 1
FROM sys.columns AS c
    INNER JOIN sys.tables AS t ON t.object_id = c.object_id
    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = 'ACC' AND t.name = 'DealerTenantTypes' AND c.name = 'Prefix'
    )
        RAISERROR('Column ACC.DealerTenantTypes.Prefix does not exist. Baseline table is missing the Prefix column.', 16, 1);

    -- =========================================================================
    -- 1. UTL.fxGetPartKey  (Scalar function)
    --    Must be created before fxGeneratePrefixParts which calls it.
    -- =========================================================================
    IF OBJECT_ID('[UTL].[fxGetPartKey]', 'FN') IS NOT NULL
        DROP FUNCTION [UTL].[fxGetPartKey];

    EXEC(N'
CREATE FUNCTION [UTL].[fxGetPartKey] ()
RETURNS VARCHAR(6)
AS
BEGIN
    DECLARE @Year     VARCHAR(4);
    DECLARE @Month    VARCHAR(2);
    DECLARE @StrValue VARCHAR(10);
    DECLARE @HexValue VARCHAR(10);
    DECLARE @Number   INT;

    SET @Year  = CAST(YEAR(GETDATE()) AS VARCHAR(4));
    SET @Month = RIGHT(''0'' + CAST(MONTH(GETDATE()) AS VARCHAR(2)), 2);
    SET @StrValue = @Year + @Month;
    SET @Number   = CAST(@StrValue AS INT);
    SET @HexValue = CONVERT(VARCHAR(10), CONVERT(VARBINARY(4), @Number), 1);

    RETURN REPLACE(@HexValue, ''0x000'', '''');
END
    ');

    PRINT 'Created [UTL].[fxGetPartKey]';

    -- =========================================================================
    -- 2. MAC.vwTableTypesAndPrefixes  (View)
    --    Must exist before fxGetPrefixTypeIdFromProxy which queries it.
    -- =========================================================================
    IF OBJECT_ID('[MAC].[vwTableTypesAndPrefixes]', 'V') IS NOT NULL
        DROP VIEW [MAC].[vwTableTypesAndPrefixes];

    EXEC(N'
CREATE VIEW [MAC].[vwTableTypesAndPrefixes]
AS
    SELECT
        [DealerTenantTypeID]            AS [Id]
        , [Prefix]
        , [DealerTenantTypeName]        AS [Name]
        , [DealerTenantTypeDescription] AS [Description]
        , ''ACC''                       AS [Schema]
        , ''DealerTenantTypes''         AS [TableName]
        , ''DealerTenant''              AS [TypeName]
    FROM
        [ACC].[DealerTenantTypes]
    WHERE
        (IsDeleted = 0)
    ');

    PRINT 'Created [MAC].[vwTableTypesAndPrefixes]';

    -- =========================================================================
    -- 3. MAC.fxGeneratePrefixParts  (Table-valued function)
    --    Depends on UTL.fxGetPartKey (created above).
    -- =========================================================================
    IF OBJECT_ID('[MAC].[fxGeneratePrefixParts]', 'TF') IS NOT NULL
        DROP FUNCTION [MAC].[fxGeneratePrefixParts];

    EXEC(N'
CREATE FUNCTION [MAC].[fxGeneratePrefixParts] (
    @TypeName  VARCHAR(50)
    , @TypeId  INT
)
RETURNS @Parts TABLE (
    Prefix   VARCHAR(4),
    PartKey  VARCHAR(6)
)
AS
BEGIN
    DECLARE @Prefix VARCHAR(4);

    IF (@TypeName = ''DealerTenant'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [ACC].[DealerTenantTypes] AS T WITH (NOLOCK)
        WHERE (T.[DealerTenantTypeID] = @TypeId);
    END

    IF (@Prefix IS NOT NULL)
    BEGIN
        INSERT INTO @Parts ([Prefix], [PartKey])
        VALUES (@Prefix, [UTL].[fxGetPartKey]());
    END

    RETURN;
END
    ');

    PRINT 'Created [MAC].[fxGeneratePrefixParts]';

    -- =========================================================================
    -- 4. MAC.fxGeneratePrefixProxy  (Scalar function)
    --    Depends on fxGeneratePrefixParts (created above).
    -- =========================================================================
    IF OBJECT_ID('[MAC].[fxGeneratePrefixProxy]', 'FN') IS NOT NULL
        DROP FUNCTION [MAC].[fxGeneratePrefixProxy];

    EXEC(N'
CREATE FUNCTION [MAC].[fxGeneratePrefixProxy] (
    @TypeName  VARCHAR(50)
    , @TypeId  INT
)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Result NVARCHAR(50);

    SELECT @Result = [Prefix] + '':'' + [PartKey] + '':''
    FROM [MAC].[fxGeneratePrefixParts](@TypeName, @TypeId);

    RETURN @Result;
END
    ');

    PRINT 'Created [MAC].[fxGeneratePrefixProxy]';

    -- =========================================================================
    -- 5. MAC.fxGetPrefixTypeIdFromProxy  (Table-valued function)
    --    Depends on vwTableTypesAndPrefixes (created above).
    -- =========================================================================
    IF OBJECT_ID('[MAC].[fxGetPrefixTypeIdFromProxy]', 'TF') IS NOT NULL
        DROP FUNCTION [MAC].[fxGetPrefixTypeIdFromProxy];

    EXEC(N'
CREATE FUNCTION [MAC].[fxGetPrefixTypeIdFromProxy] (
    @Proxy VARCHAR(100)
)
RETURNS @Parts TABLE (
    Prefix          NVARCHAR(50),
    PartKey         VARCHAR(6),
    GuidIdentifier  VARCHAR(50),
    TypeId          INT,
    TableName       NVARCHAR(100),
    TypeName        NVARCHAR(100)
)
AS
BEGIN
    DECLARE @Prefix     NVARCHAR(50);
    DECLARE @TypeName   NVARCHAR(100);
    DECLARE @TableName  NVARCHAR(100);
    DECLARE @TypeId     INT;

    SET @Prefix = LEFT(@Proxy, CHARINDEX('':'', @Proxy) - 1);

    DECLARE @Remaining      NVARCHAR(100) = SUBSTRING(@Proxy, CHARINDEX('':'', @Proxy) + 1, LEN(@Proxy));
    DECLARE @PartKey        NVARCHAR(10)  = LEFT(@Remaining, CHARINDEX('':'', @Remaining) - 1);
    DECLARE @GuidIdentifier NVARCHAR(50)  = SUBSTRING(@Remaining, CHARINDEX('':'', @Remaining) + 1, LEN(@Remaining));

    SELECT
        @TypeId    = T.[Id]
        , @TypeName  = T.[TypeName]
        , @TableName = T.[TableName]
    FROM
        [MAC].[vwTableTypesAndPrefixes] AS T
    WHERE
        T.[Prefix] = @Prefix;

    INSERT INTO @Parts ([Prefix], [PartKey], [GuidIdentifier], [TypeId], [TableName], [TypeName])
    VALUES (@Prefix, @PartKey, @GuidIdentifier, @TypeId, @TableName, @TypeName);

    RETURN;
END
    ');

    PRINT 'Created [MAC].[fxGetPrefixTypeIdFromProxy]';

    -- =========================================================================
    -- Record migration
    -- =========================================================================
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (
        @MigrationName,
        'Creates 5 Proxy-ID infrastructure objects: UTL.fxGetPartKey, MAC.vwTableTypesAndPrefixes, MAC.fxGeneratePrefixParts, MAC.fxGeneratePrefixProxy, MAC.fxGetPrefixTypeIdFromProxy. Initial coverage: ACC.DealerTenantTypes.'
    );

    COMMIT TRANSACTION;
    PRINT 'Migration 20260505_1000_AddProxyIdFoundation applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
----------------
DROP FUNCTION IF EXISTS [MAC].[fxGetPrefixTypeIdFromProxy];
DROP FUNCTION IF EXISTS [MAC].[fxGeneratePrefixProxy];
DROP FUNCTION IF EXISTS [MAC].[fxGeneratePrefixParts];
DROP VIEW   IF EXISTS [MAC].[vwTableTypesAndPrefixes];
DROP FUNCTION IF EXISTS [UTL].[fxGetPartKey];
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260505_1000_AddProxyIdFoundation';
*/

/*
TEST QUERIES:
-------------
-- Verify PartKey for current month
SELECT [UTL].[fxGetPartKey]();                                  -- e.g. "316BD"

-- Verify prefix parts lookup
SELECT * FROM [MAC].[fxGeneratePrefixParts]('DealerTenant', 1); -- Prefix=MSTR, PartKey=316BD

-- Verify proxy prefix generation (caller appends NEWID)
SELECT [MAC].[fxGeneratePrefixProxy]('DealerTenant', 1);        -- "MSTR:316BD:"

-- Verify proxy parsing
SELECT * FROM [MAC].[fxGetPrefixTypeIdFromProxy]('MSTR:316BD:E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8');

-- Verify central registry view
SELECT * FROM [MAC].[vwTableTypesAndPrefixes];
*/
