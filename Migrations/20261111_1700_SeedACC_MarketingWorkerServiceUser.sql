/*
Migration: 20261111_1700_SeedACC_MarketingWorkerServiceUser
Author: Andres Sosa
Date: 2026-11-11
Description: Adds a service user for the mysolasta.com Worker (Identity Server client
             marketing-worker), which submits affiliate applications with a client-credentials
             token. Such tokens have no "sub", so the Solasta API maps the client to this user
             (configuration ServiceAccounts:marketing-worker) for ACC.spSessionContextCreate and
             the audit columns. The user belongs to the Solasta Lighting tenant only and has no
             password: it cannot sign in.
             UserID is fixed so every environment and the API configuration agree:
               C1431C18-C4DC-4804-9050-EFFC611EAD8C
Dependencies:
  ACC.Users, ACC.DealerTenants, 20261106_1600_SeedACC_SolastaLightingTenant, MAC language en-US
Expected impact: one new ACC.Users row.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261111_1700_SeedACC_MarketingWorkerServiceUser';
    DECLARE @UserId UNIQUEIDENTIFIER = 'C1431C18-C4DC-4804-9050-EFFC611EAD8C';
    DECLARE @SolastaProxy VARCHAR(100) = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6';

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    DECLARE @TenantId INT = (SELECT [DealerTenantID] FROM [ACC].[DealerTenants] WHERE [Proxy] = @SolastaProxy);
    IF @TenantId IS NULL
        THROW 50001, 'The Solasta Lighting tenant is missing. Apply 20261106_1600_SeedACC_SolastaLightingTenant first.', 1;

    IF EXISTS (SELECT 1 FROM [ACC].[Users] WHERE [UserID] = @UserId)
        PRINT 'Marketing worker service user already exists';
    ELSE
    BEGIN
        DECLARE @Now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();
        INSERT INTO [ACC].[Users]
            ([UserID], [DealerTenantId], [LanguageId], [FirstName], [LastName], [Email], [EmailConfirmed],
             [Username], [PasswordHash], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEnabled],
             [AccessFailedCount], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
        VALUES
            (@UserId, @TenantId, 'en-US', N'Website', N'Affiliate Form', NULL, 0,
             N'svc-marketing-worker', NULL, 0, 0, 1,
             0, 1, 0, @Now, @UserId, @Now, @UserId);
        PRINT 'Added service user svc-marketing-worker';
    END;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success])
    VALUES (@MigrationName, N'Seed the marketing-worker service user', 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
ROLLBACK SCRIPT (only if the user created no rows yet):
-- BEGIN TRANSACTION;
-- DELETE FROM [ACC].[Users] WHERE [UserID] = 'C1431C18-C4DC-4804-9050-EFFC611EAD8C';
-- DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261111_1700_SeedACC_MarketingWorkerServiceUser';
-- COMMIT TRANSACTION;
*/
