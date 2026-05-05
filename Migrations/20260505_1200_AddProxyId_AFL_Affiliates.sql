/*
Migration: 20260505_1200_AddProxyId_AFL_Affiliates
Author: Andres Sosa
Date: 2026-05-05
Description: Phase 3 — Onboards AFL.Affiliates into the Proxy-ID pattern.

  1. Creates AFL.AffiliateTypes type table (Prefix source)
  2. Seeds three initial affiliate types: AFST, AFIN, AFPR
  3. Adds AffiliateTypeId, Proxy, PartKey columns to AFL.Affiliates
  4. Adds FK AFL.Affiliates.AffiliateTypeId → AFL.AffiliateTypes.AffiliateTypeID
  5. Rebuilds MAC.vwTableTypesAndPrefixes to include AFL.AffiliateTypes
  6. Rebuilds MAC.fxGeneratePrefixParts to include Affiliate branch

Dependencies:
  20260505_1000_AddProxyIdFoundation    (UTL.fxGetPartKey, MAC infra functions/view)
  20260505_1100_ReconcileProxyIdMacTables  (MAC entity table column corrections)
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260505_1200_AddProxyId_AFL_Affiliates';

    -- =========================================================================
    -- Idempotency check
    -- =========================================================================
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
WHERE name = 'AFL')
        RAISERROR('Schema AFL does not exist.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'MAC')
        RAISERROR('Schema MAC does not exist. Run baseline schema migration first.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'Affiliates' AND schema_id = SCHEMA_ID('AFL'))
        RAISERROR('AFL.Affiliates table does not exist.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.objects
WHERE name = 'fxGetPartKey' AND schema_id = SCHEMA_ID('UTL'))
        RAISERROR('UTL.fxGetPartKey does not exist. Run 20260505_1000_AddProxyIdFoundation first.', 16, 1);

    -- =========================================================================
    -- Step 1: Create AFL.AffiliateTypes
    -- =========================================================================
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'AffiliateTypes' AND schema_id = SCHEMA_ID('AFL'))
    BEGIN
    CREATE TABLE [AFL].[AffiliateTypes]
    (
        [AffiliateTypeID] [int] IDENTITY(1,1) NOT NULL,
        [Prefix] [varchar](4) NOT NULL,
        [AffiliateTypeName] [nvarchar](100) NOT NULL,
        [AffiliateTypeDescription] [nvarchar](max) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_AffiliateTypes_IsActive]     DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_AffiliateTypes_IsDeleted]    DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_AffiliateTypes_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateTypes_CreatedDate]  DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_AffiliateTypes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateTypes_DEX_ROW_TS]   DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_AffiliateTypes] PRIMARY KEY CLUSTERED ([AffiliateTypeID] ASC),
        CONSTRAINT [UQ_AffiliateTypes_Prefix] UNIQUE NONCLUSTERED ([Prefix] ASC)
    );

    PRINT 'Created AFL.AffiliateTypes';
END
    ELSE
        PRINT 'AFL.AffiliateTypes already exists — skipping CREATE';

    -- =========================================================================
    -- Step 2: Seed initial affiliate types
    --         AFST = Standard, AFIN = Influencer, AFPR = Partner
    -- =========================================================================
    MERGE INTO [AFL].[AffiliateTypes] AS target
    USING (VALUES
    ('AFST', 'Standard Affiliate', 'General-purpose affiliate account'),
    ('AFIN', 'Influencer Affiliate', 'Social media influencer affiliate'),
    ('AFPR', 'Partner Affiliate', 'Business partner affiliate')
    ) AS source ([Prefix], [AffiliateTypeName], [AffiliateTypeDescription])
    ON target.[Prefix] = source.[Prefix]
    WHEN MATCHED THEN
        UPDATE SET
            target.[AffiliateTypeName]        = source.[AffiliateTypeName],
            target.[AffiliateTypeDescription] = source.[AffiliateTypeDescription]
    WHEN NOT MATCHED THEN
        INSERT ([Prefix], [AffiliateTypeName], [AffiliateTypeDescription])
        VALUES (source.[Prefix], source.[AffiliateTypeName], source.[AffiliateTypeDescription]);

    PRINT 'Seeded AFL.AffiliateTypes (AFST, AFIN, AFPR)';

    -- =========================================================================
    -- Step 3: Add Proxy-ID columns to AFL.Affiliates
    -- =========================================================================
    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.Affiliates') AND name = 'AffiliateTypeId')
    BEGIN
    ALTER TABLE [AFL].[Affiliates] ADD [AffiliateTypeId] [int] NOT NULL;
    PRINT 'Added AFL.Affiliates.AffiliateTypeId';
END
    ELSE
        PRINT 'AFL.Affiliates.AffiliateTypeId already exists — skipping';

    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.Affiliates') AND name = 'Proxy')
    BEGIN
    ALTER TABLE [AFL].[Affiliates] ADD [Proxy] [varchar](100) NOT NULL;
    PRINT 'Added AFL.Affiliates.Proxy';
END
    ELSE
        PRINT 'AFL.Affiliates.Proxy already exists — skipping';

    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.Affiliates') AND name = 'PartKey')
    BEGIN
    ALTER TABLE [AFL].[Affiliates] ADD [PartKey] [varchar](6) NOT NULL;
    PRINT 'Added AFL.Affiliates.PartKey';
END
    ELSE
        PRINT 'AFL.Affiliates.PartKey already exists — skipping';

    -- =========================================================================
    -- Step 4: Add FK AFL.Affiliates.AffiliateTypeId → AFL.AffiliateTypes
    -- =========================================================================
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Affiliates_AffiliateTypeId')
    BEGIN
    ALTER TABLE [AFL].[Affiliates]
            WITH CHECK ADD CONSTRAINT [FK_Affiliates_AffiliateTypeId]
            FOREIGN KEY ([AffiliateTypeId]) REFERENCES [AFL].[AffiliateTypes] ([AffiliateTypeID]);

    ALTER TABLE [AFL].[Affiliates] CHECK CONSTRAINT [FK_Affiliates_AffiliateTypeId];

    PRINT 'Added FK_Affiliates_AffiliateTypeId';
END
    ELSE
        PRINT 'FK_Affiliates_AffiliateTypeId already exists — skipping';

    -- =========================================================================
    -- Step 5: Rebuild MAC.vwTableTypesAndPrefixes to include AFL.AffiliateTypes
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.views
WHERE name = 'vwTableTypesAndPrefixes' AND schema_id = SCHEMA_ID('MAC'))
        DROP VIEW [MAC].[vwTableTypesAndPrefixes];

    EXEC(N'
CREATE VIEW [MAC].[vwTableTypesAndPrefixes]
AS
    -- =========================================================================
    -- ACC.DealerTenantTypes  (Prefix examples: MSTR, QUAD)
    -- Entity: DealerTenant
    -- =========================================================================
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

    UNION ALL

    -- =========================================================================
    -- AFL.AffiliateTypes  (Prefix examples: AFST, AFIN, AFPR)
    -- Entity: Affiliate
    -- =========================================================================
    SELECT
        [AffiliateTypeID]             AS [Id]
        , [Prefix]
        , [AffiliateTypeName]         AS [Name]
        , [AffiliateTypeDescription]  AS [Description]
        , ''AFL''                     AS [Schema]
        , ''AffiliateTypes''          AS [TableName]
        , ''Affiliate''               AS [TypeName]
    FROM
        [AFL].[AffiliateTypes]
    WHERE
        (IsDeleted = 0)
    ');

    PRINT 'Rebuilt MAC.vwTableTypesAndPrefixes';

    -- =========================================================================
    -- Step 6: Rebuild MAC.fxGeneratePrefixParts to include Affiliate branch
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM sys.objects
WHERE name = 'fxGeneratePrefixParts' AND schema_id = SCHEMA_ID('MAC'))
        DROP FUNCTION [MAC].[fxGeneratePrefixParts];

    EXEC(N'
CREATE FUNCTION [MAC].[fxGeneratePrefixParts] (
    @TypeName  VARCHAR(50)
    , @TypeId  INT
)
RETURNS @Parts TABLE (
    Prefix  VARCHAR(4),
    PartKey VARCHAR(6)
)
AS
BEGIN
    DECLARE @Prefix VARCHAR(4);

    -- =========================================================================
    -- DealerTenant - ACC.DealerTenantTypes
    -- =========================================================================
    IF (@TypeName = ''DealerTenant'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [ACC].[DealerTenantTypes] AS T WITH (NOLOCK)
        WHERE (T.[DealerTenantTypeID] = @TypeId);
    END

    -- =========================================================================
    -- Affiliate - AFL.AffiliateTypes
    -- =========================================================================
    ELSE IF (@TypeName = ''Affiliate'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [AFL].[AffiliateTypes] AS T WITH (NOLOCK)
        WHERE (T.[AffiliateTypeID] = @TypeId);
    END

    -- =========================================================================
    -- ADD NEW ELSE IF BLOCKS BELOW as new Proxy-enabled entities are onboarded.
    -- Follow the checklist in .github/ProxyID-PrefixRegistry.md.
    -- =========================================================================

    -- Insert result row only if a prefix was resolved
    IF (@Prefix IS NOT NULL)
    BEGIN
        INSERT INTO @Parts ([Prefix], [PartKey])
        VALUES (@Prefix, [UTL].[fxGetPartKey]());
    END

    RETURN;
END
    ');

    PRINT 'Rebuilt MAC.fxGeneratePrefixParts';

    -- =========================================================================
    -- Record migration
    -- =========================================================================
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName, 'Phase 3: Onboards AFL.Affiliates into the Proxy-ID pattern — creates AffiliateTypes, adds Proxy/PartKey columns, seeds AFST/AFIN/AFPR, rebuilds MAC view and TVF');

    COMMIT TRANSACTION;
    PRINT 'Migration 20260505_1200_AddProxyId_AFL_Affiliates applied successfully';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/*
================================================================================
ROLLBACK SCRIPT
================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. Drop FK on Affiliates
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Affiliates_AffiliateTypeId')
        ALTER TABLE [AFL].[Affiliates] DROP CONSTRAINT [FK_Affiliates_AffiliateTypeId];

    -- 2. Remove Proxy-ID columns from Affiliates
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AFL.Affiliates') AND name = 'PartKey')
        ALTER TABLE [AFL].[Affiliates] DROP COLUMN [PartKey];

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AFL.Affiliates') AND name = 'Proxy')
        ALTER TABLE [AFL].[Affiliates] DROP COLUMN [Proxy];

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AFL.Affiliates') AND name = 'AffiliateTypeId')
        ALTER TABLE [AFL].[Affiliates] DROP COLUMN [AffiliateTypeId];

    -- 3. Drop AffiliateTypes table
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AffiliateTypes' AND schema_id = SCHEMA_ID('AFL'))
        DROP TABLE [AFL].[AffiliateTypes];

    -- 4. Rebuild view (ACC only — remove AFL block)
    IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vwTableTypesAndPrefixes' AND schema_id = SCHEMA_ID('MAC'))
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

    -- 5. Rebuild fxGeneratePrefixParts (without Affiliate branch)
    IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'fxGeneratePrefixParts' AND schema_id = SCHEMA_ID('MAC'))
        DROP FUNCTION [MAC].[fxGeneratePrefixParts];

    EXEC(N'
CREATE FUNCTION [MAC].[fxGeneratePrefixParts] (
    @TypeName  VARCHAR(50)
    , @TypeId  INT
)
RETURNS @Parts TABLE (
    Prefix  VARCHAR(4),
    PartKey VARCHAR(6)
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

    -- 6. Remove migration record
    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = '20260505_1200_AddProxyId_AFL_Affiliates';

    COMMIT TRANSACTION;
    PRINT 'Rollback complete';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    RAISERROR(ERROR_MESSAGE(), 16, 1);
END CATCH
GO

================================================================================
VERIFICATION QUERIES
================================================================================

-- 1. Confirm AffiliateTypes exists and is seeded
SELECT [AffiliateTypeID], [Prefix], [AffiliateTypeName]
FROM [AFL].[AffiliateTypes]
ORDER BY [AffiliateTypeID];
-- Expected: 3 rows — AFST, AFIN, AFPR

-- 2. Confirm columns on Affiliates
SELECT [COLUMN_NAME], [DATA_TYPE], [CHARACTER_MAXIMUM_LENGTH], [IS_NULLABLE]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'AFL' AND TABLE_NAME = 'Affiliates'
  AND [COLUMN_NAME] IN ('AffiliateTypeId','Proxy','PartKey')
ORDER BY [COLUMN_NAME];
-- Expected: 3 rows

-- 3. Confirm FK exists
SELECT name FROM sys.foreign_keys
WHERE name = 'FK_Affiliates_AffiliateTypeId';
-- Expected: 1 row

-- 4. Confirm AFL rows appear in MAC prefix view
SELECT * FROM [MAC].[vwTableTypesAndPrefixes]
WHERE [Schema] = 'AFL';
-- Expected: 3 rows — AFST, AFIN, AFPR with TypeName = 'Affiliate'

-- 5. Confirm fxGeneratePrefixParts resolves AFST (TypeId=1)
SELECT * FROM [MAC].[fxGeneratePrefixParts]('Affiliate', 1);
-- Expected: 1 row — Prefix='AFST', PartKey=5-char hex (e.g. '316BD')

-- 6. End-to-end proxy generation test
DECLARE @ProxyPrefix VARCHAR(50);
SELECT @ProxyPrefix = [MAC].[fxGeneratePrefixProxy]('Affiliate', 1);
SELECT @ProxyPrefix + CAST(NEWID() AS NVARCHAR(36)) AS SampleProxy;
-- Expected: e.g. 'AFST:316BD:E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8'

-- 7. Confirm migration recorded
SELECT * FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = '20260505_1200_AddProxyId_AFL_Affiliates';
*/
