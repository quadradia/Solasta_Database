/*
Migration: 20260416_1201_CreateRSU_JsonOutputMethod
Author: Andres Sosa
Date: 2026-04-16
Description: Creates the [RSU].[uddt_JsonOutputMethod] user-defined table type.
             This type holds a single NVARCHAR(MAX) column representing a JSON
             output string, intended to be passed as a READONLY parameter to
             stored procedures that process JSON payloads.
Dependencies: RSU schema must exist prior to running this migration.
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260416_1201_CreateRSU_JsonOutputMethod';

    -- Check if already applied
    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- Drop existing type if it exists
    IF EXISTS (
        SELECT 1
FROM sys.table_types
WHERE name = N'uddt_JsonOutputMethod'
    AND schema_id = SCHEMA_ID(N'RSU')
    )
        DROP TYPE [RSU].[uddt_JsonOutputMethod];

    -- Create the user-defined table type
    EXEC(N'
    CREATE TYPE [RSU].[uddt_JsonOutputMethod] AS TABLE
    (
        [JsonOutPutMethod] NVARCHAR(MAX) NULL
    );
    ');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName, 'Creates [RSU].[uddt_JsonOutputMethod] user-defined table type with a single NVARCHAR(MAX) JSON output column.');

    COMMIT TRANSACTION;
    PRINT 'Migration 20260416_1201_CreateRSU_JsonOutputMethod applied successfully.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
IF EXISTS (
    SELECT 1 FROM sys.table_types
    WHERE name = N'uddt_JsonOutputMethod'
    AND schema_id = SCHEMA_ID(N'RSU')
)
    DROP TYPE [RSU].[uddt_JsonOutputMethod];

DELETE FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = '20260416_1201_CreateRSU_JsonOutputMethod';
*/
