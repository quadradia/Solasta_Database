/*
Migration: 20261118_2215_CreateMSG_Messaging
Author: Andres Sosa
Date: 2026-11-18
Description: Lead-to-quote phase 7c, messaging in Solasta so GoHighLevel can be retired. New schema MSG:
               MSG.MessageTemplates  reusable SMS and email texts per code, channel and language (en, es)
               MSG.Conversations     one thread per contact (lead, customer, or unknown sender), SMS and
                                     email together, with the inbox summary and a reply key for email
               MSG.Messages          every SMS, MMS and email in or out; Queued outbound rows are the
                                     durable send queue, ScheduledFor holds them for the send window
               MSG.MessageAttachments MMS images and email attachments in DOC.Documents
               MSG.ContactConsents   opt-in / opt-out per tenant, channel and address (E.164 or email);
                                     nothing is sent to an opted-out address
             Proxy prefixes: MGCV (conversation), MGMS (message).
Dependencies:
  20261024_1637_CreateDOCDocuments
  20261117_0340_AddQAL_LeadIntake
  20261117_2330_AddMAC_QuoteSigning (ACE.Customers usable)
Rollback:
  DROP TABLE [MSG].[MessageAttachments];
  DROP TABLE [MSG].[Messages];
  DROP TABLE [MSG].[Conversations];
  DROP TABLE [MSG].[MessageTemplates];
  DROP TABLE [MSG].[ContactConsents];
  DROP SCHEMA [MSG];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261118_2215_CreateMSG_Messaging';
Expected impact: one new schema and five new, empty tables. No existing object or data changes.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261118_2215_CreateMSG_Messaging';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'QAL.Leads', N'U') IS NULL OR OBJECT_ID(N'ACE.Customers', N'U') IS NULL
       OR OBJECT_ID(N'DOC.Documents', N'U') IS NULL
        THROW 50001, 'Messaging requires QAL.Leads, ACE.Customers and DOC.Documents.', 1;

    IF SCHEMA_ID(N'MSG') IS NULL
        EXEC (N'CREATE SCHEMA [MSG] AUTHORIZATION [dbo]');

    ---------------------------------------------------------------------------
    -- MSG.MessageTemplates
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MSG.MessageTemplates', N'U') IS NULL
    BEGIN
        CREATE TABLE [MSG].[MessageTemplates]
        (
            [MessageTemplateID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [MediaDocumentId] [bigint] NULL,
            -- Stable name the API looks templates up by, e.g. LEAD_WELCOME, QUOTE_REMINDER.
            [Code] [varchar](50) NOT NULL,
            -- SMS (MMS when MediaDocumentId is set) or Email.
            [Channel] [varchar](10) NOT NULL,
            -- ISO 639-1: en or es.
            [LanguageCode] [varchar](5) NOT NULL CONSTRAINT [DF_MessageTemplates_LanguageCode] DEFAULT ('en'),
            [Name] [nvarchar](100) NOT NULL,
            -- Email only.
            [Subject] [nvarchar](200) NULL,
            -- SMS text, or the plain-text part of an email.
            [Body] [nvarchar](max) NOT NULL,
            -- Email only.
            [BodyHtml] [nvarchar](max) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_MessageTemplates_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_MessageTemplates_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MessageTemplates_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MessageTemplates_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MessageTemplates_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MessageTemplates_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MessageTemplates_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_MessageTemplates] PRIMARY KEY CLUSTERED ([MessageTemplateID] ASC),
            CONSTRAINT [FK_MessageTemplates_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_MessageTemplates_Documents] FOREIGN KEY ([MediaDocumentId]) REFERENCES [DOC].[Documents] ([DocumentID]),
            CONSTRAINT [UQ_MessageTemplates_Code] UNIQUE ([DealerTenantId], [Code], [Channel], [LanguageCode]),
            CONSTRAINT [CK_MessageTemplates_Channel] CHECK ([Channel] IN ('SMS', 'Email')),
            CONSTRAINT [CK_MessageTemplates_Subject] CHECK ([Channel] <> 'Email' OR [Subject] IS NOT NULL)
        );
        PRINT 'Created [MSG].[MessageTemplates]';
    END;

    ---------------------------------------------------------------------------
    -- MSG.Conversations
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MSG.Conversations', N'U') IS NULL
    BEGIN
        CREATE TABLE [MSG].[Conversations]
        (
            [ConversationID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [LeadId] [bigint] NULL,
            [CustomerId] [bigint] NULL,
            [Proxy] [varchar](100) NOT NULL,
            [PartKey] [varchar](6) NOT NULL,
            -- Lowercase base32, random; never derived from ids.
            [ReplyKey] [varchar](16) NOT NULL,
            [DisplayName] [nvarchar](150) NULL,
            [Phone] [varchar](20) NULL,
            [Email] [nvarchar](256) NULL,
            -- en or es: which template language automations use.
            [LanguageCode] [varchar](5) NOT NULL CONSTRAINT [DF_Conversations_LanguageCode] DEFAULT ('en'),
            -- Open or Closed (closed threads reopen on the next inbound message).
            [Status] [varchar](10) NOT NULL CONSTRAINT [DF_Conversations_Status] DEFAULT ('Open'),
            -- ACC.Users.UserID of the staff member handling it, if any.
            [AssignedToUserId] [uniqueidentifier] NULL,
            [LastMessageDate] [datetimeoffset](7) NULL,
            [LastMessageDirection] [varchar](10) NULL,
            [LastMessageChannel] [varchar](10) NULL,
            [LastMessagePreview] [nvarchar](200) NULL,
            [UnreadCount] [int] NOT NULL CONSTRAINT [DF_Conversations_UnreadCount] DEFAULT ((0)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Conversations_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Conversations_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Conversations_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Conversations_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Conversations_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Conversations_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Conversations_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Conversations] PRIMARY KEY CLUSTERED ([ConversationID] ASC),
            CONSTRAINT [FK_Conversations_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Conversations_Leads] FOREIGN KEY ([LeadId]) REFERENCES [QAL].[Leads] ([LeadID]),
            CONSTRAINT [FK_Conversations_Customers] FOREIGN KEY ([CustomerId]) REFERENCES [ACE].[Customers] ([CustomerID]),
            CONSTRAINT [UQ_Conversations_Proxy] UNIQUE ([Proxy]),
            CONSTRAINT [UQ_Conversations_ReplyKey] UNIQUE ([ReplyKey]),
            CONSTRAINT [CK_Conversations_Status] CHECK ([Status] IN ('Open', 'Closed')),
            CONSTRAINT [CK_Conversations_Phone] CHECK ([Phone] IS NULL OR [Phone] LIKE '+[1-9]%'),
            CONSTRAINT [CK_Conversations_Contact] CHECK ([Phone] IS NOT NULL OR [Email] IS NOT NULL),
            CONSTRAINT [CK_Conversations_LastMessageDirection] CHECK ([LastMessageDirection] IS NULL OR [LastMessageDirection] IN ('Inbound', 'Outbound')),
            CONSTRAINT [CK_Conversations_LastMessageChannel] CHECK ([LastMessageChannel] IS NULL OR [LastMessageChannel] IN ('SMS', 'Email')),
            CONSTRAINT [CK_Conversations_UnreadCount] CHECK ([UnreadCount] >= 0)
        );
        PRINT 'Created [MSG].[Conversations]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Conversations') AND [name] = N'UX_Conversations_LeadId')
        CREATE UNIQUE NONCLUSTERED INDEX [UX_Conversations_LeadId] ON [MSG].[Conversations] ([DealerTenantId], [LeadId]) WHERE [LeadId] IS NOT NULL AND [IsDeleted] = 0;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Conversations') AND [name] = N'IX_Conversations_CustomerId')
        CREATE NONCLUSTERED INDEX [IX_Conversations_CustomerId] ON [MSG].[Conversations] ([CustomerId]) WHERE [CustomerId] IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Conversations') AND [name] = N'IX_Conversations_Phone')
        CREATE NONCLUSTERED INDEX [IX_Conversations_Phone] ON [MSG].[Conversations] ([DealerTenantId], [Phone]) WHERE [Phone] IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Conversations') AND [name] = N'IX_Conversations_Email')
        CREATE NONCLUSTERED INDEX [IX_Conversations_Email] ON [MSG].[Conversations] ([DealerTenantId], [Email]) WHERE [Email] IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Conversations') AND [name] = N'IX_Conversations_Inbox')
        CREATE NONCLUSTERED INDEX [IX_Conversations_Inbox] ON [MSG].[Conversations] ([DealerTenantId], [Status], [LastMessageDate] DESC) INCLUDE ([UnreadCount], [DisplayName], [LastMessagePreview]);

    ---------------------------------------------------------------------------
    -- MSG.Messages
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- MSG.MessageAttachments
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- MSG.ContactConsents
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MSG.ContactConsents', N'U') IS NULL
    BEGIN
        CREATE TABLE [MSG].[ContactConsents]
        (
            [ContactConsentID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [Channel] [varchar](10) NOT NULL,
            [Address] [nvarchar](256) NOT NULL,
            [Status] [varchar](10) NOT NULL,
            -- Keyword (STOP/START reply), Unsubscribe (email link), Form (website or Meta lead form), Staff, Import.
            [Source] [varchar](20) NOT NULL,
            [StatusDate] [datetimeoffset](7) NOT NULL,
            [Evidence] [nvarchar](1000) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_ContactConsents_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_ContactConsents_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_ContactConsents_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ContactConsents_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_ContactConsents_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ContactConsents_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_ContactConsents_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_ContactConsents] PRIMARY KEY CLUSTERED ([ContactConsentID] ASC),
            CONSTRAINT [FK_ContactConsents_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [UQ_ContactConsents_Address] UNIQUE ([DealerTenantId], [Channel], [Address]),
            CONSTRAINT [CK_ContactConsents_Channel] CHECK ([Channel] IN ('SMS', 'Email')),
            CONSTRAINT [CK_ContactConsents_Status] CHECK ([Status] IN ('OptedIn', 'OptedOut')),
            CONSTRAINT [CK_ContactConsents_Source] CHECK ([Source] IN ('Keyword', 'Unsubscribe', 'Form', 'Staff', 'Import')),
            CONSTRAINT [CK_ContactConsents_Address] CHECK (([Channel] = 'SMS' AND [Address] LIKE '+[1-9]%') OR ([Channel] = 'Email' AND [Address] LIKE '%_@_%'))
        );
        PRINT 'Created [MSG].[ContactConsents]';
    END;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Messaging: MSG schema with conversations, messages, attachments, contact consents and templates',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
