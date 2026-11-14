/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: YouTubeVideos
 * Description: Videos on Solasta's YouTube channel that staff upload from the admin
 *              site, plus the videos that were on the website before the upload page
 *              existed (UploadStatus Imported). The Solasta API stages the file
 *              (StorageKey), uploads it to YouTube in the background, then records the
 *              YouTube id and a matching AFL.SocialPosts row so affiliates can share it.
 *              Rows with ShowOnWebsite = 1 are listed on the website's Videos page.
 * Author: Andres Sosa
 * Created: 2026-11-14
 * Dependencies: ACC.DealerTenants, AFL.SocialPosts
 * Migrations: 20261114_1600_CreateAFL_YouTubeVideos
 * API mappings: Models/AFL/YouTubeVideo.cs is written by hand; remove it when the
 *               AutoGenerator produces an equivalent.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'AFL.YouTubeVideos', N'U') IS NULL
BEGIN
    CREATE TABLE [AFL].[YouTubeVideos]
    (
        [YouTubeVideoID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        -- The SocialPosts row (platform YT) created once the upload finishes.
        [SocialPostId] [int] NULL,
        -- The Facebook or Instagram post whose caption the text was based on, if any.
        [CaptionSourceSocialPostId] [int] NULL,
        -- YouTube's 11-character video id; NULL until the upload finishes.
        [ExternalVideoId] [varchar](20) NULL,
        -- YouTube limits: title 100 characters, description 5000 bytes, tags 500 characters.
        [Title] [nvarchar](100) NOT NULL,
        [Description] [nvarchar](5000) NULL,
        -- Comma-separated.
        [Tags] [nvarchar](500) NULL,
        -- private, unlisted or public, as sent to YouTube. Until Google's API audit passes,
        -- YouTube forces every API upload to private whatever is sent.
        [PrivacyStatus] [varchar](10) NOT NULL CONSTRAINT [DF_YouTubeVideos_PrivacyStatus] DEFAULT ('private'),
        -- Receiving: the admin site is still sending the file in pieces.
        -- Queued: file staged, waiting for the upload job. Uploading: in progress.
        -- Uploaded: on YouTube. Failed: see UploadError; staff can retry.
        -- Imported: already on YouTube before the admin page existed.
        [UploadStatus] [varchar](10) NOT NULL CONSTRAINT [DF_YouTubeVideos_UploadStatus] DEFAULT ('Receiving'),
        [UploadError] [nvarchar](1000) NULL,
        [UploadAttempts] [int] NOT NULL CONSTRAINT [DF_YouTubeVideos_UploadAttempts] DEFAULT ((0)),
        -- Opaque key of the staged file in the API's document storage; cleared after upload.
        [StorageKey] [nvarchar](100) NULL,
        [OriginalFileName] [nvarchar](260) NULL,
        [FileSizeBytes] [bigint] NULL,
        [UploadedDate] [datetimeoffset](7) NULL,
        [ShowOnWebsite] [bit] NOT NULL CONSTRAINT [DF_YouTubeVideos_ShowOnWebsite] DEFAULT ((0)),
        -- The filter label on the website's Videos page, e.g. Showcase, Engineering.
        [WebsiteCategory] [nvarchar](30) NULL,
        -- Lower first on the Videos page.
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
GO

-- One row per YouTube video per tenant once it has an id.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.YouTubeVideos') AND [name] = N'UQ_YouTubeVideos_DealerTenantId_ExternalVideoId')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_YouTubeVideos_DealerTenantId_ExternalVideoId]
        ON [AFL].[YouTubeVideos] ([DealerTenantId], [ExternalVideoId])
        WHERE [ExternalVideoId] IS NOT NULL;
GO

-- The upload job picks up queued rows, oldest first.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.YouTubeVideos') AND [name] = N'IX_YouTubeVideos_UploadStatus')
    CREATE NONCLUSTERED INDEX [IX_YouTubeVideos_UploadStatus]
        ON [AFL].[YouTubeVideos] ([UploadStatus], [YouTubeVideoID])
        WHERE [UploadStatus] IN ('Queued', 'Uploading');
GO

-- The website's Videos page: a tenant's listed videos in order.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.YouTubeVideos') AND [name] = N'IX_YouTubeVideos_DealerTenantId_ShowOnWebsite_WebsiteSortOrder')
    CREATE NONCLUSTERED INDEX [IX_YouTubeVideos_DealerTenantId_ShowOnWebsite_WebsiteSortOrder]
        ON [AFL].[YouTubeVideos] ([DealerTenantId], [ShowOnWebsite], [WebsiteSortOrder]);
GO
