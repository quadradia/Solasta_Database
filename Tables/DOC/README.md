# DOC document metadata

`DOC.Documents` stores tenant-owned metadata for files held in external storage.
It supports signed contracts, DXF engineering files, and other formats through
`FileName` and `ContentType`; the database does not store file bytes or validate
digital signatures. `StorageKey` identifies the externally stored file.

The starting design is based on
`solasta-lighting-est-api/Database/DOC/001_CreateDocuments.sql`.

## Tables and identifiers

- `DocumentTypes` defines document classifications and their registered prefixes.
  Type 1 is General Document, with prefix `DOCT`. File formats remain independent
  of this classification: a general document can be a PDF, DXF, or another format.
- `Documents` uses `DocumentID BIGINT IDENTITY` internally and `DealerTenantId`
  references `ACC.DealerTenants`. `DocumentTypeId` defaults to 1.
- External identifiers follow `DOCT:{hex-year-month}:{GUID}`. Generate the prefix
  and partition through `MAC.fxGeneratePrefixParts('Document', @DocumentTypeId)`
  or `MAC.fxGeneratePrefixProxy('Document', @DocumentTypeId)`, then append `NEWID()`.
  Store the same partition in `PartKey VARCHAR(6)`.
- Proxy lookups must validate `PartKey` and `DocumentTypeId`, restrict by the
  authenticated `DealerTenantId`, and filter `IsActive = 1 AND IsDeleted = 0`.

Both tables follow the required audit tail; actor IDs are `UNIQUEIDENTIFIER`,
matching the reference document API. Applications must supply actor IDs. Dates
and `DEX_ROW_TS` default at insertion; applications must maintain `ModifiedDate`,
`ModifiedById`, and `DEX_ROW_TS` on updates. No update trigger is introduced.

## Integrity and indexing

Documents require a positive `SizeBytes` and a 64-character hexadecimal `Sha256`.
The checksum is metadata supplied by the file-storage layer; SQL does not verify
the external file contents. Proxy and storage keys are globally unique. Files
with identical content can have different storage keys and document rows.

Foreign keys use SQL Server's default `NO ACTION` behavior, preventing deletion
of a tenant or type while documents reference it. Indexes support tenant/active
pagination, document-type lookups, and partition/type filtering.

## Deployment and verification

1. Apply `20261024_1634_CreateDOCSchema` and the existing ACC/MAC/UTL prerequisites.
2. Apply `20261024_1637_CreateDOCDocuments` using the normal migration runner.
3. Run it a second time to confirm it skips via `dbo.SchemaVersion`.
4. Verify the seeded type, columns, indexes, and Proxy-ID resolution:

```sql
SELECT [DocumentTypeID], [Prefix], [DocumentTypeName]
FROM [DOC].[DocumentTypes];

SELECT [name], [column_id], TYPE_NAME([user_type_id]) AS [DataType], [max_length]
FROM sys.columns WHERE [object_id] = OBJECT_ID(N'DOC.Documents')
ORDER BY [column_id];

SELECT [name], [is_unique], [is_disabled]
FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'DOC.Documents');

DECLARE @Proxy VARCHAR(100) = [MAC].[fxGeneratePrefixProxy]('Document', 1)
    + CONVERT(VARCHAR(36), NEWID());
SELECT [Prefix], [PartKey], [TypeId], [TableName], [TypeName]
FROM [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy);
```

The migration refuses to adopt pre-existing, untracked DOC tables. If the API's
prototype SQL was already deployed, inspect its data and use a separate
reconciliation migration; do not drop existing document metadata to install this.
Rollback instructions are in the migration and refuse to remove document rows.

## Reference API changes needed before deployment

The reference API currently generates `DOC:` proxies with its own partition
generator and accepts `PartKey` up to 20 characters. Update it to use the registered
four-character `DOCT` prefix and the database's hex year/month partition before
using this schema. Existing identifiers need a deliberate data migration.

Map `DocumentTypeId` and the additional `IsDeleted` and `DEX_ROW_TS` fields; keep
the authenticated tenant filter and validate the parsed type and partition on
lookups. Update delete behavior and queries consistently for the two status flags.
Map `StorageKey` as Unicode (`NVARCHAR(100)`); it is an opaque external locator.
Constraint names follow this repository rather than the prototype's `DOC_` names.
The API repository has not been modified by this change.
