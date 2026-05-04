/*
Migration: 20260504_1300_AddDealerId_AFL_TenantTables
Author:
Date: 2026-05-04
Description: Adds DealerId (tenant key) to three AFL tables that were missing it:
               AFL.CampaignPlacements
               AFL.TokenClicks
               AFL.LeadAttributions
             Each column is added as NOT NULL (tables are empty at this point).
             FK constraints to ACC.Dealers are added for referential integrity.
             Affiliates and AffiliateCampaigns already carry DealerId.
Dependencies: 20260504_1200_CreateAFL_AffiliateMarketingSchema
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260504_1300_AddDealerId_AFL_TenantTables';

    -- Check if already applied
    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- Verify prerequisite tables exist
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'CampaignPlacements' AND schema_id = SCHEMA_ID('AFL'))
        RAISERROR('AFL.CampaignPlacements does not exist. Run 20260504_1200 first.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'TokenClicks' AND schema_id = SCHEMA_ID('AFL'))
        RAISERROR('AFL.TokenClicks does not exist. Run 20260504_1200 first.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'LeadAttributions' AND schema_id = SCHEMA_ID('AFL'))
        RAISERROR('AFL.LeadAttributions does not exist. Run 20260504_1200 first.', 16, 1);

    -- -------------------------------------------------------------------------
    -- AFL.CampaignPlacements — add DealerId
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.CampaignPlacements') AND name = 'DealerId'
    )
    BEGIN
    ALTER TABLE [AFL].[CampaignPlacements]
            ADD [DealerId] [int] NOT NULL
            CONSTRAINT [DF_CampaignPlacements_DealerId] DEFAULT (0);

    -- Remove the default — it was only needed to satisfy NOT NULL on ADD
    ALTER TABLE [AFL].[CampaignPlacements]
            DROP CONSTRAINT [DF_CampaignPlacements_DealerId];
END

    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_CampaignPlacements_Dealers')
        ALTER TABLE [AFL].[CampaignPlacements]
            WITH CHECK ADD CONSTRAINT [FK_CampaignPlacements_Dealers]
            FOREIGN KEY ([DealerId]) REFERENCES [ACC].[Dealers] ([DealerID]);

    -- -------------------------------------------------------------------------
    -- AFL.TokenClicks — add DealerId
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.TokenClicks') AND name = 'DealerId'
    )
    BEGIN
    ALTER TABLE [AFL].[TokenClicks]
            ADD [DealerId] [int] NOT NULL
            CONSTRAINT [DF_TokenClicks_DealerId] DEFAULT (0);

    ALTER TABLE [AFL].[TokenClicks]
            DROP CONSTRAINT [DF_TokenClicks_DealerId];
END

    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_TokenClicks_Dealers')
        ALTER TABLE [AFL].[TokenClicks]
            WITH CHECK ADD CONSTRAINT [FK_TokenClicks_Dealers]
            FOREIGN KEY ([DealerId]) REFERENCES [ACC].[Dealers] ([DealerID]);

    -- -------------------------------------------------------------------------
    -- AFL.LeadAttributions — add DealerId
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.LeadAttributions') AND name = 'DealerId'
    )
    BEGIN
    ALTER TABLE [AFL].[LeadAttributions]
            ADD [DealerId] [int] NOT NULL
            CONSTRAINT [DF_LeadAttributions_DealerId] DEFAULT (0);

    ALTER TABLE [AFL].[LeadAttributions]
            DROP CONSTRAINT [DF_LeadAttributions_DealerId];
END

    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_LeadAttributions_Dealers')
        ALTER TABLE [AFL].[LeadAttributions]
            WITH CHECK ADD CONSTRAINT [FK_LeadAttributions_Dealers]
            FOREIGN KEY ([DealerId]) REFERENCES [ACC].[Dealers] ([DealerID]);

    -- -------------------------------------------------------------------------
    -- Record migration
    -- -------------------------------------------------------------------------
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName, 'Adds DealerId (tenant key) + FK to ACC.Dealers on AFL.CampaignPlacements, AFL.TokenClicks, AFL.LeadAttributions');

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
    -- Drop FKs first
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CampaignPlacements_Dealers')
        ALTER TABLE [AFL].[CampaignPlacements] DROP CONSTRAINT [FK_CampaignPlacements_Dealers];

    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TokenClicks_Dealers')
        ALTER TABLE [AFL].[TokenClicks] DROP CONSTRAINT [FK_TokenClicks_Dealers];

    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_LeadAttributions_Dealers')
        ALTER TABLE [AFL].[LeadAttributions] DROP CONSTRAINT [FK_LeadAttributions_Dealers];

    -- Drop columns
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AFL.CampaignPlacements') AND name = 'DealerId')
        ALTER TABLE [AFL].[CampaignPlacements] DROP COLUMN [DealerId];

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AFL.TokenClicks') AND name = 'DealerId')
        ALTER TABLE [AFL].[TokenClicks] DROP COLUMN [DealerId];

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AFL.LeadAttributions') AND name = 'DealerId')
        ALTER TABLE [AFL].[LeadAttributions] DROP COLUMN [DealerId];

    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = '20260504_1300_AddDealerId_AFL_TenantTables';

    COMMIT TRANSACTION;
    PRINT 'Rollback complete.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH
*/
