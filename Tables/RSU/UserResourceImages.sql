/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserResourceImages
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserResourceImages' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserResourceImages](
	[UserResourceImageID] [int] IDENTITY(1,1) NOT NULL,
	[UserResourceId] [int] NOT NULL,
	[ImageTypeId] [varchar](20) NOT NULL,
	[Size] [int] NOT NULL,
	[FileName] [nvarchar](500) NOT NULL,
	[Image] [nvarchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_UserResourceImages] PRIMARY KEY CLUSTERED 
(
	[UserResourceImageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceImages_ImageTypeId' AND type = 'D')
ALTER TABLE [RSU].[UserResourceImages] ADD  CONSTRAINT [DF_UserResourceImages_ImageTypeId]  DEFAULT ('AVATAR') FOR [ImageTypeId]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceImages_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserResourceImages] ADD  CONSTRAINT [DF_UserResourceImages_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceImages_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserResourceImages] ADD  CONSTRAINT [DF_UserResourceImages_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceImages_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserResourceImages] ADD  CONSTRAINT [DF_UserResourceImages_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceImages_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserResourceImages] ADD  CONSTRAINT [DF_UserResourceImages_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceImages_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserResourceImages] ADD  CONSTRAINT [DF_UserResourceImages_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceImages_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserResourceImages] ADD  CONSTRAINT [DF_UserResourceImages_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserResourceImages_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [RSU].[UserResourceImages] ADD  CONSTRAINT [DF_UserResourceImages_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserResourceImages_ImageTypes')
ALTER TABLE [RSU].[UserResourceImages]  WITH CHECK ADD  CONSTRAINT [FK_UserResourceImages_ImageTypes] FOREIGN KEY([ImageTypeId])
REFERENCES [MAC].[ImageTypes] ([ImageTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserResourceImages_UserResources')
ALTER TABLE [RSU].[UserResourceImages]  WITH CHECK ADD  CONSTRAINT [FK_UserResourceImages_UserResources] FOREIGN KEY([UserResourceId])
REFERENCES [RSU].[UserResources] ([UserResourceID])
GO

ALTER TABLE [RSU].[UserResourceImages] CHECK CONSTRAINT [FK_UserResourceImages_ImageTypes]
GO

ALTER TABLE [RSU].[UserResourceImages] CHECK CONSTRAINT [FK_UserResourceImages_UserResources]
GO
