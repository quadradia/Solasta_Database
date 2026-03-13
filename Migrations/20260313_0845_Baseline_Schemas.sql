/*
Migration: 20260313_0845_Baseline_Schemas
Author: Admin
Date: 2026-03-13
Description: Creates all non-default schemas required by the SOL_MAIN database.
             This is the first migration in the initial baseline import sequence.
             Must be run before 20260313_0846_Baseline_ObjectsDeployed.

             Schemas created:
               ACC  - Access/Account management (dealers, users, roles, tenants)
               ACE  - Account/Customer entities
               AUD  - Audit logging and tracking
               CME  - Commission management
               CNS  - Consignment / grouping utilities
               FNE  - Financing / funding sources
               GEN  - General/shared reference objects
               MAC  - Master configuration and reference data
               MAS  - Monitoring Automation System
               QAL  - Qualified leads
               RSU  - Resource / user workforce management
               SEC  - Security (access levels, table permissions)
               UTL  - Utility functions and helpers

Dependencies: 00000000_0000_CreateSchemaVersionTable
*/

BEGIN TRANSACTION;

BEGIN TRY

    DECLARE @MigrationName NVARCHAR(255) = '20260313_0845_Baseline_Schemas';
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
    -- Create non-default schemas
    -- CREATE SCHEMA must be its own batch, so we use EXEC() to run within the transaction
    -- =============================================

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'ACC')
        EXEC('CREATE SCHEMA [ACC]');
    PRINT 'Schema ACC: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'ACE')
        EXEC('CREATE SCHEMA [ACE]');
    PRINT 'Schema ACE: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'AUD')
        EXEC('CREATE SCHEMA [AUD]');
    PRINT 'Schema AUD: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'CME')
        EXEC('CREATE SCHEMA [CME]');
    PRINT 'Schema CME: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'CNS')
        EXEC('CREATE SCHEMA [CNS]');
    PRINT 'Schema CNS: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'FNE')
        EXEC('CREATE SCHEMA [FNE]');
    PRINT 'Schema FNE: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'GEN')
        EXEC('CREATE SCHEMA [GEN]');
    PRINT 'Schema GEN: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'MAC')
        EXEC('CREATE SCHEMA [MAC]');
    PRINT 'Schema MAC: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'MAS')
        EXEC('CREATE SCHEMA [MAS]');
    PRINT 'Schema MAS: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'QAL')
        EXEC('CREATE SCHEMA [QAL]');
    PRINT 'Schema QAL: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'RSU')
        EXEC('CREATE SCHEMA [RSU]');
    PRINT 'Schema RSU: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'SEC')
        EXEC('CREATE SCHEMA [SEC]');
    PRINT 'Schema SEC: OK';

    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'UTL')
        EXEC('CREATE SCHEMA [UTL]');
    PRINT 'Schema UTL: OK';

    -- =============================================
    -- Record migration in SchemaVersion
    -- =============================================
    DECLARE @ExecutionTimeMs INT = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());

    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description], [ExecutionTimeMs], [Success])
VALUES
    (
        @MigrationName,
        'Creates all non-default schemas for the SOL_MAIN baseline: ACC, ACE, AUD, CME, CNS, FNE, GEN, MAC, MAS, QAL, RSU, SEC, UTL',
        @ExecutionTimeMs,
        1
    );

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully in ' + CAST(@ExecutionTimeMs AS NVARCHAR(10)) + 'ms';

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage  NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT            = ERROR_SEVERITY();
    DECLARE @ErrorState    INT            = ERROR_STATE();

    PRINT 'ERROR in migration 20260313_0845_Baseline_Schemas: ' + @ErrorMessage;
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

END CATCH
GO

/*
ROLLBACK SCRIPT:
-- WARNING: Only run if this migration needs to be fully reversed.
-- Dropping schemas will fail if they still contain objects.
-- Remove all objects from each schema before dropping.

DROP SCHEMA IF EXISTS [UTL];
DROP SCHEMA IF EXISTS [SEC];
DROP SCHEMA IF EXISTS [RSU];
DROP SCHEMA IF EXISTS [QAL];
DROP SCHEMA IF EXISTS [MAS];
DROP SCHEMA IF EXISTS [MAC];
DROP SCHEMA IF EXISTS [GEN];
DROP SCHEMA IF EXISTS [FNE];
DROP SCHEMA IF EXISTS [CNS];
DROP SCHEMA IF EXISTS [CME];
DROP SCHEMA IF EXISTS [AUD];
DROP SCHEMA IF EXISTS [ACE];
DROP SCHEMA IF EXISTS [ACC];

DELETE FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = '20260313_0845_Baseline_Schemas';
*/
