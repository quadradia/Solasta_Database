/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: SocialPosts
 * Description: Solasta Facebook Page and Instagram posts synced from Meta for
 *              affiliate sharing. Status is Pending, Shared or Hidden.
 * Author: Codex
 * Created: 2026-11-13 (UTC)
 * Dependencies: ACC.DealerTenants, AFL.MediaPlatforms
 * Migration: 20261113_0028_CreateAFL_SocialPosts
 * API mappings: Models/AFL/SocialPost.cs and CampaignPlacement.SocialPost.cs;
 *              remove corresponding manual mappings when generated equivalents exist.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_SocialPosts_Tenant_Platform_External'
               AND [object_id] = OBJECT_ID(N'AFL.SocialPosts'))
    CREATE UNIQUE INDEX [UQ_SocialPosts_Tenant_Platform_External]
        ON [AFL].[SocialPosts] ([DealerTenantId], [MediaPlatformId], [ExternalPostId]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_SocialPosts_Tenant_Status_PostedDate'
               AND [object_id] = OBJECT_ID(N'AFL.SocialPosts'))
    CREATE INDEX [IX_SocialPosts_Tenant_Status_PostedDate]
        ON [AFL].[SocialPosts] ([DealerTenantId], [Status], [PostedDate] DESC);

GO
