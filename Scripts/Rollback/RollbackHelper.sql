/*
Rollback Script: Rollback Helper
Description: Helps identify and rollback specific migrations
Author: Database Team
Date: 2026-01-07

USAGE:
    1. Review the list of applied migrations
    2. Identify the migration to rollback
    3. Check if a rollback script exists in Scripts/Rollback/
    4. Execute the appropriate rollback script
    5. Update the SchemaVersion table to reflect the rollback

WARNING: Rollbacks can be destructive. Always backup the database before rolling back!
*/

-- =============================================
-- Configuration
-- =============================================
DECLARE @ServerName NVARCHAR(255) = @@SERVERNAME;
DECLARE @DatabaseName NVARCHAR(255) = DB_NAME();
DECLARE @CurrentDate DATETIME2 = GETUTCDATE();

PRINT '========================================';
PRINT 'Solasta Database Rollback Helper';
PRINT '========================================';
PRINT 'Server: ' + @ServerName;
PRINT 'Database: ' + @DatabaseName;
PRINT 'Execution Time: ' + CONVERT(NVARCHAR(30), @CurrentDate, 120);
PRINT '========================================';
PRINT '';

-- =============================================
-- Check if SchemaVersion table exists
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SchemaVersion' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'ERROR: SchemaVersion table does not exist!';
    PRINT 'Cannot perform rollback without version tracking.';
    PRINT '';
    RETURN;
END

-- =============================================
-- Display Applied Migrations (Most Recent First)
-- =============================================
PRINT 'Applied Migrations (Most Recent First):';
PRINT '---------------------------------------';

SELECT TOP 20
    [Id],
    [MigrationName],
    [AppliedDate],
    [AppliedBy],
    [Description],
    [Success]
FROM [dbo].[SchemaVersion]
ORDER BY [AppliedDate] DESC, [Id] DESC;

PRINT '';
PRINT '========================================';
PRINT 'Rollback Instructions:';
PRINT '========================================';
PRINT '1. BACKUP THE DATABASE FIRST!';
PRINT '   BACKUP DATABASE [' + @DatabaseName + '] TO DISK = ''path_to_backup.bak''';
PRINT '';
PRINT '2. Identify the migration to rollback from the list above';
PRINT '';
PRINT '3. Check the migration file for ROLLBACK SCRIPT section';
PRINT '   - Location: Migrations/[MigrationName].sql';
PRINT '   - Look at the bottom of the file for rollback logic';
PRINT '';
PRINT '4. Execute the rollback logic in a transaction:';
PRINT '   BEGIN TRANSACTION;';
PRINT '   -- Execute rollback commands here';
PRINT '   -- Verify the rollback worked';
PRINT '   COMMIT TRANSACTION; -- Or ROLLBACK TRANSACTION if issues';
PRINT '';
PRINT '5. Update the SchemaVersion table:';
PRINT '   DELETE FROM [dbo].[SchemaVersion]';
PRINT '   WHERE [MigrationName] = ''MigrationNameToRollback'';';
PRINT '';
PRINT '6. Verify the database state is correct';
PRINT '';
PRINT '========================================';

-- =============================================
-- Example: Rollback Template
-- =============================================
PRINT '';
PRINT 'Example Rollback Template:';
PRINT '-------------------------';
PRINT '
-- Step 1: Backup
BACKUP DATABASE [' + @DatabaseName + '] 
TO DISK = ''<YOUR_BACKUP_PATH>\' + @DatabaseName + '_BeforeRollback_' + FORMAT(@CurrentDate, 'yyyyMMdd_HHmm') + '.bak'';

-- Step 2: Execute rollback in transaction
BEGIN TRANSACTION;

    -- Your rollback logic here
    -- Example: DROP TABLE IF EXISTS [dbo].[TableName];
    
    -- Remove migration record
    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = ''YYYYMMDD_HHMM_MigrationName'';
    
    -- Verify changes
    SELECT * FROM [dbo].[SchemaVersion] ORDER BY [AppliedDate] DESC;
    
    -- If everything looks good:
    COMMIT TRANSACTION;
    -- If issues found:
    -- ROLLBACK TRANSACTION;

';

PRINT '========================================';
PRINT 'Rollback helper completed.';
PRINT '========================================';
