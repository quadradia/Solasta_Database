/*
Migration: 20260417_1200_CreateRSU_GetUserTypeGroupsByDealerIdResult
Author: Andres Sosa
Date: 2026-04-17
Description: Creates the [RSU].[uddt_GetUserTypeGroupsByDealerIdResult] user-defined
             table type. This type mirrors the result set of spGetUserTypeGroupsByDealerId
             and is intended to be passed as a READONLY parameter to stored procedures
             that consume that output.
Dependencies: RSU schema must exist prior to running this migration.
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260417_1200_CreateRSU_GetUserTypeGroupsByDealerIdResult';

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
WHERE name = N'uddt_GetUserTypeGroupsByDealerIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
    )
        DROP TYPE [RSU].[uddt_GetUserTypeGroupsByDealerIdResult];

    -- Create the user-defined table type
    EXEC(N'
    CREATE TYPE [RSU].[uddt_GetUserTypeGroupsByDealerIdResult] AS TABLE
    (
        [Id]                VARCHAR(20)         NOT NULL,
        [UserTypeGroupName] VARCHAR(50)         NOT NULL,
        [IsActive]          BIT                 NOT NULL,
        [IsDeleted]         BIT                 NOT NULL,
        [ModifiedDate]      DATETIMEOFFSET(7)   NOT NULL,
        [ModifiedById]      UNIQUEIDENTIFIER    NOT NULL,
        [CreatedDate]       DATETIMEOFFSET(7)   NOT NULL,
        [CreatedById]       UNIQUEIDENTIFIER    NOT NULL,

        PRIMARY KEY ([Id])
    );
    ');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName, 'Creates [RSU].[uddt_GetUserTypeGroupsByDealerIdResult] UDTT mirroring the result set of spGetUserTypeGroupsByDealerId.');

    COMMIT TRANSACTION;
    PRINT 'Migration 20260417_1200_CreateRSU_GetUserTypeGroupsByDealerIdResult applied successfully.';
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
    WHERE name = N'uddt_GetUserTypeGroupsByDealerIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
)
    DROP TYPE [RSU].[uddt_GetUserTypeGroupsByDealerIdResult];

DELETE FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = '20260417_1200_CreateRSU_GetUserTypeGroupsByDealerIdResult';
*/
