/*******************************************************************************
 * Object Type: Table
 * Schema: MSG
 * Name: MessageAttachments
 * Description: Files on a message: MMS images and email attachments, stored in DOC.Documents. Inbound MMS media is
               downloaded from the provider and stored here, because provider media links need credentials and expire.
 * Author: Andres Sosa
 * Created: 2026-11-18
 * Dependencies: MSG.Messages, DOC.Documents
 * Migrations: 20261118_2215_CreateMSG_Messaging
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MSG.MessageAttachments', N'U') IS NULL
BEGIN
    CREATE TABLE [MSG].[MessageAttachments]
    (
        [MessageAttachmentID] [bigint] IDENTITY(1,1) NOT NULL,
        [MessageId] [bigint] NOT NULL,
        [DocumentId] [bigint] NOT NULL,
        [FileName] [nvarchar](255) NOT NULL,
        [ContentType] [varchar](100) NOT NULL,
        [SizeBytes] [bigint] NOT NULL,
        [SortOrder] [int] NOT NULL CONSTRAINT [DF_MessageAttachments_SortOrder] DEFAULT ((0)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_MessageAttachments_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_MessageAttachments_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MessageAttachments_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MessageAttachments_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MessageAttachments_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MessageAttachments_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MessageAttachments_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_MessageAttachments] PRIMARY KEY CLUSTERED ([MessageAttachmentID] ASC),
        CONSTRAINT [FK_MessageAttachments_Messages] FOREIGN KEY ([MessageId]) REFERENCES [MSG].[Messages] ([MessageID]),
        CONSTRAINT [FK_MessageAttachments_Documents] FOREIGN KEY ([DocumentId]) REFERENCES [DOC].[Documents] ([DocumentID]),
        CONSTRAINT [CK_MessageAttachments_SizeBytes] CHECK ([SizeBytes] >= 0)
    );
    PRINT 'Created [MSG].[MessageAttachments]';
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.MessageAttachments') AND [name] = N'IX_MessageAttachments_MessageId')
    CREATE NONCLUSTERED INDEX [IX_MessageAttachments_MessageId] ON [MSG].[MessageAttachments] ([MessageId]);
GO
