---
agent: 'agent'
description: 'Create a User-Defined Table Type (UDTT) with migration and schema file'
---

Your role is a SQL Server database developer following the Solasta Database conventions.

Create a new User-Defined Table Type using the following specification:

**Type name**: ${input:typeName:Enter the type name (e.g. tvp_OrderLines or tvp_BulkInsertUsers)}
**Schema**: ${input:schema:Enter the schema (dbo, app, config, audit, reporting)}
**Description**: ${input:description:What structured data does this table type represent?}
**Typical usage**: ${input:usage:Describe when/how this type is passed (e.g. passed as READONLY parameter to sp_BulkInsert)}

## Requirements

Generate two files:

### 1. Migration file → `Migrations/<timestamp>_Create<typeName>.sql`
Use the current UTC date/time for the timestamp (`YYYYMMDD_HHMM`).

The migration must:
- Check `[dbo].[SchemaVersion]` to skip if already applied
- Wrap all DDL in `BEGIN TRANSACTION` / `TRY...CATCH`
- Use `IF NOT EXISTS` guard using `sys.table_types` before creating the type
- Drop the existing type first if it exists (types cannot be altered — drop and recreate)
- Record itself in `[dbo].[SchemaVersion]` on success
- Include a `ROLLBACK SCRIPT` comment block at the bottom

### 2. Schema file → `Types/<schema>/<typeName>.sql`

The schema file must include:

- Full header comment block in this exact format:
```sql
/******************************************************************************
**      File: <typeName>.sql
**      Name: <typeName>
**      Desc: <description>
**
**      Typical Usage: <usage>
**
**      Columns:
**      -------
**      [ColumnName] - Description
**
**      Auth: <Author>
**      Date: <YYYY-MM-DD>
*******************************************************************************
**  Change History
*******************************************************************************
**  Date:       Author:         Description:
**  ----------- --------------- -----------------------------------------------
**  <YYYY-MM-DD> <Author>       Created By
**
*******************************************************************************/
```

- Drop-and-recreate guard using `sys.table_types`:
```sql
IF EXISTS (
    SELECT 1 FROM sys.table_types
    WHERE name = N'<typeName>'
    AND schema_id = SCHEMA_ID(N'<schema>')
)
    DROP TYPE [<schema>].[<typeName>];
GO
```

- `CREATE TYPE ... AS TABLE` definition with:
  - Explicit `NULL` / `NOT NULL` on every column
  - A `PRIMARY KEY` or `UNIQUE` constraint where appropriate
  - No unnecessary audit columns (table types are transient structures)
  - `GO` after the statement

- A usage example comment block showing:
  - A stored procedure signature that accepts the type as `READONLY`
  - A sample variable declaration, `INSERT INTO @var`, and `EXEC` call

Ask me for the column definitions you need. Once created, provide a quick test snippet that declares a variable of the new type, inserts a sample row, and selects from it to confirm the type works correctly.
