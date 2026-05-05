/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: Seasons
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'Seasons' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
	CREATE TABLE [RSU].[Seasons]
	(
		[SeasonID] [int] IDENTITY(1,1) NOT NULL,
		[PreSeasonID] [int] NULL,
		[DealerTenantId] [int] NOT NULL,
		[SeasonName] [nvarchar](50) NOT NULL,
		[StartDate] [datetimeoffset](7) NULL,
		[EndDate] [datetimeoffset](7) NULL,
		[ShowInHiringManager] [bit] NOT NULL,
		[IsCurrent] [bit] NOT NULL,
		[IsVisibleToRecruits] [bit] NOT NULL,
		[IsInsideSales] [bit] NOT NULL,
		[IsPreseason] [bit] NOT NULL,
		[IsSummer] [bit] NOT NULL,
		[IsExtended] [bit] NOT NULL,
		[IsYearRound] [bit] NOT NULL,
		[IsContractor] [bit] NOT NULL,
		[IsDealer] [bit] NOT NULL,
		[IsCurbNSign] [bit] NOT NULL,
		[ExcellentCreditScoreThreshold] [int] NOT NULL,
		[PassCreditScoreThreshold] [int] NOT NULL,
		[SubCreditScoreThreshold] [int] NOT NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [uniqueidentifier] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[CreatedById] [uniqueidentifier] NOT NULL,
		[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
		CONSTRAINT [PK_Season] PRIMARY KEY CLUSTERED
(
	[SeasonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Seasons_IsCurbNSign' AND type = 'D')
ALTER TABLE [RSU].[Seasons] ADD  CONSTRAINT [DF_Seasons_IsCurbNSign]  DEFAULT ((0)) FOR [IsCurbNSign]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Season_IsActive' AND type = 'D')
ALTER TABLE [RSU].[Seasons] ADD  CONSTRAINT [DF_Season_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Season_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[Seasons] ADD  CONSTRAINT [DF_Season_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Season_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[Seasons] ADD  CONSTRAINT [DF_Season_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Season_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[Seasons] ADD  CONSTRAINT [DF_Season_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Season_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[Seasons] ADD  CONSTRAINT [DF_Season_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Season_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[Seasons] ADD  CONSTRAINT [DF_Season_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Seasons_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [RSU].[Seasons] ADD  CONSTRAINT [DF_Seasons_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Season_DealerTenants')
ALTER TABLE [RSU].[Seasons]  WITH CHECK ADD  CONSTRAINT [FK_Season_DealerTenants] FOREIGN KEY([DealerTenantId])
REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
GO

ALTER TABLE [RSU].[Seasons] CHECK CONSTRAINT [FK_Season_DealerTenants]
GO
