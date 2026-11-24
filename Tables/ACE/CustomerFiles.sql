/*******************************************************************************
 * Object Type: Table
 * Schema: ACE
 * Name: CustomerFiles
 * Description: Files (photos, documents, contracts) attached to a lead and/or a customer. The bytes and metadata
               are in DOC.Documents; when a lead becomes a customer the API sets CustomerId on the lead's files so
               they follow the customer account.
 * Author: Andres Sosa
 * Created: 2026-11-24
 * Dependencies: ACC.DealerTenants, DOC.Documents, QAL.Leads, ACE.Customers
 * Migrations: 20261124_0330_AddACE_CustomerFiles
 ******************************************************************************/
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'ACE.CustomerFiles', N'U') IS NULL
BEGIN
    CREATE TABLE [ACE].[CustomerFiles]
    (
        [CustomerFileID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        -- The file itself: metadata (name, title, description, type, size, SHA-256) and the stored bytes are in DOC.
        [DocumentId] [bigint] NOT NULL,
        -- Who it belongs to: a lead, a customer, or both once the lead became that customer (the API copies the
        -- customer onto the lead's files when it converts). At least one is set.
        [LeadId] [bigint] NULL,
        [CustomerId] [bigint] NULL,
        -- Photo, Document or Other; the API picks it from the file's type when staff leave it out.
        [Category] [varchar](20) NOT NULL CONSTRAINT [DF_CustomerFiles_Category] DEFAULT ('Other'),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_CustomerFiles_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_CustomerFiles_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_CustomerFiles_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_CustomerFiles_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_CustomerFiles_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_CustomerFiles_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_CustomerFiles_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_CustomerFiles] PRIMARY KEY CLUSTERED ([CustomerFileID] ASC),
        CONSTRAINT [FK_CustomerFiles_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_CustomerFiles_Documents] FOREIGN KEY ([DocumentId]) REFERENCES [DOC].[Documents] ([DocumentID]),
        CONSTRAINT [FK_CustomerFiles_Leads] FOREIGN KEY ([LeadId]) REFERENCES [QAL].[Leads] ([LeadID]),
        CONSTRAINT [FK_CustomerFiles_Customers] FOREIGN KEY ([CustomerId]) REFERENCES [ACE].[Customers] ([CustomerID]),
        CONSTRAINT [UQ_CustomerFiles_DocumentId] UNIQUE ([DocumentId]),
        CONSTRAINT [CK_CustomerFiles_Owner] CHECK ([LeadId] IS NOT NULL OR [CustomerId] IS NOT NULL),
        CONSTRAINT [CK_CustomerFiles_Category] CHECK ([Category] IN ('Photo', 'Document', 'Other'))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACE.CustomerFiles') AND [name] = N'IX_CustomerFiles_LeadId')
    CREATE NONCLUSTERED INDEX [IX_CustomerFiles_LeadId] ON [ACE].[CustomerFiles] ([LeadId]) INCLUDE ([DocumentId], [IsActive])
        WHERE [LeadId] IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACE.CustomerFiles') AND [name] = N'IX_CustomerFiles_CustomerId')
    CREATE NONCLUSTERED INDEX [IX_CustomerFiles_CustomerId] ON [ACE].[CustomerFiles] ([CustomerId]) INCLUDE ([DocumentId], [IsActive])
        WHERE [CustomerId] IS NOT NULL;
GO
