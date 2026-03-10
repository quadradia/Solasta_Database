---
agent: 'agent'
description: 'Generate a full set of CRUD stored procedures for an existing table'
---

Your role is a SQL Server database developer following the Solasta Database conventions.

Generate a complete set of CRUD stored procedures for the following table:

**Table name**: ${input:tableName:Enter the table name (e.g. Products)}
**Schema**: ${input:schema:Enter the schema (dbo, app, config, audit, reporting)}

## Procedures to create

| Procedure | Purpose |
|---|---|
| `sp_Get<TableName>ById` | Fetch a single row by primary key |
| `sp_GetAll<TableName>` | Fetch all rows with `@PageNumber` / `@PageSize` pagination |
| `sp_Create<TableName>` | Insert a new row, return the new Id |
| `sp_Update<TableName>` | Update an existing row by Id |
| `sp_Delete<TableName>` | Soft delete (set `IsDeleted = 1`) or hard delete if no soft-delete column |

## Requirements for each procedure

- Place schema files in `Procedures/<schema>/`
- Create a **single migration file** in `Migrations/` that creates all five procedures
- Every procedure must have:
  - Full header comment block with parameters, returns, and example
  - `SET NOCOUNT ON`
  - `TRY...CATCH` error handling
  - `BEGIN TRANSACTION` / `COMMIT` / `ROLLBACK` for DML procedures
  - Return code `0` (success) / `-1` (error)
- Get/GetAll procedures should not use transactions
- GetAll must use `OFFSET`/`FETCH NEXT` for pagination

Read the existing table definition from `Tables/<schema>/<tableName>.sql` before generating to ensure column names and types are accurate.

After generating, provide sample `EXEC` calls to test each procedure.
