/*
Migration: YYYYMMDD_HHMM_DescriptionOfChange
Author: Your Name
Date: YYYY-MM-DD
Description: Detailed description of what this migration accomplishes
Dependencies: List any migrations that must be applied before this one
Rollback: Instructions for rolling back this migration if needed
*/

-- =============================================
-- Migration: [Brief Description]
-- =============================================

-- Set transaction isolation level (optional, based on requirements)
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

BEGIN TRANSACTION;

BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = 'YYYYMMDD_HHMM_DescriptionOfChange';
    DECLARE @StartTime DATETIME2 = GETUTCDATE();
    
    -- Check if migration has already been applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration ' + @MigrationName + ' has already been applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- =============================================
    -- YOUR MIGRATION LOGIC STARTS HERE
    -- =============================================
    
    -- Example: Create a new table
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'YourTableName' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        CREATE TABLE [dbo].[YourTableName] (
            [Id] INT IDENTITY(1,1) PRIMARY KEY,
            [Name] NVARCHAR(255) NOT NULL,
            [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            [ModifiedDate] DATETIME2 NULL
        );
        PRINT 'Table YourTableName created';
    END
    
    -- Example: Add a column to an existing table
    -- IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.YourTableName') AND name = 'NewColumn')
    -- BEGIN
    --     ALTER TABLE [dbo].[YourTableName]
    --     ADD [NewColumn] NVARCHAR(100) NULL;
    --     PRINT 'Column NewColumn added to YourTableName';
    -- END
    
    -- Example: Create an index
    -- IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_YourTableName_ColumnName' AND object_id = OBJECT_ID('dbo.YourTableName'))
    -- BEGIN
    --     CREATE INDEX IX_YourTableName_ColumnName ON [dbo].[YourTableName]([ColumnName]);
    --     PRINT 'Index IX_YourTableName_ColumnName created';
    -- END
    
    -- =============================================
    -- YOUR MIGRATION LOGIC ENDS HERE
    -- =============================================
    
    -- Record this migration in the SchemaVersion table
    DECLARE @ExecutionTimeMs INT = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
    
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, 'Description of what this migration does', @ExecutionTimeMs, 1);
    
    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully in ' + CAST(@ExecutionTimeMs AS NVARCHAR(10)) + 'ms';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    
    -- Log failed migration attempt (truncate error message if too long)
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success])
    VALUES (@MigrationName, 'FAILED: ' + LEFT(@ErrorMessage, 490), 0);
    
    PRINT 'Migration failed: ' + @ErrorMessage;
    
    -- Re-throw the error
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- Instructions for rolling back this migration
-- Be specific about the exact steps needed to undo the changes

-- Example: Drop the table created in this migration
-- BEGIN TRANSACTION;
-- DROP TABLE IF EXISTS [dbo].[YourTableName];
-- DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = 'YYYYMMDD_HHMM_DescriptionOfChange';
-- COMMIT TRANSACTION;
*/
