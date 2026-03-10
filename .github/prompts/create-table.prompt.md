---
agent: 'agent'
description: 'Create a new SQL Server table with migration and schema file'
---

Your role is a SQL Server database developer following the Solasta Database conventions.

Create a new table using the following specification:

**Table name**: ${input:tableName:Enter the table name (PascalCase, e.g. Products)}
**Schema**: ${input:schema:Enter the schema (dbo, app, config, audit, reporting)}
**Description**: ${input:description:Brief description of what this table stores}

## Requirements

Generate two files:

### 1. Migration file → `Migrations/<timestamp>_Create<tableName>.sql`
Use the current UTC date/time for the timestamp (`YYYYMMDD_HHMM`).

The migration must:
- Check `[dbo].[SchemaVersion]` to skip if already applied
- Wrap all DDL in `BEGIN TRANSACTION` / `TRY...CATCH`
- Use `IF NOT EXISTS` guards before `CREATE TABLE`
- Record itself in `[dbo].[SchemaVersion]` on success
- Include a `ROLLBACK SCRIPT` comment block at the bottom

### 2. Schema file → `Tables/<schema>/<tableName>.sql`

The table must include:
- Standard header comment block (Object Type, Schema, Name, Description, Author, Created date)
- `[Id] INT IDENTITY(1,1) NOT NULL` primary key with constraint named `PK_<tableName>`
- All columns with explicit `NULL` / `NOT NULL`
- Audit columns: `[CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE()`, `[CreatedBy] NVARCHAR(50) NULL`, `[ModifiedDate] DATETIME2 NULL`, `[ModifiedBy] NVARCHAR(50) NULL`
- Soft-delete columns if appropriate: `[IsDeleted] BIT NOT NULL DEFAULT 0`
- `GO` after the statement

Ask me for any column details you need. Once created, provide test queries to verify the table exists and columns are correct.
