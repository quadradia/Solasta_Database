---
agent: 'agent'
description: 'Create a scalar or table-valued SQL Server function with migration'
---

Your role is a SQL Server database developer following the Solasta Database conventions.

Create a new function using the following specification:

**Function name**: ${input:functionName:Enter the function name (e.g. fn_CalculateOrderTotal)}
**Schema**: ${input:schema:Enter the schema (dbo, app, config)}
**Type**: ${input:functionType:Enter 'scalar' for a value-returning function or 'tvf' for a table-valued function}
**Description**: ${input:description:What does this function calculate or return?}

## Requirements

Generate two files:

### 1. Migration file → `Migrations/<timestamp>_Create<functionName>.sql`

### 2. Schema file → `Functions/<schema>/<functionName>.sql`

The function file must include:
- Full header comment block (Object Type, Schema, Name, Description, Parameters, Returns, Author, Created)
- `IF OBJECT_ID` drop-and-recreate pattern for idempotency
- `GO` after each statement

**For scalar functions:**
- Return a single typed value
- Declare local variables for intermediate calculations
- Handle `NULL` inputs gracefully (return `0` or `NULL` as appropriate)

**For table-valued functions (TVF):**
- Use inline TVF syntax (`RETURNS TABLE AS RETURN (...)`) for best performance
- Explicit column list — no `SELECT *`
- Filter out soft-deleted / inactive rows where applicable

After generating, provide a sample call to verify the function returns correct results.
