# Triggers Directory

This directory contains trigger scripts organized by schema.

## Purpose

Triggers are special stored procedures that automatically execute when specific events occur on a table or view. They are commonly used for auditing, enforcing business rules, and maintaining data integrity.

## Structure

```
Triggers/
├── dbo/
│   ├── tr_Users_AfterInsert.sql
│   └── tr_Orders_AfterUpdate.sql
├── audit/
│   └── tr_AuditLog_InsteadOfDelete.sql
└── app/
    └── tr_Settings_BeforeUpdate.sql
```

## Template - DML Trigger (SQL Server)

```sql
/*******************************************************************************
 * Object Type: Trigger
 * Schema: [SchemaName]
 * Name: [TriggerName]
 * Type: [AFTER INSERT | AFTER UPDATE | AFTER DELETE | INSTEAD OF]
 * Table: [SchemaName].[TableName]
 * Description: [Brief description of what the trigger does]
 * Dependencies: [List dependent tables/procedures]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 * Modified: [YYYY-MM-DD]
 ******************************************************************************/

-- Drop existing trigger if it exists
IF OBJECT_ID('[SchemaName].[TriggerName]', 'TR') IS NOT NULL
    DROP TRIGGER [SchemaName].[TriggerName];
GO

CREATE TRIGGER [SchemaName].[TriggerName]
ON [SchemaName].[TableName]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    BEGIN TRY
        -- Trigger logic here
        -- Access inserted rows via 'inserted' pseudo-table
        -- Access deleted rows via 'deleted' pseudo-table
        
        -- Example: Audit logging
        INSERT INTO [audit].[AuditLog] 
        (
            [TableName],
            [Action],
            [RecordId],
            [OldValue],
            [NewValue],
            [ModifiedDate],
            [ModifiedBy]
        )
        SELECT 
            '[TableName]' AS [TableName],
            CASE 
                WHEN EXISTS(SELECT 1 FROM deleted) AND EXISTS(SELECT 1 FROM inserted) 
                    THEN 'UPDATE'
                WHEN EXISTS(SELECT 1 FROM inserted) 
                    THEN 'INSERT'
                ELSE 'DELETE'
            END AS [Action],
            COALESCE(i.[Id], d.[Id]) AS [RecordId],
            d.[ColumnName] AS [OldValue],
            i.[ColumnName] AS [NewValue],
            GETUTCDATE() AS [ModifiedDate],
            SUSER_SNAME() AS [ModifiedBy]
        FROM 
            inserted i
            FULL OUTER JOIN deleted d ON i.[Id] = d.[Id];
            
    END TRY
    BEGIN CATCH
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
```

## Template - PostgreSQL Trigger

```sql
/*******************************************************************************
 * Object Type: Trigger Function + Trigger
 * Schema: [SchemaName]
 * Name: [TriggerName]
 * Type: [BEFORE | AFTER | INSTEAD OF] [INSERT | UPDATE | DELETE]
 * Table: [SchemaName].[TableName]
 * Description: [Brief description]
 ******************************************************************************/

-- Create trigger function
CREATE OR REPLACE FUNCTION [SchemaName].[TriggerFunctionName]()
RETURNS TRIGGER AS $$
BEGIN
    -- Trigger logic here
    -- NEW record contains new row data (for INSERT/UPDATE)
    -- OLD record contains old row data (for UPDATE/DELETE)
    
    -- Example: Set timestamp on update
    NEW.modified_date := CURRENT_TIMESTAMP;
    
    RETURN NEW; -- or OLD for AFTER triggers
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS [TriggerName] ON [SchemaName].[TableName];
CREATE TRIGGER [TriggerName]
    BEFORE UPDATE ON [SchemaName].[TableName]
    FOR EACH ROW
    EXECUTE FUNCTION [SchemaName].[TriggerFunctionName]();
```

## Best Practices

1. **Prefix with tr_** - Use consistent naming convention
2. **Keep lightweight** - Triggers should execute quickly
3. **Avoid recursion** - Be careful of triggers firing other triggers
4. **Error handling** - Include proper error handling (especially in SQL Server)
5. **SET NOCOUNT ON** - Reduces network traffic (SQL Server)
6. **Document side effects** - Clearly document what the trigger modifies
7. **Test thoroughly** - Test with various data scenarios
8. **Consider alternatives** - Check constraints or application logic may be better
9. **Use inserted/deleted** - Properly handle the pseudo-tables (SQL Server)
10. **Avoid complex logic** - Move complex operations to stored procedures
