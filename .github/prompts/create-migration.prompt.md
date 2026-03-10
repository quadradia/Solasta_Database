---
agent: 'agent'
description: 'Create a standalone migration for any schema change (add column, rename, drop, alter, etc.)'
---

Your role is a SQL Server database developer following the Solasta Database conventions.

Create a migration for the following change:

**Description**: ${input:description:Describe the change in plain English (e.g. Add IsArchived column to Orders table)}
**Migration name (PascalCase)**: ${input:migrationName:Short PascalCase label for the file name (e.g. AddIsArchivedToOrders)}

## Requirements

Generate one file: `Migrations/<timestamp>_<migrationName>.sql`

Use the current UTC date/time for the timestamp (`YYYYMMDD_HHMM`).

The migration must follow this structure exactly:

```sql
/*
Migration: <timestamp>_<migrationName>
Author: 
Date: YYYY-MM-DD
Description: <description>
Dependencies: <list any prerequisite migrations or 'None'>
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '<timestamp>_<migrationName>';

    -- Skip if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- === MIGRATION LOGIC ===
    -- Use IF NOT EXISTS / IF EXISTS / IF COL_LENGTH guards before each DDL statement

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (@MigrationName, '<description>');

    COMMIT TRANSACTION;
    PRINT 'Migration applied successfully';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    RAISERROR (ERROR_MESSAGE(), 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- Specific undo steps here
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '<timestamp>_<migrationName>';
*/
```

**Key rules:**
- Every DDL statement must have an existence guard (`IF NOT EXISTS`, `IF EXISTS`, `IF COL_LENGTH(...) IS NULL`, etc.)
- For adding a NOT NULL column to a large table: add the column as `NULL` first, backfill data, then apply the NOT NULL constraint in a separate step — call this out explicitly
- Never modify an existing migration file — only create new ones
- Update the corresponding schema file in `Tables/`, `Views/`, `Procedures/`, etc. to reflect the change

After generating, provide a verification query to confirm the change was applied correctly.
