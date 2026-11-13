/*
Migration: 20261113_0045_AlignAFL_SocialPostsWithConstitution
Author: Andres Sosa
Date: 2026-11-13
Description: Brings the objects from 20261113_0028_CreateAFL_SocialPosts in line with
             DATABASE_CONSTITUTION.md (Article III naming, Article V Section 4 column order).

  1. Recreates AFL.SocialPosts with the full audit tail
     (IsActive, IsDeleted, ModifiedDate, ModifiedById, CreatedDate, CreatedById, DEX_ROW_TS)
     and constraint names without the schema prefix (PK_SocialPosts, DF_SocialPosts_*,
     FK_SocialPosts_*, CK_SocialPosts_Status, UQ_/IX_SocialPosts_<columns>).
     Rows and SocialPostID values are preserved. CreatedById/ModifiedById get the system user
     default like the other AFL tables.
  2. Recreates AFL.CampaignPlacements so the FK column SocialPostId sits with the other foreign
     keys (after MediaPlatformId) instead of after DEX_ROW_TS, and renames
     FK_AFL_CampaignPlacements_SocialPosts to FK_CampaignPlacements_SocialPosts. Rows, identity
     values and the inbound foreign keys from AFL.TokenClicks and AFL.LeadAttributions are
     preserved.

  Column names and types do not change, so the Solasta API's hand-written mapping
  (Models/AFL/SocialPost.cs, CampaignPlacement.SocialPost.cs) keeps working. The API does not
  map IsDeleted or DEX_ROW_TS; their defaults fill them on insert.

Dependencies:
  20261113_0028_CreateAFL_SocialPosts

Expected impact:
  AFL.SocialPosts and AFL.CampaignPlacements are dropped and recreated inside one transaction.
  FK_TokenClicks_CampaignPlacements and FK_LeadAttributions_CampaignPlacements are dropped and
  recreated. Table-level GRANTs and extended properties on the two tables are not carried over;
  re-apply them if any exist. Run while the API is stopped or idle: the tables are locked for
  the duration.
*/

-- Filtered indexes require these; sqlcmd defaults QUOTED_IDENTIFIER to OFF.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261113_0045_AlignAFL_SocialPostsWithConstitution';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- =========================================================================
    -- Prerequisite checks
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM [dbo].[SchemaVersion]
                   WHERE [MigrationName] = N'20261113_0028_CreateAFL_SocialPosts' AND [Success] = 1)
        THROW 50001, 'Apply 20261113_0028_CreateAFL_SocialPosts first.', 1;
    IF OBJECT_ID(N'AFL.SocialPosts', N'U') IS NULL OR COL_LENGTH(N'AFL.CampaignPlacements', N'SocialPostId') IS NULL
        THROW 50001, 'AFL.SocialPosts or CampaignPlacements.SocialPostId is missing.', 1;

    -- Both recreations copy exactly these columns. Stop if a live table has drifted.
    IF (SELECT COUNT(*) FROM sys.columns WHERE [object_id] = OBJECT_ID(N'AFL.SocialPosts')) <> 17
       OR EXISTS (SELECT 1 FROM sys.columns
                  WHERE [object_id] = OBJECT_ID(N'AFL.SocialPosts')
                    AND [name] NOT IN (N'SocialPostID', N'DealerTenantId', N'MediaPlatformId', N'ExternalPostId',
                                       N'Permalink', N'Caption', N'MediaType', N'PostedDate', N'Status',
                                       N'ShareCaptionEn', N'ShareCaptionEs', N'LastSyncedDate', N'IsActive',
                                       N'CreatedDate', N'ModifiedDate', N'CreatedById', N'ModifiedById'))
        THROW 50001, 'AFL.SocialPosts columns differ from 20261113_0028_CreateAFL_SocialPosts. Reconcile the table first.', 1;
    IF (SELECT COUNT(*) FROM sys.columns WHERE [object_id] = OBJECT_ID(N'AFL.CampaignPlacements')) <> 16
       OR EXISTS (SELECT 1 FROM sys.columns
                  WHERE [object_id] = OBJECT_ID(N'AFL.CampaignPlacements')
                    AND [name] NOT IN (N'CampaignPlacementID', N'DealerTenantId', N'AffiliateCampaignId', N'MediaPlatformId',
                                       N'SocialPostId', N'TrackingToken', N'PlacementUrl', N'PostedDate', N'Notes',
                                       N'IsActive', N'IsDeleted', N'ModifiedDate', N'ModifiedById',
                                       N'CreatedDate', N'CreatedById', N'DEX_ROW_TS'))
        THROW 50001, 'AFL.CampaignPlacements columns differ from Tables/AFL/CampaignPlacements.sql. Add the extra columns to this migration first.', 1;

    IF EXISTS (SELECT 1 FROM sys.foreign_keys
               WHERE [referenced_object_id] = OBJECT_ID(N'AFL.SocialPosts')
                 AND [name] <> N'FK_AFL_CampaignPlacements_SocialPosts')
        THROW 50001, 'An unexpected foreign key references AFL.SocialPosts. Add it to this migration first.', 1;
    IF EXISTS (SELECT 1 FROM sys.foreign_keys
               WHERE [referenced_object_id] = OBJECT_ID(N'AFL.CampaignPlacements')
                 AND [name] NOT IN (N'FK_TokenClicks_CampaignPlacements', N'FK_LeadAttributions_CampaignPlacements'))
        THROW 50001, 'An unexpected foreign key references AFL.CampaignPlacements. Add it to this migration first.', 1;
    IF EXISTS (SELECT 1 FROM sys.triggers
               WHERE [parent_id] IN (OBJECT_ID(N'AFL.SocialPosts'), OBJECT_ID(N'AFL.CampaignPlacements')))
        THROW 50001, 'AFL.SocialPosts or AFL.CampaignPlacements has triggers. Add them to this migration first.', 1;
    IF EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.CampaignPlacements') AND [type] > 0
                 AND [name] NOT IN (N'PK_CampaignPlacements', N'UQ_CampaignPlacements_TrackingToken',
                                    N'IX_CampaignPlacements_SocialPostId'))
       OR EXISTS (SELECT 1 FROM sys.indexes
                  WHERE [object_id] = OBJECT_ID(N'AFL.SocialPosts') AND [type] > 0
                    AND [name] NOT IN (N'PK_AFL_SocialPosts', N'UQ_SocialPosts_Tenant_Platform_External',
                                       N'IX_SocialPosts_Tenant_Status_PostedDate'))
        THROW 50001, 'AFL.SocialPosts or AFL.CampaignPlacements has an index this migration does not know. Add it first.', 1;

    -- =========================================================================
    -- Step 1: Back up both tables and drop them
    -- =========================================================================
    SELECT [SocialPostID], [DealerTenantId], [MediaPlatformId], [ExternalPostId], [Permalink], [Caption],
           [MediaType], [PostedDate], [Status], [ShareCaptionEn], [ShareCaptionEs], [LastSyncedDate],
           [IsActive], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById]
    INTO #SocialPostsBackup
    FROM [AFL].[SocialPosts];
    DECLARE @PostRows INT = @@ROWCOUNT;
    DECLARE @PostIdentity BIGINT = IDENT_CURRENT(N'AFL.SocialPosts');
    DECLARE @PostIdentityUsed BIT = CASE WHEN EXISTS (SELECT 1 FROM sys.identity_columns
                                                      WHERE [object_id] = OBJECT_ID(N'AFL.SocialPosts')
                                                        AND [last_value] IS NOT NULL) THEN 1 ELSE 0 END;

    SELECT [CampaignPlacementID], [DealerTenantId], [AffiliateCampaignId], [MediaPlatformId], [SocialPostId],
           [TrackingToken], [PlacementUrl], [PostedDate], [Notes],
           [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById], [DEX_ROW_TS]
    INTO #CampaignPlacementsBackup
    FROM [AFL].[CampaignPlacements];
    DECLARE @PlacementRows INT = @@ROWCOUNT;
    DECLARE @PlacementIdentity BIGINT = IDENT_CURRENT(N'AFL.CampaignPlacements');
    DECLARE @PlacementIdentityUsed BIT = CASE WHEN EXISTS (SELECT 1 FROM sys.identity_columns
                                                           WHERE [object_id] = OBJECT_ID(N'AFL.CampaignPlacements')
                                                             AND [last_value] IS NOT NULL) THEN 1 ELSE 0 END;

    IF OBJECT_ID(N'AFL.TokenClicks', N'U') IS NOT NULL
       AND EXISTS (SELECT 1 FROM sys.foreign_keys WHERE [name] = N'FK_TokenClicks_CampaignPlacements')
        ALTER TABLE [AFL].[TokenClicks] DROP CONSTRAINT [FK_TokenClicks_CampaignPlacements];
    IF OBJECT_ID(N'AFL.LeadAttributions', N'U') IS NOT NULL
       AND EXISTS (SELECT 1 FROM sys.foreign_keys WHERE [name] = N'FK_LeadAttributions_CampaignPlacements')
        ALTER TABLE [AFL].[LeadAttributions] DROP CONSTRAINT [FK_LeadAttributions_CampaignPlacements];

    DROP TABLE [AFL].[CampaignPlacements];
    DROP TABLE [AFL].[SocialPosts];

    -- =========================================================================
    -- Step 2: Recreate AFL.SocialPosts
    -- =========================================================================
    CREATE TABLE [AFL].[SocialPosts]
    (
        [SocialPostID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [MediaPlatformId] [int] NOT NULL,
        -- Meta Page post id (pageid_postid) or Instagram media id.
        [ExternalPostId] [varchar](100) NOT NULL,
        [Permalink] [nvarchar](1000) NULL,
        [Caption] [nvarchar](max) NULL,
        -- As Meta reports it: PHOTO, VIDEO, CAROUSEL_ALBUM, REELS, TEXT, LINK ...
        [MediaType] [varchar](30) NULL,
        [PostedDate] [datetimeoffset](7) NOT NULL,
        -- Pending: new, staff have not decided. Shared: affiliates see it. Hidden: staff chose not to share it.
        [Status] [varchar](10) NOT NULL CONSTRAINT [DF_SocialPosts_Status] DEFAULT ('Pending'),
        -- Captions staff suggest to affiliates; 2200 is Instagram's caption limit.
        [ShareCaptionEn] [nvarchar](2200) NULL,
        [ShareCaptionEs] [nvarchar](2200) NULL,
        [LastSyncedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_SocialPosts_LastSyncedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_SocialPosts_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_SocialPosts_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_SocialPosts_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SocialPosts_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_SocialPosts_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SocialPosts_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_SocialPosts_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_SocialPosts] PRIMARY KEY CLUSTERED ([SocialPostID] ASC),
        CONSTRAINT [FK_SocialPosts_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_SocialPosts_MediaPlatforms] FOREIGN KEY ([MediaPlatformId])
            REFERENCES [AFL].[MediaPlatforms] ([MediaPlatformID]),
        CONSTRAINT [CK_SocialPosts_Status] CHECK ([Status] IN ('Pending', 'Shared', 'Hidden'))
    );

    SET IDENTITY_INSERT [AFL].[SocialPosts] ON;
    INSERT INTO [AFL].[SocialPosts]
        ([SocialPostID], [DealerTenantId], [MediaPlatformId], [ExternalPostId], [Permalink], [Caption],
         [MediaType], [PostedDate], [Status], [ShareCaptionEn], [ShareCaptionEs], [LastSyncedDate],
         [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
    SELECT [SocialPostID], [DealerTenantId], [MediaPlatformId], [ExternalPostId], [Permalink], [Caption],
           [MediaType], [PostedDate], [Status], [ShareCaptionEn], [ShareCaptionEs], [LastSyncedDate],
           [IsActive], 0, [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById]
    FROM #SocialPostsBackup;
    SET IDENTITY_INSERT [AFL].[SocialPosts] OFF;

    IF (SELECT COUNT(*) FROM [AFL].[SocialPosts]) <> @PostRows
        THROW 50001, 'AFL.SocialPosts row count changed during the recreation.', 1;
    -- Keep new ids above every id ever issued, deleted ones included.
    IF @PostIdentityUsed = 1
        DBCC CHECKIDENT (N'AFL.SocialPosts', RESEED, @PostIdentity) WITH NO_INFOMSGS;

    -- One row per Meta post per tenant; the sync upserts on this key.
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_SocialPosts_DealerTenantId_MediaPlatformId_ExternalPostId]
        ON [AFL].[SocialPosts] ([DealerTenantId], [MediaPlatformId], [ExternalPostId]);
    -- Staff and affiliate lists: a tenant's posts by status, newest first.
    CREATE NONCLUSTERED INDEX [IX_SocialPosts_DealerTenantId_Status_PostedDate]
        ON [AFL].[SocialPosts] ([DealerTenantId], [Status], [PostedDate] DESC);

    DROP TABLE #SocialPostsBackup;
    PRINT 'Recreated AFL.SocialPosts (' + CAST(@PostRows AS NVARCHAR(10)) + ' rows kept)';

    -- =========================================================================
    -- Step 3: Recreate AFL.CampaignPlacements with SocialPostId among the FKs
    -- =========================================================================
    CREATE TABLE [AFL].[CampaignPlacements]
    (
        [CampaignPlacementID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [AffiliateCampaignId] [int] NOT NULL,
        [MediaPlatformId] [int] NOT NULL,
        -- Set when the placement is an affiliate's tracked link for one of Solasta's own posts.
        [SocialPostId] [int] NULL,
        [TrackingToken] [varchar](50) NOT NULL,
        [PlacementUrl] [nvarchar](2000) NULL,
        [PostedDate] [datetimeoffset](7) NULL,
        [Notes] [nvarchar](500) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_CampaignPlacements_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_CampaignPlacements_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_CampaignPlacements_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_CampaignPlacements_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_CampaignPlacements_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_CampaignPlacements_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_CampaignPlacements_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_CampaignPlacements] PRIMARY KEY CLUSTERED ([CampaignPlacementID] ASC),
        CONSTRAINT [FK_CampaignPlacements_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_CampaignPlacements_AffiliateCampaigns] FOREIGN KEY ([AffiliateCampaignId])
            REFERENCES [AFL].[AffiliateCampaigns] ([AffiliateCampaignID]),
        CONSTRAINT [FK_CampaignPlacements_MediaPlatforms] FOREIGN KEY ([MediaPlatformId])
            REFERENCES [AFL].[MediaPlatforms] ([MediaPlatformID]),
        CONSTRAINT [FK_CampaignPlacements_SocialPosts] FOREIGN KEY ([SocialPostId])
            REFERENCES [AFL].[SocialPosts] ([SocialPostID]),
        CONSTRAINT [UQ_CampaignPlacements_TrackingToken] UNIQUE ([TrackingToken])
    );

    SET IDENTITY_INSERT [AFL].[CampaignPlacements] ON;
    INSERT INTO [AFL].[CampaignPlacements]
        ([CampaignPlacementID], [DealerTenantId], [AffiliateCampaignId], [MediaPlatformId], [SocialPostId],
         [TrackingToken], [PlacementUrl], [PostedDate], [Notes],
         [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById], [DEX_ROW_TS])
    SELECT [CampaignPlacementID], [DealerTenantId], [AffiliateCampaignId], [MediaPlatformId], [SocialPostId],
           [TrackingToken], [PlacementUrl], [PostedDate], [Notes],
           [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById], [DEX_ROW_TS]
    FROM #CampaignPlacementsBackup;
    SET IDENTITY_INSERT [AFL].[CampaignPlacements] OFF;

    IF (SELECT COUNT(*) FROM [AFL].[CampaignPlacements]) <> @PlacementRows
        THROW 50001, 'AFL.CampaignPlacements row count changed during the recreation.', 1;
    IF @PlacementIdentityUsed = 1
        DBCC CHECKIDENT (N'AFL.CampaignPlacements', RESEED, @PlacementIdentity) WITH NO_INFOMSGS;

    CREATE NONCLUSTERED INDEX [IX_CampaignPlacements_SocialPostId]
        ON [AFL].[CampaignPlacements] ([SocialPostId]) WHERE [SocialPostId] IS NOT NULL;

    DROP TABLE #CampaignPlacementsBackup;

    IF OBJECT_ID(N'AFL.TokenClicks', N'U') IS NOT NULL
        ALTER TABLE [AFL].[TokenClicks] WITH CHECK ADD CONSTRAINT [FK_TokenClicks_CampaignPlacements]
            FOREIGN KEY ([CampaignPlacementId]) REFERENCES [AFL].[CampaignPlacements] ([CampaignPlacementID]);
    IF OBJECT_ID(N'AFL.LeadAttributions', N'U') IS NOT NULL
        ALTER TABLE [AFL].[LeadAttributions] WITH CHECK ADD CONSTRAINT [FK_LeadAttributions_CampaignPlacements]
            FOREIGN KEY ([CampaignPlacementId]) REFERENCES [AFL].[CampaignPlacements] ([CampaignPlacementID]);

    PRINT 'Recreated AFL.CampaignPlacements (' + CAST(@PlacementRows AS NVARCHAR(10)) + ' rows kept)';

    -- =========================================================================
    -- Record migration
    -- =========================================================================
    INSERT INTO [dbo].[SchemaVersion]
        ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName,
            N'AFL.SocialPosts and AFL.CampaignPlacements recreated in constitutional column order and naming.',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration 20261113_0045_AlignAFL_SocialPostsWithConstitution applied successfully';
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
The previous layout broke the constitution, so there is nothing worth restoring: the data and
column names are unchanged. To undo the record only (for example to rerun after a fix):

DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261113_0045_AlignAFL_SocialPostsWithConstitution';

To return to the 0028 layout, follow the ROLLBACK SCRIPT of 20261113_0028_CreateAFL_SocialPosts
(after backing up the data), then rerun that migration.

================================================================================
VERIFICATION QUERIES
================================================================================
-- 1. Column order (SocialPostId after MediaPlatformId; audit tail last)
SELECT [column_id], [name] FROM sys.columns WHERE [object_id] = OBJECT_ID(N'AFL.CampaignPlacements') ORDER BY [column_id];
SELECT [column_id], [name] FROM sys.columns WHERE [object_id] = OBJECT_ID(N'AFL.SocialPosts') ORDER BY [column_id];

-- 2. No constraint or index keeps the AFL_ prefix
SELECT [name] FROM sys.objects WHERE [name] LIKE '%[_]AFL[_]SocialPosts%' OR [name] LIKE 'FK[_]AFL[_]CampaignPlacements%';   -- Expected: none
SELECT [name] FROM sys.indexes WHERE [object_id] IN (OBJECT_ID(N'AFL.SocialPosts'), OBJECT_ID(N'AFL.CampaignPlacements'));

-- 3. Inbound foreign keys are back
SELECT [name] FROM sys.foreign_keys
WHERE [name] IN (N'FK_TokenClicks_CampaignPlacements', N'FK_LeadAttributions_CampaignPlacements', N'FK_CampaignPlacements_SocialPosts');

-- 4. Migration recorded
SELECT * FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261113_0045_AlignAFL_SocialPostsWithConstitution';
*/
