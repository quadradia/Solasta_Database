/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: TerminationReasons
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TerminationReasons' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[TerminationReasons](
	[TerminationReasonID] [int] IDENTITY(1,1) NOT NULL,
	[TerminationTypeId] [int] NOT NULL,
	[TerminationReasonName] [nvarchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_TerminationReasons] PRIMARY KEY CLUSTERED 
(
	[TerminationReasonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationReasons_IsActive' AND type = 'D')
ALTER TABLE [RSU].[TerminationReasons] ADD  CONSTRAINT [DF_TerminationReasons_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationReasons_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[TerminationReasons] ADD  CONSTRAINT [DF_TerminationReasons_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationReasons_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[TerminationReasons] ADD  CONSTRAINT [DF_TerminationReasons_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationReasons_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[TerminationReasons] ADD  CONSTRAINT [DF_TerminationReasons_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationReasons_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[TerminationReasons] ADD  CONSTRAINT [DF_TerminationReasons_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationReasons_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[TerminationReasons] ADD  CONSTRAINT [DF_TerminationReasons_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TerminationReasons_TerminationTypes')
ALTER TABLE [RSU].[TerminationReasons]  WITH CHECK ADD  CONSTRAINT [FK_TerminationReasons_TerminationTypes] FOREIGN KEY([TerminationTypeId])
REFERENCES [RSU].[TerminationTypes] ([TerminationTypeID])
GO

ALTER TABLE [RSU].[TerminationReasons] CHECK CONSTRAINT [FK_TerminationReasons_TerminationTypes]
GO
