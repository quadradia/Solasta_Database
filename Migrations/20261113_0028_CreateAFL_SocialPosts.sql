/*
Migration: 20261113_0028_CreateAFL_SocialPosts
Author: Codex
Date: 2026-11-13 (UTC)
Description: Stores Solasta Facebook Page and Instagram posts synced from Meta,
             with staff sharing status and optional campaign placement links.
Dependencies:
  20260504_1200_CreateAFL_AffiliateMarketingSchema
  20260505_1800_DeprecateDealers_ReplaceWithDealerTenants
  20260504_1400_SeedAFL_MediaPlatforms (FB and IG used by the sync)

The API maps these objects by hand in Models/AFL/SocialPost.cs and
Models/AFL/CampaignPlacement.SocialPost.cs. If a later AutoGenerator run creates
SocialPost.generated.cs or SocialPostId on CampaignPlacement, remove the
corresponding hand-written mapping to avoid duplicate definitions.
No database is selected implicitly; the migration runner supplies the target.
*/

-- Required SET options for the filtered CampaignPlacements index.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261113_0028_CreateAFL_SocialPosts';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion]
               WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'AFL.MediaPlatforms', N'U') IS NULL
       OR OBJECT_ID(N'AFL.CampaignPlacements', N'U') IS NULL
       OR OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL
        THROW 50001, 'AFL.SocialPosts requires AFL.MediaPlatforms, AFL.CampaignPlacements and ACC.DealerTenants.', 1;

    IF OBJECT_ID(N'AFL.SocialPosts', N'U') IS NULL
    BEGIN
        CREATE TABLE [AFL].[SocialPosts]
        (
            [SocialPostID] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_AFL_SocialPosts] PRIMARY KEY,
            [DealerTenantId] INT NOT NULL,
            [MediaPlatformId] INT NOT NULL,
            -- Meta Page post id (pageid_postid) or Instagram media id.
            [ExternalPostId] VARCHAR(100) NOT NULL,
            [Permalink] NVARCHAR(1000) NULL,
            [Caption] NVARCHAR(MAX) NULL,
            -- IMAGE, VIDEO, CAROUSEL_ALBUM, REELS, TEXT, LINK ...
            [MediaType] VARCHAR(30) NULL,
            [PostedDate] DATETIMEOFFSET NOT NULL,
            [Status] VARCHAR(10) NOT NULL CONSTRAINT [DF_AFL_SocialPosts_Status] DEFAULT ('Pending'),
            [ShareCaptionEn] NVARCHAR(2200) NULL,
            [ShareCaptionEs] NVARCHAR(2200) NULL,
            [LastSyncedDate] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_AFL_SocialPosts_LastSyncedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [IsActive] BIT NOT NULL CONSTRAINT [DF_AFL_SocialPosts_IsActive] DEFAULT (1),
            [CreatedDate] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_AFL_SocialPosts_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedDate] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_AFL_SocialPosts_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] UNIQUEIDENTIFIER NOT NULL,
            [ModifiedById] UNIQUEIDENTIFIER NOT NULL,
            CONSTRAINT [FK_AFL_SocialPosts_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_AFL_SocialPosts_MediaPlatforms] FOREIGN KEY ([MediaPlatformId])
                REFERENCES [AFL].[MediaPlatforms] ([MediaPlatformID]),
            CONSTRAINT [CK_AFL_SocialPosts_Status] CHECK ([Status] IN ('Pending', 'Shared', 'Hidden'))
        );
    END;

    -- Separate guards also support databases where the standalone script ran first.
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_SocialPosts_Tenant_Platform_External'
                   AND [object_id] = OBJECT_ID(N'AFL.SocialPosts'))
        CREATE UNIQUE INDEX [UQ_SocialPosts_Tenant_Platform_External]
            ON [AFL].[SocialPosts] ([DealerTenantId], [MediaPlatformId], [ExternalPostId]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_SocialPosts_Tenant_Status_PostedDate'
                   AND [object_id] = OBJECT_ID(N'AFL.SocialPosts'))
        CREATE INDEX [IX_SocialPosts_Tenant_Status_PostedDate]
            ON [AFL].[SocialPosts] ([DealerTenantId], [Status], [PostedDate] DESC);

    IF COL_LENGTH(N'AFL.CampaignPlacements', N'SocialPostId') IS NULL
        ALTER TABLE [AFL].[CampaignPlacements] ADD [SocialPostId] INT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE [name] = N'FK_AFL_CampaignPlacements_SocialPosts'
                   AND [parent_object_id] = OBJECT_ID(N'AFL.CampaignPlacements'))
        ALTER TABLE [AFL].[CampaignPlacements] WITH CHECK
            ADD CONSTRAINT [FK_AFL_CampaignPlacements_SocialPosts] FOREIGN KEY ([SocialPostId])
            REFERENCES [AFL].[SocialPosts] ([SocialPostID]);

    -- Compile separately: SocialPostId may have been added in this batch.
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_CampaignPlacements_SocialPostId'
                   AND [object_id] = OBJECT_ID(N'AFL.CampaignPlacements'))
        EXEC sys.sp_executesql N'CREATE INDEX [IX_CampaignPlacements_SocialPostId]
            ON [AFL].[CampaignPlacements] ([SocialPostId]) WHERE [SocialPostId] IS NOT NULL;';

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Create AFL.SocialPosts and link campaign placements to synced Meta posts',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- The earlier platform seed includes FB and IG; verify before the first sync.
SELECT [MediaPlatformID], [MediaPlatformCode], [MediaPlatformName], [IsActive]
FROM [AFL].[MediaPlatforms]
WHERE [MediaPlatformCode] IN ('FB', 'IG');
GO

/*
ROLLBACK SCRIPT (removes synced posts and placement associations; review data first).
Do not use this rollback if the standalone script created these objects before
this migration; removing the SchemaVersion entry alone preserves those objects.

-- SET XACT_ABORT ON;
-- BEGIN TRANSACTION;
-- ALTER TABLE [AFL].[CampaignPlacements] DROP CONSTRAINT [FK_AFL_CampaignPlacements_SocialPosts];
-- DROP INDEX [IX_CampaignPlacements_SocialPostId] ON [AFL].[CampaignPlacements];
-- ALTER TABLE [AFL].[CampaignPlacements] DROP COLUMN [SocialPostId];
-- DROP TABLE [AFL].[SocialPosts];
-- DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261113_0028_CreateAFL_SocialPosts';
-- COMMIT TRANSACTION;
*/
