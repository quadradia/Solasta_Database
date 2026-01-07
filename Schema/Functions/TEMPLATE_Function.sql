/*
Function: fn_FunctionName
Type: Scalar Function (returns a single value) or Table-Valued Function (returns a table)
Description: Brief description of what this function does
Author: Your Name
Date: YYYY-MM-DD
Parameters:
    @Param1 - Description of parameter 1
Returns: Description of what is returned
Example Usage:
    SELECT [dbo].[fn_FunctionName](@Param1)
*/

-- Example: Scalar Function
IF EXISTS (SELECT * FROM sys.objects WHERE type IN ('FN', 'IF', 'TF') AND name = 'fn_ScalarFunctionName')
    DROP FUNCTION [dbo].[fn_ScalarFunctionName];
GO

CREATE FUNCTION [dbo].[fn_ScalarFunctionName]
(
    @Param1 NVARCHAR(255),
    @Param2 INT = 0
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX);
    
    -- Your function logic here
    -- Example: Concatenate strings or perform calculations
    SET @Result = @Param1 + ' - ' + CAST(@Param2 AS NVARCHAR(10));
    
    RETURN @Result;
END
GO

-- Example: Inline Table-Valued Function (preferred for better performance)
IF EXISTS (SELECT * FROM sys.objects WHERE type IN ('FN', 'IF', 'TF') AND name = 'fn_TableFunctionName')
    DROP FUNCTION [dbo].[fn_TableFunctionName];
GO

CREATE FUNCTION [dbo].[fn_TableFunctionName]
(
    @Param1 NVARCHAR(255),
    @ActiveOnly BIT = 1
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        [Id],
        [Name],
        [Description],
        [IsActive],
        [CreatedDate]
    FROM [dbo].[YourTable]
    WHERE [Name] LIKE '%' + @Param1 + '%'
        AND (@ActiveOnly = 0 OR [IsActive] = 1)
);
GO

-- Add extended properties for documentation
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Brief description of the scalar function',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'FUNCTION', @level1name = N'fn_ScalarFunctionName';
GO

EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Brief description of the table-valued function',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'FUNCTION', @level1name = N'fn_TableFunctionName';
GO

/*
Notes:
- Inline table-valued functions generally perform better than multi-statement functions
- Scalar functions can impact performance when used in WHERE clauses on large tables
- Consider whether a view or stored procedure might be more appropriate
- Functions cannot modify database state (no INSERT, UPDATE, DELETE)
*/
