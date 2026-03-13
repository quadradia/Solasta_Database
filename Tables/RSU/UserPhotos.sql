/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserPhotos
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserPhotos' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserPhotos](
	[UserPhotoID] [int] IDENTITY(1,1) NOT NULL,
	[UserResourceId] [int] NOT NULL,
	[PhotoImage] [nvarchar](max) NOT NULL,
	[FileSize] [bigint] NOT NULL,
	[MimeType] [nvarchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_UserPhotos] PRIMARY KEY CLUSTERED 
(
	[UserPhotoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserPhotos_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserPhotos] ADD  CONSTRAINT [DF_UserPhotos_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserPhotos_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserPhotos] ADD  CONSTRAINT [DF_UserPhotos_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserPhotos_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserPhotos] ADD  CONSTRAINT [DF_UserPhotos_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserPhotos_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserPhotos] ADD  CONSTRAINT [DF_UserPhotos_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserPhotos_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserPhotos] ADD  CONSTRAINT [DF_UserPhotos_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserPhotos_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserPhotos] ADD  CONSTRAINT [DF_UserPhotos_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserPhotos_UserResources')
ALTER TABLE [RSU].[UserPhotos]  WITH CHECK ADD  CONSTRAINT [FK_UserPhotos_UserResources] FOREIGN KEY([UserResourceId])
REFERENCES [RSU].[UserResources] ([UserResourceID])
GO

ALTER TABLE [RSU].[UserPhotos] CHECK CONSTRAINT [FK_UserPhotos_UserResources]
GO
