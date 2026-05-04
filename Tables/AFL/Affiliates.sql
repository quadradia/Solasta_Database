/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: Affiliates
 * Description: Registered affiliates who promote dealer products and earn
 *              commission on leads they generate. Each affiliate is tied to a
 *              Dealer and receives a unique AffiliateCode used in tracking tokens.
 *              AffiliateCode is set by the application on creation (e.g., "JSMITH").
 * Author:
 * Created: 2026-05-04
 * Dependencies: ACC.Dealers
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Affiliates' AND schema_id = SCHEMA_ID('AFL'))
BEGIN
CREATE TABLE [AFL].[Affiliates](
	[AffiliateID] [bigint] IDENTITY(1,1) NOT NULL,
	[DealerId] [int] NOT NULL,
	[AffiliateCode] [varchar](20) NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[Email] [nvarchar](256) NOT NULL,
	[PhoneMobile] [nvarchar](20) NULL,
	[CommissionRate] [decimal](5,4) NULL,
	[Notes] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Affiliates] PRIMARY KEY CLUSTERED
(
	[AffiliateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'UQ_Affiliates_AffiliateCode' AND type = 'UQ')
ALTER TABLE [AFL].[Affiliates] ADD CONSTRAINT [UQ_Affiliates_AffiliateCode] UNIQUE ([AffiliateCode])
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Affiliates_IsActive' AND type = 'D')
ALTER TABLE [AFL].[Affiliates] ADD  CONSTRAINT [DF_Affiliates_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Affiliates_IsDeleted' AND type = 'D')
ALTER TABLE [AFL].[Affiliates] ADD  CONSTRAINT [DF_Affiliates_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Affiliates_ModifiedDate' AND type = 'D')
ALTER TABLE [AFL].[Affiliates] ADD  CONSTRAINT [DF_Affiliates_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Affiliates_ModifiedById' AND type = 'D')
ALTER TABLE [AFL].[Affiliates] ADD  CONSTRAINT [DF_Affiliates_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Affiliates_CreatedDate' AND type = 'D')
ALTER TABLE [AFL].[Affiliates] ADD  CONSTRAINT [DF_Affiliates_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Affiliates_CreatedById' AND type = 'D')
ALTER TABLE [AFL].[Affiliates] ADD  CONSTRAINT [DF_Affiliates_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Affiliates_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [AFL].[Affiliates] ADD  CONSTRAINT [DF_Affiliates_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Affiliates_Dealers')
ALTER TABLE [AFL].[Affiliates]  WITH CHECK ADD  CONSTRAINT [FK_Affiliates_Dealers] FOREIGN KEY([DealerId])
REFERENCES [ACC].[Dealers] ([DealerID])
GO

ALTER TABLE [AFL].[Affiliates] CHECK CONSTRAINT [FK_Affiliates_Dealers]
GO
