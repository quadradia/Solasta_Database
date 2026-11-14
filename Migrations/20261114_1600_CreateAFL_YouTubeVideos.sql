/*
Migration: 20261114_1600_CreateAFL_YouTubeVideos
Author: Andres Sosa
Date: 2026-11-14
Description: Creates AFL.YouTubeVideos for the admin site's YouTube upload page and the
             website's Videos page, and seeds the 7 videos the website lists today
             (UploadStatus Imported, ShowOnWebsite 1) for the Solasta Lighting tenant.
             The YouTube platform (code YT) is already in AFL.MediaPlatforms.
Dependencies:
  20261113_0045_AlignAFL_SocialPostsWithConstitution
  20261106_1600_SeedACC_SolastaLightingTenant
  20260504_1400_SeedAFL_MediaPlatforms
Rollback:
  DROP TABLE [AFL].[YouTubeVideos];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261114_1600_CreateAFL_YouTubeVideos';
  (AFL.SocialPosts rows with platform YT that the upload job created stay; delete them separately if wanted.)
Expected impact: New table only; no existing object changes.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261114_1600_CreateAFL_YouTubeVideos';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();
    DECLARE @SolastaProxy VARCHAR(100) = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6';

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'AFL.SocialPosts', N'U') IS NULL OR OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL
        THROW 50001, 'AFL.YouTubeVideos requires AFL.SocialPosts and ACC.DealerTenants.', 1;

    IF OBJECT_ID(N'AFL.YouTubeVideos', N'U') IS NULL
    BEGIN
        CREATE TABLE [AFL].[YouTubeVideos]
        (
            [YouTubeVideoID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [SocialPostId] [int] NULL,
            [CaptionSourceSocialPostId] [int] NULL,
            [ExternalVideoId] [varchar](20) NULL,
            [Title] [nvarchar](100) NOT NULL,
            [Description] [nvarchar](5000) NULL,
            [Tags] [nvarchar](500) NULL,
            [PrivacyStatus] [varchar](10) NOT NULL CONSTRAINT [DF_YouTubeVideos_PrivacyStatus] DEFAULT ('private'),
            [UploadStatus] [varchar](10) NOT NULL CONSTRAINT [DF_YouTubeVideos_UploadStatus] DEFAULT ('Receiving'),
            [UploadError] [nvarchar](1000) NULL,
            [UploadAttempts] [int] NOT NULL CONSTRAINT [DF_YouTubeVideos_UploadAttempts] DEFAULT ((0)),
            [StorageKey] [nvarchar](100) NULL,
            [OriginalFileName] [nvarchar](260) NULL,
            [FileSizeBytes] [bigint] NULL,
            [UploadedDate] [datetimeoffset](7) NULL,
            [ShowOnWebsite] [bit] NOT NULL CONSTRAINT [DF_YouTubeVideos_ShowOnWebsite] DEFAULT ((0)),
            [WebsiteCategory] [nvarchar](30) NULL,
            [WebsiteSortOrder] [int] NOT NULL CONSTRAINT [DF_YouTubeVideos_WebsiteSortOrder] DEFAULT ((0)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_YouTubeVideos_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_YouTubeVideos_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_YouTubeVideos_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_YouTubeVideos_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_YouTubeVideos_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_YouTubeVideos_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_YouTubeVideos_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_YouTubeVideos] PRIMARY KEY CLUSTERED ([YouTubeVideoID] ASC),
            CONSTRAINT [FK_YouTubeVideos_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_YouTubeVideos_SocialPosts] FOREIGN KEY ([SocialPostId])
                REFERENCES [AFL].[SocialPosts] ([SocialPostID]),
            CONSTRAINT [FK_YouTubeVideos_SocialPosts_CaptionSource] FOREIGN KEY ([CaptionSourceSocialPostId])
                REFERENCES [AFL].[SocialPosts] ([SocialPostID]),
            CONSTRAINT [CK_YouTubeVideos_PrivacyStatus] CHECK ([PrivacyStatus] IN ('private', 'unlisted', 'public')),
            CONSTRAINT [CK_YouTubeVideos_UploadStatus] CHECK ([UploadStatus] IN ('Receiving', 'Queued', 'Uploading', 'Uploaded', 'Failed', 'Imported'))
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'AFL.YouTubeVideos') AND [name] = N'UQ_YouTubeVideos_DealerTenantId_ExternalVideoId')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_YouTubeVideos_DealerTenantId_ExternalVideoId]
            ON [AFL].[YouTubeVideos] ([DealerTenantId], [ExternalVideoId])
            WHERE [ExternalVideoId] IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'AFL.YouTubeVideos') AND [name] = N'IX_YouTubeVideos_UploadStatus')
        CREATE NONCLUSTERED INDEX [IX_YouTubeVideos_UploadStatus]
            ON [AFL].[YouTubeVideos] ([UploadStatus], [YouTubeVideoID])
            WHERE [UploadStatus] IN ('Queued', 'Uploading');

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'AFL.YouTubeVideos') AND [name] = N'IX_YouTubeVideos_DealerTenantId_ShowOnWebsite_WebsiteSortOrder')
        CREATE NONCLUSTERED INDEX [IX_YouTubeVideos_DealerTenantId_ShowOnWebsite_WebsiteSortOrder]
            ON [AFL].[YouTubeVideos] ([DealerTenantId], [ShowOnWebsite], [WebsiteSortOrder]);

    -- Seed the videos the website's Videos page hard-codes today (src/components/pages/VideosPage.tsx),
    -- in the same order, so the page looks the same once it reads from the API.
    DECLARE @TenantId INT = (SELECT [DealerTenantID] FROM [ACC].[DealerTenants] WHERE [Proxy] = @SolastaProxy);
    IF @TenantId IS NULL
        PRINT 'Solasta Lighting tenant not found; skipping the website video seed.';
    ELSE
        INSERT INTO [AFL].[YouTubeVideos]
            ([DealerTenantId], [ExternalVideoId], [Title], [Description], [PrivacyStatus], [UploadStatus],
             [ShowOnWebsite], [WebsiteCategory], [WebsiteSortOrder])
        SELECT @TenantId, s.[ExternalVideoId], s.[Title], s.[Description], 'public', 'Imported', 1, s.[WebsiteCategory], s.[WebsiteSortOrder]
        FROM (VALUES
            ('HIiqk05ImlQ', N'This House Comes Alive at Halloween',
             N'A Halloween home showcase featuring Solasta permanent lighting', N'Showcase', 10),
            ('Q840l7Ri5-o', N'Architectural Accent Lighting That Transforms Your Home',
             N'A home showcase featuring architectural accent lighting from Solasta', N'Showcase', 20),
            ('aEp_VRQc9B0', N'From Holiday Lights to Architectural Accent Lighting',
             N'Solasta permanent lighting for holiday displays and architectural accents', N'Showcase', 30),
            ('kwO0h8lFqb8', N'Engineered Gable Peak Component',
             N'Our custom-engineered gable peak piece centers a light exactly at the top of every gable, so the lights below line up perfectly on both sides', N'Engineering', 40),
            ('8MG9Ym5gAwc', N'Gable Peak Installed',
             N'We don''t just sell permanent lights, we engineer them. The Solasta Gable Peak places a light precisely at the center of every gable and keeps the spacing symmetrical down both sides', N'Engineering', 50),
            ('b9rZlAVsfAA', N'Integrated 8K Security Cameras',
             N'Security cameras built into the Deluxe Track System: Ultra HD 8K video, a 180° field of view and two-way voice, cleanly integrated into your soffit and installed to help protect against tampering', N'Engineering', 60),
            ('EPU9VJLpvHM', N'Dual-Zone Double Track Deluxe System',
             N'Two independently controlled tracks on one soffit: vibrant holiday lighting up front and elegant year-round accent lighting behind it. Designed, engineered and manufactured in Orem, Utah', N'Engineering', 70)
        ) AS s ([ExternalVideoId], [Title], [Description], [WebsiteCategory], [WebsiteSortOrder])
        WHERE NOT EXISTS (SELECT 1 FROM [AFL].[YouTubeVideos] v
                          WHERE v.[DealerTenantId] = @TenantId AND v.[ExternalVideoId] = s.[ExternalVideoId]);

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Create AFL.YouTubeVideos and seed the website''s current videos',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
