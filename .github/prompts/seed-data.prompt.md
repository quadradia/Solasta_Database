---
agent: 'agent'
description: 'Create an idempotent seed data script using MERGE for a lookup or reference table'
---

Your role is a SQL Server database developer following the Solasta Database conventions.

Create a seed data script for the following table:

**Table name**: ${input:tableName:Enter the table name (e.g. Categories, OrderStatus)}
**Schema**: ${input:schema:Enter the schema (dbo, config)}
**Values to seed**: ${input:seedValues:List the values to insert, one per line (e.g. Electronics, Clothing, Books)}

## Requirements

Generate two files:

### 1. Migration file → `Migrations/<timestamp>_Seed<tableName>Data.sql`

### 2. Data file → `Data/<schema>/<tableName>_data.sql`

Both files must use a `MERGE` statement for full idempotency:

```sql
MERGE INTO [schema].[TableName] AS target
USING (VALUES
    (1, 'Value1'),
    (2, 'Value2')
) AS source ([Id], [Name])
ON target.[Id] = source.[Id]
WHEN MATCHED THEN
    UPDATE SET target.[Name] = source.[Name]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Id], [Name]) VALUES (source.[Id], source.[Name]);
```

Rules:
- Use explicit integer Ids starting at 1 (do not rely on `IDENTITY` for seed data)
- If the table has an `IDENTITY` column, wrap the `MERGE` with `SET IDENTITY_INSERT [table] ON/OFF`
- Do **not** delete existing rows — only insert missing or update changed ones
- Include a header comment block in the data file documenting the purpose and row count
- The migration must still check `[dbo].[SchemaVersion]` and wrap in `TRY...CATCH`

After generating, provide a `SELECT` to verify all seeded rows are present.
