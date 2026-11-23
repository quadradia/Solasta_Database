/*
Migration: 20261121_1500_AddPublicEstimatesForMcp
Author: Andres Sosa
Date: 2026-11-21
Description: Tables for the public AI quoting MCP server (mcp.mysolasta.com, repo SosaNuvol/solasta-dealer-mcp).
             Homeowners and businesses ask an AI assistant for a price range; the MCP server calls the API's
             api/public/{dealer}/... routes, which price with the dealer's own catalog and create a lead when the
             person asks for a quote.
               ACC.DealerPublicProfiles  one row per dealer tenant that is public through the MCP: its URL slug,
                                         public contact details, estimate uncertainty, and the ACC.Users service
                                         user the API signs in as for that dealer
               ACC.DealerServiceAreas    the ZIP codes (5 digits) or ZIP prefixes (3 digits) a dealer serves
               MAC.PublicEstimates       every range estimate given, with no personal data; LeadId is set when the
                                         person asks for a quote
             MAC.Products.IsPublic (default 1) and MAC.Promotions.IsPublic (default 0) say what the public catalog
             may show.
             Seeds: lead source 'AI Assistant' and Solasta Lighting's profile (slug 'solasta') with Utah ZIP
             prefixes 840-847. The profile is enabled only when its service user exists in ACC.Users.
             Proxy prefix: MAPE (public estimate).
Dependencies:
  20261117_0330_CreateMAC_PricingCatalog
  20261117_0340_AddQAL_LeadIntake
Rollback:
  DROP TABLE [MAC].[PublicEstimates];
  DROP TABLE [ACC].[DealerServiceAreas];
  DROP TABLE [ACC].[DealerPublicProfiles];
  ALTER TABLE [MAC].[Products] DROP CONSTRAINT [DF_Products_IsPublic];
  ALTER TABLE [MAC].[Products] DROP COLUMN [IsPublic];
  ALTER TABLE [MAC].[Promotions] DROP CONSTRAINT [DF_Promotions_IsPublic];
  ALTER TABLE [MAC].[Promotions] DROP COLUMN [IsPublic];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261121_1500_AddPublicEstimatesForMcp';
  The 'AI Assistant' lead source stays; delete it only if no lead uses it.
Expected impact: three new tables and two new columns with defaults. Every existing product becomes public and
                 every existing promotion stays private. No other data changes besides the seeds.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261121_1500_AddPublicEstimatesForMcp';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MAC.Products', N'U') IS NULL OR OBJECT_ID(N'MAC.Promotions', N'U') IS NULL
       OR OBJECT_ID(N'QAL.LeadSources', N'U') IS NULL
        THROW 50001, 'Public estimates require MAC.Products, MAC.Promotions (20261117_0330) and QAL.LeadSources (20261117_0340).', 1;

    ---------------------------------------------------------------------------
    -- MAC.Products.IsPublic, MAC.Promotions.IsPublic
    ---------------------------------------------------------------------------
    IF COL_LENGTH(N'MAC.Products', N'IsPublic') IS NULL
    BEGIN
        ALTER TABLE [MAC].[Products] ADD [IsPublic] [bit] NOT NULL CONSTRAINT [DF_Products_IsPublic] DEFAULT ((1));
        PRINT 'Added [MAC].[Products].[IsPublic]';
    END;

    IF COL_LENGTH(N'MAC.Promotions', N'IsPublic') IS NULL
    BEGIN
        ALTER TABLE [MAC].[Promotions] ADD [IsPublic] [bit] NOT NULL CONSTRAINT [DF_Promotions_IsPublic] DEFAULT ((0));
        PRINT 'Added [MAC].[Promotions].[IsPublic]';
    END;

    ---------------------------------------------------------------------------
    -- ACC.DealerPublicProfiles
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'ACC.DealerPublicProfiles', N'U') IS NULL
    BEGIN
        CREATE TABLE [ACC].[DealerPublicProfiles]
        (
            [DealerPublicProfileID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            -- Lower-case URL name: mcp.mysolasta.com/d/{Slug}/mcp and api/public/{Slug}/...
            [Slug] [varchar](40) NOT NULL,
            [DisplayName] [nvarchar](100) NOT NULL,
            -- A few sentences an AI assistant can repeat: who the dealer is and what it installs.
            [Description] [nvarchar](1000) NULL,
            [WebsiteUrl] [varchar](255) NULL,
            [Phone] [varchar](20) NULL,
            [Email] [varchar](255) NULL,
            -- Off hides the dealer from the MCP and every api/public/{Slug} route.
            [IsMcpEnabled] [bit] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_IsMcpEnabled] DEFAULT ((0)),
            -- The share an estimate's feet can be off, by where the feet came from (0.25 is +/-25%).
            [FootprintUncertainty] [decimal](5, 4) NOT NULL CONSTRAINT [DF_DealerPublicProfiles_FootprintUncertainty] DEFAULT ((0.25)),
            [KmlUncertainty] [decimal](5, 4) NOT NULL CONSTRAINT [DF_DealerPublicProfiles_KmlUncertainty] DEFAULT ((0.10)),
            -- How long an estimate is good for.
            [EstimateValidityDays] [int] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_EstimateValidityDays] DEFAULT ((30)),
            -- The ACC.Users row the API signs in as for this dealer's public requests (audit columns, session context).
            [ServiceUserId] [uniqueidentifier] NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerPublicProfiles_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerPublicProfiles_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerPublicProfiles_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_DealerPublicProfiles] PRIMARY KEY CLUSTERED ([DealerPublicProfileID] ASC),
            CONSTRAINT [FK_DealerPublicProfiles_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_DealerPublicProfiles_Users] FOREIGN KEY ([ServiceUserId]) REFERENCES [ACC].[Users] ([UserID]),
            CONSTRAINT [UQ_DealerPublicProfiles_DealerTenantId] UNIQUE ([DealerTenantId]),
            CONSTRAINT [UQ_DealerPublicProfiles_Slug] UNIQUE ([Slug]),
            CONSTRAINT [CK_DealerPublicProfiles_Slug] CHECK ([Slug] NOT LIKE '%[^a-z0-9-]%' AND LEN([Slug]) >= 2),
            CONSTRAINT [CK_DealerPublicProfiles_Uncertainty] CHECK ([FootprintUncertainty] >= 0 AND [FootprintUncertainty] < 1
                                                                    AND [KmlUncertainty] >= 0 AND [KmlUncertainty] < 1),
            CONSTRAINT [CK_DealerPublicProfiles_EstimateValidityDays] CHECK ([EstimateValidityDays] BETWEEN 1 AND 365),
            CONSTRAINT [CK_DealerPublicProfiles_EnabledNeedsUser] CHECK ([IsMcpEnabled] = 0 OR [ServiceUserId] IS NOT NULL)
        );
        PRINT 'Created [ACC].[DealerPublicProfiles]';
    END;

    ---------------------------------------------------------------------------
    -- ACC.DealerServiceAreas
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'ACC.DealerServiceAreas', N'U') IS NULL
    BEGIN
        CREATE TABLE [ACC].[DealerServiceAreas]
        (
            [DealerServiceAreaID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            -- A whole ZIP code (84043) or a 3-digit prefix (840). A whole ZIP wins over a prefix.
            [PostalCode] [varchar](5) NOT NULL,
            -- Lower comes first when two dealers serve the same ZIP.
            [Priority] [int] NOT NULL CONSTRAINT [DF_DealerServiceAreas_Priority] DEFAULT ((100)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_DealerServiceAreas_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_DealerServiceAreas_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerServiceAreas_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_DealerServiceAreas_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerServiceAreas_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_DealerServiceAreas_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerServiceAreas_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_DealerServiceAreas] PRIMARY KEY CLUSTERED ([DealerServiceAreaID] ASC),
            CONSTRAINT [FK_DealerServiceAreas_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [UQ_DealerServiceAreas_DealerTenantId_PostalCode] UNIQUE ([DealerTenantId], [PostalCode]),
            CONSTRAINT [CK_DealerServiceAreas_PostalCode] CHECK ([PostalCode] LIKE '[0-9][0-9][0-9]' OR [PostalCode] LIKE '[0-9][0-9][0-9][0-9][0-9]')
        );
        PRINT 'Created [ACC].[DealerServiceAreas]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACC.DealerServiceAreas') AND [name] = N'IX_DealerServiceAreas_PostalCode')
        CREATE NONCLUSTERED INDEX [IX_DealerServiceAreas_PostalCode] ON [ACC].[DealerServiceAreas] ([PostalCode]) INCLUDE ([DealerTenantId], [Priority]) WHERE [IsActive] = 1;

    ---------------------------------------------------------------------------
    -- MAC.PublicEstimates
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MAC.PublicEstimates', N'U') IS NULL
    BEGIN
        CREATE TABLE [MAC].[PublicEstimates]
        (
            [PublicEstimateID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [Proxy] [varchar](100) NOT NULL,
            [PartKey] [varchar](6) NOT NULL,
            -- Where the feet came from: Footprint (building outline), Kml (the person's pins) or Typed.
            [Source] [varchar](10) NOT NULL,
            -- The feet measured or estimated, before the uncertainty and the allowance.
            [Feet] [decimal](10, 2) NOT NULL,
            [Uncertainty] [decimal](5, 4) NOT NULL,
            [ProductId] [int] NOT NULL,
            -- The color or other variant chosen, if any (INE.StockItems).
            [VariantStockItemId] [int] NULL,
            [PromotionId] [int] NULL,
            [TaxRate] [decimal](9, 6) NOT NULL,
            -- Totals with tax, rounded to $50.
            [LowTotal] [decimal](12, 2) NOT NULL,
            [HighTotal] [decimal](12, 2) NOT NULL,
            [City] [nvarchar](100) NULL,
            [StateCode] [char](2) NULL,
            [PostalCode] [varchar](10) NULL,
            [ValidUntil] [datetimeoffset](7) NOT NULL,
            -- The KML's pins, runs and warnings as the person sent them (JSON), when Source = Kml.
            [DetailJson] [nvarchar](max) NULL,
            -- Set when the person asks for a quote.
            [LeadId] [bigint] NULL,
            -- The MCP session that asked, for rate limits and support. Not personal data.
            [ClientSessionId] [varchar](100) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_PublicEstimates_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_PublicEstimates_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PublicEstimates_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PublicEstimates_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PublicEstimates_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PublicEstimates_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PublicEstimates_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_PublicEstimates] PRIMARY KEY CLUSTERED ([PublicEstimateID] ASC),
            CONSTRAINT [FK_PublicEstimates_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_PublicEstimates_Products] FOREIGN KEY ([ProductId]) REFERENCES [MAC].[Products] ([ProductID]),
            CONSTRAINT [FK_PublicEstimates_Promotions] FOREIGN KEY ([PromotionId]) REFERENCES [MAC].[Promotions] ([PromotionID]),
            CONSTRAINT [FK_PublicEstimates_Leads] FOREIGN KEY ([LeadId]) REFERENCES [QAL].[Leads] ([LeadID]),
            CONSTRAINT [UQ_PublicEstimates_Proxy] UNIQUE ([Proxy]),
            CONSTRAINT [CK_PublicEstimates_Source] CHECK ([Source] IN ('Footprint', 'Kml', 'Typed')),
            CONSTRAINT [CK_PublicEstimates_Amounts] CHECK ([Feet] > 0 AND [Uncertainty] >= 0 AND [Uncertainty] < 1
                                                       AND [TaxRate] >= 0 AND [LowTotal] >= 0 AND [HighTotal] >= [LowTotal])
        );
        PRINT 'Created [MAC].[PublicEstimates]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.PublicEstimates') AND [name] = N'IX_PublicEstimates_DealerTenantId_CreatedDate')
        CREATE NONCLUSTERED INDEX [IX_PublicEstimates_DealerTenantId_CreatedDate] ON [MAC].[PublicEstimates] ([DealerTenantId], [CreatedDate]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.PublicEstimates') AND [name] = N'IX_PublicEstimates_LeadId')
        CREATE NONCLUSTERED INDEX [IX_PublicEstimates_LeadId] ON [MAC].[PublicEstimates] ([LeadId]) WHERE [LeadId] IS NOT NULL;

    ---------------------------------------------------------------------------
    -- Seeds
    ---------------------------------------------------------------------------
    DECLARE @SolastaTenantId INT = (SELECT TOP (1) [DealerTenantID] FROM [ACC].[DealerTenants]
                                    WHERE [Proxy] = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6');
    -- The service user the API already uses for Solasta's webhooks (GoHighLevel, Meta, Twilio).
    DECLARE @ServiceUserId UNIQUEIDENTIFIER = (SELECT TOP (1) [UserID] FROM [ACC].[Users]
                                               WHERE [UserID] = 'C1431C18-C4DC-4804-9050-EFFC611EAD8C');

    IF @SolastaTenantId IS NULL
        PRINT 'Solasta Lighting tenant not found; profile, service areas and lead source not seeded.';
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM [QAL].[LeadSources] WHERE [DealerTenantId] = @SolastaTenantId AND [LeadSourceName] = N'AI Assistant')
            INSERT INTO [QAL].[LeadSources] ([DealerTenantId], [LeadSourceName], [IsActive], [IsDeleted])
            VALUES (@SolastaTenantId, N'AI Assistant', 1, 0);

        IF NOT EXISTS (SELECT 1 FROM [ACC].[DealerPublicProfiles] WHERE [DealerTenantId] = @SolastaTenantId)
            INSERT INTO [ACC].[DealerPublicProfiles]
                ([DealerTenantId], [Slug], [DisplayName], [Description], [WebsiteUrl], [Email], [IsMcpEnabled], [ServiceUserId])
            VALUES (@SolastaTenantId, 'solasta', N'Solasta Lighting',
                    N'Solasta Lighting designs and installs permanent, app-controlled LED lighting on the rooflines of homes and businesses in Utah.',
                    'https://mysolasta.com', 'info@mysolasta.com',
                    CASE WHEN @ServiceUserId IS NULL THEN 0 ELSE 1 END, @ServiceUserId);

        -- Every Utah ZIP starts with 840-847.
        INSERT INTO [ACC].[DealerServiceAreas] ([DealerTenantId], [PostalCode])
        SELECT @SolastaTenantId, Z.[PostalCode]
        FROM (VALUES ('840'), ('841'), ('842'), ('843'), ('844'), ('845'), ('846'), ('847')) AS Z ([PostalCode])
        WHERE NOT EXISTS (SELECT 1 FROM [ACC].[DealerServiceAreas] A
                          WHERE A.[DealerTenantId] = @SolastaTenantId AND A.[PostalCode] = Z.[PostalCode]);
    END;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Public AI quoting MCP: dealer public profiles, service areas, public estimates, public catalog flags',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
