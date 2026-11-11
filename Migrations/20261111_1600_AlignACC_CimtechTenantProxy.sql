/*
Migration: 20261111_1600_AlignACC_CimtechTenantProxy
Author: Andres Sosa
Date: 2026-11-11
Description: Gives the Cimtech Manufacturing tenant the SAME proxy in every database:
               CIMT:31772:E1518BD7-D0B7-4472-85C2-AAC7A8E42EBB
             Production SOL_MAIN was seeded by 20261026_2352 with a generated proxy
             (CIMT:31773:...), while every environment shares one Identity Server database
             (GBDC_IDENTITY) whose user tenant memberships and TenantAudiences mapping hold
             the dev proxy above. Tokens for Cimtech users therefore never matched the
             production tenant. Same approach as 20261106_1600 for Solasta Lighting.
             Tables reference DealerTenants by DealerTenantID, so changing Proxy and PartKey
             does not break foreign keys.
Dependencies:
  ACC.DealerTenants, MAC.fxGetPrefixTypeIdFromProxy, 20261026_2352_SeedACC_CimtechManufacturingTenant
Expected impact: dev, no change. Production, one ACC.DealerTenants row updated.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261111_1600_AlignACC_CimtechTenantProxy';
    DECLARE @Proxy VARCHAR(100) = 'CIMT:31772:E1518BD7-D0B7-4472-85C2-AAC7A8E42EBB';
    DECLARE @PartKey VARCHAR(6) = '31772';

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM [ACC].[DealerTenants] WHERE [Proxy] = @Proxy AND [DealerPrefix] <> 'CIM')
        THROW 50001, 'The shared Cimtech proxy is already used by another tenant. Reconcile it before applying this migration.', 1;

    IF EXISTS (SELECT 1 FROM [ACC].[DealerTenants] WHERE [Proxy] = @Proxy)
        PRINT 'Cimtech tenant already has the shared proxy';
    ELSE
    BEGIN
        DECLARE @Count INT = (SELECT COUNT(*) FROM [ACC].[DealerTenants] WHERE [DealerPrefix] = 'CIM');
        IF @Count <> 1
            THROW 50001, 'Expected exactly one tenant with DealerPrefix CIM. Reconcile ACC.DealerTenants before applying this migration.', 1;

        DECLARE @OldProxy VARCHAR(100) = (SELECT [Proxy] FROM [ACC].[DealerTenants] WHERE [DealerPrefix] = 'CIM');

        UPDATE [ACC].[DealerTenants]
        SET [Proxy] = @Proxy, [PartKey] = @PartKey
        WHERE [DealerPrefix] = 'CIM';

        PRINT 'Cimtech proxy changed from ' + @OldProxy + ' to ' + @Proxy;
    END;

    -- The session-context procedure resolves tenants through the proxy's prefix and PartKey.
    IF NOT EXISTS (
        SELECT 1 FROM [ACC].[DealerTenants] AS T
        INNER JOIN [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy) AS P
            ON P.[TypeId] = T.[DealerTenantTypeId] AND P.[PartKey] = T.[PartKey] AND P.[TypeName] = 'DealerTenant'
        WHERE T.[Proxy] = @Proxy)
        THROW 50001, 'The Cimtech proxy does not resolve through MAC.fxGetPrefixTypeIdFromProxy. Check the CIMT prefix registration.', 1;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success])
    VALUES (@MigrationName, N'Align Cimtech tenant with the shared CIMT proxy', 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
ROLLBACK SCRIPT (production only; put back the proxy printed when the migration ran):
-- BEGIN TRANSACTION;
-- UPDATE [ACC].[DealerTenants] SET [Proxy] = '<old proxy>', [PartKey] = '<old part key>' WHERE [DealerPrefix] = 'CIM';
-- DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261111_1600_AlignACC_CimtechTenantProxy';
-- COMMIT TRANSACTION;
*/
