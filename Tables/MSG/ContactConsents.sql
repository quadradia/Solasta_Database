/*******************************************************************************
 * Object Type: Table
 * Schema: MSG
 * Name: ContactConsents
 * Description: Whether Solasta may message an address on a channel, one row per tenant, channel and address (E.164 phone
               or lowercased email), so an opt-out follows the number, not the lead. The API checks it before every
               outbound message and records Blocked when the status is OptedOut. Changes come from a STOP or START
               reply, an email unsubscribe link, a form with consent wording, staff, or the GoHighLevel DND import;
               Evidence keeps what proved it (the reply text, the form's consent wording).
 * Author: Andres Sosa
 * Created: 2026-11-18
 * Dependencies: ACC.DealerTenants
 * Migrations: 20261118_2215_CreateMSG_Messaging
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
GO
