# Database Migrations

This directory contains all database migration scripts in chronological order. Each migration represents a single logical change to the database schema or data.

## Overview

Migrations are the **source of truth** for how the database evolved over time. They should be:
- **Immutable** - Once deployed, never modify an existing migration
- **Sequential** - Applied in chronological order based on filename
- **Idempotent** - Safe to run multiple times
- **Atomic** - Each migration is a single logical unit of change

## File Naming Convention

```
YYYYMMDD_HHMM_DescriptionOfChange.sql
```

### Examples
- `20260107_1430_CreateUsersTable.sql`
- `20260107_1445_AddIndexToUsersEmail.sql`
- `20260108_0900_AlterUsersAddPhoneNumber.sql`
- `20260108_1000_SeedInitialUserData.sql`

### Naming Guidelines
- Use UTC timestamp for consistency across time zones
- Use underscores to separate parts
- Use PascalCase for the description
- Be descriptive but concise
- Start with verb (Create, Add, Alter, Drop, Seed, etc.)

## Migration Structure

Every migration must include:

1. **Header Comment Block**
   ```sql
   /*
   Migration: YYYYMMDD_HHMM_DescriptionOfChange
   Author: Your Name
   Date: YYYY-MM-DD
   Description: What this migration does
   Dependencies: Any prerequisite migrations
   */
   ```

2. **Idempotency Check**
   ```sql
   IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] 
              WHERE [MigrationName] = 'MigrationName')
   BEGIN
       PRINT 'Already applied. Skipping...';
       RETURN;
   END
   ```

3. **Transaction Wrapper**
   ```sql
   BEGIN TRANSACTION;
   BEGIN TRY
       -- Your changes here
       COMMIT TRANSACTION;
   END TRY
   BEGIN CATCH
       ROLLBACK TRANSACTION;
       -- Error handling
   END CATCH
   ```

4. **SchemaVersion Update**
   ```sql
   INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
   VALUES ('MigrationName', 'Description');
   ```

5. **Rollback Instructions**
   ```sql
   /*
   ROLLBACK SCRIPT:
   -- Steps to undo this migration
   */
   ```

## Creating a New Migration

### Using the Template
1. Copy the template:
   ```bash
   cp Migrations/TEMPLATE_Migration.sql Migrations/20260107_1500_YourChange.sql
   ```

2. Update placeholders:
   - Replace `YYYYMMDD_HHMM_DescriptionOfChange` with your migration name
   - Fill in author, date, description
   - Add your migration logic
   - Include rollback instructions

3. Test locally before committing

### Quick Migration Template
```sql
/*
Migration: 20260107_1500_CreateOrdersTable
Author: John Doe
Date: 2026-01-07
Description: Creates the Orders table for order management
Dependencies: 20260107_1400_CreateUsersTable
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260107_1500_CreateOrdersTable';
    
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] 
               WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Your migration logic here
    CREATE TABLE [dbo].[Orders] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [UserId] INT NOT NULL,
        [OrderDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [TotalAmount] DECIMAL(18,2) NOT NULL
    );
    
    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (@MigrationName, 'Creates the Orders table');
    
    COMMIT TRANSACTION;
    PRINT 'Migration applied successfully';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR (@ErrorMessage, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
DROP TABLE IF EXISTS [dbo].[Orders];
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260107_1500_CreateOrdersTable';
*/
```

## Migration Types

### Schema Migrations
Changes to database structure:
- Creating tables, views, stored procedures, functions
- Altering existing objects (add/modify/drop columns)
- Adding/removing indexes
- Adding/removing constraints

### Data Migrations
Changes to database data:
- Seeding initial data
- Migrating data between columns
- Cleaning up orphaned records
- Updating existing records

### Both
Some migrations involve both schema and data changes.

## Best Practices

### ✅ DO
- Test migrations on local database first
- Make migrations idempotent (check before creating/altering)
- Use transactions for atomicity
- Include clear rollback instructions
- Keep migrations focused (one logical change)
- Add appropriate indexes
- Use meaningful constraint names
- Document breaking changes
- Run migrations in order

### ❌ DON'T
- Don't modify existing migrations after deployment
- Don't skip migrations in the sequence
- Don't include environment-specific values
- Don't commit sensitive data
- Don't make unrelated changes together
- Don't forget error handling
- Don't ignore performance implications

## Execution Order

Migrations are executed in chronological order based on filename:
1. `00000000_0000_CreateSchemaVersionTable.sql` (Base migration)
2. `20260107_1400_CreateUsersTable.sql`
3. `20260107_1500_CreateOrdersTable.sql`
4. `20260108_0900_AddIndexToOrders.sql`
5. ...and so on

## Deployment

### Development Environment
```sql
-- Run each migration manually in SSMS
USE [SolastaDB_Dev];
GO
-- Execute migration file
```

### Staging/Production
```sql
-- 1. Backup database
BACKUP DATABASE [SolastaDB] TO DISK = 'backup.bak';

-- 2. Check current version
SELECT * FROM [dbo].[SchemaVersion] ORDER BY [AppliedDate] DESC;

-- 3. Execute pending migrations in order

-- 4. Verify
SELECT * FROM [dbo].[SchemaVersion] ORDER BY [AppliedDate] DESC;
```

## Troubleshooting

### Migration Failed
1. Check error message
2. Rollback will happen automatically (transaction)
3. Fix the migration script
4. Remove SchemaVersion entry if inserted
5. Re-run the corrected migration

### Migration Already Applied
```sql
-- Check if it was actually applied
SELECT * FROM [dbo].[SchemaVersion] 
WHERE [MigrationName] = 'YourMigration';

-- If incorrectly marked as applied, delete the record
DELETE FROM [dbo].[SchemaVersion] 
WHERE [MigrationName] = 'YourMigration';
```

### Conflicting Migrations
If two developers create migrations with similar timestamps:
1. Rename the later one to have a unique timestamp
2. Update the migration name inside the file
3. Ensure both migrations are independent or merge them

## Version Tracking

The `SchemaVersion` table tracks all applied migrations:

```sql
-- View all applied migrations
SELECT [Id], [MigrationName], [AppliedDate], [AppliedBy], [Success]
FROM [dbo].[SchemaVersion]
ORDER BY [AppliedDate];

-- Check if specific migration was applied
SELECT * FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = '20260107_1500_CreateOrdersTable';

-- View recent migrations
SELECT TOP 10 * FROM [dbo].[SchemaVersion]
ORDER BY [AppliedDate] DESC;
```

## Getting Help

- Review the `TEMPLATE_Migration.sql` file
- Check existing migrations for examples
- Read the [QUICKSTART.md](../QUICKSTART.md) guide
- See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines
- Ask questions in Pull Requests

---

**Remember**: Migrations are permanent history. Once deployed, they should never be modified. Create a new migration to make additional changes.
