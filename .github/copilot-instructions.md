# GitHub Copilot Instructions for Solasta Database

> **IMPORTANT**: You must also follow the [Copilot Constitution](copilot-constitution.md). The Constitution defines inviolable rules and absolute prohibitions. These instructions define patterns and templates. When in conflict, the Constitution takes precedence.

## Project Overview
This is the Solasta Lighting backend MS SQL Server database repository. All database objects are organized by type and schema, with version-controlled migrations for tracking changes.

## Core Principles

### 1. Repository Structure
- **Two-level organization**: ObjectType → Schema → File
- **Object types**: Tables, Views, Procedures, Functions, Triggers, Indexes, Constraints, Sequences, Types, Grants, Data, Scripts
- **Standard schemas**: `dbo`, `app`, `config`, `audit`, `reporting`
- Each object type has its own top-level directory with schema subdirectories

### 2. Migration System
- **All schema changes** must have a migration in `Migrations/`
- **Naming**: `YYYYMMDD_HHMM_DescriptionOfChange.sql` (use UTC time)
- **Immutable**: Never modify deployed migrations; create new ones instead
- **Idempotent**: All scripts must be safe to run multiple times
- **Tracked**: SchemaVersion table records all applied migrations

### 3. File Organization Pattern
```
Tables/dbo/Users.sql          # Table definition
Views/reporting/vw_Users.sql  # View definition
Procedures/app/sp_GetUser.sql # Stored procedure
Data/dbo/Countries_data.sql   # Seed data
```

## Code Generation Rules

### When Creating Tables
```sql
/*******************************************************************************
 * Object Type: Table
 * Schema: [Schema]
 * Name: [TableName]
 * Description: [Purpose]
 * Author: [Name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

CREATE TABLE [schema].[TableName]
(
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [ModifiedDate] DATETIME2 NULL,
    
    CONSTRAINT PK_[TableName] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
```

**Always include**:
- Proper header with metadata
- Explicit NULL/NOT NULL for all columns
- Primary key constraint with descriptive name
- CreatedDate/ModifiedDate audit columns where appropriate
- GO statement at the end

**Constraint naming**:
- Primary keys: `PK_[TableName]`
- Foreign keys: `FK_[TableName]_[ReferencedTable]`
- Unique: `UQ_[TableName]_[ColumnName]`
- Check: `CK_[TableName]_[ColumnName]`
- Default: `DF_[TableName]_[ColumnName]`

### When Creating Views
```sql
/*******************************************************************************
 * Object Type: View
 * Schema: [Schema]
 * Name: [ViewName]
 * Description: [Purpose]
 * Dependencies: [List tables/views]
 * Author: [Name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

IF OBJECT_ID('[schema].[ViewName]', 'V') IS NOT NULL
    DROP VIEW [schema].[ViewName];
GO

CREATE VIEW [schema].[ViewName]
AS
    SELECT 
        [Column1],
        [Column2]
    FROM 
        [schema].[TableName]
    WHERE 
        [IsActive] = 1;
GO
```

**Always**:
- List dependencies in header
- Use explicit column names (no SELECT *)
- Include DROP IF EXISTS for idempotency
- Consider indexing needs for complex views

### When Creating Stored Procedures
```sql
/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: [Schema]
 * Name: [ProcedureName]
 * Description: [Purpose]
 * Parameters: 
 *   @Param1 - [Description]
 *   @Result OUTPUT - [Description]
 * Returns: [Description]
 * Author: [Name]
 * Created: [YYYY-MM-DD]
 * Example:
 *   EXEC [schema].[ProcedureName] @Param1 = 1;
 ******************************************************************************/

IF OBJECT_ID('[schema].[ProcedureName]', 'P') IS NOT NULL
    DROP PROCEDURE [schema].[ProcedureName];
GO

CREATE PROCEDURE [schema].[ProcedureName]
    @Param1 INT,
    @Result INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Procedure logic
        
        COMMIT TRANSACTION;
        RETURN 0; -- Success
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN -1; -- Error
    END CATCH
END
GO
```

**Always include**:
- SET NOCOUNT ON
- TRY...CATCH error handling
- Transaction wrapping for DML
- Return codes (0 = success, -1 = error)
- Usage example in header

### When Creating Migrations
```sql
/*
Migration: YYYYMMDD_HHMM_DescriptionOfChange
Author: [Name]
Date: YYYY-MM-DD
Description: [Detailed description]
Dependencies: [List prerequisite migrations]
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = 'YYYYMMDD_HHMM_DescriptionOfChange';
    
    -- Check if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] 
               WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Migration logic with existence checks
    IF NOT EXISTS (SELECT * FROM sys.tables 
                   WHERE name = 'TableName' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        CREATE TABLE [dbo].[TableName] (...);
    END
    
    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (@MigrationName, 'Description');
    
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
-- Specific undo steps
DROP TABLE IF EXISTS [dbo].[TableName];
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = 'YYYYMMDD_HHMM_DescriptionOfChange';
*/
```

**Migration requirements**:
- Always check SchemaVersion table first
- Wrap in transaction with TRY...CATCH
- Use existence checks (IF NOT EXISTS)
- Record in SchemaVersion table
- Include rollback script at bottom
- Never modify existing migrations

### When Creating Functions
```sql
/*******************************************************************************
 * Object Type: Function
 * Schema: [Schema]
 * Name: [FunctionName]
 * Description: [Purpose]
 * Parameters: @Param1 - [Description]
 * Returns: [Data type and description]
 * Author: [Name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

IF OBJECT_ID('[schema].[FunctionName]', 'FN') IS NOT NULL
    DROP FUNCTION [schema].[FunctionName];
GO

-- Scalar function
CREATE FUNCTION [schema].[FunctionName]
(
    @Param1 INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
    -- Function logic
    RETURN @Result;
END
GO

-- Or table-valued function
CREATE FUNCTION [schema].[FunctionName]
(
    @Param1 INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT [Column1], [Column2]
    FROM [schema].[TableName]
    WHERE [Id] = @Param1
);
GO
```

## Naming Conventions

### File Names
- Tables: `TableName.sql` (PascalCase)
- Views: `ViewName.sql` or `vw_ViewName.sql`
- Procedures: `ProcedureName.sql` or `sp_ProcedureName.sql` 
- Functions: `FunctionName.sql` or `fn_FunctionName.sql`
- Triggers: `TriggerName.sql` or `tr_TriggerName.sql`
- Data: `TableName_data.sql`
- Migrations: `YYYYMMDD_HHMM_Description.sql`

### SQL Objects
- Use square brackets: `[schema].[ObjectName]`
- Use descriptive constraint names
- Prefix views with `vw_` (optional but recommended)
- Prefix stored procedures with `sp_` or `usp_`
- Prefix functions with `fn_`
- Prefix triggers with `tr_`

## Deployment Order

When suggesting deployment scripts or creating comprehensive deployments:

1. Schemas
2. Types (User-defined)
3. Tables
4. Indexes
5. Constraints
6. Sequences
7. Views
8. Functions
9. Procedures
10. Triggers
11. Grants
12. Data (Seed/Reference)

## Best Practices to Follow

### Idempotency
- Always use IF NOT EXISTS checks
- Use DROP IF EXISTS before CREATE
- Or use CREATE OR ALTER (SQL Server 2016+)
- MERGE for data scripts

### Transactions
- Wrap DDL in transactions for migration scripts
- Use TRY...CATCH for error handling
- ROLLBACK on error, COMMIT on success

### Documentation
- Every file must have a header comment block
- Include author, date, description
- Document dependencies
- Provide usage examples for procedures/functions
- Keep rollback instructions for migrations

### Performance
- Always specify column names explicitly
- Create appropriate indexes
- Avoid SELECT * in production code
- Consider execution plans for complex queries
- Use SET NOCOUNT ON in procedures

### Security
- Use parameterized queries/procedures
- Be cautious with dynamic SQL
- Document required permissions
- Use principle of least privilege

### Data Types
- Use NVARCHAR for Unicode support
- Use DATETIME2 over DATETIME
- Use appropriate precision for DECIMAL
- Avoid deprecated types (TEXT, NTEXT, IMAGE)

## Common Patterns

### Audit Columns
Include in most tables:
```sql
[CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
[CreatedBy] NVARCHAR(50) NULL,
[ModifiedDate] DATETIME2 NULL,
[ModifiedBy] NVARCHAR(50) NULL
```

### Soft Delete
```sql
[IsDeleted] BIT NOT NULL DEFAULT 0,
[DeletedDate] DATETIME2 NULL,
[DeletedBy] NVARCHAR(50) NULL
```

### Foreign Key Pattern
```sql
CONSTRAINT FK_Orders_CustomerId 
    FOREIGN KEY ([CustomerId])
    REFERENCES [dbo].[Customers] ([CustomerId])
    ON DELETE CASCADE -- or NO ACTION
```

### Seed Data with MERGE
```sql
MERGE INTO [schema].[Table] AS target
USING (VALUES (1, 'Value')) AS source ([Id], [Name])
ON target.[Id] = source.[Id]
WHEN MATCHED THEN
    UPDATE SET target.[Name] = source.[Name]
WHEN NOT MATCHED THEN
    INSERT ([Id], [Name]) VALUES (source.[Id], source.[Name]);
```

## What NOT to Do

❌ Never modify deployed migrations
❌ Never use SELECT * in production views/procedures
❌ Never commit without testing locally first
❌ Never mix multiple unrelated changes in one migration
❌ Never skip error handling in procedures
❌ Never hardcode server/database names
❌ Never commit credentials or sensitive data
❌ Never skip the header documentation
❌ Never create objects without proper schema qualification
❌ Never forget to update both migration AND schema files

## When Asked to Add Database Objects

1. **Determine the schema** - Which schema does this belong to? (dbo, app, config, audit, reporting)
2. **Create the migration** - In `Migrations/` with proper timestamp and description
3. **Create the schema file** - In appropriate `ObjectType/schema/` directory
4. **Follow templates** - Use the templates from README files or TEMPLATES.sql
5. **Include tests** - Suggest test queries to validate the changes
6. **Document dependencies** - List what this depends on or what depends on it

## File Placement Logic

Ask yourself:
- What type of object? → Choose directory (Tables, Views, Procedures, etc.)
- Which schema? → Choose subdirectory (dbo, app, config, audit, reporting)
- Is this a change or new? → Migration needed? Update existing file?

## Context Awareness

When suggesting code:
- Consider existing patterns in the codebase
- Maintain consistency with current naming conventions
- Respect the established schema organization
- Follow the migration versioning system
- Think about backward compatibility
- Consider database dependencies and deployment order

## Response Format

When asked to create database objects:
1. Show the migration file content
2. Show the schema file content (if applicable)
3. Explain where each file should be placed
4. Provide test queries
5. List any dependencies or prerequisites
6. Suggest rollback steps

## Testing Reminders

Always remind users to:
- Test migrations locally before committing
- Run migrations twice to verify idempotency
- Check SchemaVersion table after running
- Verify objects exist as expected
- Test rollback procedures
- Review execution plans for performance
