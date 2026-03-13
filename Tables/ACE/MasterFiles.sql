/*******************************************************************************
 * Object Type: Table
 * Schema: ACE
 * Name: MasterFiles
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MasterFiles' AND schema_id = SCHEMA_ID('ACE'))
BEGIN
CREATE TABLE [ACE].[MasterFiles](
	[MasterFileID] [bigint] IDENTITY(1,1) NOT NULL,
	[DealerId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_MasterFiles] PRIMARY KEY CLUSTERED 
(
	[MasterFileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasterFiles_IsActive' AND type = 'D')
ALTER TABLE [ACE].[MasterFiles] ADD  CONSTRAINT [DF_MasterFiles_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasterFiles_IsDeleted' AND type = 'D')
ALTER TABLE [ACE].[MasterFiles] ADD  CONSTRAINT [DF_MasterFiles_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasterFiles_ModifiedDate' AND type = 'D')
ALTER TABLE [ACE].[MasterFiles] ADD  CONSTRAINT [DF_MasterFiles_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasterFiles_ModifiedById' AND type = 'D')
ALTER TABLE [ACE].[MasterFiles] ADD  CONSTRAINT [DF_MasterFiles_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasterFiles_CreatedDate' AND type = 'D')
ALTER TABLE [ACE].[MasterFiles] ADD  CONSTRAINT [DF_MasterFiles_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasterFiles_CreatedById' AND type = 'D')
ALTER TABLE [ACE].[MasterFiles] ADD  CONSTRAINT [DF_MasterFiles_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasterFiles_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [ACE].[MasterFiles] ADD  CONSTRAINT [DF_MasterFiles_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasterFiles_Dealers')
ALTER TABLE [ACE].[MasterFiles]  WITH CHECK ADD  CONSTRAINT [FK_MasterFiles_Dealers] FOREIGN KEY([DealerId])
REFERENCES [ACC].[Dealers] ([DealerID])
GO

ALTER TABLE [ACE].[MasterFiles] CHECK CONSTRAINT [FK_MasterFiles_Dealers]
GO
