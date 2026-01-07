# Quick Reference Guide

This guide provides a quick overview of how to work with the Solasta Database repository structure.

## Common Tasks

### 1. Adding a New Table

```bash
# Navigate to the Tables directory and appropriate schema
cd Tables/dbo/

# Create a new SQL file (e.g., Users.sql)
# Use the template from Tables/README.md or TEMPLATES.sql
```

Example table script:
```sql
CREATE TABLE [dbo].[Users]
(
    [UserId] INT IDENTITY(1,1) NOT NULL,
    [Username] NVARCHAR(50) NOT NULL,
    [Email] NVARCHAR(320) NOT NULL,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED ([UserId] ASC),
    CONSTRAINT UQ_Users_Username UNIQUE ([Username]),
    CONSTRAINT UQ_Users_Email UNIQUE ([Email])
);
GO
```

### 2. Adding a Stored Procedure

```bash
cd Procedures/dbo/
# Create sp_GetUserById.sql
```

Example procedure:
```sql
CREATE PROCEDURE [dbo].[sp_GetUserById]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        [UserId],
        [Username],
        [Email],
        [CreatedDate]
    FROM 
        [dbo].[Users]
    WHERE 
        [UserId] = @UserId;
END
GO
```

### 3. Adding a View

```bash
cd Views/reporting/
# Create vw_ActiveUsers.sql
```

Example view:
```sql
CREATE VIEW [reporting].[vw_ActiveUsers]
AS
    SELECT 
        [UserId],
        [Username],
        [Email],
        [CreatedDate]
    FROM 
        [dbo].[Users]
    WHERE 
        [IsActive] = 1;
GO
```

### 4. Adding Seed Data

```bash
cd Data/dbo/
# Create Countries_data.sql
```

Example data script:
```sql
MERGE INTO [dbo].[Countries] AS target
USING (
    VALUES 
        (1, N'United States', N'US'),
        (2, N'Canada', N'CA'),
        (3, N'Mexico', N'MX')
) AS source ([CountryId], [Name], [Code])
ON target.[CountryId] = source.[CountryId]
WHEN MATCHED THEN
    UPDATE SET 
        target.[Name] = source.[Name],
        target.[Code] = source.[Code]
WHEN NOT MATCHED THEN
    INSERT ([CountryId], [Name], [Code])
    VALUES (source.[CountryId], source.[Name], source.[Code]);
GO
```

### 5. Creating a New Schema

```bash
cd Schemas/
# Create a new schema directory
mkdir myschema

cd myschema/
# Create schema.sql
```

Example schema script:
```sql
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'myschema')
BEGIN
    EXEC('CREATE SCHEMA [myschema]');
END
GO
```

Then create subdirectories in other object type folders:
```bash
mkdir Tables/myschema
mkdir Views/myschema
mkdir Procedures/myschema
# etc...
```

## File Naming Conventions

| Object Type | Naming Pattern | Example |
|------------|----------------|---------|
| Table | `TableName.sql` | `Users.sql` |
| View | `ViewName.sql` or `vw_ViewName.sql` | `vw_ActiveUsers.sql` |
| Procedure | `ProcedureName.sql` or `sp_ProcedureName.sql` | `sp_GetUserById.sql` |
| Function | `FunctionName.sql` or `fn_FunctionName.sql` | `fn_CalculateDiscount.sql` |
| Trigger | `TriggerName.sql` or `tr_TriggerName.sql` | `tr_Users_AfterInsert.sql` |
| Index | `IX_TableName_Columns.sql` | `IX_Users_Email.sql` |
| Constraint | `ConstraintType_TableName_Column.sql` | `FK_Orders_CustomerId.sql` |
| Sequence | `seq_SequenceName.sql` | `seq_OrderNumbers.sql` |
| Type | `TypeName.sql` | `EmailAddress.sql` |
| Data | `TableName_data.sql` | `Countries_data.sql` |

## Directory Cheat Sheet

```
Object Type          Directory Path           Schema Subdir?
─────────────────────────────────────────────────────────────
Schema Definition    Schemas/                 Yes
Tables               Tables/                  Yes
Views                Views/                   Yes
Functions            Functions/               Yes
Stored Procedures    Procedures/              Yes
Triggers             Triggers/                Yes
Indexes              Indexes/                 Yes
Constraints          Constraints/             Yes
Sequences            Sequences/               Yes
User-Defined Types   Types/                   Yes
Permission Grants    Grants/                  Yes
Seed/Reference Data  Data/                    Yes
Deployment Scripts   Scripts/deploy/          No
Rollback Scripts     Scripts/rollback/        No
```

## SQL Header Template

Copy this header for every SQL file:

```sql
/*******************************************************************************
 * Object Type: [Table|View|Procedure|Function|Trigger|etc.]
 * Schema: [SchemaName]
 * Name: [ObjectName]
 * Description: [Brief description of purpose]
 * Dependencies: [List any dependent objects, if applicable]
 * Author: [Your Name]
 * Created: [YYYY-MM-DD]
 * Modified: [YYYY-MM-DD when changed]
 ******************************************************************************/
```

## Deployment Order

When deploying to a fresh database, execute scripts in this order:

1. ✅ Schemas
2. ✅ Types
3. ✅ Tables
4. ✅ Indexes
5. ✅ Constraints
6. ✅ Sequences
7. ✅ Views
8. ✅ Functions
9. ✅ Procedures
10. ✅ Triggers
11. ✅ Grants
12. ✅ Data

## Common SQL Patterns

### Idempotent DROP Pattern

```sql
-- SQL Server
IF OBJECT_ID('[SchemaName].[ObjectName]', 'U') IS NOT NULL  -- U=Table
    DROP TABLE [SchemaName].[ObjectName];
GO

IF OBJECT_ID('[SchemaName].[ObjectName]', 'V') IS NOT NULL  -- V=View
    DROP VIEW [SchemaName].[ObjectName];
GO

IF OBJECT_ID('[SchemaName].[ObjectName]', 'P') IS NOT NULL  -- P=Procedure
    DROP PROCEDURE [SchemaName].[ObjectName];
GO

-- PostgreSQL
DROP TABLE IF EXISTS [SchemaName].[ObjectName];
DROP VIEW IF EXISTS [SchemaName].[ObjectName];
DROP FUNCTION IF EXISTS [SchemaName].[ObjectName];
```

### Transaction Pattern

```sql
BEGIN TRANSACTION;

BEGIN TRY
    -- Your SQL statements here
    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH
GO
```

## Git Workflow

```bash
# After creating or modifying SQL files

# Check what's changed
git status

# Add specific files
git add Tables/dbo/Users.sql
git add Procedures/dbo/sp_GetUserById.sql

# Or add all changes
git add .

# Commit with descriptive message
git commit -m "Add Users table and GetUserById procedure"

# Push to remote
git push
```

## Tips

- 🔍 **Look for examples**: Check existing files in similar directories for patterns
- 📖 **Read the READMEs**: Each directory has a README with detailed templates
- 📝 **Use TEMPLATES.sql**: Quick reference for all object types in one file
- 🔄 **Make scripts idempotent**: Scripts should be safe to run multiple times
- 📋 **Document everything**: Future you (and your team) will thank you
- 🧪 **Test in dev first**: Always test scripts in development before production
- 🤝 **Follow conventions**: Consistency makes the codebase easier to maintain

## Getting Help

1. Check **[README.md](README.md)** for overview
2. Read **[STRUCTURE.md](STRUCTURE.md)** for detailed guidelines
3. Review directory-specific READMEs for templates
4. Look at **[TEMPLATES.sql](TEMPLATES.sql)** for quick reference
5. Examine existing scripts for patterns
6. Contact the database team for questions

## Useful Commands

```bash
# Find all SQL files for a specific table
find . -name "*Users*.sql"

# Search for a specific object in SQL files
grep -r "CREATE TABLE.*Users" .

# List all procedures in dbo schema
ls -la Procedures/dbo/

# Count files by type
find Tables -name "*.sql" | wc -l
```

---

**Remember**: When in doubt, look at existing examples in the repository!
