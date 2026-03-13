/*
Migration: 20260313_0846_Baseline_ObjectsDeployed
Author: Admin
Date: 2026-03-13
Description: Records the initial baseline import of all database objects into the
             SchemaVersion tracking table. This migration MUST be run AFTER the
             deployment script has been executed:

               Scripts\deploy\Deploy_Baseline.ps1 -ServerInstance <server> -Database <db>

             The deployment script deploys the following objects from the
             individual schema files in the correct dependency order:

               Tables     : 90 files across 11 schemas
               Views      : 37 files across 3 schemas (ACC, RSU, UTL)
               Functions  : 25 files across 6 schemas (ACC, CNS, dbo, GEN, RSU, UTL)
               Procedures : 130 files across 4 schemas (dbo, GEN, RSU, UTL)
               Total      : 282 database objects

             This migration validates that objects were deployed by checking for
             the presence of key representative objects before recording success.

Dependencies: 00000000_0000_CreateSchemaVersionTable
              20260313_0845_Baseline_Schemas
              (Deploy_Baseline.ps1 must have been run first)
*/

BEGIN TRANSACTION;

BEGIN TRY

    DECLARE @MigrationName NVARCHAR(255) = '20260313_0846_Baseline_ObjectsDeployed';
    DECLARE @StartTime DATETIME2 = GETUTCDATE();

    -- Check if migration has already been applied
    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration ' + @MigrationName + ' has already been applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- =============================================
    -- Validate that baseline objects were deployed
    -- Check representative objects from each object type
    -- =============================================

    -- Validate schemas exist
    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'ACC')
        RAISERROR('Schema ACC does not exist. Run 20260313_0845_Baseline_Schemas.sql first.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'RSU')
        RAISERROR('Schema RSU does not exist. Run 20260313_0845_Baseline_Schemas.sql first.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'MAC')
        RAISERROR('Schema MAC does not exist. Run 20260313_0845_Baseline_Schemas.sql first.', 16, 1);

    -- Validate representative tables (one per key schema)
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'Dealers' AND schema_id = SCHEMA_ID('ACC'))
        RAISERROR('Table ACC.Dealers does not exist. Run Deploy_Baseline.ps1 before applying this migration.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'UserResources' AND schema_id = SCHEMA_ID('RSU'))
        RAISERROR('Table RSU.UserResources does not exist. Run Deploy_Baseline.ps1 before applying this migration.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'PoliticalTimeZones' AND schema_id = SCHEMA_ID('MAC'))
        RAISERROR('Table MAC.PoliticalTimeZones does not exist. Run Deploy_Baseline.ps1 before applying this migration.', 16, 1);

    -- Validate representative views
    IF NOT EXISTS (SELECT 1
FROM sys.views
WHERE name = 'vwGen_UserResources' AND schema_id = SCHEMA_ID('RSU'))
        RAISERROR('View RSU.vwGen_UserResources does not exist. Run Deploy_Baseline.ps1 before applying this migration.', 16, 1);

    -- Validate representative functions
    IF OBJECT_ID('ACC.fxGetUserInfoByUserIdTABLE', 'TF') IS NULL
    AND OBJECT_ID('ACC.fxGetUserInfoByUserIdTABLE', 'IF') IS NULL
    AND OBJECT_ID('ACC.fxGetUserInfoByUserIdTABLE', 'FN') IS NULL
        RAISERROR('Function ACC.fxGetUserInfoByUserIdTABLE does not exist. Run Deploy_Baseline.ps1 before applying this migration.', 16, 1);

    -- Validate representative stored procedures
    IF OBJECT_ID('RSU.spAutoGen_UserResources_GetByUserId', 'P') IS NULL
    AND OBJECT_ID('RSU.spAutoGen_UserResources_GetByUserId', 'PC') IS NULL
    BEGIN
    -- Check if ANY RSU procedures exist (the specific proc name may differ)
    IF NOT EXISTS (SELECT 1
    FROM sys.procedures
    WHERE schema_id = SCHEMA_ID('RSU'))
            RAISERROR('No procedures found in RSU schema. Run Deploy_Baseline.ps1 before applying this migration.', 16, 1);
END

    PRINT 'Validation passed: baseline objects confirmed present.';

    -- =============================================
    -- Record a summary count of deployed objects
    -- =============================================
    DECLARE @TableCount      INT = (SELECT COUNT(*)
FROM sys.tables
WHERE is_ms_shipped = 0);
    DECLARE @ViewCount       INT = (SELECT COUNT(*)
FROM sys.views
WHERE is_ms_shipped = 0);
    DECLARE @ProcedureCount  INT = (SELECT COUNT(*)
FROM sys.procedures
WHERE is_ms_shipped = 0);
    DECLARE @FunctionCount   INT = (SELECT COUNT(*)
FROM sys.objects
WHERE type IN ('FN','IF','TF') AND is_ms_shipped = 0);

    PRINT 'Deployed object summary:';
    PRINT '  Tables:     ' + CAST(@TableCount     AS NVARCHAR(10));
    PRINT '  Views:      ' + CAST(@ViewCount      AS NVARCHAR(10));
    PRINT '  Procedures: ' + CAST(@ProcedureCount AS NVARCHAR(10));
    PRINT '  Functions:  ' + CAST(@FunctionCount  AS NVARCHAR(10));

    -- =============================================
    -- Record migration in SchemaVersion
    -- =============================================
    DECLARE @ExecutionTimeMs INT = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
    DECLARE @Description NVARCHAR(500) =
        'Baseline import: ' +
        CAST(@TableCount AS NVARCHAR(5)) + ' tables, ' +
        CAST(@ViewCount AS NVARCHAR(5)) + ' views, ' +
        CAST(@ProcedureCount AS NVARCHAR(5)) + ' procedures, ' +
        CAST(@FunctionCount AS NVARCHAR(5)) + ' functions deployed via Deploy_Baseline.ps1';

    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description], [ExecutionTimeMs], [Success])
VALUES
    (@MigrationName, @Description, @ExecutionTimeMs, 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully in ' + CAST(@ExecutionTimeMs AS NVARCHAR(10)) + 'ms';

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage  NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT            = ERROR_SEVERITY();
    DECLARE @ErrorState    INT            = ERROR_STATE();

    PRINT 'ERROR in migration 20260313_0846_Baseline_ObjectsDeployed: ' + @ErrorMessage;
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

END CATCH
GO

/*
ROLLBACK SCRIPT:
-- This migration is a record only. Rolling it back does not remove objects.
-- To remove deployed objects, use the rollback procedures in Scripts\Rollback\RollbackHelper.sql

DELETE FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = '20260313_0846_Baseline_ObjectsDeployed';
*/
