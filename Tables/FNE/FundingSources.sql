/*******************************************************************************
 * Object Type: Table
 * Schema: FNE
 * Name: FundingSources
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FundingSources' AND schema_id = SCHEMA_ID('FNE'))
BEGIN
CREATE TABLE [FNE].[FundingSources](
	[FundingSourceID] [int] IDENTITY(1001,1) NOT NULL,
	[DealerId] [int] NOT NULL,
	[FundingSourceTypeId] [varchar](20) NOT NULL,
	[FundingSourceName] [varchar](50) NOT NULL,
	[CriteriaMemo] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_FundingSources] PRIMARY KEY CLUSTERED 
(
	[FundingSourceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_FundingSources_DealerId' AND type = 'D')
ALTER TABLE [FNE].[FundingSources] ADD  CONSTRAINT [DF_FundingSources_DealerId]  DEFAULT ((0)) FOR [DealerId]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_FundingSources_FundingSourceTypeId' AND type = 'D')
ALTER TABLE [FNE].[FundingSources] ADD  CONSTRAINT [DF_FundingSources_FundingSourceTypeId]  DEFAULT ('BUY') FOR [FundingSourceTypeId]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_FundingSources_IsActive' AND type = 'D')
ALTER TABLE [FNE].[FundingSources] ADD  CONSTRAINT [DF_FundingSources_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_FundingSources_IsDeleted' AND type = 'D')
ALTER TABLE [FNE].[FundingSources] ADD  CONSTRAINT [DF_FundingSources_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_FundingSources_ModifiedDate' AND type = 'D')
ALTER TABLE [FNE].[FundingSources] ADD  CONSTRAINT [DF_FundingSources_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_FundingSources_ModifiedById' AND type = 'D')
ALTER TABLE [FNE].[FundingSources] ADD  CONSTRAINT [DF_FundingSources_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_FundingSources_CreatedDate' AND type = 'D')
ALTER TABLE [FNE].[FundingSources] ADD  CONSTRAINT [DF_FundingSources_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_FundingSources_CreatedById' AND type = 'D')
ALTER TABLE [FNE].[FundingSources] ADD  CONSTRAINT [DF_FundingSources_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_FundingSources_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [FNE].[FundingSources] ADD  CONSTRAINT [DF_FundingSources_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FundingSources_Dealers')
ALTER TABLE [FNE].[FundingSources]  WITH CHECK ADD  CONSTRAINT [FK_FundingSources_Dealers] FOREIGN KEY([DealerId])
REFERENCES [ACC].[Dealers] ([DealerID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FundingSources_Dealers1')
ALTER TABLE [FNE].[FundingSources]  WITH CHECK ADD  CONSTRAINT [FK_FundingSources_Dealers1] FOREIGN KEY([DealerId])
REFERENCES [ACC].[Dealers] ([DealerID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FundingSources_FundingSourceTypes')
ALTER TABLE [FNE].[FundingSources]  WITH CHECK ADD  CONSTRAINT [FK_FundingSources_FundingSourceTypes] FOREIGN KEY([FundingSourceTypeId])
REFERENCES [FNE].[FundingSourceTypes] ([FundingSourceTypeID])
GO

ALTER TABLE [FNE].[FundingSources] CHECK CONSTRAINT [FK_FundingSources_Dealers]
GO

ALTER TABLE [FNE].[FundingSources] CHECK CONSTRAINT [FK_FundingSources_Dealers1]
GO

ALTER TABLE [FNE].[FundingSources] CHECK CONSTRAINT [FK_FundingSources_FundingSourceTypes]
GO
