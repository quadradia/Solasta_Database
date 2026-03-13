/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: PoliticalStates
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PoliticalStates' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
CREATE TABLE [MAC].[PoliticalStates](
	[PoliticalStateID] [varchar](4) NOT NULL,
	[PoliticalCountryId] [nvarchar](10) NOT NULL,
	[PoliticalStateName] [nvarchar](100) NOT NULL,
	[StateAB] [char](2) NOT NULL,
	[GLStateCode] [nchar](3) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW] [int] IDENTITY(1,1) NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_PoliticalStates] PRIMARY KEY CLUSTERED 
(
	[PoliticalStateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalStates_IsActive' AND type = 'D')
ALTER TABLE [MAC].[PoliticalStates] ADD  CONSTRAINT [DF_PoliticalStates_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalStates_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[PoliticalStates] ADD  CONSTRAINT [DF_PoliticalStates_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalStates_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[PoliticalStates] ADD  CONSTRAINT [DF_PoliticalStates_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalStates_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[PoliticalStates] ADD  CONSTRAINT [DF_PoliticalStates_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalStates_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[PoliticalStates] ADD  CONSTRAINT [DF_PoliticalStates_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalStates_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[PoliticalStates] ADD  CONSTRAINT [DF_PoliticalStates_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_PoliticalStates_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[PoliticalStates] ADD  CONSTRAINT [DF_PoliticalStates_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PoliticalStates_PoliticalCountries')
ALTER TABLE [MAC].[PoliticalStates]  WITH CHECK ADD  CONSTRAINT [FK_PoliticalStates_PoliticalCountries] FOREIGN KEY([PoliticalCountryId])
REFERENCES [MAC].[PoliticalCountries] ([PoliticalCountryID])
GO

ALTER TABLE [MAC].[PoliticalStates] CHECK CONSTRAINT [FK_PoliticalStates_PoliticalCountries]
GO
