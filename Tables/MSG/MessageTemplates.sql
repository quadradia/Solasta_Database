/*******************************************************************************
 * Object Type: Table
 * Schema: MSG
 * Name: MessageTemplates
 * Description: Reusable texts and emails staff and automations send (new-lead reply, quote reminder, ...), one row per
               code, channel and language. Body text may hold {{FirstName}}-style placeholders the API fills in.
               MediaDocumentId is an optional MMS image or email attachment kept in DOC.Documents.
 * Author: Andres Sosa
 * Created: 2026-11-18
 * Dependencies: ACC.DealerTenants, DOC.Documents
 * Migrations: 20261118_2215_CreateMSG_Messaging
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
GO
