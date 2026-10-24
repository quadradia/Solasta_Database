/*
Migration: 20261024_1634_CreateDOCSchema
Author: Database Team
Date: 2026-10-24
Description: Creates the DOC domain for document management, including signed
             contracts, engineering files such as DXF, and other document formats.
Dependencies: 00000000_0000_CreateSchemaVersionTable
Expected impact: Adds an empty schema; no existing objects or data are modified.
*/

SET XACT_ABORT ON;

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261024_1634_CreateDOCSchema';
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion]
               WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- CREATE SCHEMA requires a separate batch, executed inside this transaction.
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'DOC')
    BEGIN
        EXEC sys.sp_executesql N'CREATE SCHEMA [DOC] AUTHORIZATION [dbo];';
    END;

    INSERT INTO [dbo].[SchemaVersion]
        ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES
        (@MigrationName,
         N'Creates DOC for document management: signed contracts, DXF engineering files, and other document formats.',
         DATEDIFF(MILLISECOND, @StartTime, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'DOC schema migration applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
VERIFICATION:
SELECT [name], USER_NAME([principal_id]) AS [OwnerName]
FROM sys.schemas WHERE [name] = N'DOC';

SELECT [MigrationName], [AppliedDate], [Success]
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = N'20261024_1634_CreateDOCSchema';

ROLLBACK SCRIPT:
-- Only drop DOC if it was introduced by this migration and remains empty.
-- DROP SCHEMA fails if any objects remain; the transaction preserves history.
BEGIN TRANSACTION;
BEGIN TRY
    IF EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'DOC')
        EXEC sys.sp_executesql N'DROP SCHEMA [DOC];';

    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = N'20261024_1634_CreateDOCSchema';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
*/
