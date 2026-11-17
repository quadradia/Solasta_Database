/*******************************************************************************
 * Object Type: Function (inline table-valued)
 * Schema: INE
 * Name: fxGetSessionContext
 * Description: Returns the signed-in user and dealer tenant from the UserContext JSON
 *              that ACC.spSessionContextCreate stores in SESSION_CONTEXT (the Solasta
 *              API's DynamicSqlInjectionInterceptor calls it before every command).
 *              Both columns are NULL when no session context has been set.
 * Dependencies: ACC.spSessionContextCreate (writes the UserContext key)
 * Returns: one row (UserId UNIQUEIDENTIFIER, DealerTenantId INT)
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Example:
 *   SELECT [UserId], [DealerTenantId] FROM [INE].[fxGetSessionContext]();
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [INE].[fxGetSessionContext]()
RETURNS TABLE
AS
RETURN
(
    -- spSessionContextCreate stores FOR JSON PATH output, so the object is element 0 of an array.
    SELECT
        TRY_CAST(JSON_VALUE(CTX.[Json], N'$[0].UserID') AS UNIQUEIDENTIFIER) AS [UserId]
        , TRY_CAST(JSON_VALUE(CTX.[Json], N'$[0].TenantId') AS INT) AS [DealerTenantId]
    FROM (SELECT CAST(SESSION_CONTEXT(N'UserContext') AS NVARCHAR(4000)) AS [Json]) AS CTX
);
GO
