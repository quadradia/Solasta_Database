/*
Migration: 20261026_2022_CreateACCSessionContextCreate
Author: Database Team
Date: 2026-10-26
Description: Creates ACC.spSessionContextCreate using the current user and
             dealer-tenant model. The procedure validates Proxy-ID components,
             confirms tenant ownership, and stores the UserContext JSON payload.
Dependencies:
  ACC.Users, ACC.DealerTenants
  MAC.fxGetPrefixTypeIdFromProxy, GEN.spExceptionsThrown
*/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261026_2022_CreateACCSessionContextCreate';
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'ACC.Users', N'U') IS NULL
       OR OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL
        THROW 50001, 'ACC.Users and ACC.DealerTenants must exist before this migration.', 1;

    IF OBJECT_ID(N'MAC.fxGetPrefixTypeIdFromProxy') IS NULL
       OR OBJECT_ID(N'GEN.spExceptionsThrown', N'P') IS NULL
        THROW 50001, 'MAC.fxGetPrefixTypeIdFromProxy and GEN.spExceptionsThrown must exist before this migration.', 1;

    EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE [ACC].[spSessionContextCreate]
(
    @IdentityID UNIQUEIDENTIFIER,
    @TenantProxy VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS
        (
            SELECT 1
            FROM [ACC].[Users] AS U
            WHERE U.[UserID] = @IdentityID
              AND U.[IsActive] = 1
              AND U.[IsDeleted] = 0
        )
        BEGIN
            DECLARE @IdentityIdVarchar VARCHAR(50) = CONVERT(VARCHAR(50), @IdentityID);
            RAISERROR(''03021|:|User not found with Identity ID ''''%s''''.'', 16, 1, @IdentityIdVarchar);
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM [ACC].[DealerTenants] AS T
            INNER JOIN [MAC].[fxGetPrefixTypeIdFromProxy](@TenantProxy) AS TParts
                ON TParts.[TypeId] = T.[DealerTenantTypeId]
               AND TParts.[PartKey] = T.[PartKey]
               AND TParts.[TypeName] = ''DealerTenant''
            WHERE T.[Proxy] = @TenantProxy
              AND T.[IsActive] = 1
              AND T.[IsDeleted] = 0
        )
        BEGIN
            RAISERROR(''03022|:|Tenant not found with Tenant Proxy ''''%s''''.'', 16, 1, @TenantProxy);
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM [ACC].[Users] AS U
            INNER JOIN [ACC].[DealerTenants] AS T
                ON T.[DealerTenantID] = U.[DealerTenantId]
            INNER JOIN [MAC].[fxGetPrefixTypeIdFromProxy](@TenantProxy) AS TParts
                ON TParts.[TypeId] = T.[DealerTenantTypeId]
               AND TParts.[PartKey] = T.[PartKey]
               AND TParts.[TypeName] = ''DealerTenant''
            WHERE U.[UserID] = @IdentityID
              AND U.[IsActive] = 1
              AND U.[IsDeleted] = 0
              AND T.[Proxy] = @TenantProxy
              AND T.[IsActive] = 1
              AND T.[IsDeleted] = 0
        )
        BEGIN
            RAISERROR(''03023|:|User is not assigned to the requested tenant.'', 16, 1);
        END;

        DECLARE @JsonResult NVARCHAR(MAX);

        SELECT @JsonResult =
        (
            SELECT
                U.[UserID] AS [UserID],
                T.[DealerTenantID] AS [TenantId],
                U.[UserID] AS [IdentityId],
                U.[LanguageId] AS [LanguageId],
                U.[FirstName] AS [FirstName],
                U.[LastName] AS [LastName],
                U.[Email] AS [Email],
                U.[PhoneNumber] AS [PhoneNumber],
                ''XXXXXXX-XXXX-XXXX-XXXX-'' + RIGHT(CONVERT(VARCHAR(50), U.[UserID]), 12)
                    AS [UserGuidIDMasked]
            FROM [ACC].[Users] AS U
            INNER JOIN [ACC].[DealerTenants] AS T
                ON T.[DealerTenantID] = U.[DealerTenantId]
            INNER JOIN [MAC].[fxGetPrefixTypeIdFromProxy](@TenantProxy) AS TParts
                ON TParts.[TypeId] = T.[DealerTenantTypeId]
               AND TParts.[PartKey] = T.[PartKey]
               AND TParts.[TypeName] = ''DealerTenant''
            WHERE U.[UserID] = @IdentityID
              AND U.[IsActive] = 1
              AND U.[IsDeleted] = 0
              AND T.[Proxy] = @TenantProxy
              AND T.[IsActive] = 1
              AND T.[IsDeleted] = 0
            FOR JSON PATH
        );

        IF DATALENGTH(@JsonResult) > 8000
            RAISERROR(''03024|:|UserContext JSON exceeds the SQL Server session-context value limit.'', 16, 1);

        EXEC sys.sp_set_session_context
            @key = N''UserContext'',
            @value = @JsonResult;

        RETURN 0;
    END TRY
    BEGIN CATCH
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;';

    INSERT INTO [dbo].[SchemaVersion]
        ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES
        (@MigrationName,
         N'Creates ACC.spSessionContextCreate using the current user and dealer-tenant model.',
         DATEDIFF(MILLISECOND, @StartTime, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
VERIFICATION:
SELECT [MigrationName], [AppliedDate], [Success]
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = N'20261026_2022_CreateACCSessionContextCreate';

SELECT OBJECT_ID(N'ACC.spSessionContextCreate', N'P') AS [ProcedureObjectId];

ROLLBACK SCRIPT:
BEGIN TRANSACTION;
BEGIN TRY
    IF OBJECT_ID(N'ACC.spSessionContextCreate', N'P') IS NOT NULL
        DROP PROCEDURE [ACC].[spSessionContextCreate];

    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = N'20261026_2022_CreateACCSessionContextCreate';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
*/
