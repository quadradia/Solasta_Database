/*
Migration: 20261103_2132_AddAFL_AffiliateApplicationsAndBucks
Author: Andres Sosa
Date: 2026-11-03
Description: Phase 1 of the affiliate program (website signup -> staff review -> portal login).

  1. Recreates AFL.Affiliates to add [UserId] (the Identity Server user id, `sub`) in
     constitutional column order, and adds UQ_Affiliates_Proxy. Rows are preserved;
     any row with an empty Proxy/PartKey (written by the old API create path) gets a
     generated proxy.
  2. Creates AFL.AffiliateApplicationTypes (prefix AFAW) and AFL.AffiliateApplications:
     signups from mysolasta.com, Pending -> Approved | Rejected. At most one Pending
     application per tenant and email.
  3. Creates AFL.BucksTransactionTypes (AFBP, AFBR, AFBD, AFBA) and AFL.BucksTransactions:
     the append-only Solasta Bucks ledger. A balance is SUM([Amount]); there is no
     balance column. Rows are never updated or deleted by the application.
  4. Extends MAC.vwTableTypesAndPrefixes and MAC.fxGeneratePrefixParts for the new types.

Dependencies:
  20260505_1200_AddProxyId_AFL_Affiliates
  20261024_1637_CreateDOCDocuments   (current MAC view/function definitions include DOC)

Expected impact:
  AFL.Affiliates is dropped and recreated inside the transaction. Table-level GRANTs and
  extended properties on AFL.Affiliates are not carried over; re-apply them if any exist.
  FK_AffiliateCampaigns_Affiliates is dropped and recreated. No other objects change.
*/

-- Filtered indexes require these; sqlcmd defaults QUOTED_IDENTIFIER to OFF.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261103_2132_AddAFL_AffiliateApplicationsAndBucks';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();
    DECLARE @SystemUserId UNIQUEIDENTIFIER = 'E6872B58-52B2-415C-A32B-45805F95A70A';

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- =========================================================================
    -- Prerequisite checks
    -- =========================================================================
    IF OBJECT_ID(N'AFL.Affiliates', N'U') IS NULL OR OBJECT_ID(N'AFL.AffiliateTypes', N'U') IS NULL
        THROW 50001, 'AFL.Affiliates and AFL.AffiliateTypes are required.', 1;
    IF OBJECT_ID(N'DOC.DocumentTypes', N'U') IS NULL
        THROW 50001, 'Apply 20261024_1637_CreateDOCDocuments first; the MAC objects rebuilt here include DOC.', 1;
    IF OBJECT_ID(N'MAC.fxGeneratePrefixParts', N'TF') IS NULL
       OR OBJECT_ID(N'MAC.vwTableTypesAndPrefixes', N'V') IS NULL
       OR OBJECT_ID(N'MAC.fxGeneratePrefixProxy', N'FN') IS NULL
       OR OBJECT_ID(N'UTL.fxGetPartKey', N'FN') IS NULL
        THROW 50001, 'Deploy the existing Proxy-ID infrastructure first.', 1;

    IF COL_LENGTH(N'AFL.Affiliates', N'UserId') IS NOT NULL
        THROW 50001, 'AFL.Affiliates already has UserId. Reconcile the table before applying this migration.', 1;
    IF EXISTS (SELECT 1 FROM sys.foreign_keys
               WHERE [referenced_object_id] = OBJECT_ID(N'AFL.Affiliates')
                 AND [name] <> N'FK_AffiliateCampaigns_Affiliates')
        THROW 50001, 'An unexpected foreign key references AFL.Affiliates. Add it to this migration before recreating the table.', 1;
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE [parent_id] = OBJECT_ID(N'AFL.Affiliates'))
        THROW 50001, 'AFL.Affiliates has triggers. Add them to this migration before recreating the table.', 1;
    IF EXISTS (SELECT 1 FROM [AFL].[Affiliates] WHERE [Proxy] <> '' GROUP BY [Proxy] HAVING COUNT(*) > 1)
        THROW 50001, 'AFL.Affiliates has duplicate Proxy values; UQ_Affiliates_Proxy cannot be created.', 1;

    IF OBJECT_ID(N'AFL.AffiliateApplicationTypes', N'U') IS NOT NULL
       OR OBJECT_ID(N'AFL.AffiliateApplications', N'U') IS NOT NULL
       OR OBJECT_ID(N'AFL.BucksTransactionTypes', N'U') IS NOT NULL
       OR OBJECT_ID(N'AFL.BucksTransactions', N'U') IS NOT NULL
        THROW 50001, 'Untracked AFL application/Bucks tables exist. Reconcile them before applying this migration.', 1;
    IF EXISTS (SELECT 1 FROM [MAC].[vwTableTypesAndPrefixes]
               WHERE [Prefix] IN ('AFAW', 'AFBP', 'AFBR', 'AFBD', 'AFBA'))
        THROW 50001, 'A new AFL prefix is already assigned. Resolve the registry collision first.', 1;

    -- =========================================================================
    -- Step 1: Recreate AFL.Affiliates with UserId
    -- =========================================================================
    SELECT * INTO #AffiliatesBackup FROM [AFL].[Affiliates];

    ALTER TABLE [AFL].[AffiliateCampaigns] DROP CONSTRAINT [FK_AffiliateCampaigns_Affiliates];
    DROP TABLE [AFL].[Affiliates];

    CREATE TABLE [AFL].[Affiliates]
    (
        [AffiliateID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [AffiliateTypeId] [int] NOT NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        [UserId] [uniqueidentifier] NULL,
        [AffiliateCode] [varchar](20) NOT NULL,
        [FirstName] [nvarchar](50) NOT NULL,
        [LastName] [nvarchar](50) NOT NULL,
        [Email] [nvarchar](256) NOT NULL,
        [PhoneMobile] [nvarchar](20) NULL,
        [CommissionRate] [decimal](5,4) NULL,
        [Notes] [nvarchar](max) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Affiliates_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Affiliates_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Affiliates_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Affiliates_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Affiliates_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Affiliates_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Affiliates_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Affiliates] PRIMARY KEY CLUSTERED ([AffiliateID] ASC),
        CONSTRAINT [FK_Affiliates_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Affiliates_AffiliateTypeId] FOREIGN KEY ([AffiliateTypeId])
            REFERENCES [AFL].[AffiliateTypes] ([AffiliateTypeID]),
        CONSTRAINT [UQ_Affiliates_AffiliateCode] UNIQUE ([AffiliateCode]),
        CONSTRAINT [UQ_Affiliates_Proxy] UNIQUE ([Proxy])
    );

    SET IDENTITY_INSERT [AFL].[Affiliates] ON;
    INSERT INTO [AFL].[Affiliates]
        ([AffiliateID], [DealerTenantId], [AffiliateTypeId], [Proxy], [PartKey],
         [AffiliateCode], [FirstName], [LastName], [Email], [PhoneMobile], [CommissionRate], [Notes],
         [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById], [DEX_ROW_TS])
    SELECT
        B.[AffiliateID], B.[DealerTenantId], B.[AffiliateTypeId],
        CASE WHEN B.[Proxy] = '' OR B.[PartKey] = '' THEN G.[NewProxy] ELSE B.[Proxy] END,
        CASE WHEN B.[Proxy] = '' OR B.[PartKey] = ''
             THEN SUBSTRING(G.[NewProxy], 6, CHARINDEX(':', G.[NewProxy], 6) - 6)
             ELSE B.[PartKey] END,
        B.[AffiliateCode], B.[FirstName], B.[LastName], B.[Email], B.[PhoneMobile], B.[CommissionRate], B.[Notes],
        B.[IsActive], B.[IsDeleted], B.[ModifiedDate], B.[ModifiedById], B.[CreatedDate], B.[CreatedById], B.[DEX_ROW_TS]
    FROM #AffiliatesBackup AS B
    CROSS APPLY (SELECT [MAC].[fxGeneratePrefixProxy]('Affiliate', B.[AffiliateTypeId])
                        + CAST(NEWID() AS NVARCHAR(36)) AS [NewProxy]) AS G;
    SET IDENTITY_INSERT [AFL].[Affiliates] OFF;

    DROP TABLE #AffiliatesBackup;

    -- One portal login maps to at most one affiliate. Separate batch: this batch was
    -- compiled against the old table, which has no UserId column.
    EXEC sys.sp_executesql N'CREATE UNIQUE NONCLUSTERED INDEX [IX_Affiliates_UserId]
        ON [AFL].[Affiliates] ([UserId]) WHERE [UserId] IS NOT NULL;';
    CREATE NONCLUSTERED INDEX [IX_Affiliates_DealerTenantId_Email]
        ON [AFL].[Affiliates] ([DealerTenantId], [Email]);
    CREATE NONCLUSTERED INDEX [IX_Affiliates_PartKey_AffiliateTypeId]
        ON [AFL].[Affiliates] ([PartKey], [AffiliateTypeId]);

    ALTER TABLE [AFL].[AffiliateCampaigns] WITH CHECK ADD CONSTRAINT [FK_AffiliateCampaigns_Affiliates]
        FOREIGN KEY ([AffiliateId]) REFERENCES [AFL].[Affiliates] ([AffiliateID]);

    PRINT 'Recreated AFL.Affiliates with UserId';

    -- =========================================================================
    -- Step 2: AFL.AffiliateApplicationTypes + AFL.AffiliateApplications
    -- =========================================================================
    CREATE TABLE [AFL].[AffiliateApplicationTypes]
    (
        [AffiliateApplicationTypeID] [int] IDENTITY(1,1) NOT NULL,
        [Prefix] [varchar](4) NOT NULL,
        [AffiliateApplicationTypeName] [nvarchar](100) NOT NULL,
        [AffiliateApplicationTypeDescription] [nvarchar](2000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_AffiliateApplicationTypes_IsActive] DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_AffiliateApplicationTypes_IsDeleted] DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplicationTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplicationTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplicationTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_AffiliateApplicationTypes] PRIMARY KEY CLUSTERED ([AffiliateApplicationTypeID]),
        CONSTRAINT [UQ_AffiliateApplicationTypes_Prefix] UNIQUE ([Prefix]),
        CONSTRAINT [CK_AffiliateApplicationTypes_Prefix] CHECK
            (DATALENGTH([Prefix]) = 4 AND [Prefix] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^A-Z0-9]%')
    );

    SET IDENTITY_INSERT [AFL].[AffiliateApplicationTypes] ON;
    INSERT INTO [AFL].[AffiliateApplicationTypes]
        ([AffiliateApplicationTypeID], [Prefix], [AffiliateApplicationTypeName], [AffiliateApplicationTypeDescription],
         [ModifiedById], [CreatedById])
    VALUES
        (1, 'AFAW', N'Website Application', N'Submitted through the public affiliate signup form.',
         @SystemUserId, @SystemUserId);
    SET IDENTITY_INSERT [AFL].[AffiliateApplicationTypes] OFF;

    CREATE TABLE [AFL].[AffiliateApplications]
    (
        [AffiliateApplicationID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [AffiliateApplicationTypeId] [int] NOT NULL CONSTRAINT [DF_AffiliateApplications_AffiliateApplicationTypeId] DEFAULT (1),
        [AffiliateId] [bigint] NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        [Status] [varchar](20) NOT NULL CONSTRAINT [DF_AffiliateApplications_Status] DEFAULT ('Pending'),
        [FirstName] [nvarchar](50) NOT NULL,
        [LastName] [nvarchar](50) NOT NULL,
        [Email] [nvarchar](256) NOT NULL,
        [PhoneMobile] [nvarchar](20) NULL,
        [StreetAddress] [nvarchar](200) NULL,
        [City] [nvarchar](100) NULL,
        [StateCode] [char](2) NULL,
        [PostalCode] [varchar](10) NULL,
        [ReviewedDate] [datetimeoffset](7) NULL,
        [ReviewedById] [uniqueidentifier] NULL,
        [ReviewNotes] [nvarchar](1000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_AffiliateApplications_IsActive] DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_AffiliateApplications_IsDeleted] DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplications_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplications_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplications_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_AffiliateApplications] PRIMARY KEY CLUSTERED ([AffiliateApplicationID]),
        CONSTRAINT [FK_AffiliateApplications_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_AffiliateApplications_AffiliateApplicationTypes] FOREIGN KEY ([AffiliateApplicationTypeId])
            REFERENCES [AFL].[AffiliateApplicationTypes] ([AffiliateApplicationTypeID]),
        CONSTRAINT [FK_AffiliateApplications_Affiliates] FOREIGN KEY ([AffiliateId])
            REFERENCES [AFL].[Affiliates] ([AffiliateID]),
        CONSTRAINT [UQ_AffiliateApplications_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [CK_AffiliateApplications_Status] CHECK ([Status] IN ('Pending', 'Approved', 'Rejected')),
        -- Exactly the approved applications point at the affiliate they created.
        CONSTRAINT [CK_AffiliateApplications_AffiliateId] CHECK
            (([Status] = 'Approved' AND [AffiliateId] IS NOT NULL) OR ([Status] <> 'Approved' AND [AffiliateId] IS NULL)),
        CONSTRAINT [CK_AffiliateApplications_ReviewedDate] CHECK
            (([Status] = 'Pending' AND [ReviewedDate] IS NULL) OR ([Status] <> 'Pending' AND [ReviewedDate] IS NOT NULL)),
        CONSTRAINT [CK_AffiliateApplications_StateCode] CHECK
            ([StateCode] IS NULL OR [StateCode] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^A-Z]%')
    );

    -- Resubmitting the form while an application is pending returns the existing one.
    CREATE UNIQUE NONCLUSTERED INDEX [IX_AffiliateApplications_DealerTenantId_Email_Pending]
        ON [AFL].[AffiliateApplications] ([DealerTenantId], [Email])
        WHERE [Status] = 'Pending' AND [IsDeleted] = 0;
    CREATE NONCLUSTERED INDEX [IX_AffiliateApplications_DealerTenantId_Status]
        ON [AFL].[AffiliateApplications] ([DealerTenantId], [Status], [AffiliateApplicationID] DESC);
    CREATE NONCLUSTERED INDEX [IX_AffiliateApplications_PartKey_AffiliateApplicationTypeId]
        ON [AFL].[AffiliateApplications] ([PartKey], [AffiliateApplicationTypeId]);
    CREATE NONCLUSTERED INDEX [IX_AffiliateApplications_AffiliateId]
        ON [AFL].[AffiliateApplications] ([AffiliateId]) WHERE [AffiliateId] IS NOT NULL;

    PRINT 'Created AFL.AffiliateApplicationTypes and AFL.AffiliateApplications';

    -- =========================================================================
    -- Step 3: AFL.BucksTransactionTypes + AFL.BucksTransactions (append-only ledger)
    -- =========================================================================
    CREATE TABLE [AFL].[BucksTransactionTypes]
    (
        [BucksTransactionTypeID] [int] IDENTITY(1,1) NOT NULL,
        [Prefix] [varchar](4) NOT NULL,
        [BucksTransactionTypeName] [nvarchar](100) NOT NULL,
        [BucksTransactionTypeDescription] [nvarchar](2000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_BucksTransactionTypes_IsActive] DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_BucksTransactionTypes_IsDeleted] DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactionTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactionTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactionTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_BucksTransactionTypes] PRIMARY KEY CLUSTERED ([BucksTransactionTypeID]),
        CONSTRAINT [UQ_BucksTransactionTypes_Prefix] UNIQUE ([Prefix]),
        CONSTRAINT [CK_BucksTransactionTypes_Prefix] CHECK
            (DATALENGTH([Prefix]) = 4 AND [Prefix] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^A-Z0-9]%')
    );

    SET IDENTITY_INSERT [AFL].[BucksTransactionTypes] ON;
    INSERT INTO [AFL].[BucksTransactionTypes]
        ([BucksTransactionTypeID], [Prefix], [BucksTransactionTypeName], [BucksTransactionTypeDescription],
         [ModifiedById], [CreatedDate], [CreatedById])
    SELECT V.[Id], V.[Prefix], V.[Name], V.[Description], @SystemUserId, SYSDATETIMEOFFSET(), @SystemUserId
    FROM (VALUES
        (1, 'AFBP', N'Post Reward',      N'Credit for an approved social media post.'),
        (2, 'AFBR', N'Referral Reward',  N'Credit for a qualifying purchase by a referred customer.'),
        (3, 'AFBD', N'Redemption',       N'Debit when Bucks are applied to an order.'),
        (4, 'AFBA', N'Adjustment',       N'Manual staff correction; credit or debit.')
    ) AS V ([Id], [Prefix], [Name], [Description]);
    SET IDENTITY_INSERT [AFL].[BucksTransactionTypes] OFF;

    CREATE TABLE [AFL].[BucksTransactions]
    (
        [BucksTransactionID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [AffiliateId] [bigint] NOT NULL,
        [BucksTransactionTypeId] [int] NOT NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        -- Whole Bucks; 1 Buck = $1 store credit. Credits are positive, debits negative.
        [Amount] [int] NOT NULL,
        [TransactionDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactions_TransactionDate] DEFAULT (SYSDATETIMEOFFSET()),
        [Description] [nvarchar](500) NULL,
        -- Proxy of what earned or spent the Bucks (placement, lead, order), when there is one.
        [SourceProxy] [varchar](100) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_BucksTransactions_IsActive] DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_BucksTransactions_IsDeleted] DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactions_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactions_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactions_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_BucksTransactions] PRIMARY KEY CLUSTERED ([BucksTransactionID]),
        CONSTRAINT [FK_BucksTransactions_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_BucksTransactions_Affiliates] FOREIGN KEY ([AffiliateId])
            REFERENCES [AFL].[Affiliates] ([AffiliateID]),
        CONSTRAINT [FK_BucksTransactions_BucksTransactionTypes] FOREIGN KEY ([BucksTransactionTypeId])
            REFERENCES [AFL].[BucksTransactionTypes] ([BucksTransactionTypeID]),
        CONSTRAINT [UQ_BucksTransactions_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [CK_BucksTransactions_Amount] CHECK ([Amount] <> 0)
    );

    CREATE NONCLUSTERED INDEX [IX_BucksTransactions_AffiliateId_TransactionDate]
        ON [AFL].[BucksTransactions] ([AffiliateId], [TransactionDate] DESC) INCLUDE ([Amount]);
    CREATE NONCLUSTERED INDEX [IX_BucksTransactions_PartKey_BucksTransactionTypeId]
        ON [AFL].[BucksTransactions] ([PartKey], [BucksTransactionTypeId]);

    PRINT 'Created AFL.BucksTransactionTypes and AFL.BucksTransactions';

    -- =========================================================================
    -- Step 4: Register the new types with the Proxy-ID infrastructure
    -- =========================================================================
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
    WHERE [IsDeleted] = 0

    UNION ALL

    -- =========================================================================
    -- AFL.AffiliateApplicationTypes  (Prefix examples: AFAW)
    -- Entity: AffiliateApplication
    -- =========================================================================
    SELECT
        [AffiliateApplicationTypeID]          AS [Id]
        , [Prefix]
        , [AffiliateApplicationTypeName]      AS [Name]
        , [AffiliateApplicationTypeDescription] AS [Description]
        , ''AFL''                               AS [Schema]
        , ''AffiliateApplicationTypes''         AS [TableName]
        , ''AffiliateApplication''              AS [TypeName]
    FROM
        [AFL].[AffiliateApplicationTypes]
    WHERE
        (IsDeleted = 0)

    UNION ALL

    -- =========================================================================
    -- AFL.BucksTransactionTypes  (Prefix examples: AFBP, AFBR, AFBD, AFBA)
    -- Entity: BucksTransaction
    -- =========================================================================
    SELECT
        [BucksTransactionTypeID]          AS [Id]
        , [Prefix]
        , [BucksTransactionTypeName]      AS [Name]
        , [BucksTransactionTypeDescription] AS [Description]
        , ''AFL''                           AS [Schema]
        , ''BucksTransactionTypes''         AS [TableName]
        , ''BucksTransaction''              AS [TypeName]
    FROM
        [AFL].[BucksTransactionTypes]
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

    -- =========================================================================
    -- Document — DOC.DocumentTypes
    -- =========================================================================
    ELSE IF (@TypeName = ''Document'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [DOC].[DocumentTypes] AS T
        WHERE T.[DocumentTypeID] = @TypeId AND T.[IsActive] = 1 AND T.[IsDeleted] = 0;
    END

    -- =========================================================================
    -- AffiliateApplication — AFL.AffiliateApplicationTypes
    -- =========================================================================
    ELSE IF (@TypeName = ''AffiliateApplication'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [AFL].[AffiliateApplicationTypes] AS T
        WHERE T.[AffiliateApplicationTypeID] = @TypeId AND T.[IsActive] = 1 AND T.[IsDeleted] = 0;
    END

    -- =========================================================================
    -- BucksTransaction — AFL.BucksTransactionTypes
    -- =========================================================================
    ELSE IF (@TypeName = ''BucksTransaction'')
    BEGIN
        SELECT @Prefix = [Prefix]
        FROM [AFL].[BucksTransactionTypes] AS T
        WHERE T.[BucksTransactionTypeID] = @TypeId AND T.[IsActive] = 1 AND T.[IsDeleted] = 0;
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

    PRINT 'Rebuilt MAC.vwTableTypesAndPrefixes and MAC.fxGeneratePrefixParts';

    -- =========================================================================
    -- Record migration
    -- =========================================================================
    INSERT INTO [dbo].[SchemaVersion]
        ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName,
            N'Affiliate program Phase 1: Affiliates.UserId (table recreated), AffiliateApplications, Bucks ledger, AFAW/AFBP/AFBR/AFBD/AFBA prefixes.',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration 20261103_2132_AddAFL_AffiliateApplicationsAndBucks applied successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
================================================================================
ROLLBACK SCRIPT
================================================================================
-- Use only before applications or Bucks contain real data. Guards refuse otherwise.
-- Restore the MAC view/function by re-running the version of
-- Views/MAC/vwTableTypesAndPrefixes.sql and Functions/MAC/fxGeneratePrefixParts.sql
-- from before this migration (git history), after the steps below.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    IF EXISTS (SELECT 1 FROM [AFL].[BucksTransactions])
        THROW 50001, 'BucksTransactions contains data; archive it before rollback.', 1;
    IF EXISTS (SELECT 1 FROM [AFL].[AffiliateApplications])
        THROW 50001, 'AffiliateApplications contains data; archive it before rollback.', 1;

    DROP TABLE [AFL].[BucksTransactions];
    DROP TABLE [AFL].[BucksTransactionTypes];
    DROP TABLE [AFL].[AffiliateApplications];
    DROP TABLE [AFL].[AffiliateApplicationTypes];

    -- AFL.Affiliates intentionally keeps the nullable UserId column and UQ_Affiliates_Proxy;
    -- removing them needs another table recreation. To unlink portal logins instead:
    -- UPDATE [AFL].[Affiliates] SET [UserId] = NULL;

    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = N'20261103_2132_AddAFL_AffiliateApplicationsAndBucks';

    COMMIT TRANSACTION;
    PRINT 'Rollback complete';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

================================================================================
VERIFICATION QUERIES
================================================================================
-- 1. Column order of AFL.Affiliates (UserId after PartKey)
SELECT [column_id], [name] FROM sys.columns WHERE [object_id] = OBJECT_ID(N'AFL.Affiliates') ORDER BY [column_id];

-- 2. New prefixes resolve
SELECT * FROM [MAC].[vwTableTypesAndPrefixes] WHERE [Prefix] IN ('AFAW','AFBP','AFBR','AFBD','AFBA');
SELECT [MAC].[fxGeneratePrefixProxy]('AffiliateApplication', 1) + CAST(NEWID() AS NVARCHAR(36)) AS SampleProxy;
SELECT [MAC].[fxGeneratePrefixProxy]('BucksTransaction', 1) + CAST(NEWID() AS NVARCHAR(36)) AS SampleProxy;

-- 3. No affiliate is left without a proxy
SELECT COUNT(*) FROM [AFL].[Affiliates] WHERE [Proxy] = '' OR [PartKey] = '';   -- Expected: 0

-- 4. Campaign FK is back
SELECT [name] FROM sys.foreign_keys WHERE [name] = N'FK_AffiliateCampaigns_Affiliates';

-- 5. Migration recorded
SELECT * FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261103_2132_AddAFL_AffiliateApplicationsAndBucks';
*/
