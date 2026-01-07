/*
Stored Procedure: sp_ProcedureName or usp_ProcedureName
Description: Brief description of what this stored procedure does
Author: Your Name
Date: YYYY-MM-DD
Parameters:
    @Param1 - Description of parameter 1
    @Param2 - Description of parameter 2
Returns: Description of what is returned
Example Usage:
    EXEC [dbo].[usp_ProcedureName] @Param1 = 'value', @Param2 = 123
*/

-- Drop and recreate (or use CREATE OR ALTER in SQL Server 2016+)
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_ProcedureName')
    DROP PROCEDURE [dbo].[usp_ProcedureName];
GO

CREATE PROCEDURE [dbo].[usp_ProcedureName]
    @Param1 NVARCHAR(255),
    @Param2 INT = 0,  -- Default value example
    @Param3 BIT = 1 OUTPUT  -- Output parameter example
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate input parameters
        IF @Param1 IS NULL OR @Param1 = ''
        BEGIN
            RAISERROR('Parameter @Param1 cannot be null or empty', 16, 1);
            RETURN -1;
        END
        
        -- Your business logic here
        -- Example: SELECT or UPDATE statements
        SELECT 
            [Id],
            [Name],
            [Description]
        FROM [dbo].[YourTable]
        WHERE [Name] LIKE '%' + @Param1 + '%'
            AND [IsActive] = 1;
        
        -- Set output parameter if used
        SET @Param3 = 1;
        
        COMMIT TRANSACTION;
        RETURN 0;  -- Success
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        -- Log error or re-throw
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;  -- Error
    END CATCH
END
GO

-- Add extended property for documentation
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Brief description of what this stored procedure does',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'PROCEDURE', @level1name = N'usp_ProcedureName';
GO
