/*******************************************************************************
 * Object Type: Index
 * Schema: DOC
 * Name: IX_Documents_DealerTenantId_IsActive_DocumentID
 * Description: Tenant-scoped active document pagination, matching the reference API.
 * Dependencies: DOC.Documents
 * Author: Database Team
 * Created: 2026-10-24
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'DOC.Documents') AND [name] = N'IX_Documents_DealerTenantId_IsActive_DocumentID')
    CREATE NONCLUSTERED INDEX [IX_Documents_DealerTenantId_IsActive_DocumentID]
        ON [DOC].[Documents] ([DealerTenantId], [IsActive], [DocumentID] DESC);
GO

