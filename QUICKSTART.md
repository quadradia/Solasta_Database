# Quick Start Guide - Solasta Database

This guide will help you get started with the Solasta Database source control system.

## For Developers: Making Your First Database Change

### Step 1: Set Up Your Environment
```bash
# Clone the repository
git clone https://github.com/quadradia/Solasta_Database.git
cd Solasta_Database

# Create a feature branch
git checkout -b feature/add-user-authentication
```

### Step 2: Initialize Your Database
1. Create a local SQL Server database for testing
2. Run the base migration to set up version tracking:
   ```sql
   -- Execute in SQL Server Management Studio
   USE [YourDatabaseName];
   GO
   -- Run: Migrations/00000000_0000_CreateSchemaVersionTable.sql
   ```

### Step 3: Create Your Migration
1. Copy the migration template:
   ```bash
   cp Migrations/TEMPLATE_Migration.sql Migrations/20260107_1400_CreateUsersTable.sql
   ```

2. Edit the migration file:
   - Update the migration name and metadata
   - Add your CREATE TABLE or ALTER TABLE statements
   - Update the SchemaVersion insert statement
   - Add rollback instructions at the bottom

3. Test locally:
   ```sql
   -- Execute your migration in SSMS
   -- Verify it works
   -- Test running it twice to ensure idempotency
   ```

### Step 4: Update Schema Files (if creating new objects)
If you created a new table, also create a schema file:
```bash
cp Schema/Tables/TEMPLATE_Table.sql Schema/Tables/Users.sql
# Edit to match your table structure
```

### Step 5: Commit and Push
```bash
git add .
git commit -m "Add Users table for authentication"
git push origin feature/add-user-authentication
```

### Step 6: Create Pull Request
- Go to GitHub and create a Pull Request
- Fill in the description with what changed
- Request review from database administrator
- Address any feedback

## For Database Administrators: Deploying Changes

### Review Process
1. Review the PR for:
   - Correct naming conventions
   - Idempotent migrations
   - Proper error handling
   - Appropriate indexes
   - Rollback instructions

2. Test on development database:
   ```sql
   -- Backup first!
   BACKUP DATABASE [SolastaDB_Dev] TO DISK = 'backup.bak';
   
   -- Execute migration
   -- Verify results
   ```

### Deployment to Production
1. **Schedule maintenance window**
2. **Backup production database**:
   ```sql
   BACKUP DATABASE [SolastaDB_Prod] 
   TO DISK = 'C:\Backups\SolastaDB_Prod_20260107.bak'
   WITH COMPRESSION, STATS = 10;
   ```

3. **Run deployment helper**:
   ```sql
   USE [SolastaDB_Prod];
   GO
   -- Execute: Scripts/Deployment/DeploymentHelper.sql
   -- Review list of applied migrations
   ```

4. **Execute new migrations** in chronological order:
   ```sql
   -- Execute each new migration file
   -- Verify SchemaVersion table is updated after each
   ```

5. **Verify deployment**:
   ```sql
   -- Check SchemaVersion table
   SELECT * FROM [dbo].[SchemaVersion] 
   ORDER BY [AppliedDate] DESC;
   
   -- Verify database objects
   SELECT name, type_desc FROM sys.objects 
   WHERE is_ms_shipped = 0;
   ```

6. **Update documentation** if needed

## Common Tasks

### Check Which Migrations Have Been Applied
```sql
USE [YourDatabase];
GO
SELECT [MigrationName], [AppliedDate], [AppliedBy], [Success]
FROM [dbo].[SchemaVersion]
ORDER BY [AppliedDate] DESC;
```

### Roll Back a Migration
```sql
-- 1. Backup first!
BACKUP DATABASE [YourDatabase] TO DISK = 'rollback_backup.bak';

-- 2. Review the rollback script in the migration file
-- 3. Execute rollback in a transaction
BEGIN TRANSACTION;
    -- Execute rollback commands from migration file
    DELETE FROM [dbo].[SchemaVersion] 
    WHERE [MigrationName] = 'MigrationToRollback';
COMMIT TRANSACTION;
```

### Update an Existing Stored Procedure
1. Edit the file in `Schema/StoredProcedures/`
2. Execute the file (it uses CREATE OR ALTER or DROP/CREATE)
3. No migration needed for stored proc changes (unless changing signature)
4. Commit and push the change

### Add an Index to an Existing Table
1. Create a migration: `YYYYMMDD_HHMM_AddIndexToTableColumn.sql`
2. Use IF NOT EXISTS check for idempotency
3. Update the table definition file in `Schema/Tables/`
4. Test and commit

## Troubleshooting

### Migration Already Applied
If you see "Migration already applied" but changes aren't in database:
```sql
-- Check SchemaVersion table
SELECT * FROM [dbo].[SchemaVersion] WHERE [MigrationName] = 'YourMigration';

-- If needed, delete the record to re-run
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = 'YourMigration';
```

### Migration Failed Mid-Way
If a migration fails:
1. Check the error message
2. Fix the issue in the migration script
3. Delete the SchemaVersion record if it was inserted
4. Re-run the migration

### Merge Conflicts in Migrations
If two people create migrations with similar timestamps:
1. Rename one migration file to have a later timestamp
2. Update the migration name inside the file
3. Resolve the conflict
4. Test both migrations in order

## Best Practices Summary

✅ **DO**:
- Always backup before deploying
- Test migrations locally first
- Make migrations idempotent
- Include rollback instructions
- Use transactions
- Follow naming conventions
- Document your changes

❌ **DON'T**:
- Don't commit credentials or sensitive data
- Don't skip testing
- Don't make unrelated changes in one migration
- Don't modify already-deployed migrations
- Don't forget to update schema files

## Need More Help?

- 📖 Read the full [README.md](README.md)
- 🤝 Check [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines
- 💬 Ask questions in your Pull Request
- 📧 Contact the database team

---

**Ready to contribute? Create your first migration and submit a PR!** 🚀
