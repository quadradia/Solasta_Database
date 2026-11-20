/*******************************************************************************
 * Object Type: Table
 * Schema: MSG
 * Name: Conversations
 * Description: One message thread per contact, holding SMS and email together. A conversation belongs to a lead, to a
               customer (ACE.Customers, which keeps its LeadId), or to neither when an unknown number or address writes in;
               staff link it later. Phone is E.164 (+18015551234), Email is lowercased. The Last* columns and UnreadCount
               are kept up to date by the API so the inbox lists without reading MSG.Messages. ReplyKey goes in the
               reply-to address of outbound email (replies+<ReplyKey>@...) so an emailed reply lands in this thread.
 * Author: Andres Sosa
 * Created: 2026-11-18
 * Dependencies: ACC.DealerTenants, QAL.Leads, ACE.Customers
 * Migrations: 20261118_2215_CreateMSG_Messaging, 20261120_2100_AddMSG_Calls (LastMessageChannel Call)
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
        CONSTRAINT [CK_Conversations_LastMessageChannel] CHECK ([LastMessageChannel] IS NULL OR [LastMessageChannel] IN ('SMS', 'Email', 'Call')),
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
GO
