/*
Migration: 20261105_0645_AddACC_UserTenantMemberships
Author: Andres Sosa
Date: 2026-11-05
Description: Lets a user act in more than one dealer tenant.

  1. Creates ACC.UserTenantMemberships (UserId, DealerTenantId): extra tenants beyond
     ACC.Users.DealerTenantId. Mirrors the Identity Server's AspNetUserTenantMemberships,
     which decides which tenant_id a token may carry.
  2. Alters ACC.spSessionContextCreate to accept the user's own tenant OR an active
     membership, and to report the requested tenant as TenantId in UserContext.

Before this, a staff login issued a token for Solasta (via a membership) was rejected with
03023 "User is not assigned to the requested tenant" because ACC.Users holds one tenant.

Dependencies: ACC.Users, ACC.DealerTenants, MAC.fxGetPrefixTypeIdFromProxy, GEN.spExceptionsThrown,
              20261026_2022_CreateACCSessionContextCreate
Expected impact: new table; procedure body replaced. No existing data changes.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261105_0645_AddACC_UserTenantMemberships';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'ACC.Users', N'U') IS NULL OR OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL
        THROW 50001, 'ACC.Users and ACC.DealerTenants are required.', 1;
    IF OBJECT_ID(N'ACC.UserTenantMemberships', N'U') IS NOT NULL
        THROW 50001, 'ACC.UserTenantMemberships already exists untracked. Reconcile it before applying this migration.', 1;

    -- Step 1: table (same definition as Tables/ACC/UserTenantMemberships.sql)
    CREATE TABLE [ACC].[UserTenantMemberships]
    (
        [UserId] [uniqueidentifier] NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_UserTenantMemberships_IsActive] DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_UserTenantMemberships_IsDeleted] DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_UserTenantMemberships_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_UserTenantMemberships_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_UserTenantMemberships_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        [DEX_ROW] [bigint] IDENTITY(1,1) NOT NULL,
        CONSTRAINT [PK_UserTenantMemberships] PRIMARY KEY CLUSTERED ([UserId], [DealerTenantId]),
        CONSTRAINT [FK_UserTenantMemberships_Users] FOREIGN KEY ([UserId])
            REFERENCES [ACC].[Users] ([UserID]),
        CONSTRAINT [FK_UserTenantMemberships_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
    );
    CREATE NONCLUSTERED INDEX [IX_UserTenantMemberships_DealerTenantId]
        ON [ACC].[UserTenantMemberships] ([DealerTenantId]);
    PRINT 'Created ACC.UserTenantMemberships';

    -- Step 2: procedure (same body as Procedures/ACC/spSessionContextCreate.sql)
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

        DECLARE @TenantId INT =
        (
            SELECT T.[DealerTenantID]
            FROM [ACC].[DealerTenants] AS T
            INNER JOIN [MAC].[fxGetPrefixTypeIdFromProxy](@TenantProxy) AS TParts
                ON TParts.[TypeId] = T.[DealerTenantTypeId]
               AND TParts.[PartKey] = T.[PartKey]
               AND TParts.[TypeName] = ''DealerTenant''
            WHERE T.[Proxy] = @TenantProxy
              AND T.[IsActive] = 1
              AND T.[IsDeleted] = 0
        );

        IF @TenantId IS NULL
        BEGIN
            RAISERROR(''03022|:|Tenant not found with Tenant Proxy ''''%s''''.'', 16, 1, @TenantProxy);
        END;

        -- The user''s own tenant, or an active membership in the requested tenant.
        IF NOT EXISTS
        (
            SELECT 1
            FROM [ACC].[Users] AS U
            WHERE U.[UserID] = @IdentityID
              AND U.[IsActive] = 1
              AND U.[IsDeleted] = 0
              AND (
                    U.[DealerTenantId] = @TenantId
                    OR EXISTS
                    (
                        SELECT 1
                        FROM [ACC].[UserTenantMemberships] AS M
                        WHERE M.[UserId] = U.[UserID]
                          AND M.[DealerTenantId] = @TenantId
                          AND M.[IsActive] = 1
                          AND M.[IsDeleted] = 0
                    )
                  )
        )
        BEGIN
            RAISERROR(''03023|:|User is not assigned to the requested tenant.'', 16, 1);
        END;

        DECLARE @JsonResult NVARCHAR(MAX);

        SELECT @JsonResult =
        (
            SELECT
                U.[UserID] AS [UserID],
                @TenantId AS [TenantId],
                U.[UserID] AS [IdentityId],
                U.[LanguageId] AS [LanguageId],
                U.[FirstName] AS [FirstName],
                U.[LastName] AS [LastName],
                U.[Email] AS [Email],
                U.[PhoneNumber] AS [PhoneNumber],
                ''XXXXXXX-XXXX-XXXX-XXXX-'' + RIGHT(CONVERT(VARCHAR(50), U.[UserID]), 12)
                    AS [UserGuidIDMasked]
            FROM [ACC].[Users] AS U
            WHERE U.[UserID] = @IdentityID
              AND U.[IsActive] = 1
              AND U.[IsDeleted] = 0
            FOR JSON PATH
        );

        IF DATALENGTH(@JsonResult) > 8000
            RAISERROR(''03024|:|UserContext JSON exceeds the SQL Server session-context value limit.'', 16, 1);

        -- sp_set_session_context takes sql_variant, which cannot hold NVARCHAR(MAX).
        DECLARE @UserContext NVARCHAR(4000) = @JsonResult;

        EXEC sys.sp_set_session_context
            @key = N''UserContext'',
            @value = @UserContext;

        RETURN 0;
    END TRY
    BEGIN CATCH
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
';
    PRINT 'Altered ACC.spSessionContextCreate';

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Add ACC.UserTenantMemberships; spSessionContextCreate accepts memberships',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
ROLLBACK SCRIPT:
-- Restore the single-tenant procedure from Migrations/20261026_2022_CreateACCSessionContextCreate.sql
-- (with the NVARCHAR(4000) @UserContext fix), then:
-- BEGIN TRANSACTION;
-- DROP TABLE IF EXISTS [ACC].[UserTenantMemberships];
-- DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261105_0645_AddACC_UserTenantMemberships';
-- COMMIT TRANSACTION;
*/