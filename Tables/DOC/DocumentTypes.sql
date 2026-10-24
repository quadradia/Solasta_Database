/*******************************************************************************
 * Object Type: Table
 * Schema: DOC
 * Name: DocumentTypes
 * Description: Document classifications and registered Proxy-ID prefixes.
 * Dependencies: DOC schema
 * Author: Database Team
 * Created: 2026-10-24
 ******************************************************************************/

IF OBJECT_ID(N'DOC.DocumentTypes', N'U') IS NULL
BEGIN
    CREATE TABLE [DOC].[DocumentTypes]
    (
        [DocumentTypeID] INT IDENTITY(1,1) NOT NULL,
        [Prefix] VARCHAR(4) NOT NULL,
        [DocumentTypeName] NVARCHAR(100) NOT NULL,
        [DocumentTypeDescription] NVARCHAR(2000) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_DocumentTypes_IsActive] DEFAULT (1),
        [IsDeleted] BIT NOT NULL CONSTRAINT [DF_DocumentTypes_IsDeleted] DEFAULT (0),
        [ModifiedDate] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_DocumentTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] UNIQUEIDENTIFIER NOT NULL,
        [CreatedDate] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_DocumentTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] UNIQUEIDENTIFIER NOT NULL,
        [DEX_ROW_TS] DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_DocumentTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_DocumentTypes] PRIMARY KEY CLUSTERED ([DocumentTypeID]),
        CONSTRAINT [UQ_DocumentTypes_Prefix] UNIQUE ([Prefix]),
        CONSTRAINT [CK_DocumentTypes_Prefix] CHECK
            (DATALENGTH([Prefix]) = 4 AND [Prefix] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^A-Z0-9]%')
    );
END;
GO

