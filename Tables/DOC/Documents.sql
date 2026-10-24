/*******************************************************************************
 * Object Type: Table
 * Schema: DOC
 * Name: Documents
 * Description: Tenant-owned file metadata; file bytes remain in external storage.
 * Dependencies: DOC.DocumentTypes, ACC.DealerTenants
 * Author: Database Team
 * Created: 2026-10-24
 ******************************************************************************/

IF OBJECT_ID(N'DOC.Documents', N'U') IS NULL
BEGIN
    CREATE TABLE [DOC].[Documents]
    (
        [DocumentID] BIGINT IDENTITY(1,1) NOT NULL,
        [DealerTenantId] INT NOT NULL,
        [DocumentTypeId] INT NOT NULL CONSTRAINT [DF_Documents_DocumentTypeId] DEFAULT (1),
        [Proxy] VARCHAR(100) NOT NULL,
        [PartKey] VARCHAR(6) NOT NULL,
        [FileName] NVARCHAR(255) NOT NULL,
        [Title] NVARCHAR(255) NOT NULL,
        [Description] NVARCHAR(2000) NULL,
        [ContentType] NVARCHAR(255) NOT NULL,
        [SizeBytes] BIGINT NOT NULL,
        [Sha256] VARCHAR(64) NOT NULL,
        [StorageKey] NVARCHAR(100) NOT NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_Documents_IsActive] DEFAULT (1),
        [IsDeleted] BIT NOT NULL CONSTRAINT [DF_Documents_IsDeleted] DEFAULT (0),
        [ModifiedDate] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_Documents_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] UNIQUEIDENTIFIER NOT NULL,
        [CreatedDate] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_Documents_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] UNIQUEIDENTIFIER NOT NULL,
        [DEX_ROW_TS] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_Documents_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Documents] PRIMARY KEY CLUSTERED ([DocumentID]),
        CONSTRAINT [FK_Documents_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Documents_DocumentTypes] FOREIGN KEY ([DocumentTypeId])
            REFERENCES [DOC].[DocumentTypes] ([DocumentTypeID]),
        CONSTRAINT [CK_Documents_SizeBytes] CHECK ([SizeBytes] > 0),
        CONSTRAINT [CK_Documents_Sha256] CHECK
            (DATALENGTH([Sha256]) = 64 AND [Sha256] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9A-Fa-f]%'),
        CONSTRAINT [UQ_Documents_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [UQ_Documents_StorageKey] UNIQUE ([StorageKey])
    );
END;
GO

