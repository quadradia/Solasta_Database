/*
Migration: 20261026_2352_SeedACC_CimtechManufacturingTenant
Author: Database Team
Date: 2026-10-26
Description: Registers the CIMT Manufacturing Company Tenant type and seeds the
             Cimtech Manufacturing tenant with DealerPrefix=CIM.
Dependencies:
  ACC.DealerTenantTypes, ACC.DealerTenants, dbo.SchemaVersion
  20260505_1000_AddProxyIdFoundation
*/

SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261026_2352_SeedACC_CimtechManufacturingTenant';

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'ACC.DealerTenantTypes', N'U') IS NULL
       OR OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL
        THROW 50001, 'ACC.DealerTenantTypes and ACC.DealerTenants must exist before this migration.', 1;

    IF OBJECT_ID(N'MAC.vwTableTypesAndPrefixes', N'V') IS NULL
       OR OBJECT_ID(N'MAC.fxGeneratePrefixProxy', N'FN') IS NULL
        THROW 50001, 'Deploy the Proxy-ID infrastructure before this migration.', 1;

    IF EXISTS (SELECT 1 FROM [MAC].[vwTableTypesAndPrefixes] WHERE [Prefix] = 'CIMT')
        THROW 50001, 'The CIMT prefix is already assigned. Resolve the prefix collision before applying this migration.', 1;

    DECLARE @NewTypeId INT;

    INSERT INTO [ACC].[DealerTenantTypes]
        ([Prefix], [DealerTenantTypeName], [DealerTenantTypeDescription])
    VALUES
        ('CIMT', N'Manufacturing Company Tenant', N'Manufacturing company tenant');

    SET @NewTypeId = CAST(SCOPE_IDENTITY() AS INT);

    IF EXISTS (
        SELECT 1
        FROM [ACC].[DealerTenants]
        WHERE [DealerPrefix] = 'CIM'
    )
        THROW 50001, 'DealerPrefix CIM is already assigned to a tenant. Resolve the conflict before applying this migration.', 1;

    DECLARE @Proxy VARCHAR(100);
    DECLARE @PartKey VARCHAR(6);

    SET @Proxy =
        (SELECT [MAC].[fxGeneratePrefixProxy]('DealerTenant', @NewTypeId))
        + CAST(NEWID() AS NVARCHAR(36));

    SET @PartKey = SUBSTRING(
        @Proxy,
        CHARINDEX(':', @Proxy) + 1,
        CHARINDEX(':', @Proxy, CHARINDEX(':', @Proxy) + 1)
            - CHARINDEX(':', @Proxy) - 1
    );

    INSERT INTO [ACC].[DealerTenants]
        ([DealerTenantTypeId], [PoliticalTimeZoneId], [Proxy], [PartKey],
         [DealerTenantName], [DealerTenantDescription], [DealerPrefix],
         [SquareMedLogoPath], [DealerRootSettingsJson])
    VALUES
        (@NewTypeId, 4, @Proxy, @PartKey,
         N'Cimtech Manufacturing',
         N'Cimtech Engineering is a mas fabricator of high precision parts for aviation, automobile, and various other industries...',
         'CIM', N'WebSiteLogo.png', N'{}');

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (
        @MigrationName,
        N'Registers the CIMT Manufacturing Company Tenant type and seeds the Cimtech Manufacturing tenant with DealerPrefix=CIM.'
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
BEGIN TRANSACTION;
BEGIN TRY
    DELETE FROM [ACC].[DealerTenants]
    WHERE [DealerPrefix] = 'CIM'
      AND [DealerTenantName] = N'Cimtech Manufacturing'
      AND [DealerTenantTypeId] = (
          SELECT [DealerTenantTypeID]
          FROM [ACC].[DealerTenantTypes]
          WHERE [Prefix] = 'CIMT'
      );

    DELETE FROM [ACC].[DealerTenantTypes]
    WHERE [Prefix] = 'CIMT'
      AND [DealerTenantTypeName] = N'Manufacturing Company Tenant';

    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = '20261026_2352_SeedACC_CimtechManufacturingTenant';

    COMMIT TRANSACTION;
    PRINT 'Rollback complete.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
*/
