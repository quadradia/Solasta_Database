/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: AffiliateTypes
 * Description: Lookup table for affiliate classification types. Each type
 *              carries a 4-character Prefix that is used to generate globally
 *              unique Proxy-ID identifiers on AFL.Affiliates rows.
 *              Registered prefixes: AFST (Standard), AFIN (Influencer), AFPR (Partner).
 * Author: Andres Sosa
 * Created: 2026-05-05
 * Dependencies: (none)
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'AffiliateTypes' AND schema_id = SCHEMA_ID('AFL'))
BEGIN
    CREATE TABLE [AFL].[AffiliateTypes]
    (
        [AffiliateTypeID] [int] IDENTITY(1,1) NOT NULL,
        [Prefix] [varchar](4) NOT NULL,
        [AffiliateTypeName] [nvarchar](100) NOT NULL,
        [AffiliateTypeDescription] [nvarchar](max) NULL,
        [IsActive] [bit] NOT NULL,
        [IsDeleted] [bit] NOT NULL,
        [ModifiedDate] [datetimeoffset](7) NOT NULL,
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL,
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
        CONSTRAINT [PK_AffiliateTypes] PRIMARY KEY CLUSTERED
(
	[AffiliateTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON),
        CONSTRAINT [UQ_AffiliateTypes_Prefix] UNIQUE NONCLUSTERED
(
	[Prefix] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    )

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_AffiliateTypes_IsActive' AND type = 'D')
ALTER TABLE [AFL].[AffiliateTypes] ADD  CONSTRAINT [DF_AffiliateTypes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_AffiliateTypes_IsDeleted' AND type = 'D')
ALTER TABLE [AFL].[AffiliateTypes] ADD  CONSTRAINT [DF_AffiliateTypes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_AffiliateTypes_ModifiedDate' AND type = 'D')
ALTER TABLE [AFL].[AffiliateTypes] ADD  CONSTRAINT [DF_AffiliateTypes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_AffiliateTypes_ModifiedById' AND type = 'D')
ALTER TABLE [AFL].[AffiliateTypes] ADD  CONSTRAINT [DF_AffiliateTypes_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_AffiliateTypes_CreatedDate' AND type = 'D')
ALTER TABLE [AFL].[AffiliateTypes] ADD  CONSTRAINT [DF_AffiliateTypes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_AffiliateTypes_CreatedById' AND type = 'D')
ALTER TABLE [AFL].[AffiliateTypes] ADD  CONSTRAINT [DF_AffiliateTypes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_AffiliateTypes_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [AFL].[AffiliateTypes] ADD  CONSTRAINT [DF_AffiliateTypes_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO
