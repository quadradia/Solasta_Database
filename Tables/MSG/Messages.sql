/*******************************************************************************
 * Object Type: Table
 * Schema: MSG
 * Name: Messages
 * Description: Every SMS, MMS and email to or from a contact, inbound and outbound. Outbound rows are the durable send
               queue: the API inserts them Queued (ScheduledFor holds a send until the send window opens), a worker sends
               them and moves them to Sent, then the provider's status callback to Delivered, Undelivered or Failed.
               Blocked = not sent because the address had opted out. Inbound rows arrive Received. ProviderMessageId is the
               Twilio SID or the email Message-ID, unique per provider so callbacks and retries never duplicate a row.
 * Author: Andres Sosa
 * Created: 2026-11-18
 * Dependencies: ACC.DealerTenants, MSG.Conversations, MSG.MessageTemplates
 * Migrations: 20261118_2215_CreateMSG_Messaging
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MSG.Messages', N'U') IS NULL
BEGIN
    CREATE TABLE [MSG].[Messages]
    (
        [MessageID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [ConversationId] [bigint] NOT NULL,
        [MessageTemplateId] [int] NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        -- SMS (MMS when it has attachments) or Email.
        [Channel] [varchar](10) NOT NULL,
        [Direction] [varchar](10) NOT NULL,
        [Status] [varchar](12) NOT NULL,
        -- E.164 phone or email address.
        [FromAddress] [nvarchar](256) NOT NULL,
        [ToAddress] [nvarchar](256) NOT NULL,
        [Subject] [nvarchar](200) NULL,
        [Body] [nvarchar](max) NULL,
        [BodyHtml] [nvarchar](max) NULL,
        -- Twilio or Smtp.
        [Provider] [varchar](20) NULL,
        [ProviderMessageId] [varchar](255) NULL,
        [ErrorCode] [varchar](50) NULL,
        [ErrorMessage] [nvarchar](1000) NULL,
        -- SMS segments billed, from the provider.
        [Segments] [int] NULL,
        -- What started it: Staff, Automation, Bulk or Contact (inbound).
        [Origin] [varchar](12) NOT NULL,
        -- ACC.Users.UserID of the staff member who sent it.
        [SentByUserId] [uniqueidentifier] NULL,
        [ScheduledFor] [datetimeoffset](7) NULL,
        [AttemptCount] [int] NOT NULL CONSTRAINT [DF_Messages_AttemptCount] DEFAULT ((0)),
        [NextAttemptAt] [datetimeoffset](7) NULL,
        [SentDate] [datetimeoffset](7) NULL,
        [DeliveredDate] [datetimeoffset](7) NULL,
        [ReceivedDate] [datetimeoffset](7) NULL,
        -- Inbound only: when staff first opened it.
        [ReadDate] [datetimeoffset](7) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Messages_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Messages_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Messages_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Messages_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Messages_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Messages_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Messages_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Messages] PRIMARY KEY CLUSTERED ([MessageID] ASC),
        CONSTRAINT [FK_Messages_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Messages_Conversations] FOREIGN KEY ([ConversationId]) REFERENCES [MSG].[Conversations] ([ConversationID]),
        CONSTRAINT [FK_Messages_MessageTemplates] FOREIGN KEY ([MessageTemplateId]) REFERENCES [MSG].[MessageTemplates] ([MessageTemplateID]),
        CONSTRAINT [UQ_Messages_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [CK_Messages_Channel] CHECK ([Channel] IN ('SMS', 'Email')),
        CONSTRAINT [CK_Messages_Direction] CHECK ([Direction] IN ('Inbound', 'Outbound')),
        CONSTRAINT [CK_Messages_Status] CHECK ([Status] IN ('Queued', 'Sending', 'Sent', 'Delivered', 'Undelivered', 'Failed', 'Blocked', 'Canceled', 'Received')),
        CONSTRAINT [CK_Messages_DirectionStatus] CHECK (([Direction] = 'Inbound' AND [Status] = 'Received') OR ([Direction] = 'Outbound' AND [Status] <> 'Received')),
        CONSTRAINT [CK_Messages_Origin] CHECK ([Origin] IN ('Staff', 'Automation', 'Bulk', 'Contact')),
        CONSTRAINT [CK_Messages_Provider] CHECK ([Provider] IS NULL OR [Provider] IN ('Twilio', 'Smtp')),
        CONSTRAINT [CK_Messages_AttemptCount] CHECK ([AttemptCount] >= 0)
    );
    PRINT 'Created [MSG].[Messages]';
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Messages') AND [name] = N'IX_Messages_ConversationId')
    CREATE NONCLUSTERED INDEX [IX_Messages_ConversationId] ON [MSG].[Messages] ([ConversationId], [CreatedDate]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Messages') AND [name] = N'IX_Messages_Queue')
    CREATE NONCLUSTERED INDEX [IX_Messages_Queue] ON [MSG].[Messages] ([NextAttemptAt], [ScheduledFor]) INCLUDE ([DealerTenantId], [Channel]) WHERE [Status] = 'Queued';

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Messages') AND [name] = N'UX_Messages_ProviderMessageId')
    CREATE UNIQUE NONCLUSTERED INDEX [UX_Messages_ProviderMessageId] ON [MSG].[Messages] ([Provider], [ProviderMessageId]) WHERE [ProviderMessageId] IS NOT NULL;
GO
