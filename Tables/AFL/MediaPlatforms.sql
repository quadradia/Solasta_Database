/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: MediaPlatforms
 * Description: Lookup table for social media and advertising platforms used
 *              in affiliate marketing campaigns (e.g., LinkedIn, Facebook,
 *              Instagram, TikTok, X, YouTube). MediaPlatformCode is the short
 *              code embedded in tracking tokens (e.g., LI, FB, IG).
 * Author:
 * Created: 2026-05-04
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MediaPlatforms' AND schema_id = SCHEMA_ID('AFL'))
BEGIN
CREATE TABLE [AFL].[MediaPlatforms](
	[MediaPlatformID] [int] IDENTITY(1,1) NOT NULL,
	[MediaPlatformName] [nvarchar](50) NOT NULL,
	[MediaPlatformCode] [varchar](10) NOT NULL,
	[IconUrl] [nvarchar](500) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_MediaPlatforms] PRIMARY KEY CLUSTERED
(
	[MediaPlatformID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'UQ_MediaPlatforms_MediaPlatformCode' AND type = 'UQ')
ALTER TABLE [AFL].[MediaPlatforms] ADD CONSTRAINT [UQ_MediaPlatforms_MediaPlatformCode] UNIQUE ([MediaPlatformCode])
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MediaPlatforms_IsActive' AND type = 'D')
ALTER TABLE [AFL].[MediaPlatforms] ADD  CONSTRAINT [DF_MediaPlatforms_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MediaPlatforms_IsDeleted' AND type = 'D')
ALTER TABLE [AFL].[MediaPlatforms] ADD  CONSTRAINT [DF_MediaPlatforms_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MediaPlatforms_ModifiedDate' AND type = 'D')
ALTER TABLE [AFL].[MediaPlatforms] ADD  CONSTRAINT [DF_MediaPlatforms_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MediaPlatforms_ModifiedById' AND type = 'D')
ALTER TABLE [AFL].[MediaPlatforms] ADD  CONSTRAINT [DF_MediaPlatforms_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MediaPlatforms_CreatedDate' AND type = 'D')
ALTER TABLE [AFL].[MediaPlatforms] ADD  CONSTRAINT [DF_MediaPlatforms_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MediaPlatforms_CreatedById' AND type = 'D')
ALTER TABLE [AFL].[MediaPlatforms] ADD  CONSTRAINT [DF_MediaPlatforms_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MediaPlatforms_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [AFL].[MediaPlatforms] ADD  CONSTRAINT [DF_MediaPlatforms_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO
