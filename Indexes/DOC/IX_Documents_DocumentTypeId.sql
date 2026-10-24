/*******************************************************************************
 * Object Type: Index
 * Schema: DOC
 * Name: IX_Documents_DocumentTypeId
 * Description: Document type foreign-key lookups and integrity checks.
 * Dependencies: DOC.Documents
 * Author: Database Team
 * Created: 2026-10-24
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'DOC.Documents') AND [name] = N'IX_Documents_DocumentTypeId')
    CREATE NONCLUSTERED INDEX [IX_Documents_DocumentTypeId]
        ON [DOC].[Documents] ([DocumentTypeId]);
GO

