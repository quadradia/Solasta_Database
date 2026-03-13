/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: UserAuthentication
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserAuthentication' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[UserAuthentication](
	[UserAuthenticationID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserResourceId] [int] NULL,
	[TokenId] [uniqueidentifier] NOT NULL,
	[Username] [nvarchar](50) NOT NULL,
	[Password] [nvarchar](50) NOT NULL,
	[IPAddress] [varchar](16) NOT NULL,
	[Successfull] [bit] NOT NULL,
	[Message] [varchar](150) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_UserAuthentication] PRIMARY KEY CLUSTERED 
(
	[UserAuthenticationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserAuthentication_IsActive' AND type = 'D')
ALTER TABLE [RSU].[UserAuthentication] ADD  CONSTRAINT [DF_UserAuthentication_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserAuthentication_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[UserAuthentication] ADD  CONSTRAINT [DF_UserAuthentication_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserAuthentication_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[UserAuthentication] ADD  CONSTRAINT [DF_UserAuthentication_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserAuthentication_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[UserAuthentication] ADD  CONSTRAINT [DF_UserAuthentication_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserAuthentication_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[UserAuthentication] ADD  CONSTRAINT [DF_UserAuthentication_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_UserAuthentication_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[UserAuthentication] ADD  CONSTRAINT [DF_UserAuthentication_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserAuthentication_UserResources')
ALTER TABLE [RSU].[UserAuthentication]  WITH CHECK ADD  CONSTRAINT [FK_UserAuthentication_UserResources] FOREIGN KEY([UserResourceId])
REFERENCES [RSU].[UserResources] ([UserResourceID])
GO

ALTER TABLE [RSU].[UserAuthentication] CHECK CONSTRAINT [FK_UserAuthentication_UserResources]
GO
