/*
Migration: 20260417_1500_CreateRSU_GetUserTypeTeamTypesByDealerIdResult
Author: Andres Sosa
Date: 2026-04-17
Description: Creates the User-Defined Table Type RSU.uddt_GetUserTypeTeamTypesByDealerIdResult,
             which mirrors the result set returned by RSU.spGetUserTypeTeamTypesByDealerId.
Dependencies: 20260417_1400_CreateRSU_GetUserTypesByDealerIdResult
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260417_1500_CreateRSU_GetUserTypeTeamTypesByDealerIdResult';

    -- Check if already applied
    IF EXISTS (
        SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName
    )
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- Drop existing type if present (types cannot be altered — drop and recreate)
    IF EXISTS (
        SELECT 1
FROM sys.table_types
WHERE name = N'uddt_GetUserTypeTeamTypesByDealerIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
    )
    BEGIN
    EXEC(N'DROP TYPE [RSU].[uddt_GetUserTypeTeamTypesByDealerIdResult];');
END

    -- Create the type (must use EXEC inside a transaction)
    EXEC(N'
    CREATE TYPE [RSU].[uddt_GetUserTypeTeamTypesByDealerIdResult] AS TABLE
    (
        [Id]                   INT               NOT NULL,
        [UserTypeTeamTypeName] VARCHAR(30)       NOT NULL,
        [ParentId]             INT               NULL,
        [IsActive]             BIT               NOT NULL,
        [IsDeleted]            BIT               NOT NULL,
        [CreatedById]          UNIQUEIDENTIFIER  NOT NULL,
        [CreatedDate]          DATETIMEOFFSET(7) NOT NULL,
        [ModifiedById]         UNIQUEIDENTIFIER  NOT NULL,
        [ModifiedDate]         DATETIMEOFFSET(7) NOT NULL,

        PRIMARY KEY ([Id])
    );
    ');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (
        @MigrationName,
        'Creates RSU.uddt_GetUserTypeTeamTypesByDealerIdResult table type mirroring spGetUserTypeTeamTypesByDealerId result set'
    );

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
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
    WHERE name = N'uddt_GetUserTypeTeamTypesByDealerIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
)
    DROP TYPE [RSU].[uddt_GetUserTypeTeamTypesByDealerIdResult];

DELETE FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = '20260417_1500_CreateRSU_GetUserTypeTeamTypesByDealerIdResult';
*/
