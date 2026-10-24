/*
Migration: 20260509_1000_SeedACC_LightingCompanyTenantType
Author:
Date: 2026-05-09
Description: Seeds ACC.DealerTenantTypes with the 'Lighting Company Tenant' type
             (Prefix = 'SOLA') and creates a corresponding ACC.DealerTenants row
             (DealerPrefix = 'SLD', PoliticalTimeZoneId = 4).
             The Proxy and PartKey for the DealerTenants row are generated at
             runtime using the MAC Proxy-ID infrastructure.
Dependencies:
  20260505_1000_AddProxyIdFoundation   (MAC Proxy-ID infrastructure)
  20260505_1700_ReorderColumns_DealerTenants
  20260505_1800_DeprecateDealers_ReplaceWithDealerTenants
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260509_1000_SeedACC_LightingCompanyTenantType';

    -- Check if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- =========================================================================
    -- STEP 1: Seed ACC.DealerTenantTypes — 'Lighting Company Tenant' (SOLA)
    -- =========================================================================
    DECLARE @NewTypeId INT;

    IF NOT EXISTS (SELECT 1 FROM [ACC].[DealerTenantTypes] WHERE [Prefix] = 'SOLA')
    BEGIN
        INSERT INTO [ACC].[DealerTenantTypes]
            ([Prefix], [DealerTenantTypeName], [DealerTenantTypeDescription])
        VALUES
            ('SOLA', 'Lighting Company Tenant', 'This is for a lighting company with sales reps and technicians');

        SET @NewTypeId = CAST(SCOPE_IDENTITY() AS INT);
        PRINT 'Inserted DealerTenantTypes row: Prefix=SOLA, DealerTenantTypeID=' + CAST(@NewTypeId AS NVARCHAR(10));
    END
    ELSE
    BEGIN
        SELECT @NewTypeId = [DealerTenantTypeID]
        FROM [ACC].[DealerTenantTypes]
        WHERE [Prefix] = 'SOLA';

        PRINT 'DealerTenantTypes row already exists: Prefix=SOLA, DealerTenantTypeID=' + CAST(@NewTypeId AS NVARCHAR(10));
    END

    -- =========================================================================
    -- STEP 2: Seed ACC.DealerTenants — 'Solasta Lighting'
    -- =========================================================================
    IF NOT EXISTS (
        SELECT 1
        FROM [ACC].[DealerTenants]
        WHERE [DealerPrefix]        = 'SLD'
          AND [DealerTenantTypeId]  = @NewTypeId
    )
    BEGIN
        DECLARE @Proxy   VARCHAR(100);
        DECLARE @PartKey VARCHAR(6);

        -- Generate Proxy: "SOLA:<PartKey>:<GUID>"
        SET @Proxy =
            (SELECT [MAC].[fxGeneratePrefixProxy]('DealerTenant', @NewTypeId))
            + CAST(NEWID() AS NVARCHAR(36));

        -- Extract PartKey from the second colon-delimited segment of the Proxy
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
             'Solasta Lighting', NULL, 'SLD',
             'N%C3%BAvol9Head.png', N'{}');

        PRINT 'Inserted DealerTenants row: DealerPrefix=SLD, Proxy=' + @Proxy + ', PartKey=' + @PartKey;
    END
    ELSE
    BEGIN
        PRINT 'DealerTenants row already exists for DealerPrefix=SLD and DealerTenantTypeId=' + CAST(@NewTypeId AS NVARCHAR(10));
    END

    -- =========================================================================
    -- Record migration
    -- =========================================================================
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (
        @MigrationName,
        'Seeds ACC.DealerTenantTypes with Prefix=SOLA (Lighting Company Tenant) and ' +
        'creates a corresponding ACC.DealerTenants row with DealerPrefix=SLD, PoliticalTimeZoneId=4.'
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
    WHERE [DealerPrefix]       = 'SLD'
      AND [DealerTenantTypeId] = (
          SELECT [DealerTenantTypeID]
          FROM [ACC].[DealerTenantTypes]
          WHERE [Prefix] = 'SOLA'
      );

    DELETE FROM [ACC].[DealerTenantTypes]
    WHERE [Prefix] = 'SOLA';

    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = '20260509_1000_SeedACC_LightingCompanyTenantType';

    COMMIT TRANSACTION;
    PRINT 'Rollback complete.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
*/
