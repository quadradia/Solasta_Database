# Functions Directory

This directory contains user-defined function scripts organized by schema.

## Purpose

Functions are reusable code blocks that accept parameters, perform operations, and return a value. They can return scalar values or table results.

## Structure

```
Functions/
├── dbo/
│   ├── fn_CalculateDiscount.sql
│   └── fn_GetUserRole.sql
├── app/
│   └── fn_ValidateEmail.sql
└── reporting/
    └── fn_GetDateRange.sql
```

## Template - Scalar Function

```sql
/*******************************************************************************
 * Object Type: Scalar Function
 * Schema: [SchemaName]
 * Name: [FunctionName]
 * Description: [Brief description of what the function does]
 * Parameters: 
 *   @Param1 - [Description]
 *   @Param2 - [Description]
 * Returns: [Data type and description]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 * Modified: [YYYY-MM-DD]
 ******************************************************************************/

-- Drop existing function if it exists
IF OBJECT_ID('[SchemaName].[FunctionName]', 'FN') IS NOT NULL
    DROP FUNCTION [SchemaName].[FunctionName];
GO

CREATE FUNCTION [SchemaName].[FunctionName]
(
    @Param1 INT,
    @Param2 NVARCHAR(100)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Result DECIMAL(18,2);
    
    -- Function logic here
    SELECT @Result = [CalculatedValue]
    FROM [SchemaName].[SomeTable]
    WHERE [Id] = @Param1
        AND [Name] = @Param2;
    
    RETURN ISNULL(@Result, 0);
END
GO
```

## Template - Table-Valued Function

```sql
/*******************************************************************************
 * Object Type: Table-Valued Function
 * Schema: [SchemaName]
 * Name: [FunctionName]
 * Description: [Brief description of what the function returns]
 * Parameters: 
 *   @Param1 - [Description]
 * Returns: Table with columns [list columns]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

-- Drop existing function if it exists
IF OBJECT_ID('[SchemaName].[FunctionName]', 'TF') IS NOT NULL
    DROP FUNCTION [SchemaName].[FunctionName];
GO

CREATE FUNCTION [SchemaName].[FunctionName]
(
    @Param1 INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        [Id],
        [Name],
        [Description],
        [CreatedDate]
    FROM 
        [SchemaName].[SomeTable]
    WHERE 
        [SomeColumn] = @Param1
);
GO
```

## Best Practices

1. **Prefix with fn_** - Use consistent naming convention (optional)
2. **Document parameters** - Clearly describe all inputs and outputs
3. **Error handling** - Use appropriate NULL handling and validation
4. **Keep simple** - Complex logic may be better in stored procedures
5. **Avoid side effects** - Functions should not modify database state
6. **Performance** - Be mindful of function calls in WHERE clauses
