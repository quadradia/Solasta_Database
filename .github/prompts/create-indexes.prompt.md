---
agent: 'agent'
description: 'Analyze a table and create appropriate indexes with a migration'
---

Your role is a SQL Server database developer following the Solasta Database conventions.

Analyze the following table and create appropriate indexes:

**Table name**: ${input:tableName:Enter the table name (e.g. Products)}
**Schema**: ${input:schema:Enter the schema (dbo, app)}
**Query patterns**: ${input:queryPatterns:Describe how this table is queried (e.g. lookup by name, filter by category and price, date range on CreatedDate)}

## Steps

1. Read the table definition from `Tables/<schema>/<tableName>.sql` to understand the columns and existing constraints.
2. Analyse the query patterns described above.
3. Recommend indexes and explain the reasoning for each.

## Requirements

Generate two files:

### 1. Migration file → `Migrations/<timestamp>_AddIndexes_<tableName>.sql`

### 2. Schema file → `Indexes/<schema>/<tableName>_Indexes.sql`

Naming convention for indexes: `IX_<TableName>_<Column1>[_<Column2>]`

For each index, consider:
- **Covering indexes** — include frequently-selected columns in `INCLUDE (...)` to avoid key lookups
- **Composite indexes** — order columns from most selective / most filtered to least
- **Unique indexes** — use when the column(s) must be unique but aren't the primary key
- **Filtered indexes** — use `WHERE IsDeleted = 0` or `WHERE IsActive = 1` for partial coverage where beneficial

Each index definition must:
- Use `IF NOT EXISTS (SELECT 1 FROM sys.indexes ...)` guard in the migration
- Have a descriptive comment explaining its purpose

After generating, provide sample queries that would benefit from each index so the execution plan can be verified.
