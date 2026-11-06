/*******************************************************************************
 * Object Type: User-Defined Table Type
 * Schema: ACC
 * Name: udttSessionContextPayload
 * Description: Carries validated user and tenant context values.
 * Typical Usage: Table-valued parameter for session-context operations.
 * Author: Database Team
 * Created: 2026-10-30
 ******************************************************************************/

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
GO
