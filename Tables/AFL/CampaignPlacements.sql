/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: CampaignPlacements
 * Description: Represents a single ad or post placement for a campaign on a
 *              specific media platform. Each placement generates a unique
 *              TrackingToken that the application embeds in the ad URL as a
 *              query parameter (e.g., ?afl=AFL-LI-00042). The token is composed
 *              of the affiliate code, platform code, and placement ID and is
 *              set by the application on insert.
 *              Example: Affiliate "JSMITH" posts on LinkedIn → token "AFL-LI-00042"
 * Author:
 * Created: 2026-05-04
 * Dependencies: AFL.AffiliateCampaigns, AFL.MediaPlatforms, ACC.DealerTenants
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'CampaignPlacements' AND schema_id = SCHEMA_ID('AFL'))
BEGIN
    CREATE TABLE [AFL].[CampaignPlacements]
    (
        [CampaignPlacementID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [AffiliateCampaignId] [int] NOT NULL,
        [MediaPlatformId] [int] NOT NULL,
        [TrackingToken] [varchar](50) NOT NULL,
        [PlacementUrl] [nvarchar](2000) NULL,
        [PostedDate] [datetimeoffset](7) NULL,
        [Notes] [nvarchar](500) NULL,
        [IsActive] [bit] NOT NULL,
        [IsDeleted] [bit] NOT NULL,
        [ModifiedDate] [datetimeoffset](7) NOT NULL,
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL,
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
        CONSTRAINT [PK_CampaignPlacements] PRIMARY KEY CLUSTERED
(
	[CampaignPlacementID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    )

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'UQ_CampaignPlacements_TrackingToken' AND type = 'UQ')
ALTER TABLE [AFL].[CampaignPlacements] ADD CONSTRAINT [UQ_CampaignPlacements_TrackingToken] UNIQUE ([TrackingToken])
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CampaignPlacements_IsActive' AND type = 'D')
ALTER TABLE [AFL].[CampaignPlacements] ADD  CONSTRAINT [DF_CampaignPlacements_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CampaignPlacements_IsDeleted' AND type = 'D')
ALTER TABLE [AFL].[CampaignPlacements] ADD  CONSTRAINT [DF_CampaignPlacements_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CampaignPlacements_ModifiedDate' AND type = 'D')
ALTER TABLE [AFL].[CampaignPlacements] ADD  CONSTRAINT [DF_CampaignPlacements_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CampaignPlacements_ModifiedById' AND type = 'D')
ALTER TABLE [AFL].[CampaignPlacements] ADD  CONSTRAINT [DF_CampaignPlacements_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CampaignPlacements_CreatedDate' AND type = 'D')
ALTER TABLE [AFL].[CampaignPlacements] ADD  CONSTRAINT [DF_CampaignPlacements_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CampaignPlacements_CreatedById' AND type = 'D')
ALTER TABLE [AFL].[CampaignPlacements] ADD  CONSTRAINT [DF_CampaignPlacements_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_CampaignPlacements_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [AFL].[CampaignPlacements] ADD  CONSTRAINT [DF_CampaignPlacements_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_CampaignPlacements_AffiliateCampaigns')
ALTER TABLE [AFL].[CampaignPlacements]  WITH CHECK ADD  CONSTRAINT [FK_CampaignPlacements_AffiliateCampaigns] FOREIGN KEY([AffiliateCampaignId])
REFERENCES [AFL].[AffiliateCampaigns] ([AffiliateCampaignID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_CampaignPlacements_MediaPlatforms')
ALTER TABLE [AFL].[CampaignPlacements]  WITH CHECK ADD  CONSTRAINT [FK_CampaignPlacements_MediaPlatforms] FOREIGN KEY([MediaPlatformId])
REFERENCES [AFL].[MediaPlatforms] ([MediaPlatformID])
GO

ALTER TABLE [AFL].[CampaignPlacements] CHECK CONSTRAINT [FK_CampaignPlacements_AffiliateCampaigns]
GO

ALTER TABLE [AFL].[CampaignPlacements] CHECK CONSTRAINT [FK_CampaignPlacements_MediaPlatforms]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_CampaignPlacements_DealerTenants')
ALTER TABLE [AFL].[CampaignPlacements]  WITH CHECK ADD  CONSTRAINT [FK_CampaignPlacements_DealerTenants] FOREIGN KEY([DealerTenantId])
REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
GO

ALTER TABLE [AFL].[CampaignPlacements] CHECK CONSTRAINT [FK_CampaignPlacements_DealerTenants]
GO
