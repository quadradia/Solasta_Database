/*
Migration: 20260505_1600_RenamePoliticalTimeZoneId_DealerTenants
Author: Andres Sosa
Date: 2026-05-05
Description: Renames ACC.DealerTenants.DefaultTimeZoneId to PoliticalTimeZoneId
             (per FK naming convention), sets the column to NOT NULL, backfills
             existing NULLs to 4 (UTC), and adds a DEFAULT constraint of 4.
Dependencies:
  20260505_1500_AddDefaultTimeZoneId_DealerTenants  (column + FK exist)
*/

BEGIN TRANSACTION;
BEGIN TRY

    DECLARE @MigrationName NVARCHAR(255) = '20260505_1600_RenamePoliticalTimeZoneId_DealerTenants';

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
    -- 1. Drop FK that references the old column name so rename is unblocked
    -- -------------------------------------------------------------------------
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_DealerTenants_PoliticalTimeZones')
    BEGIN
    ALTER TABLE [ACC].[DealerTenants]
            DROP CONSTRAINT [FK_DealerTenants_PoliticalTimeZones];

    PRINT 'FK FK_DealerTenants_PoliticalTimeZones dropped.';
END

    -- -------------------------------------------------------------------------
    -- 2. Rename the column
    -- -------------------------------------------------------------------------
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACC.DealerTenants')
    AND name = 'DefaultTimeZoneId')
    BEGIN
    EXEC sp_rename 'ACC.DealerTenants.DefaultTimeZoneId', 'PoliticalTimeZoneId', 'COLUMN';

    PRINT 'Column renamed: DefaultTimeZoneId -> PoliticalTimeZoneId.';
END

    -- -------------------------------------------------------------------------
    -- 3. Backfill NULLs to 4 (UTC) before enforcing NOT NULL
    --    (dynamic SQL required: column name resolved at runtime after sp_rename)
    -- -------------------------------------------------------------------------
    EXEC sp_executesql N'UPDATE [ACC].[DealerTenants] SET [PoliticalTimeZoneId] = 4 WHERE [PoliticalTimeZoneId] IS NULL';

    PRINT 'Backfilled NULL PoliticalTimeZoneId rows to 4.';

    -- -------------------------------------------------------------------------
    -- 4. Alter column to NOT NULL
    -- -------------------------------------------------------------------------
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACC.DealerTenants')
    AND name = 'PoliticalTimeZoneId'
    AND is_nullable = 1)
    BEGIN
    ALTER TABLE [ACC].[DealerTenants]
            ALTER COLUMN [PoliticalTimeZoneId] [int] NOT NULL;

    PRINT 'Column PoliticalTimeZoneId set to NOT NULL.';
END

    -- -------------------------------------------------------------------------
    -- 5. Add DEFAULT constraint
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1
FROM sys.objects
WHERE name = 'DF_DealerTenants_PoliticalTimeZoneId' AND type = 'D')
    BEGIN
    ALTER TABLE [ACC].[DealerTenants]
            ADD CONSTRAINT [DF_DealerTenants_PoliticalTimeZoneId]
            DEFAULT ((4)) FOR [PoliticalTimeZoneId];

    PRINT 'Default constraint DF_DealerTenants_PoliticalTimeZoneId added (value = 4).';
END

    -- -------------------------------------------------------------------------
    -- 6. Re-add FK constraint pointing to the renamed column
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_DealerTenants_PoliticalTimeZones')
    BEGIN
    ALTER TABLE [ACC].[DealerTenants]
            ADD CONSTRAINT [FK_DealerTenants_PoliticalTimeZones]
            FOREIGN KEY ([PoliticalTimeZoneId])
            REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID]);

    PRINT 'FK FK_DealerTenants_PoliticalTimeZones re-added.';
END

    -- -------------------------------------------------------------------------
    -- Record migration
    -- -------------------------------------------------------------------------
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName,
        'Rename DefaultTimeZoneId -> PoliticalTimeZoneId, NOT NULL, DEFAULT 4 on ACC.DealerTenants');

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
    ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [DF_DealerTenants_PoliticalTimeZoneId];
    ALTER TABLE [ACC].[DealerTenants] ALTER COLUMN [PoliticalTimeZoneId] [int] NULL;
    EXEC sp_rename 'ACC.DealerTenants.PoliticalTimeZoneId', 'DefaultTimeZoneId', 'COLUMN';
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [FK_DealerTenants_PoliticalTimeZones]
        FOREIGN KEY ([DefaultTimeZoneId])
        REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID]);
    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = '20260505_1600_RenamePoliticalTimeZoneId_DealerTenants';
*/
