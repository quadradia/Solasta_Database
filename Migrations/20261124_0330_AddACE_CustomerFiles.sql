/*
Migration: 20261124_0330_AddACE_CustomerFiles
Author: Andres Sosa
Date: 2026-11-24
Description: Files on leads and customers (photos sent to the contact, documents, contracts). New table:
               ACE.CustomerFiles  one row per attached file: the DOC.Documents row that holds it, the lead and/or the
                                  customer it belongs to, and a category (Photo, Document, Other).
             When a lead becomes a customer the API sets CustomerId on the lead's files, so they follow the customer
             account and still show on the lead. The file bytes stay in DOC storage; there is no proxy of its own
             (files are addressed by their DOC proxy).
Dependencies:
  20261024_1637_CreateDOCDocuments (DOC.Documents)
Rollback:
  DROP TABLE [ACE].[CustomerFiles];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261124_0330_AddACE_CustomerFiles';
Expected impact: one new, empty table. No existing data changes.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261124_0330_AddACE_CustomerFiles';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'DOC.Documents', N'U') IS NULL OR OBJECT_ID(N'QAL.Leads', N'U') IS NULL OR OBJECT_ID(N'ACE.Customers', N'U') IS NULL
        THROW 50001, 'Customer files require DOC.Documents, QAL.Leads and ACE.Customers.', 1;

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
        PRINT 'Created [ACE].[CustomerFiles]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACE.CustomerFiles') AND [name] = N'IX_CustomerFiles_LeadId')
        CREATE NONCLUSTERED INDEX [IX_CustomerFiles_LeadId] ON [ACE].[CustomerFiles] ([LeadId]) INCLUDE ([DocumentId], [IsActive])
            WHERE [LeadId] IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACE.CustomerFiles') AND [name] = N'IX_CustomerFiles_CustomerId')
        CREATE NONCLUSTERED INDEX [IX_CustomerFiles_CustomerId] ON [ACE].[CustomerFiles] ([CustomerId]) INCLUDE ([DocumentId], [IsActive])
            WHERE [CustomerId] IS NOT NULL;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Files on leads and customers: ACE.CustomerFiles (links DOC.Documents to QAL.Leads and ACE.Customers)',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
