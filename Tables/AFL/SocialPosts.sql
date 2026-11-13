/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: SocialPosts
 * Description: Solasta's own Facebook Page and Instagram posts, synced from the Meta
 *              Graph API by the Solasta API so affiliates can reshare them with their
 *              tracked link. Staff set Status: Pending (new), Shared (affiliates see it)
 *              or Hidden. Meta's media links expire, so none are stored.
 * Author: Andres Sosa
 * Created: 2026-11-13
 * Dependencies: ACC.DealerTenants, AFL.MediaPlatforms
 * Migrations: 20261113_0028_CreateAFL_SocialPosts,
 *             20261113_0045_AlignAFL_SocialPostsWithConstitution
 * API mappings: Models/AFL/SocialPost.cs and CampaignPlacement.SocialPost.cs are written
 *               by hand; remove them when the AutoGenerator produces equivalents.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'AFL.SocialPosts', N'U') IS NULL
BEGIN
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
END;
GO

-- One row per Meta post per tenant; the sync upserts on this key.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.SocialPosts') AND [name] = N'UQ_SocialPosts_DealerTenantId_MediaPlatformId_ExternalPostId')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_SocialPosts_DealerTenantId_MediaPlatformId_ExternalPostId]
        ON [AFL].[SocialPosts] ([DealerTenantId], [MediaPlatformId], [ExternalPostId]);
GO

-- Staff and affiliate lists: a tenant's posts by status, newest first.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.SocialPosts') AND [name] = N'IX_SocialPosts_DealerTenantId_Status_PostedDate')
    CREATE NONCLUSTERED INDEX [IX_SocialPosts_DealerTenantId_Status_PostedDate]
        ON [AFL].[SocialPosts] ([DealerTenantId], [Status], [PostedDate] DESC);
GO
