/*
Deployment Script: Deploy All Pending Migrations
Description: Displays information about applied migrations and provides deployment guidance
Author: Database Team
Date: 2026-01-07

USAGE:
    1. Execute this script in SQL Server Management Studio to see applied migrations
    2. Review the output to identify pending migrations
    3. Manually execute pending migration scripts in chronological order
    4. Verify each migration completes successfully
*/

-- =============================================
-- Configuration
-- =============================================
DECLARE @ServerName NVARCHAR(255) = @@SERVERNAME;
DECLARE @DatabaseName NVARCHAR(255) = DB_NAME();
DECLARE @CurrentDate DATETIME2 = GETUTCDATE();

PRINT '========================================';
PRINT 'Solasta Database Deployment Script';
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
    PRINT 'WARNING: SchemaVersion table does not exist!';
    PRINT 'Please run migration 00000000_0000_CreateSchemaVersionTable.sql first';
    PRINT '';
    RETURN;
END

-- =============================================
-- Display Applied Migrations
-- =============================================
PRINT 'Currently Applied Migrations:';
PRINT '----------------------------';

SELECT 
    [Id],
    [MigrationName],
    [AppliedDate],
    [AppliedBy],
    [Success]
FROM [dbo].[SchemaVersion]
ORDER BY [AppliedDate];

PRINT '';
PRINT '========================================';
PRINT 'Manual Migration Steps:';
PRINT '========================================';
PRINT '1. Navigate to the Migrations folder';
PRINT '2. Execute each .sql file in chronological order (by filename)';
PRINT '3. Skip any migrations already listed above';
PRINT '4. Verify each migration completes successfully before proceeding';
PRINT '';
PRINT 'Migrations should be executed in this order:';
PRINT '  - 00000000_0000_CreateSchemaVersionTable.sql (if not already applied)';
PRINT '  - YYYYMMDD_HHMM_*.sql files in chronological order';
PRINT '';

-- =============================================
-- Display Database Statistics
-- =============================================
PRINT '========================================';
PRINT 'Database Statistics:';
PRINT '========================================';

SELECT 
    'Tables' AS [ObjectType],
    COUNT(*) AS [Count]
FROM sys.tables
WHERE is_ms_shipped = 0

UNION ALL

SELECT 
    'Views' AS [ObjectType],
    COUNT(*) AS [Count]
FROM sys.views
WHERE is_ms_shipped = 0

UNION ALL

SELECT 
    'Stored Procedures' AS [ObjectType],
    COUNT(*) AS [Count]
FROM sys.procedures
WHERE is_ms_shipped = 0

UNION ALL

SELECT 
    'Functions' AS [ObjectType],
    COUNT(*) AS [Count]
FROM sys.objects
WHERE type IN ('FN', 'IF', 'TF')
    AND is_ms_shipped = 0;

PRINT '';
PRINT 'Deployment information displayed successfully.';
PRINT '========================================';
