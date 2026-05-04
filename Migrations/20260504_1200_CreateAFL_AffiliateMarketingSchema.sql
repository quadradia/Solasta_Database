/*
Migration: 20260504_1200_CreateAFL_AffiliateMarketingSchema
Author:
Date: 2026-05-04
Description: Creates the AFL (Affiliate Marketing) schema and all supporting
             tables to track affiliate registrations, campaigns, ad placements,
             click events, and lead attribution.

             Objects created:
               Schema  : AFL
               Tables  : AFL.MediaPlatforms
                         AFL.Affiliates
                         AFL.AffiliateCampaigns
                         AFL.CampaignPlacements
                         AFL.TokenClicks
                         AFL.LeadAttributions

             Data flow:
               Affiliate signs up (Affiliates)
               → creates a Campaign (AffiliateCampaigns)
               → posts an ad on a platform (CampaignPlacements → unique TrackingToken)
               → prospect clicks the tracked URL (TokenClicks)
               → prospect submits a lead form (QAL.Leads)
               → system creates attribution record (LeadAttributions)

Dependencies: 20260313_0845_Baseline_Schemas
              20260313_0846_Baseline_ObjectsDeployed  (ACC.Dealers, QAL.Leads must exist)
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260504_1200_CreateAFL_AffiliateMarketingSchema';

    -- Check if already applied
    IF EXISTS (
        SELECT 1 FROM [dbo].[SchemaVersion]
        WHERE [MigrationName] = @MigrationName
    )
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- =========================================================================
    -- Validate prerequisites
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Dealers' AND schema_id = SCHEMA_ID('ACC'))
        RAISERROR('Table ACC.Dealers does not exist. Run baseline migrations first.', 16, 1);

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Leads' AND schema_id = SCHEMA_ID('QAL'))
        RAISERROR('Table QAL.Leads does not exist. Run baseline migrations first.', 16, 1);

    -- =========================================================================
    -- Create AFL schema
    -- CREATE SCHEMA must run in its own batch; use EXEC() to stay in transaction
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'AFL')
        EXEC('CREATE SCHEMA [AFL]');
    PRINT 'Schema AFL: OK';

    -- =========================================================================
    -- AFL.MediaPlatforms
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'MediaPlatforms' AND schema_id = SCHEMA_ID('AFL'))
    BEGIN
        CREATE TABLE [AFL].[MediaPlatforms](
            [MediaPlatformID] [int] IDENTITY(1,1) NOT NULL,
            [MediaPlatformName] [nvarchar](50) NOT NULL,
            [MediaPlatformCode] [varchar](10) NOT NULL,
            [IconUrl] [nvarchar](500) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_MediaPlatforms_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_MediaPlatforms_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MediaPlatforms_ModifiedDate] DEFAULT (sysdatetimeoffset()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MediaPlatforms_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MediaPlatforms_CreatedDate] DEFAULT (sysdatetimeoffset()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MediaPlatforms_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MediaPlatforms_DEX_ROW_TS] DEFAULT (sysdatetimeoffset()),
            CONSTRAINT [PK_MediaPlatforms] PRIMARY KEY CLUSTERED ([MediaPlatformID] ASC),
            CONSTRAINT [UQ_MediaPlatforms_MediaPlatformCode] UNIQUE ([MediaPlatformCode])
        );
        PRINT 'Table AFL.MediaPlatforms: Created';
    END
    ELSE PRINT 'Table AFL.MediaPlatforms: Already exists';

    -- =========================================================================
    -- AFL.Affiliates
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Affiliates' AND schema_id = SCHEMA_ID('AFL'))
    BEGIN
        CREATE TABLE [AFL].[Affiliates](
            [AffiliateID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerId] [int] NOT NULL,
            [AffiliateCode] [varchar](20) NOT NULL,
            [FirstName] [nvarchar](50) NOT NULL,
            [LastName] [nvarchar](50) NOT NULL,
            [Email] [nvarchar](256) NOT NULL,
            [PhoneMobile] [nvarchar](20) NULL,
            [CommissionRate] [decimal](5,4) NULL,
            [Notes] [nvarchar](max) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Affiliates_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Affiliates_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Affiliates_ModifiedDate] DEFAULT (sysdatetimeoffset()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Affiliates_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Affiliates_CreatedDate] DEFAULT (sysdatetimeoffset()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Affiliates_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Affiliates_DEX_ROW_TS] DEFAULT (sysdatetimeoffset()),
            CONSTRAINT [PK_Affiliates] PRIMARY KEY CLUSTERED ([AffiliateID] ASC),
            CONSTRAINT [UQ_Affiliates_AffiliateCode] UNIQUE ([AffiliateCode])
        );
        PRINT 'Table AFL.Affiliates: Created';
    END
    ELSE PRINT 'Table AFL.Affiliates: Already exists';

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Affiliates_Dealers')
        ALTER TABLE [AFL].[Affiliates] WITH CHECK
            ADD CONSTRAINT [FK_Affiliates_Dealers] FOREIGN KEY([DealerId])
            REFERENCES [ACC].[Dealers] ([DealerID]);

    -- =========================================================================
    -- AFL.AffiliateCampaigns
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AffiliateCampaigns' AND schema_id = SCHEMA_ID('AFL'))
    BEGIN
        CREATE TABLE [AFL].[AffiliateCampaigns](
            [AffiliateCampaignID] [int] IDENTITY(1,1) NOT NULL,
            [AffiliateId] [bigint] NOT NULL,
            [DealerId] [int] NOT NULL,
            [CampaignName] [nvarchar](100) NOT NULL,
            [CampaignDescription] [nvarchar](500) NULL,
            [StartDate] [date] NULL,
            [EndDate] [date] NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_AffiliateCampaigns_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_AffiliateCampaigns_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateCampaigns_ModifiedDate] DEFAULT (sysdatetimeoffset()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_AffiliateCampaigns_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateCampaigns_CreatedDate] DEFAULT (sysdatetimeoffset()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_AffiliateCampaigns_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateCampaigns_DEX_ROW_TS] DEFAULT (sysdatetimeoffset()),
            CONSTRAINT [PK_AffiliateCampaigns] PRIMARY KEY CLUSTERED ([AffiliateCampaignID] ASC)
        );
        PRINT 'Table AFL.AffiliateCampaigns: Created';
    END
    ELSE PRINT 'Table AFL.AffiliateCampaigns: Already exists';

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_AffiliateCampaigns_Affiliates')
        ALTER TABLE [AFL].[AffiliateCampaigns] WITH CHECK
            ADD CONSTRAINT [FK_AffiliateCampaigns_Affiliates] FOREIGN KEY([AffiliateId])
            REFERENCES [AFL].[Affiliates] ([AffiliateID]);

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_AffiliateCampaigns_Dealers')
        ALTER TABLE [AFL].[AffiliateCampaigns] WITH CHECK
            ADD CONSTRAINT [FK_AffiliateCampaigns_Dealers] FOREIGN KEY([DealerId])
            REFERENCES [ACC].[Dealers] ([DealerID]);

    -- =========================================================================
    -- AFL.CampaignPlacements
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CampaignPlacements' AND schema_id = SCHEMA_ID('AFL'))
    BEGIN
        CREATE TABLE [AFL].[CampaignPlacements](
            [CampaignPlacementID] [int] IDENTITY(1,1) NOT NULL,
            [AffiliateCampaignId] [int] NOT NULL,
            [MediaPlatformId] [int] NOT NULL,
            [TrackingToken] [varchar](50) NOT NULL,
            [PlacementUrl] [nvarchar](2000) NULL,
            [PostedDate] [datetimeoffset](7) NULL,
            [Notes] [nvarchar](500) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_CampaignPlacements_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_CampaignPlacements_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_CampaignPlacements_ModifiedDate] DEFAULT (sysdatetimeoffset()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_CampaignPlacements_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_CampaignPlacements_CreatedDate] DEFAULT (sysdatetimeoffset()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_CampaignPlacements_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_CampaignPlacements_DEX_ROW_TS] DEFAULT (sysdatetimeoffset()),
            CONSTRAINT [PK_CampaignPlacements] PRIMARY KEY CLUSTERED ([CampaignPlacementID] ASC),
            CONSTRAINT [UQ_CampaignPlacements_TrackingToken] UNIQUE ([TrackingToken])
        );
        PRINT 'Table AFL.CampaignPlacements: Created';
    END
    ELSE PRINT 'Table AFL.CampaignPlacements: Already exists';

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CampaignPlacements_AffiliateCampaigns')
        ALTER TABLE [AFL].[CampaignPlacements] WITH CHECK
            ADD CONSTRAINT [FK_CampaignPlacements_AffiliateCampaigns] FOREIGN KEY([AffiliateCampaignId])
            REFERENCES [AFL].[AffiliateCampaigns] ([AffiliateCampaignID]);

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CampaignPlacements_MediaPlatforms')
        ALTER TABLE [AFL].[CampaignPlacements] WITH CHECK
            ADD CONSTRAINT [FK_CampaignPlacements_MediaPlatforms] FOREIGN KEY([MediaPlatformId])
            REFERENCES [AFL].[MediaPlatforms] ([MediaPlatformID]);

    -- =========================================================================
    -- AFL.TokenClicks
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TokenClicks' AND schema_id = SCHEMA_ID('AFL'))
    BEGIN
        CREATE TABLE [AFL].[TokenClicks](
            [TokenClickID] [bigint] IDENTITY(1,1) NOT NULL,
            [CampaignPlacementId] [int] NOT NULL,
            [ClickDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TokenClicks_ClickDate] DEFAULT (sysdatetimeoffset()),
            [IPAddress] [varchar](45) NULL,
            [UserAgent] [nvarchar](500) NULL,
            [SessionId] [varchar](100) NULL,
            [ReferrerUrl] [nvarchar](2000) NULL,
            [IsConverted] [bit] NOT NULL CONSTRAINT [DF_TokenClicks_IsConverted] DEFAULT ((0)),
            [ConvertedDate] [datetimeoffset](7) NULL,
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TokenClicks_ModifiedDate] DEFAULT (sysdatetimeoffset()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TokenClicks_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TokenClicks_CreatedDate] DEFAULT (sysdatetimeoffset()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TokenClicks_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TokenClicks_DEX_ROW_TS] DEFAULT (sysdatetimeoffset()),
            CONSTRAINT [PK_TokenClicks] PRIMARY KEY CLUSTERED ([TokenClickID] ASC)
        );
        PRINT 'Table AFL.TokenClicks: Created';
    END
    ELSE PRINT 'Table AFL.TokenClicks: Already exists';

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TokenClicks_CampaignPlacements')
        ALTER TABLE [AFL].[TokenClicks] WITH CHECK
            ADD CONSTRAINT [FK_TokenClicks_CampaignPlacements] FOREIGN KEY([CampaignPlacementId])
            REFERENCES [AFL].[CampaignPlacements] ([CampaignPlacementID]);

    -- =========================================================================
    -- AFL.LeadAttributions
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'LeadAttributions' AND schema_id = SCHEMA_ID('AFL'))
    BEGIN
        CREATE TABLE [AFL].[LeadAttributions](
            [LeadAttributionID] [bigint] IDENTITY(1,1) NOT NULL,
            [LeadId] [bigint] NOT NULL,
            [CampaignPlacementId] [int] NOT NULL,
            [TokenClickId] [bigint] NULL,
            [AttributedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_LeadAttributions_AttributedDate] DEFAULT (sysdatetimeoffset()),
            [Notes] [nvarchar](500) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_LeadAttributions_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_LeadAttributions_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_LeadAttributions_ModifiedDate] DEFAULT (sysdatetimeoffset()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_LeadAttributions_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_LeadAttributions_CreatedDate] DEFAULT (sysdatetimeoffset()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_LeadAttributions_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_LeadAttributions_DEX_ROW_TS] DEFAULT (sysdatetimeoffset()),
            CONSTRAINT [PK_LeadAttributions] PRIMARY KEY CLUSTERED ([LeadAttributionID] ASC),
            CONSTRAINT [UQ_LeadAttributions_LeadId] UNIQUE ([LeadId])
        );
        PRINT 'Table AFL.LeadAttributions: Created';
    END
    ELSE PRINT 'Table AFL.LeadAttributions: Already exists';

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_LeadAttributions_Leads')
        ALTER TABLE [AFL].[LeadAttributions] WITH CHECK
            ADD CONSTRAINT [FK_LeadAttributions_Leads] FOREIGN KEY([LeadId])
            REFERENCES [QAL].[Leads] ([LeadID]);

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_LeadAttributions_CampaignPlacements')
        ALTER TABLE [AFL].[LeadAttributions] WITH CHECK
            ADD CONSTRAINT [FK_LeadAttributions_CampaignPlacements] FOREIGN KEY([CampaignPlacementId])
            REFERENCES [AFL].[CampaignPlacements] ([CampaignPlacementID]);

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_LeadAttributions_TokenClicks')
        ALTER TABLE [AFL].[LeadAttributions] WITH CHECK
            ADD CONSTRAINT [FK_LeadAttributions_TokenClicks] FOREIGN KEY([TokenClickId])
            REFERENCES [AFL].[TokenClicks] ([TokenClickID]);

    -- =========================================================================
    -- Record migration
    -- =========================================================================
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (
        @MigrationName,
        'Creates AFL schema and tables: MediaPlatforms, Affiliates, AffiliateCampaigns, CampaignPlacements, TokenClicks, LeadAttributions for affiliate marketing tracking'
    );

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
BEGIN TRANSACTION;
BEGIN TRY
    -- Drop FK constraints first (reverse dependency order)
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_LeadAttributions_TokenClicks')
        ALTER TABLE [AFL].[LeadAttributions] DROP CONSTRAINT [FK_LeadAttributions_TokenClicks];
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_LeadAttributions_CampaignPlacements')
        ALTER TABLE [AFL].[LeadAttributions] DROP CONSTRAINT [FK_LeadAttributions_CampaignPlacements];
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_LeadAttributions_Leads')
        ALTER TABLE [AFL].[LeadAttributions] DROP CONSTRAINT [FK_LeadAttributions_Leads];
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TokenClicks_CampaignPlacements')
        ALTER TABLE [AFL].[TokenClicks] DROP CONSTRAINT [FK_TokenClicks_CampaignPlacements];
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CampaignPlacements_MediaPlatforms')
        ALTER TABLE [AFL].[CampaignPlacements] DROP CONSTRAINT [FK_CampaignPlacements_MediaPlatforms];
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CampaignPlacements_AffiliateCampaigns')
        ALTER TABLE [AFL].[CampaignPlacements] DROP CONSTRAINT [FK_CampaignPlacements_AffiliateCampaigns];
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_AffiliateCampaigns_Dealers')
        ALTER TABLE [AFL].[AffiliateCampaigns] DROP CONSTRAINT [FK_AffiliateCampaigns_Dealers];
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_AffiliateCampaigns_Affiliates')
        ALTER TABLE [AFL].[AffiliateCampaigns] DROP CONSTRAINT [FK_AffiliateCampaigns_Affiliates];
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Affiliates_Dealers')
        ALTER TABLE [AFL].[Affiliates] DROP CONSTRAINT [FK_Affiliates_Dealers];

    -- Drop tables (reverse dependency order)
    DROP TABLE IF EXISTS [AFL].[LeadAttributions];
    DROP TABLE IF EXISTS [AFL].[TokenClicks];
    DROP TABLE IF EXISTS [AFL].[CampaignPlacements];
    DROP TABLE IF EXISTS [AFL].[AffiliateCampaigns];
    DROP TABLE IF EXISTS [AFL].[Affiliates];
    DROP TABLE IF EXISTS [AFL].[MediaPlatforms];

    -- Drop schema
    IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'AFL')
        EXEC('DROP SCHEMA [AFL]');

    -- Remove migration record
    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = '20260504_1200_CreateAFL_AffiliateMarketingSchema';

    COMMIT TRANSACTION;
    PRINT 'Rollback complete.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    RAISERROR(ERROR_MESSAGE(), 16, 1);
END CATCH
*/
