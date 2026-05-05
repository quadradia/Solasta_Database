/*
Migration: 20260505_1400_SeedMAC_PoliticalReferenceData
Author: Andres Sosa
Date: 2026-05-05
Description: Seeds the four MAC political reference tables from NVL9_MAIN
             using cross-database MERGE statements. All four tables must
             already exist in SOL_MAIN before this migration runs.

             Tables seeded (in FK-safe order):
               1. MAC.PoliticalCountries      (4 rows)
               2. MAC.PoliticalTimeZones     (17 rows)
               3. MAC.PoliticalStates        (61 rows)
               4. MAC.PoliticalStatesAndTimeZoneMaps (75 rows)

             The MERGEs are idempotent — safe to re-run at any time.

Dependencies:
  20260313_0846_Baseline_ObjectsDeployed       (MAC schema tables)
  20260505_1300_CreatePoliticalStatesAndTimeZoneMaps
  NVL9_MAIN database accessible on same server instance
*/

BEGIN TRANSACTION;
BEGIN TRY

    DECLARE @MigrationName NVARCHAR(255) = '20260505_1400_SeedMAC_PoliticalReferenceData';

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
    -- Guard: verify target tables exist
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'PoliticalCountries' AND schema_id = SCHEMA_ID('MAC'))
        RAISERROR('MAC.PoliticalCountries does not exist.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'PoliticalTimeZones' AND schema_id = SCHEMA_ID('MAC'))
        RAISERROR('MAC.PoliticalTimeZones does not exist.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'PoliticalStates' AND schema_id = SCHEMA_ID('MAC'))
        RAISERROR('MAC.PoliticalStates does not exist.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'PoliticalStatesAndTimeZoneMaps' AND schema_id = SCHEMA_ID('MAC'))
        RAISERROR('MAC.PoliticalStatesAndTimeZoneMaps does not exist.', 16, 1);

    -- =========================================================================
    -- 1. MAC.PoliticalCountries
    --    PK: PoliticalCountryID (nvarchar) — not an identity column
    --    DEX_ROW is identity but not the PK; omit from INSERT
    -- =========================================================================
    MERGE INTO [MAC].[PoliticalCountries] AS target
    USING [NVL9_MAIN].[MAC].[PoliticalCountries] AS source
    ON target.[PoliticalCountryID] = source.[PoliticalCountryID]
    WHEN MATCHED THEN
        UPDATE SET
            target.[PoliticalCountryName] = source.[PoliticalCountryName],
            target.[CountryAB]            = source.[CountryAB],
            target.[IsActive]             = source.[IsActive],
            target.[IsDeleted]            = source.[IsDeleted],
            target.[ModifiedDate]         = sysdatetimeoffset()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([PoliticalCountryID], [PoliticalCountryName], [CountryAB], [IsActive], [IsDeleted])
        VALUES (source.[PoliticalCountryID], source.[PoliticalCountryName], source.[CountryAB], source.[IsActive], source.[IsDeleted]);

    PRINT 'MAC.PoliticalCountries seeded.';

    -- =========================================================================
    -- 2. MAC.PoliticalTimeZones
    --    PK: PoliticalTimeZoneID (plain int — NOT an identity column in SOL_MAIN)
    --    Computed columns (TimezoneOffset, etc.) are excluded; they are derived.
    -- =========================================================================
    MERGE INTO [MAC].[PoliticalTimeZones] AS target
    USING [NVL9_MAIN].[MAC].[PoliticalTimeZones] AS source
    ON target.[PoliticalTimeZoneID] = source.[PoliticalTimeZoneID]
    WHEN MATCHED THEN
        UPDATE SET
            target.[PoliticalTimeZoneName]       = source.[PoliticalTimeZoneName],
            target.[PresentationString]          = source.[PresentationString],
            target.[MSTimeZoneName]              = source.[MSTimeZoneName],
            target.[RawTimeZoneOffset]           = source.[RawTimeZoneOffset],
            target.[RawTimeZoneOffsetMinutes]    = source.[RawTimeZoneOffsetMinutes],
            target.[RawTimeZoneOffsetMilSeconds] = source.[RawTimeZoneOffsetMilSeconds],
            target.[IsDLS]                       = source.[IsDLS],
            target.[IsActive]                    = source.[IsActive],
            target.[IsDeleted]                   = source.[IsDeleted],
            target.[ModifiedDate]                = sysdatetimeoffset()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            [PoliticalTimeZoneID], [PoliticalTimeZoneName], [PresentationString],
            [MSTimeZoneName], [RawTimeZoneOffset], [RawTimeZoneOffsetMinutes],
            [RawTimeZoneOffsetMilSeconds], [IsDLS], [IsActive], [IsDeleted]
        )
        VALUES (
            source.[PoliticalTimeZoneID], source.[PoliticalTimeZoneName], source.[PresentationString],
            source.[MSTimeZoneName], source.[RawTimeZoneOffset], source.[RawTimeZoneOffsetMinutes],
            source.[RawTimeZoneOffsetMilSeconds], source.[IsDLS], source.[IsActive], source.[IsDeleted]
        );

    PRINT 'MAC.PoliticalTimeZones seeded.';

    -- =========================================================================
    -- 3. MAC.PoliticalStates
    --    PK: PoliticalStateID (varchar) — not an identity column
    --    DEX_ROW is identity but not the PK; omit from INSERT
    -- =========================================================================
    MERGE INTO [MAC].[PoliticalStates] AS target
    USING [NVL9_MAIN].[MAC].[PoliticalStates] AS source
    ON target.[PoliticalStateID] = source.[PoliticalStateID]
    WHEN MATCHED THEN
        UPDATE SET
            target.[PoliticalCountryId]  = source.[PoliticalCountryId],
            target.[PoliticalStateName]  = source.[PoliticalStateName],
            target.[StateAB]             = source.[StateAB],
            target.[GLStateCode]         = source.[GLStateCode],
            target.[IsActive]            = source.[IsActive],
            target.[IsDeleted]           = source.[IsDeleted],
            target.[ModifiedDate]        = sysdatetimeoffset()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([PoliticalStateID], [PoliticalCountryId], [PoliticalStateName], [StateAB], [GLStateCode], [IsActive], [IsDeleted])
        VALUES (source.[PoliticalStateID], source.[PoliticalCountryId], source.[PoliticalStateName], source.[StateAB], source.[GLStateCode], source.[IsActive], source.[IsDeleted]);

    PRINT 'MAC.PoliticalStates seeded.';

    -- =========================================================================
    -- 4. MAC.PoliticalStatesAndTimeZoneMaps
    --    PK: PoliticalStatesAndTimeZoneMapID (identity int) — auto-generated
    --    Merge key: (PoliticalStateId, PoliticalTimeZoneId, OrderPriority)
    -- =========================================================================
    MERGE INTO [MAC].[PoliticalStatesAndTimeZoneMaps] AS target
    USING [NVL9_MAIN].[MAC].[PoliticalStatesAndTimeZoneMaps] AS source
    ON  target.[PoliticalStateId]    = source.[PoliticalStateId]
    AND target.[PoliticalTimeZoneId] = source.[PoliticalTimeZoneId]
    AND target.[OrderPriority]       = source.[OrderPriority]
    WHEN MATCHED THEN
        UPDATE SET
            target.[IsActive]     = source.[IsActive],
            target.[IsDeleted]    = source.[IsDeleted],
            target.[ModifiedDate] = sysdatetimeoffset()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([PoliticalStateId], [PoliticalTimeZoneId], [OrderPriority], [IsActive], [IsDeleted])
        VALUES (source.[PoliticalStateId], source.[PoliticalTimeZoneId], source.[OrderPriority], source.[IsActive], source.[IsDeleted]);

    PRINT 'MAC.PoliticalStatesAndTimeZoneMaps seeded.';

    -- -------------------------------------------------------------------------
    -- Record migration
    -- -------------------------------------------------------------------------
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName, 'Seeds MAC political reference data (Countries 4, TimeZones 17, States 61, StateTZMaps 75) from NVL9_MAIN');

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
    DELETE FROM [MAC].[PoliticalStatesAndTimeZoneMaps];
    DELETE FROM [MAC].[PoliticalStates];
    DELETE FROM [MAC].[PoliticalTimeZones];
    DELETE FROM [MAC].[PoliticalCountries];

    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = '20260505_1400_SeedMAC_PoliticalReferenceData';
*/
