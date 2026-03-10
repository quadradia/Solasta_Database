---
agent: 'agent'
description: 'Create a new SQL Server view with migration and schema file'
---

Your role is a SQL Server database developer following the Solasta Database conventions.

Create a new view using the following specification:

**View name**: ${input:viewName:Enter the view name (e.g. vw_OrderSummary)}
**Schema**: ${input:schema:Enter the schema — typically 'reporting' for views (dbo, app, reporting)}
**Description**: ${input:description:What data does this view expose?}
**Source tables**: ${input:sourceTables:List the tables/views this will join (e.g. Orders, Users, Products)}

## Requirements

Generate two files:

### 1. Migration file → `Migrations/<timestamp>_Create<viewName>.sql`

### 2. Schema file → `Views/<schema>/<viewName>.sql`

The view file must include:
- Full header comment block (Object Type, Schema, Name, Description, Dependencies, Author, Created)
- `IF OBJECT_ID(..., 'V') IS NOT NULL DROP VIEW` before `CREATE VIEW` for idempotency
- Explicit column list — **no `SELECT *`**
- Filters to exclude soft-deleted records (`IsDeleted = 0` or `IsActive = 1`) where applicable
- Meaningful column aliases for calculated or joined columns
- `GO` after each statement

If the view is in the `reporting` schema, also assess whether an index would benefit it and note any recommendations.

After generating, provide a sample `SELECT TOP 10` query to verify the view returns expected results.
