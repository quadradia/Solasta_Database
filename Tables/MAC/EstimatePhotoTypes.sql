/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: EstimatePhotoTypes
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'EstimatePhotoTypes' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
	CREATE TABLE [MAC].[EstimatePhotoTypes]
	(
		[EstimatePhotoTypeID] [int] IDENTITY(1,1) NOT NULL,
		[Prefix] [varchar](4) NOT NULL,
		[Name] [nvarchar](100) NOT NULL,
		[Description] [nvarchar](max) NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [int] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[CreatedById] [int] NOT NULL,
		[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
		CONSTRAINT [PK_EstimatePhotoTypes] PRIMARY KEY CLUSTERED
(
	[EstimatePhotoTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotoTypes_IsActive' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotoTypes] ADD  CONSTRAINT [DF_EstimatePhotoTypes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotoTypes_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotoTypes] ADD  CONSTRAINT [DF_EstimatePhotoTypes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotoTypes_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotoTypes] ADD  CONSTRAINT [DF_EstimatePhotoTypes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotoTypes_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotoTypes] ADD  CONSTRAINT [DF_EstimatePhotoTypes_ModifiedById]  DEFAULT ((0)) FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotoTypes_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotoTypes] ADD  CONSTRAINT [DF_EstimatePhotoTypes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotoTypes_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotoTypes] ADD  CONSTRAINT [DF_EstimatePhotoTypes_CreatedById]  DEFAULT ((0)) FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotoTypes_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotoTypes] ADD  CONSTRAINT [DF_EstimatePhotoTypes_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'UQ_EstimatePhotoTypes_Prefix' AND type = 'UQ')
ALTER TABLE [MAC].[EstimatePhotoTypes] ADD CONSTRAINT [UQ_EstimatePhotoTypes_Prefix] UNIQUE ([Prefix])
GO
