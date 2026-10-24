/*
Migration: 20261024_1637_CreateDOCDocuments
Author: Database Team
Date: 2026-10-24
Description: Creates tenant-owned document metadata and its Proxy-ID type registry.
             File bytes stay in external storage. Supports all file formats.
Dependencies: 20261024_1634_CreateDOCSchema
              20260505_1200_AddProxyId_AFL_Affiliates
              ACC.DealerTenants, UTL.fxGetPartKey, MAC Proxy-ID infrastructure
Expected impact: Adds two DOC tables, one seed row, and lookup indexes;
                 extends the existing MAC Proxy-ID view and generation function.
*/

SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261024_1637_CreateDOCDocuments';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF SCHEMA_ID(N'DOC') IS NULL
        THROW 50001, 'Run the DOC schema migration first.', 1;
    IF OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL
        THROW 50001, 'ACC.DealerTenants is required.', 1;
    IF OBJECT_ID(N'MAC.fxGeneratePrefixParts', N'TF') IS NULL
       OR OBJECT_ID(N'MAC.vwTableTypesAndPrefixes', N'V') IS NULL
       OR OBJECT_ID(N'UTL.fxGetPartKey', N'FN') IS NULL
       OR OBJECT_ID(N'MAC.fxGeneratePrefixProxy', N'FN') IS NULL
       OR OBJECT_ID(N'MAC.fxGetPrefixTypeIdFromProxy') IS NULL
        THROW 50001, 'Deploy the existing Proxy-ID infrastructure first.', 1;

    -- Never mark a pre-existing API prototype table as migrated without reconciling it.
    IF OBJECT_ID(N'DOC.Documents', N'U') IS NOT NULL
       OR OBJECT_ID(N'DOC.DocumentTypes', N'U') IS NOT NULL
        THROW 50001, 'Untracked DOC tables exist. Reconcile their structure and data before applying this creation migration.', 1;
    IF EXISTS (SELECT 1 FROM [MAC].[vwTableTypesAndPrefixes] WHERE [Prefix] = 'DOCT')
        THROW 50001, 'The DOCT prefix is already assigned. Resolve the registry collision first.', 1;

IF OBJECT_ID(N'DOC.DocumentTypes', N'U') IS NULL
BEGIN
    CREATE TABLE [DOC].[DocumentTypes]
    (
        [DocumentTypeID] INT IDENTITY(1,1) NOT NULL,
        [Prefix] VARCHAR(4) NOT NULL,
        [DocumentTypeName] NVARCHAR(100) NOT NULL,
        [DocumentTypeDescription] NVARCHAR(2000) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_DocumentTypes_IsActive] DEFAULT (1),
        [IsDeleted] BIT NOT NULL CONSTRAINT [DF_DocumentTypes_IsDeleted] DEFAULT (0),
        [ModifiedDate] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_DocumentTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] UNIQUEIDENTIFIER NOT NULL,
        [CreatedDate] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_DocumentTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] UNIQUEIDENTIFIER NOT NULL,
        [DEX_ROW_TS] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_DocumentTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_DocumentTypes] PRIMARY KEY CLUSTERED ([DocumentTypeID]),
        CONSTRAINT [UQ_DocumentTypes_Prefix] UNIQUE ([Prefix]),
        CONSTRAINT [CK_DocumentTypes_Prefix] CHECK
            (DATALENGTH([Prefix]) = 4 AND [Prefix] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^A-Z0-9]%')
    );
END;

-- A deployed prefix is immutable: fail rather than silently reassigning it.
IF EXISTS (SELECT 1 FROM [DOC].[DocumentTypes]
           WHERE ([DocumentTypeID] = 1 AND [Prefix] <> 'DOCT')
              OR ([Prefix] = 'DOCT' AND [DocumentTypeID] <> 1))
    THROW 50001, 'Document type 1 must use the registered DOCT prefix.', 1;

SET IDENTITY_INSERT [DOC].[DocumentTypes] ON;
BEGIN TRY
    MERGE INTO [DOC].[DocumentTypes] AS target
    USING (VALUES (1, 'DOCT', N'General Document',
        N'General-purpose document, including signed contracts and engineering files such as DXF.'))
        AS source ([DocumentTypeID], [Prefix], [DocumentTypeName], [DocumentTypeDescription])
    ON target.[DocumentTypeID] = source.[DocumentTypeID]
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([DocumentTypeID], [Prefix], [DocumentTypeName], [DocumentTypeDescription],
                [ModifiedById], [CreatedById])
        VALUES (source.[DocumentTypeID], source.[Prefix], source.[DocumentTypeName],
                source.[DocumentTypeDescription],
                'E6872B58-52B2-415C-A32B-45805F95A70A', 'E6872B58-52B2-415C-A32B-45805F95A70A');
    SET IDENTITY_INSERT [DOC].[DocumentTypes] OFF;
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT [DOC].[DocumentTypes] OFF;
    THROW;
END CATCH;

IF OBJECT_ID(N'DOC.Documents', N'U') IS NULL
BEGIN
    CREATE TABLE [DOC].[Documents]
    (
        [DocumentID] BIGINT IDENTITY(1,1) NOT NULL,
        [DealerTenantId] INT NOT NULL,
        [DocumentTypeId] INT NOT NULL CONSTRAINT [DF_Documents_DocumentTypeId] DEFAULT (1),
        [Proxy] VARCHAR(100) NOT NULL,
        [PartKey] VARCHAR(6) NOT NULL,
        [FileName] NVARCHAR(255) NOT NULL,
        [Title] NVARCHAR(255) NOT NULL,
        [Description] NVARCHAR(2000) NULL,
        [ContentType] NVARCHAR(255) NOT NULL,
        [SizeBytes] BIGINT NOT NULL,
        [Sha256] VARCHAR(64) NOT NULL,
        [StorageKey] NVARCHAR(100) NOT NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_Documents_IsActive] DEFAULT (1),
        [IsDeleted] BIT NOT NULL CONSTRAINT [DF_Documents_IsDeleted] DEFAULT (0),
        [ModifiedDate] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_Documents_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] UNIQUEIDENTIFIER NOT NULL,
        [CreatedDate] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_Documents_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] UNIQUEIDENTIFIER NOT NULL,
        [DEX_ROW_TS] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_Documents_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Documents] PRIMARY KEY CLUSTERED ([DocumentID]),
        CONSTRAINT [FK_Documents_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Documents_DocumentTypes] FOREIGN KEY ([DocumentTypeId])
            REFERENCES [DOC].[DocumentTypes] ([DocumentTypeID]),
        CONSTRAINT [CK_Documents_SizeBytes] CHECK ([SizeBytes] > 0),
        CONSTRAINT [CK_Documents_Sha256] CHECK
            (DATALENGTH([Sha256]) = 64 AND [Sha256] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9A-Fa-f]%'),
        CONSTRAINT [UQ_Documents_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [UQ_Documents_StorageKey] UNIQUE ([StorageKey])
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'DOC.Documents') AND [name] = N'IX_Documents_DealerTenantId_IsActive_DocumentID')
    CREATE NONCLUSTERED INDEX [IX_Documents_DealerTenantId_IsActive_DocumentID]
        ON [DOC].[Documents] ([DealerTenantId], [IsActive], [DocumentID] DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'DOC.Documents') AND [name] = N'IX_Documents_PartKey_DocumentTypeId')
    CREATE NONCLUSTERED INDEX [IX_Documents_PartKey_DocumentTypeId]
        ON [DOC].[Documents] ([PartKey], [DocumentTypeId]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'DOC.Documents') AND [name] = N'IX_Documents_DocumentTypeId')
    CREATE NONCLUSTERED INDEX [IX_Documents_DocumentTypeId]
        ON [DOC].[Documents] ([DocumentTypeId]);

    -- Separate batches are required for programmable object definitions.
    EXEC sys.sp_executesql N'CREATE OR ALTER VIEW [MAC].[vwTableTypesAndPrefixes]
AS
    -- =========================================================================
    -- ACC.DealerTenantTypes  (Prefix examples: MSTR, QUAD)
    -- Entity: DealerTenant
    -- =========================================================================
    SELECT
        [DealerTenantTypeID]          AS [Id]
        , [Prefix]
        , [DealerTenantTypeName]      AS [Name]
        , [DealerTenantTypeDescription] AS [Description]
        , ''ACC''                       AS [Schema]
        , ''DealerTenantTypes''         AS [TableName]
        , ''DealerTenant''              AS [TypeName]
    FROM
        [ACC].[DealerTenantTypes]
    WHERE
        (IsDeleted = 0)

    -- =========================================================================
    -- ADD NEW UNION BLOCKS BELOW as new Proxy-enabled entities are onboarded.
    -- Follow the checklist in .github/ProxyID-PrefixRegistry.md.
    -- =========================================================================

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
        , ''AFL''                       AS [Schema]
        , ''AffiliateTypes''            AS [TableName]
        , ''Affiliate''                 AS [TypeName]
    FROM
        [AFL].[AffiliateTypes]
    WHERE
        (IsDeleted = 0)

    UNION ALL

    SELECT
        [DocumentTypeID] AS [Id],
        [Prefix],
        [DocumentTypeName] AS [Name],
        [DocumentTypeDescription] AS [Description],
        ''DOC'' AS [Schema],
        ''DocumentTypes'' AS [TableName],
        ''Document'' AS [TypeName]
    FROM [DOC].[DocumentTypes]
    WHERE [IsDeleted] = 0';

    EXEC sys.sp_executesql N'CREATE OR ALTER FUNCTION [MAC].[fxGeneratePrefixParts] (
    @TypeName  VARCHAR(50)
    , @TypeId  INT
)
RETURNS @Parts TABLE (
    Prefix VARCHAR(4),
    PartKey VARCHAR(6)
)
AS
BEGIN
    DECLARE @Prefix VARCHAR(4);

    -- =========================================================================
    -- DealerTenant — ACC.DealerTenantTypes
    -- =========================================================================
    IF (@TypeName = ''DealerTenant'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [ACC].[DealerTenantTypes] AS T WITH (NOLOCK)
        WHERE (T.[DealerTenantTypeID] = @TypeId);
    END

    -- =========================================================================
    -- ADD NEW ELSE IF BLOCKS BELOW as new Proxy-enabled entities are onboarded.
    -- Follow the checklist in .github/ProxyID-PrefixRegistry.md.
    -- =========================================================================

    -- =========================================================================
    -- Affiliate — AFL.AffiliateTypes
    -- =========================================================================
    ELSE IF (@TypeName = ''Affiliate'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [AFL].[AffiliateTypes] AS T WITH (NOLOCK)
        WHERE (T.[AffiliateTypeID] = @TypeId);
    END

    -- Insert result row only if a prefix was resolved
    ELSE IF (@TypeName = ''Document'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [DOC].[DocumentTypes] AS T
        WHERE T.[DocumentTypeID] = @TypeId AND T.[IsActive] = 1 AND T.[IsDeleted] = 0;
    END

    -- Insert result row only if a prefix was resolved
    IF (@Prefix IS NOT NULL)
    BEGIN
        INSERT INTO @Parts
            ([Prefix], [PartKey])
        VALUES
            (@Prefix, [UTL].[fxGetPartKey]());
    END

    RETURN;
END';

    INSERT INTO [dbo].[SchemaVersion]
        ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Creates DOC.Documents, DocumentTypes, DOCT seed and Proxy-ID integration.',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'DOC document metadata migration applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
ROLLBACK SCRIPT:
-- Only use before document data is accepted and before subsequent changes to the
-- MAC helpers. Restore/reconcile subsequent helper registrations before rollback.
-- Guards refuse to discard uploaded document metadata.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    IF EXISTS (SELECT 1 FROM [DOC].[Documents])
        THROW 50001, 'Documents contains data; archive metadata and stored files before rollback.', 1;

    EXEC sys.sp_executesql N'CREATE OR ALTER VIEW [MAC].[vwTableTypesAndPrefixes]
AS
    -- =========================================================================
    -- ACC.DealerTenantTypes  (Prefix examples: MSTR, QUAD)
    -- Entity: DealerTenant
    -- =========================================================================
    SELECT
        [DealerTenantTypeID]          AS [Id]
        , [Prefix]
        , [DealerTenantTypeName]      AS [Name]
        , [DealerTenantTypeDescription] AS [Description]
        , ''ACC''                       AS [Schema]
        , ''DealerTenantTypes''         AS [TableName]
        , ''DealerTenant''              AS [TypeName]
    FROM
        [ACC].[DealerTenantTypes]
    WHERE
        (IsDeleted = 0)

    -- =========================================================================
    -- ADD NEW UNION BLOCKS BELOW as new Proxy-enabled entities are onboarded.
    -- Follow the checklist in .github/ProxyID-PrefixRegistry.md.
    -- =========================================================================

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
        , ''AFL''                       AS [Schema]
        , ''AffiliateTypes''            AS [TableName]
        , ''Affiliate''                 AS [TypeName]
    FROM
        [AFL].[AffiliateTypes]
    WHERE
        (IsDeleted = 0)';

    EXEC sys.sp_executesql N'CREATE OR ALTER FUNCTION [MAC].[fxGeneratePrefixParts] (
    @TypeName  VARCHAR(50)
    , @TypeId  INT
)
RETURNS @Parts TABLE (
    Prefix VARCHAR(4),
    PartKey VARCHAR(6)
)
AS
BEGIN
    DECLARE @Prefix VARCHAR(4);

    -- =========================================================================
    -- DealerTenant — ACC.DealerTenantTypes
    -- =========================================================================
    IF (@TypeName = ''DealerTenant'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [ACC].[DealerTenantTypes] AS T WITH (NOLOCK)
        WHERE (T.[DealerTenantTypeID] = @TypeId);
    END

    -- =========================================================================
    -- ADD NEW ELSE IF BLOCKS BELOW as new Proxy-enabled entities are onboarded.
    -- Follow the checklist in .github/ProxyID-PrefixRegistry.md.
    -- =========================================================================

    -- =========================================================================
    -- Affiliate — AFL.AffiliateTypes
    -- =========================================================================
    ELSE IF (@TypeName = ''Affiliate'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [AFL].[AffiliateTypes] AS T WITH (NOLOCK)
        WHERE (T.[AffiliateTypeID] = @TypeId);
    END
    -- Insert result row only if a prefix was resolved
    IF (@Prefix IS NOT NULL)
    BEGIN
        INSERT INTO @Parts
            ([Prefix], [PartKey])
        VALUES
            (@Prefix, [UTL].[fxGetPartKey]());
    END

    RETURN;
END';

    DROP TABLE IF EXISTS [DOC].[Documents];
    DROP TABLE IF EXISTS [DOC].[DocumentTypes];
    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = N'20261024_1637_CreateDOCDocuments';
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
*/

