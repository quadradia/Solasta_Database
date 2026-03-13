/*******************************************************************************
 * Object Type: Table
 * Schema: ACC
 * Name: Dealers
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Dealers' AND schema_id = SCHEMA_ID('ACC'))
BEGIN
CREATE TABLE [ACC].[Dealers](
	[DealerID] [int] IDENTITY(3000,1) NOT NULL,
	[PoliticalTimeZoneId] [int] NOT NULL,
	[DealerName] [nvarchar](50) NOT NULL,
	[DealerPrefix] [char](3) NOT NULL,
	[SquareMedLogoPath] [nvarchar](max) NOT NULL,
	[DealerRootSettingsJson] [nvarchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Dealers] PRIMARY KEY CLUSTERED 
(
	[DealerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_PoliticalTimeZoneId' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_PoliticalTimeZoneId]  DEFAULT ((4)) FOR [PoliticalTimeZoneId]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_DealerPrefix' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_DealerPrefix]  DEFAULT ('NNN') FOR [DealerPrefix]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_SquareMedLogoPath' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_SquareMedLogoPath]  DEFAULT ('N%C3%BAvol9Head.png') FOR [SquareMedLogoPath]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_DealerRootSettingsJson' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_DealerRootSettingsJson]  DEFAULT (N'{}') FOR [DealerRootSettingsJson]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_IsActive' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_IsDeleted' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_ModifiedDate' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_ModifiedById' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_CreatedDate' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_CreatedById' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Dealers_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [ACC].[Dealers] ADD  CONSTRAINT [DF_Dealers_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Dealers_PoliticalTimeZones')
ALTER TABLE [ACC].[Dealers]  WITH CHECK ADD  CONSTRAINT [FK_Dealers_PoliticalTimeZones] FOREIGN KEY([PoliticalTimeZoneId])
REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID])
GO

ALTER TABLE [ACC].[Dealers] CHECK CONSTRAINT [FK_Dealers_PoliticalTimeZones]
GO
