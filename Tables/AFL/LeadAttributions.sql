/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: LeadAttributions
 * Description: Bridge table linking a QAL.Lead back to the affiliate placement
 *              and click event that drove the conversion. This is the record of
 *              credit — it answers "which affiliate, which campaign, and which
 *              platform gets credit for this lead?"
 *              A unique constraint on LeadId enforces one attribution per lead.
 *              TokenClickId is nullable to handle cases where click tracking
 *              was unavailable but the placement token was still captured from
 *              the form submission.
 * Author:
 * Created: 2026-05-04
 * Dependencies: QAL.Leads, AFL.CampaignPlacements, AFL.TokenClicks
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LeadAttributions' AND schema_id = SCHEMA_ID('AFL'))
BEGIN
CREATE TABLE [AFL].[LeadAttributions](
	[LeadAttributionID] [bigint] IDENTITY(1,1) NOT NULL,
	[LeadId] [bigint] NOT NULL,
	[CampaignPlacementId] [int] NOT NULL,
	[TokenClickId] [bigint] NULL,
	[AttributedDate] [datetimeoffset](7) NOT NULL,
	[Notes] [nvarchar](500) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_LeadAttributions] PRIMARY KEY CLUSTERED
(
	[LeadAttributionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'UQ_LeadAttributions_LeadId' AND type = 'UQ')
ALTER TABLE [AFL].[LeadAttributions] ADD CONSTRAINT [UQ_LeadAttributions_LeadId] UNIQUE ([LeadId])
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAttributions_AttributedDate' AND type = 'D')
ALTER TABLE [AFL].[LeadAttributions] ADD  CONSTRAINT [DF_LeadAttributions_AttributedDate]  DEFAULT (sysdatetimeoffset()) FOR [AttributedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAttributions_IsActive' AND type = 'D')
ALTER TABLE [AFL].[LeadAttributions] ADD  CONSTRAINT [DF_LeadAttributions_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAttributions_IsDeleted' AND type = 'D')
ALTER TABLE [AFL].[LeadAttributions] ADD  CONSTRAINT [DF_LeadAttributions_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAttributions_ModifiedDate' AND type = 'D')
ALTER TABLE [AFL].[LeadAttributions] ADD  CONSTRAINT [DF_LeadAttributions_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAttributions_ModifiedById' AND type = 'D')
ALTER TABLE [AFL].[LeadAttributions] ADD  CONSTRAINT [DF_LeadAttributions_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAttributions_CreatedDate' AND type = 'D')
ALTER TABLE [AFL].[LeadAttributions] ADD  CONSTRAINT [DF_LeadAttributions_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAttributions_CreatedById' AND type = 'D')
ALTER TABLE [AFL].[LeadAttributions] ADD  CONSTRAINT [DF_LeadAttributions_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_LeadAttributions_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [AFL].[LeadAttributions] ADD  CONSTRAINT [DF_LeadAttributions_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_LeadAttributions_Leads')
ALTER TABLE [AFL].[LeadAttributions]  WITH CHECK ADD  CONSTRAINT [FK_LeadAttributions_Leads] FOREIGN KEY([LeadId])
REFERENCES [QAL].[Leads] ([LeadID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_LeadAttributions_CampaignPlacements')
ALTER TABLE [AFL].[LeadAttributions]  WITH CHECK ADD  CONSTRAINT [FK_LeadAttributions_CampaignPlacements] FOREIGN KEY([CampaignPlacementId])
REFERENCES [AFL].[CampaignPlacements] ([CampaignPlacementID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_LeadAttributions_TokenClicks')
ALTER TABLE [AFL].[LeadAttributions]  WITH CHECK ADD  CONSTRAINT [FK_LeadAttributions_TokenClicks] FOREIGN KEY([TokenClickId])
REFERENCES [AFL].[TokenClicks] ([TokenClickID])
GO

ALTER TABLE [AFL].[LeadAttributions] CHECK CONSTRAINT [FK_LeadAttributions_Leads]
GO

ALTER TABLE [AFL].[LeadAttributions] CHECK CONSTRAINT [FK_LeadAttributions_CampaignPlacements]
GO

ALTER TABLE [AFL].[LeadAttributions] CHECK CONSTRAINT [FK_LeadAttributions_TokenClicks]
GO
