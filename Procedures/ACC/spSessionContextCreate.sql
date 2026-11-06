/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: ACC
 * Name: spSessionContextCreate
 * Description: Validates a user and a dealer tenant they may act in, then stores their
 *              session context as JSON under the UserContext key. A user may act in
 *              their own tenant (ACC.Users.DealerTenantId) or in any tenant they have an
 *              active ACC.UserTenantMemberships row for.
 * Dependencies: ACC.Users, ACC.DealerTenants, ACC.UserTenantMemberships,
 *               MAC.fxGetPrefixTypeIdFromProxy, GEN.spExceptionsThrown
 * Parameters:
 *   @IdentityID - UserID of an active user
 *   @TenantProxy - Proxy of an active dealer tenant the user belongs to
 * Returns: 0 on success; -1 when validation or execution fails
 * Author: Database Team
 * Created: 2026-10-26
 * Modified: 2026-11-05 - accept ACC.UserTenantMemberships; TenantId in the JSON is the
 *                        requested tenant
 * Example:
 *   EXEC [ACC].[spSessionContextCreate]
 *       @IdentityID = '00000000-0000-0000-0000-000000000000',
 *       @TenantProxy = 'SOLA:316BD:E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8';
 *******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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
            RAISERROR('03021|:|User not found with Identity ID ''%s''.', 16, 1, @IdentityIdVarchar);
        END;

        DECLARE @TenantId INT =
        (
            SELECT T.[DealerTenantID]
            FROM [ACC].[DealerTenants] AS T
            INNER JOIN [MAC].[fxGetPrefixTypeIdFromProxy](@TenantProxy) AS TParts
                ON TParts.[TypeId] = T.[DealerTenantTypeId]
               AND TParts.[PartKey] = T.[PartKey]
               AND TParts.[TypeName] = 'DealerTenant'
            WHERE T.[Proxy] = @TenantProxy
              AND T.[IsActive] = 1
              AND T.[IsDeleted] = 0
        );

        IF @TenantId IS NULL
        BEGIN
            RAISERROR('03022|:|Tenant not found with Tenant Proxy ''%s''.', 16, 1, @TenantProxy);
        END;

        -- The user's own tenant, or an active membership in the requested tenant.
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
            RAISERROR('03023|:|User is not assigned to the requested tenant.', 16, 1);
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
                'XXXXXXX-XXXX-XXXX-XXXX-' + RIGHT(CONVERT(VARCHAR(50), U.[UserID]), 12)
                    AS [UserGuidIDMasked]
            FROM [ACC].[Users] AS U
            WHERE U.[UserID] = @IdentityID
              AND U.[IsActive] = 1
              AND U.[IsDeleted] = 0
            FOR JSON PATH
        );

        IF DATALENGTH(@JsonResult) > 8000
            RAISERROR('03024|:|UserContext JSON exceeds the SQL Server session-context value limit.', 16, 1);

        -- sp_set_session_context takes sql_variant, which cannot hold NVARCHAR(MAX).
        DECLARE @UserContext NVARCHAR(4000) = @JsonResult;

        EXEC sys.sp_set_session_context
            @key = N'UserContext',
            @value = @UserContext;

        RETURN 0;
    END TRY
    BEGIN CATCH
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
GO
