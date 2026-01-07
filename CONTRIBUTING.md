# Contributing to Solasta Database

Thank you for contributing to the Solasta Lighting database! This guide will help you make database changes following our standards and best practices.

## Prerequisites

- SQL Server Management Studio (SSMS) or Azure Data Studio
- Access to a development SQL Server instance
- Git for version control
- Understanding of T-SQL and database design principles

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/quadradia/Solasta_Database.git
   cd Solasta_Database
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set up your local database**
   - Create a local database for testing
   - Run all existing migrations in order

## Making Database Changes

### 1. Schema Changes (Tables, Views, Functions, Stored Procedures)

When adding or modifying schema objects:

#### Adding a New Table
1. Create a migration script in `Migrations/`:
   - Use naming: `YYYYMMDD_HHMM_CreateTableName.sql`
   - Use the migration template as a starting point
   - Include complete CREATE TABLE statement
   - Add appropriate indexes and constraints

2. Create a table definition file in `Schema/Tables/`:
   - Use naming: `TableName.sql`
   - Include complete CREATE statement for documentation
   - This serves as the "source of truth" for the table structure

#### Modifying an Existing Table
1. Create a migration script in `Migrations/`:
   - Use naming: `YYYYMMDD_HHMM_AlterTableName.sql`
   - Include ALTER TABLE statements
   - Make changes idempotent (check if column exists before adding)

2. Update the table definition file in `Schema/Tables/`:
   - Modify the file to reflect the current state
   - This should always match the actual database structure

#### Adding/Modifying Views, Stored Procedures, or Functions
1. Create or update the file in the appropriate `Schema/` subfolder:
   - Views: `Schema/Views/vw_ViewName.sql`
   - Stored Procedures: `Schema/StoredProcedures/sp_ProcedureName.sql`
   - Functions: `Schema/Functions/fn_FunctionName.sql`

2. Use CREATE OR ALTER (SQL Server 2016+) or DROP/CREATE pattern
3. These files can be re-run to update the objects

### 2. Data Changes

For data migrations or seeding:

1. Create a migration script in `Migrations/`
2. Use clear naming: `YYYYMMDD_HHMM_SeedDataForTable.sql`
3. Make data changes idempotent:
   ```sql
   IF NOT EXISTS (SELECT 1 FROM [dbo].[Table] WHERE [Id] = 1)
   BEGIN
       INSERT INTO [dbo].[Table] ([Id], [Name]) VALUES (1, 'Value');
   END
   ```

### 3. Migration Script Guidelines

Every migration script must:

1. **Include a header** with metadata:
   ```sql
   /*
   Migration: YYYYMMDD_HHMM_Description
   Author: Your Name
   Date: YYYY-MM-DD
   Description: What this migration does
   Dependencies: Any prerequisite migrations
   */
   ```

2. **Check SchemaVersion table** to prevent duplicate execution:
   ```sql
   IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = 'MigrationName')
   BEGIN
       PRINT 'Migration already applied. Skipping...';
       RETURN;
   END
   ```

3. **Use transactions** for data consistency:
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

4. **Record the migration** in SchemaVersion:
   ```sql
   INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
   VALUES ('MigrationName', 'Description');
   ```

5. **Include rollback instructions** at the bottom:
   ```sql
   /*
   ROLLBACK SCRIPT:
   -- Specific steps to undo this migration
   */
   ```

## Testing Your Changes

1. **Test on local database first**
   ```sql
   -- Create a test database
   CREATE DATABASE SolastaDB_Test;
   GO
   USE SolastaDB_Test;
   GO
   ```

2. **Apply your migration**
   - Execute your migration script
   - Verify it completes without errors
   - Check that SchemaVersion table is updated

3. **Test rollback**
   - Execute the rollback script
   - Verify database returns to previous state
   - Re-apply migration to ensure it still works

4. **Test edge cases**
   - Run migration twice to ensure idempotency
   - Test with existing data
   - Verify performance with realistic data volumes

## Code Review Checklist

Before submitting a Pull Request, ensure:

- [ ] Migration script follows naming convention
- [ ] Migration is idempotent (can be run multiple times safely)
- [ ] Transaction handling is implemented
- [ ] Error handling is in place
- [ ] Rollback script is provided
- [ ] SchemaVersion table is updated
- [ ] Schema object files are updated to reflect changes
- [ ] Changes tested on local database
- [ ] No hardcoded server or database names
- [ ] Appropriate indexes are added for performance
- [ ] Extended properties added for documentation
- [ ] No sensitive data or credentials in scripts

## Pull Request Process

1. **Create a Pull Request** with:
   - Clear title describing the change
   - Detailed description of what changed and why
   - List of migrations included
   - Any breaking changes highlighted
   - Testing notes

2. **PR Description Template**:
   ```markdown
   ## Summary
   Brief description of the database changes
   
   ## Migrations Included
   - YYYYMMDD_HHMM_MigrationName1.sql
   - YYYYMMDD_HHMM_MigrationName2.sql
   
   ## Changes
   - Added table: TableName
   - Modified stored procedure: sp_ProcName
   
   ## Testing
   - Tested on local SQL Server 2019
   - Verified migration is idempotent
   - Tested rollback successfully
   
   ## Breaking Changes
   None / List any breaking changes
   
   ## Deployment Notes
   Any special considerations for deployment
   ```

3. **Address review feedback**
   - Respond to all comments
   - Make requested changes
   - Re-test after changes

4. **Approval and merge**
   - Requires approval from database administrator
   - Squash commits if requested
   - Delete feature branch after merge

## Common Patterns

### Adding a Column with Default Value
```sql
IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID('dbo.TableName') 
               AND name = 'NewColumn')
BEGIN
    ALTER TABLE [dbo].[TableName]
    ADD [NewColumn] NVARCHAR(100) NOT NULL 
    CONSTRAINT DF_TableName_NewColumn DEFAULT 'DefaultValue';
END
```

### Adding an Index
```sql
IF NOT EXISTS (SELECT * FROM sys.indexes 
               WHERE name = 'IX_TableName_Column' 
               AND object_id = OBJECT_ID('dbo.TableName'))
BEGIN
    CREATE INDEX IX_TableName_Column 
    ON [dbo].[TableName]([Column]);
END
```

### Adding a Foreign Key
```sql
IF NOT EXISTS (SELECT * FROM sys.foreign_keys 
               WHERE name = 'FK_TableName_OtherTable')
BEGIN
    ALTER TABLE [dbo].[TableName]
    ADD CONSTRAINT FK_TableName_OtherTable 
    FOREIGN KEY ([OtherTableId])
    REFERENCES [dbo].[OtherTable]([Id]);
END
```

## Best Practices

1. **Keep migrations small** - One logical change per migration
2. **Make changes backward compatible** when possible
3. **Use meaningful names** - Names should describe the change
4. **Document everything** - Use comments and extended properties
5. **Think about performance** - Add indexes for common queries
6. **Consider data volume** - Test with realistic data sizes
7. **Plan for rollback** - Always have a way to undo changes
8. **Avoid breaking changes** - Or communicate them clearly
9. **Use standard data types** - Follow team conventions
10. **Security first** - Never commit credentials or sensitive data

## Need Help?

- Review existing migrations for examples
- Check the templates in `Migrations/TEMPLATE_Migration.sql`
- Ask questions in Pull Request comments
- Contact the database team for guidance

## Additional Resources

- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/)
- [Database Version Control Best Practices](https://www.red-gate.com/solutions/database-version-control)
- [T-SQL Style Guide](https://www.sqlstyle.guide/)

---

Thank you for contributing to Solasta Database! 🚀
