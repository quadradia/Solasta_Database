# Procedures Directory

This directory contains stored procedure scripts organized by schema.

## Purpose

Stored procedures (SPROCs) are precompiled SQL statements that can accept parameters, execute complex logic, and return multiple result sets. They are ideal for encapsulating business logic in the database.

## Structure

```
Procedures/
├── dbo/
│   ├── sp_CreateUser.sql
│   ├── sp_UpdateOrder.sql
│   └── sp_DeleteProduct.sql
├── app/
│   └── sp_ProcessPayment.sql
├── audit/
│   └── sp_LogActivity.sql
└── reporting/
    └── sp_GenerateReport.sql
```

## Template

```sql
/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: [SchemaName]
 * Name: [ProcedureName]
 * Description: [Brief description of what the procedure does]
 * Parameters: 
 *   @Param1 - [Description]
 *   @Param2 - [Description]
 *   @Result OUTPUT - [Description of output parameter]
 * Returns: [Description of result sets or return value]
 * Dependencies: [List dependent tables/views/procedures]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 * Modified: [YYYY-MM-DD]
 * Example:
 *   EXEC [SchemaName].[ProcedureName] @Param1 = 1, @Param2 = 'Test';
 ******************************************************************************/

-- Drop existing procedure if it exists
IF OBJECT_ID('[SchemaName].[ProcedureName]', 'P') IS NOT NULL
    DROP PROCEDURE [SchemaName].[ProcedureName];
GO

CREATE PROCEDURE [SchemaName].[ProcedureName]
    @Param1 INT,
    @Param2 NVARCHAR(100),
    @Result INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Procedure logic here
        INSERT INTO [SchemaName].[SomeTable] ([Column1], [Column2])
        VALUES (@Param1, @Param2);
        
        SET @Result = SCOPE_IDENTITY();
        
        -- Return result set (optional)
        SELECT 
            [Id],
            [Name],
            [CreatedDate]
        FROM 
            [SchemaName].[SomeTable]
        WHERE 
            [Id] = @Result;
        
        COMMIT TRANSACTION;
        
        RETURN 0; -- Success
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        
        RETURN -1; -- Error
    END CATCH
END
GO
```

## Best Practices

1. **Prefix with sp_** - Use consistent naming convention (optional, but avoid sp_ prefix for SQL Server system procedures)
2. **Use SET NOCOUNT ON** - Improves performance by reducing network traffic
3. **Error handling** - Always use TRY...CATCH blocks for robust error handling
4. **Transactions** - Use transactions for data modification operations
5. **Document thoroughly** - Include usage examples in header comments
6. **Output parameters** - Use for returning single values
7. **Return codes** - Use RETURN for success/error status codes
8. **Avoid cursors** - Use set-based operations when possible
9. **Security** - Be cautious of SQL injection with dynamic SQL
10. **Testing** - Include test scripts with various parameter combinations
