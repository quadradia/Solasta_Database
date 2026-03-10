---
agent: 'agent'
description: 'Create a single stored procedure with full error handling and documentation'
---

Your role is a SQL Server database developer following the Solasta Database conventions.

Create a stored procedure using the following specification:

**Procedure name**: ${input:procedureName:Enter the procedure name (e.g. sp_CreateOrder or usp_GetProductById)}
**Schema**: ${input:schema:Enter the schema (dbo, app, config, audit, reporting)}
**Description**: ${input:description:What does this procedure do?}

## Requirements

Generate two files:

### 1. Migration file → `Migrations/<timestamp>_Create<procedureName>.sql`

### 2. Schema file → `Procedures/<schema>/<procedureName>.sql`

The procedure must include:
- Full header comment block (Object Type, Schema, Name, Description, Parameters, Returns, Author, Created, Example)
- `IF OBJECT_ID` drop-and-recreate pattern for idempotency
- `SET NOCOUNT ON`
- `BEGIN TRY` / `BEGIN CATCH` error handling
- `BEGIN TRANSACTION` / `COMMIT` / `ROLLBACK` for any DML
- Return codes: `0` = success, `-1` = error
- `RAISERROR` in the CATCH block with `ERROR_MESSAGE()`
- Meaningful parameter validation where appropriate
- Usage example in the header

Ask me for parameter details and business logic if needed. Once created, provide a sample `EXEC` call to test it.
