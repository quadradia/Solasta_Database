/*
Migration: 20260505_1500_AddDefaultTimeZoneId_DealerTenants
Author: Andres Sosa
Date: 2026-05-05
Description: Adds DefaultTimeZoneId (INT NULL) to ACC.DealerTenants with a
             foreign key to MAC.PoliticalTimeZones. The column is nullable so
             existing rows are unaffected. Set per-dealer as needed.
Dependencies:
  20260313_0846_Baseline_ObjectsDeployed       (ACC.DealerTenants)
  20260505_1400_SeedMAC_PoliticalReferenceData  (MAC.PoliticalTimeZones seeded)
*/

BEGIN TRANSACTION;
BEGIN TRY

    DECLARE @MigrationName NVARCHAR(255) = '20260505_1500_AddDefaultTimeZoneId_DealerTenants';

    -- Check if already applied
    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- -------------------------------------------------------------------------
    -- 1. Add DefaultTimeZoneId column (after DealerTenantTypeId)
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACC.DealerTenants')
    AND name = 'DefaultTimeZoneId'
    )
    BEGIN
    ALTER TABLE [ACC].[DealerTenants]
            ADD [DefaultTimeZoneId] [int] NULL;

    PRINT 'Column ACC.DealerTenants.DefaultTimeZoneId added.';
END

    -- -------------------------------------------------------------------------
    -- 2. Add FK constraint to MAC.PoliticalTimeZones
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_DealerTenants_PoliticalTimeZones')
    BEGIN
    ALTER TABLE [ACC].[DealerTenants]
            ADD CONSTRAINT [FK_DealerTenants_PoliticalTimeZones]
            FOREIGN KEY ([DefaultTimeZoneId])
            REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID]);

    PRINT 'FK FK_DealerTenants_PoliticalTimeZones added.';
END

    -- -------------------------------------------------------------------------
    -- Record migration
    -- -------------------------------------------------------------------------
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName, 'Adds DefaultTimeZoneId (INT NULL) + FK to MAC.PoliticalTimeZones on ACC.DealerTenants');

    COMMIT TRANSACTION;
    PRINT 'Migration applied successfully: ' + @MigrationName;

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/*
ROLLBACK SCRIPT:
    ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [FK_DealerTenants_PoliticalTimeZones];
    ALTER TABLE [ACC].[DealerTenants] DROP COLUMN [DefaultTimeZoneId];

    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = '20260505_1500_AddDefaultTimeZoneId_DealerTenants';
*/
