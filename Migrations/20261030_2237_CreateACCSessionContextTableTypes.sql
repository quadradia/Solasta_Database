/*
Migration: 20261030_2237_CreateACCSessionContextTableTypes
Author: Database Team
Date: 2026-10-30
Description: Creates ACC.udttSessionContextPayload and
             ACC.udttApplicationValidationResult with the declared columns,
             nullability, and clustered primary keys.
Dependencies: ACC schema, dbo.SchemaVersion
Rollback: Drop the types after removing all dependent procedures and functions.
*/

SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) =
        N'20261030_2237_CreateACCSessionContextTableTypes';

    IF EXISTS (
        SELECT 1
        FROM [dbo].[SchemaVersion]
        WHERE [MigrationName] = @MigrationName
    )
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF SCHEMA_ID(N'ACC') IS NULL
        THROW 50001, 'ACC schema must exist before this migration.', 1;

    IF TYPE_ID(N'ACC.udttSessionContextPayload') IS NULL
    BEGIN
        EXEC(N'
            CREATE TYPE [ACC].[udttSessionContextPayload] AS TABLE
            (
                [UserID] UNIQUEIDENTIFIER NOT NULL,
                [TenantId] INT NOT NULL,
                [IdentityId] UNIQUEIDENTIFIER NOT NULL,
                [LanguageId] VARCHAR(50) NOT NULL,
                [FirstName] NVARCHAR(50) NOT NULL,
                [LastName] NVARCHAR(50) NOT NULL,
                [Email] NVARCHAR(50) NOT NULL,
                [PhoneNumber] NVARCHAR(50) NOT NULL,
                [UserGuidIDMasked] VARCHAR(50) NOT NULL,
                PRIMARY KEY CLUSTERED ([UserID] ASC) WITH (IGNORE_DUP_KEY = OFF)
            );
        ');
    END;

    IF TYPE_ID(N'ACC.udttApplicationValidationResult') IS NULL
    BEGIN
        EXEC(N'
            CREATE TYPE [ACC].[udttApplicationValidationResult] AS TABLE
            (
                [ApplicationID] INT NOT NULL,
                [EntityTypeID] INT NULL,
                [Proxy] VARCHAR(100) NOT NULL,
                [ApplicationName] NVARCHAR(100) NOT NULL,
                [EntityTypeName] NVARCHAR(100) NULL,
                [Username] NVARCHAR(256) NOT NULL,
                [Email] NVARCHAR(MAX) NULL,
                [EntityID] BIGINT NOT NULL,
                [UserEntityTypeID] INT NOT NULL,
                [ValidationStatus] NVARCHAR(150) NOT NULL,
                PRIMARY KEY CLUSTERED ([ApplicationID] ASC, [EntityID] ASC)
                    WITH (IGNORE_DUP_KEY = OFF)
            );
        ');
    END;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (
        @MigrationName,
        N'Creates ACC.udttSessionContextPayload and ACC.udttApplicationValidationResult.'
    );

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- Run only after dropping procedures and functions that depend on these types.
BEGIN TRANSACTION;
BEGIN TRY
    IF TYPE_ID(N'ACC.udttApplicationValidationResult') IS NOT NULL
        DROP TYPE [ACC].[udttApplicationValidationResult];

    IF TYPE_ID(N'ACC.udttSessionContextPayload') IS NOT NULL
        DROP TYPE [ACC].[udttSessionContextPayload];

    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = N'20261030_2237_CreateACCSessionContextTableTypes';

    COMMIT TRANSACTION;
    PRINT 'Rollback complete.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
*/
