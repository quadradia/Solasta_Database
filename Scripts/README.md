# Scripts Directory

This directory contains deployment and utility scripts.

## Purpose

The Scripts folder houses database deployment scripts, rollback scripts, and other utility scripts that help manage the database lifecycle.

## Structure

```
Scripts/
├── deploy/           # Deployment scripts
│   ├── 001_initial_schema.sql
│   ├── 002_add_user_tables.sql
│   └── 003_add_audit_triggers.sql
└── rollback/         # Rollback scripts
    ├── 001_initial_schema.sql
    ├── 002_add_user_tables.sql
    └── 003_add_audit_triggers.sql
```

## Deploy Scripts

Deployment scripts are numbered sequentially and executed in order. Each script should:
- Be idempotent (can run multiple times safely)
- Include a corresponding rollback script
- Document what changes it makes
- Include validation checks

### Template - Deploy Script

```sql
/*******************************************************************************
 * Script: [001_ScriptName.sql]
 * Type: Deployment
 * Description: [Brief description of changes]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 * Dependencies: [List of prior scripts that must run first]
 ******************************************************************************/

-- Check if script has already been executed
IF NOT EXISTS (
    SELECT 1 FROM [config].[DeploymentHistory] 
    WHERE [ScriptName] = '001_ScriptName.sql'
)
BEGIN
    PRINT 'Starting deployment: 001_ScriptName.sql';
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Add your deployment code here
        -- Examples:
        -- 1. Create tables
        -- 2. Add columns
        -- 3. Create indexes
        -- 4. Insert seed data
        
        -- Log successful deployment
        INSERT INTO [config].[DeploymentHistory] 
        ([ScriptName], [ExecutedDate], [Status])
        VALUES 
        ('001_ScriptName.sql', GETUTCDATE(), 'Success');
        
        COMMIT TRANSACTION;
        PRINT 'Successfully deployed: 001_ScriptName.sql';
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error deploying 001_ScriptName.sql: ' + @ErrorMessage;
        
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
ELSE
BEGIN
    PRINT 'Script 001_ScriptName.sql has already been executed.';
END
GO
```

## Rollback Scripts

Rollback scripts reverse the changes made by deployment scripts. Each deployment script should have a corresponding rollback.

### Template - Rollback Script

```sql
/*******************************************************************************
 * Script: [001_ScriptName.sql]
 * Type: Rollback
 * Description: [Brief description of what this rollback reverses]
 * Reverses: deploy/001_ScriptName.sql
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

PRINT 'Starting rollback: 001_ScriptName.sql';

BEGIN TRANSACTION;

BEGIN TRY
    -- Add your rollback code here
    -- Examples:
    -- 1. Drop tables
    -- 2. Remove columns
    -- 3. Drop indexes
    -- 4. Delete data
    
    -- Remove from deployment history
    DELETE FROM [config].[DeploymentHistory] 
    WHERE [ScriptName] = '001_ScriptName.sql';
    
    COMMIT TRANSACTION;
    PRINT 'Successfully rolled back: 001_ScriptName.sql';
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT 'Error rolling back 001_ScriptName.sql: ' + @ErrorMessage;
    
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH
GO
```

## Deployment History Table

Create a table to track script execution:

```sql
CREATE TABLE [config].[DeploymentHistory]
(
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ScriptName] NVARCHAR(255) NOT NULL,
    [ExecutedDate] DATETIME2 NOT NULL,
    [Status] NVARCHAR(50) NOT NULL,
    [ExecutedBy] NVARCHAR(128) NOT NULL DEFAULT SUSER_SNAME(),
    
    CONSTRAINT PK_DeploymentHistory PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_DeploymentHistory_ScriptName UNIQUE ([ScriptName])
);
```

## Best Practices

1. **Number sequentially** - Use 001, 002, 003, etc.
2. **Descriptive names** - Make it clear what the script does
3. **Idempotent scripts** - Scripts should be safe to run multiple times
4. **Test rollbacks** - Always test rollback scripts in a dev environment
5. **Track execution** - Use a DeploymentHistory table to track what's been run
6. **Include validation** - Check prerequisites before executing
7. **Document dependencies** - Note which scripts must run before this one
8. **Atomic changes** - Use transactions where possible
9. **Backup first** - Always backup before running scripts in production
10. **Version control** - Never modify existing scripts, create new ones
