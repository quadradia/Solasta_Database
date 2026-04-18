/*
Migration: 20260416_1202_CreateRSU_GetUserEmployeeTypesByDealerIdResult
Author: Andres Sosa
Date: 2026-04-16
Description: Creates the [RSU].[uddt_GetUserEmployeeTypesByDealerIdResult] user-defined
             table type. This type mirrors the result set of spGetUserEmployeeTypesByDealerId
             and is intended to be passed as a READONLY parameter to stored procedures
             that consume that output.
Dependencies: RSU schema must exist prior to running this migration.
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260416_1202_CreateRSU_GetUserEmployeeTypesByDealerIdResult';

    -- Check if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion]
               WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Drop existing type if it exists
    IF EXISTS (
        SELECT 1 FROM sys.table_types
        WHERE name = N'uddt_GetUserEmployeeTypesByDealerIdResult'
        AND schema_id = SCHEMA_ID(N'RSU')
    )
        DROP TYPE [RSU].[uddt_GetUserEmployeeTypesByDealerIdResult];

    -- Create the user-defined table type
    EXEC(N'
    CREATE TYPE [RSU].[uddt_GetUserEmployeeTypesByDealerIdResult] AS TABLE
    (
        [Id]                    VARCHAR(20)          NOT NULL,
        [UserEmployeeTypeName]  NVARCHAR(50)         NOT NULL,
        [IsActive]              BIT                  NOT NULL,
        [IsDeleted]             BIT                  NOT NULL,
        [CreatedById]           UNIQUEIDENTIFIER     NOT NULL,
        [CreatedDate]           DATETIMEOFFSET(7)    NOT NULL,
        [ModifiedById]          UNIQUEIDENTIFIER     NOT NULL,
        [ModifiedDate]          DATETIMEOFFSET(7)    NOT NULL,

        PRIMARY KEY ([Id])
    );
    ');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (@MigrationName, 'Creates [RSU].[uddt_GetUserEmployeeTypesByDealerIdResult] UDTT mirroring the result set of spGetUserEmployeeTypesByDealerId.');

    COMMIT TRANSACTION;
    PRINT 'Migration 20260416_1202_CreateRSU_GetUserEmployeeTypesByDealerIdResult applied successfully.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    RAISERROR (ERROR_MESSAGE(), 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
IF EXISTS (
    SELECT 1 FROM sys.table_types
    WHERE name = N'uddt_GetUserEmployeeTypesByDealerIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
)
    DROP TYPE [RSU].[uddt_GetUserEmployeeTypesByDealerIdResult];

DELETE FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = '20260416_1202_CreateRSU_GetUserEmployeeTypesByDealerIdResult';
*/
