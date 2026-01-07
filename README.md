# Solasta Database Source Control

This repository is for designing and source controlling all database changes to the Solasta Lighting backend MS SQL Database.

## Repository Structure

```
Solasta_Database/
├── Schema/                      # Database schema objects
│   ├── Tables/                  # Table definitions
│   ├── Views/                   # View definitions
│   ├── StoredProcedures/        # Stored procedure definitions
│   └── Functions/               # Function definitions (scalar and table-valued)
├── Migrations/                  # Versioned migration scripts
├── Scripts/                     # Utility scripts
│   ├── Deployment/              # Deployment helper scripts
│   └── Rollback/                # Rollback scripts for migrations
└── README.md                    # This file
```

## Naming Conventions

### Migration Scripts
- **Format**: `YYYYMMDD_HHMM_DescriptionOfChange.sql`
- **Example**: `20260107_1430_CreateUserTable.sql`
- Each migration should be idempotent where possible
- Include both UP and DOWN (rollback) logic when applicable

### Schema Objects
- **Tables**: `TableName.sql` (PascalCase)
- **Views**: `vw_ViewName.sql` (prefix with `vw_`)
- **Stored Procedures**: `sp_ProcedureName.sql` or `usp_ProcedureName.sql`
- **Functions**: `fn_FunctionName.sql` (prefix with `fn_`)

## Migration Guidelines

### Creating a New Migration

1. **Create the migration file** in the `Migrations/` folder following the naming convention
2. **Include metadata** at the top of each migration:
   ```sql
   /*
   Migration: YYYYMMDD_HHMM_DescriptionOfChange
   Author: Your Name
   Date: YYYY-MM-DD
   Description: Brief description of what this migration does
   Dependencies: List any dependent migrations
   */
   ```

3. **Write idempotent scripts** using IF EXISTS/IF NOT EXISTS checks:
   ```sql
   IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TableName')
   BEGIN
       CREATE TABLE TableName (...)
   END
   ```

4. **Include rollback logic** when possible as comments or in a separate rollback script

### Migration Best Practices

- **One logical change per migration** - Don't mix unrelated changes
- **Test locally first** - Always test migrations on a local database
- **Use transactions** - Wrap DDL statements in transactions where supported
- **Add appropriate indexes** - Consider performance implications
- **Document breaking changes** - Clearly mark any breaking changes
- **Backward compatibility** - Strive for backward-compatible changes when possible

## Deployment Process

1. **Review Changes**: All database changes must be reviewed via Pull Request
2. **Approval**: Changes require approval from database administrators
3. **Testing**: Test migrations on development environment first
4. **Staging**: Deploy to staging environment
5. **Production**: Deploy to production during maintenance window

### Manual Deployment Steps

```sql
-- 1. Backup the database
BACKUP DATABASE [SolastaDB] TO DISK = 'path_to_backup'

-- 2. Run migration scripts in order
-- Execute each migration file in chronological order

-- 3. Verify deployment
-- Run verification queries to ensure changes applied correctly

-- 4. Update schema version tracking
-- Record the migration in the schema version table
```

## Schema Version Tracking

The database includes a schema version tracking table that records all applied migrations. This ensures migrations are applied in order and not repeated.

See `Migrations/00000000_0000_CreateSchemaVersionTable.sql` for the version tracking table definition.

## Working with Schema Objects

### Tables
Store complete CREATE TABLE statements in `Schema/Tables/`. When modifying a table:
1. Create a migration script in `Migrations/` with the ALTER statement
2. Update the table definition file in `Schema/Tables/` to reflect the new structure

### Views, Stored Procedures, and Functions
Store CREATE OR ALTER (or DROP/CREATE) statements for these objects. These can be re-run to update the objects.

## Rollback Procedures

If a migration needs to be rolled back:
1. Check if a rollback script exists in `Scripts/Rollback/`
2. Review the migration script for any DOWN/rollback logic
3. Create and test a rollback script if one doesn't exist
4. Execute rollback during maintenance window
5. Update schema version table to reflect rollback

## Contributing

1. Create a feature branch for your database changes
2. Add migration scripts following the naming conventions
3. Update schema object files as needed
4. Test changes locally
5. Create a Pull Request with detailed description
6. Address review comments
7. Merge after approval

## Tools and Resources

- **SQL Server Management Studio (SSMS)**: Primary tool for development
- **Azure Data Studio**: Alternative cross-platform tool
- **sqlcmd**: Command-line tool for script execution
- **Git**: Version control system

## Support

For questions or issues with database changes, please contact the Solasta Lighting development team.
