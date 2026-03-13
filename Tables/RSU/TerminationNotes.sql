/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: TerminationNotes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TerminationNotes' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[TerminationNotes](
	[TerminationNoteID] [int] IDENTITY(1,1) NOT NULL,
	[TerminationId] [int] NOT NULL,
	[NoteText] [nvarchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_TerminationNotes] PRIMARY KEY CLUSTERED 
(
	[TerminationNoteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationNotes_IsActive' AND type = 'D')
ALTER TABLE [RSU].[TerminationNotes] ADD  CONSTRAINT [DF_TerminationNotes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationNotes_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[TerminationNotes] ADD  CONSTRAINT [DF_TerminationNotes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationNotes_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[TerminationNotes] ADD  CONSTRAINT [DF_TerminationNotes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationNotes_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[TerminationNotes] ADD  CONSTRAINT [DF_TerminationNotes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationNotes_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[TerminationNotes] ADD  CONSTRAINT [DF_TerminationNotes_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationNotes_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[TerminationNotes] ADD  CONSTRAINT [DF_TerminationNotes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TerminationNotes_Terminations')
ALTER TABLE [RSU].[TerminationNotes]  WITH CHECK ADD  CONSTRAINT [FK_TerminationNotes_Terminations] FOREIGN KEY([TerminationId])
REFERENCES [RSU].[Terminations] ([TerminationID])
GO

ALTER TABLE [RSU].[TerminationNotes] CHECK CONSTRAINT [FK_TerminationNotes_Terminations]
GO
