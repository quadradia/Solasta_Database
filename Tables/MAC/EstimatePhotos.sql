/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: EstimatePhotos
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'EstimatePhotos' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
	CREATE TABLE [MAC].[EstimatePhotos]
	(
		[EstimatePhotoID] [bigint] IDENTITY(1,1) NOT NULL,
		[Proxy] [nvarchar](100) NOT NULL,
		[PartKey] [varchar](6) NOT NULL,
		[EstimatePhotoTypeId] [int] NOT NULL,
		[EstimateId] [bigint] NOT NULL,
		[PhotoURL] [nvarchar](500) NOT NULL,
		[Caption] [nvarchar](255) NULL,
		[UploadDate] [datetime] NOT NULL,
		[FileSize] [int] NULL,
		[MimeType] [nvarchar](100) NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [bigint] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[CreatedById] [bigint] NOT NULL,
		[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
		CONSTRAINT [PK_EstimatePhotos] PRIMARY KEY CLUSTERED
(
	[EstimatePhotoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotos_IsActive' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotos] ADD  CONSTRAINT [DF_EstimatePhotos_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotos_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotos] ADD  CONSTRAINT [DF_EstimatePhotos_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotos_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotos] ADD  CONSTRAINT [DF_EstimatePhotos_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotos_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotos] ADD  CONSTRAINT [DF_EstimatePhotos_ModifiedById]  DEFAULT ((0)) FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotos_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotos] ADD  CONSTRAINT [DF_EstimatePhotos_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotos_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotos] ADD  CONSTRAINT [DF_EstimatePhotos_CreatedById]  DEFAULT ((0)) FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_EstimatePhotos_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[EstimatePhotos] ADD  CONSTRAINT [DF_EstimatePhotos_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_EstimatePhotos_EstimatePhotoTypes')
ALTER TABLE [MAC].[EstimatePhotos]  WITH CHECK ADD  CONSTRAINT [FK_EstimatePhotos_EstimatePhotoTypes] FOREIGN KEY([EstimatePhotoTypeId])
REFERENCES [MAC].[EstimatePhotoTypes] ([EstimatePhotoTypeID])
GO

ALTER TABLE [MAC].[EstimatePhotos] CHECK CONSTRAINT [FK_EstimatePhotos_EstimatePhotoTypes]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_EstimatePhotos_Estimates')
ALTER TABLE [MAC].[EstimatePhotos]  WITH CHECK ADD  CONSTRAINT [FK_EstimatePhotos_Estimates] FOREIGN KEY([EstimateId])
REFERENCES [MAC].[Estimates] ([EstimateID])
GO

ALTER TABLE [MAC].[EstimatePhotos] CHECK CONSTRAINT [FK_EstimatePhotos_Estimates]
GO
