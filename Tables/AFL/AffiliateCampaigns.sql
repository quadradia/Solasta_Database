/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: AffiliateCampaigns
 * Description: A named marketing campaign owned by an affiliate for a specific
 *              dealer. A campaign groups one or more placements across different
 *              media platforms (e.g., "Summer 2026 Solar Promo"). Date range is
 *              optional and used for reporting and expiration enforcement.
 * Author:
 * Created: 2026-05-04
 * Dependencies: AFL.Affiliates, ACC.Dealers
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AffiliateCampaigns' AND schema_id = SCHEMA_ID('AFL'))
BEGIN
CREATE TABLE [AFL].[AffiliateCampaigns](
	[AffiliateCampaignID] [int] IDENTITY(1,1) NOT NULL,
	[AffiliateId] [bigint] NOT NULL,
	[DealerId] [int] NOT NULL,
	[CampaignName] [nvarchar](100) NOT NULL,
	[CampaignDescription] [nvarchar](500) NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_AffiliateCampaigns] PRIMARY KEY CLUSTERED
(
	[AffiliateCampaignID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AffiliateCampaigns_IsActive' AND type = 'D')
ALTER TABLE [AFL].[AffiliateCampaigns] ADD  CONSTRAINT [DF_AffiliateCampaigns_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AffiliateCampaigns_IsDeleted' AND type = 'D')
ALTER TABLE [AFL].[AffiliateCampaigns] ADD  CONSTRAINT [DF_AffiliateCampaigns_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AffiliateCampaigns_ModifiedDate' AND type = 'D')
ALTER TABLE [AFL].[AffiliateCampaigns] ADD  CONSTRAINT [DF_AffiliateCampaigns_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AffiliateCampaigns_ModifiedById' AND type = 'D')
ALTER TABLE [AFL].[AffiliateCampaigns] ADD  CONSTRAINT [DF_AffiliateCampaigns_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AffiliateCampaigns_CreatedDate' AND type = 'D')
ALTER TABLE [AFL].[AffiliateCampaigns] ADD  CONSTRAINT [DF_AffiliateCampaigns_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AffiliateCampaigns_CreatedById' AND type = 'D')
ALTER TABLE [AFL].[AffiliateCampaigns] ADD  CONSTRAINT [DF_AffiliateCampaigns_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AffiliateCampaigns_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [AFL].[AffiliateCampaigns] ADD  CONSTRAINT [DF_AffiliateCampaigns_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AffiliateCampaigns_Affiliates')
ALTER TABLE [AFL].[AffiliateCampaigns]  WITH CHECK ADD  CONSTRAINT [FK_AffiliateCampaigns_Affiliates] FOREIGN KEY([AffiliateId])
REFERENCES [AFL].[Affiliates] ([AffiliateID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AffiliateCampaigns_Dealers')
ALTER TABLE [AFL].[AffiliateCampaigns]  WITH CHECK ADD  CONSTRAINT [FK_AffiliateCampaigns_Dealers] FOREIGN KEY([DealerId])
REFERENCES [ACC].[Dealers] ([DealerID])
GO

ALTER TABLE [AFL].[AffiliateCampaigns] CHECK CONSTRAINT [FK_AffiliateCampaigns_Affiliates]
GO

ALTER TABLE [AFL].[AffiliateCampaigns] CHECK CONSTRAINT [FK_AffiliateCampaigns_Dealers]
GO
