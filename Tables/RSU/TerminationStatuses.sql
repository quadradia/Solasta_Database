/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: TerminationStatuses
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TerminationStatuses' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[TerminationStatuses](
	[TerminationStatusID] [int] IDENTITY(1,1) NOT NULL,
	[TerminationId] [int] NOT NULL,
	[TerminationStatusCodeId] [int] NOT NULL,
	[Comments] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_TerminationStatuses] PRIMARY KEY CLUSTERED 
(
	[TerminationStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatuses_IsActive' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatuses] ADD  CONSTRAINT [DF_TerminationStatuses_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatuses_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatuses] ADD  CONSTRAINT [DF_TerminationStatuses_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatuses_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatuses] ADD  CONSTRAINT [DF_TerminationStatuses_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatuses_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatuses] ADD  CONSTRAINT [DF_TerminationStatuses_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatuses_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatuses] ADD  CONSTRAINT [DF_TerminationStatuses_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatuses_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatuses] ADD  CONSTRAINT [DF_TerminationStatuses_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TerminationStatuses_Terminations')
ALTER TABLE [RSU].[TerminationStatuses]  WITH CHECK ADD  CONSTRAINT [FK_TerminationStatuses_Terminations] FOREIGN KEY([TerminationId])
REFERENCES [RSU].[Terminations] ([TerminationID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TerminationStatuses_TerminationStatusCodes')
ALTER TABLE [RSU].[TerminationStatuses]  WITH CHECK ADD  CONSTRAINT [FK_TerminationStatuses_TerminationStatusCodes] FOREIGN KEY([TerminationStatusCodeId])
REFERENCES [RSU].[TerminationStatusCodes] ([TerminationStatusCodeID])
GO

ALTER TABLE [RSU].[TerminationStatuses] CHECK CONSTRAINT [FK_TerminationStatuses_Terminations]
GO

ALTER TABLE [RSU].[TerminationStatuses] CHECK CONSTRAINT [FK_TerminationStatuses_TerminationStatusCodes]
GO
