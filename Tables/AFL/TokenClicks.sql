/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: TokenClicks
 * Description: Records every click event on a tracked affiliate ad URL. Each
 *              row is an immutable inbound click captured by the web layer when
 *              the tracking token is resolved. IsConverted is flipped to 1 and
 *              ConvertedDate is set when a LeadAttribution row is created for
 *              this click.
 *              SessionId links a click to a subsequent form submission so the
 *              application can attribute the lead back to the correct click.
 * Author:
 * Created: 2026-05-04
 * Dependencies: AFL.CampaignPlacements
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TokenClicks' AND schema_id = SCHEMA_ID('AFL'))
BEGIN
CREATE TABLE [AFL].[TokenClicks](
	[TokenClickID] [bigint] IDENTITY(1,1) NOT NULL,
	[CampaignPlacementId] [int] NOT NULL,
	[ClickDate] [datetimeoffset](7) NOT NULL,
	[IPAddress] [varchar](45) NULL,
	[UserAgent] [nvarchar](500) NULL,
	[SessionId] [varchar](100) NULL,
	[ReferrerUrl] [nvarchar](2000) NULL,
	[IsConverted] [bit] NOT NULL,
	[ConvertedDate] [datetimeoffset](7) NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_TokenClicks] PRIMARY KEY CLUSTERED
(
	[TokenClickID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TokenClicks_ClickDate' AND type = 'D')
ALTER TABLE [AFL].[TokenClicks] ADD  CONSTRAINT [DF_TokenClicks_ClickDate]  DEFAULT (sysdatetimeoffset()) FOR [ClickDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TokenClicks_IsConverted' AND type = 'D')
ALTER TABLE [AFL].[TokenClicks] ADD  CONSTRAINT [DF_TokenClicks_IsConverted]  DEFAULT ((0)) FOR [IsConverted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TokenClicks_ModifiedDate' AND type = 'D')
ALTER TABLE [AFL].[TokenClicks] ADD  CONSTRAINT [DF_TokenClicks_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TokenClicks_ModifiedById' AND type = 'D')
ALTER TABLE [AFL].[TokenClicks] ADD  CONSTRAINT [DF_TokenClicks_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TokenClicks_CreatedDate' AND type = 'D')
ALTER TABLE [AFL].[TokenClicks] ADD  CONSTRAINT [DF_TokenClicks_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TokenClicks_CreatedById' AND type = 'D')
ALTER TABLE [AFL].[TokenClicks] ADD  CONSTRAINT [DF_TokenClicks_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TokenClicks_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [AFL].[TokenClicks] ADD  CONSTRAINT [DF_TokenClicks_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TokenClicks_CampaignPlacements')
ALTER TABLE [AFL].[TokenClicks]  WITH CHECK ADD  CONSTRAINT [FK_TokenClicks_CampaignPlacements] FOREIGN KEY([CampaignPlacementId])
REFERENCES [AFL].[CampaignPlacements] ([CampaignPlacementID])
GO

ALTER TABLE [AFL].[TokenClicks] CHECK CONSTRAINT [FK_TokenClicks_CampaignPlacements]
GO
