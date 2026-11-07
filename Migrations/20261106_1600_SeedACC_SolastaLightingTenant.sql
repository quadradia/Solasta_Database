/*
Migration: 20261106_1600_SeedACC_SolastaLightingTenant
Author: Andres Sosa
Date: 2026-11-06
Description: Seeds the Solasta Lighting tenant in databases that do not have it yet (production
             SOL_MAIN only had Cimtech). Uses the SAME proxy as dev on purpose:
               SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6
             Every environment shares one Identity Server database (GBDC_IDENTITY), whose user
             tenant memberships and the admin app's VITE_OIDC_TENANT hold this proxy. A tenant
             proxy that differs per environment would not match the tokens' tenant_id.
             Also adds the SOLA "Lighting Company Tenant" type when it is missing.
Dependencies:
  ACC.DealerTenantTypes, ACC.DealerTenants, MAC.fxGetPrefixTypeIdFromProxy
Expected impact: at most one new DealerTenantTypes row and one new DealerTenants row.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261106_1600_SeedACC_SolastaLightingTenant';
    DECLARE @Proxy VARCHAR(100) = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6';
    DECLARE @PartKey VARCHAR(6) = '3176D';

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'ACC.DealerTenantTypes', N'U') IS NULL OR OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL
        THROW 50001, 'ACC.DealerTenantTypes and ACC.DealerTenants must exist before this migration.', 1;

    -- Step 1: the SOLA tenant type
    IF NOT EXISTS (SELECT 1 FROM [ACC].[DealerTenantTypes] WHERE [Prefix] = 'SOLA')
    BEGIN
        INSERT INTO [ACC].[DealerTenantTypes] ([Prefix], [DealerTenantTypeName], [DealerTenantTypeDescription])
        VALUES ('SOLA', N'Lighting Company Tenant', N'This is for a lighting company with sales reps and technicians');
        PRINT 'Added DealerTenantType SOLA';
    END;
    DECLARE @TypeId INT = (SELECT [DealerTenantTypeID] FROM [ACC].[DealerTenantTypes] WHERE [Prefix] = 'SOLA');

    -- Step 2: the tenant, with the shared proxy
    IF EXISTS (SELECT 1 FROM [ACC].[DealerTenants] WHERE [Proxy] = @Proxy)
        PRINT 'Solasta Lighting tenant already exists';
    ELSE
    BEGIN
        IF EXISTS (SELECT 1 FROM [ACC].[DealerTenants] WHERE [DealerPrefix] = 'SLD')
            THROW 50001, 'DealerPrefix SLD is already used by another tenant. Reconcile it before applying this migration.', 1;

        INSERT INTO [ACC].[DealerTenants]
            ([DealerTenantTypeId], [PoliticalTimeZoneId], [Proxy], [PartKey],
             [DealerTenantName], [DealerTenantDescription], [DealerPrefix],
             [SquareMedLogoPath], [DealerRootSettingsJson])
        VALUES
            (@TypeId, 4, @Proxy, @PartKey,
             N'Solasta Lighting', NULL, 'SLD',
             N'N%C3%BAvol9Head.png', N'{}');
        PRINT 'Added tenant Solasta Lighting';
    END;

    -- The session-context procedure resolves tenants through the proxy's prefix and PartKey.
    IF NOT EXISTS (
        SELECT 1 FROM [ACC].[DealerTenants] AS T
        INNER JOIN [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy) AS P
            ON P.[TypeId] = T.[DealerTenantTypeId] AND P.[PartKey] = T.[PartKey] AND P.[TypeName] = 'DealerTenant'
        WHERE T.[Proxy] = @Proxy)
        THROW 50001, 'The Solasta proxy does not resolve through MAC.fxGetPrefixTypeIdFromProxy. Check the SOLA prefix registration.', 1;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success])
    VALUES (@MigrationName, N'Seed Solasta Lighting tenant with the shared SOLA proxy', 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
ROLLBACK SCRIPT (only if nothing references the tenant yet):
-- BEGIN TRANSACTION;
-- DELETE FROM [ACC].[DealerTenants] WHERE [Proxy] = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6';
-- DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261106_1600_SeedACC_SolastaLightingTenant';
-- COMMIT TRANSACTION;
*/
