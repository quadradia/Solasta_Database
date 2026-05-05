/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: Quotes
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'Quotes' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
	CREATE TABLE [MAC].[Quotes]
	(
		[Id] [bigint] IDENTITY(1,1) NOT NULL,
		[Proxy] [nvarchar](100) NOT NULL,
		[PartKey] [varchar](6) NOT NULL,
		[TypeId] [int] NOT NULL,
		[EstimateId] [bigint] NOT NULL,
		[QuoteNumber] [nvarchar](50) NOT NULL,
		[QuoteDate] [date] NOT NULL,
		[ValidUntil] [date] NULL,
		[TotalAmount] [decimal](18, 2) NULL,
		[Status] [nvarchar](50) NULL,
		[Terms] [nvarchar](max) NULL,
		[Notes] [nvarchar](max) NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [bigint] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[CreatedById] [bigint] NOT NULL,
		[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
		PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Quotes_IsActive' AND type = 'D')
ALTER TABLE [MAC].[Quotes] ADD  CONSTRAINT [DF_Quotes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Quotes_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[Quotes] ADD  CONSTRAINT [DF_Quotes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Quotes_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[Quotes] ADD  CONSTRAINT [DF_Quotes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Quotes_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[Quotes] ADD  CONSTRAINT [DF_Quotes_ModifiedById]  DEFAULT ((0)) FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Quotes_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[Quotes] ADD  CONSTRAINT [DF_Quotes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Quotes_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[Quotes] ADD  CONSTRAINT [DF_Quotes_CreatedById]  DEFAULT ((0)) FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_Quotes_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[Quotes] ADD  CONSTRAINT [DF_Quotes_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO
