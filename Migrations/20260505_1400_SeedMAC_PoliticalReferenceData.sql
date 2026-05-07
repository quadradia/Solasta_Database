/*
Migration: 20260505_1400_SeedMAC_PoliticalReferenceData
Author: Andres Sosa
Date: 2026-05-05
Description: Seeds the four MAC political reference tables using hardcoded
             VALUES (standalone — no cross-database dependency). All four
             tables must already exist before this migration runs.

             Tables seeded (in FK-safe order):
               1. MAC.PoliticalCountries      (4 rows)
               2. MAC.PoliticalTimeZones     (17 rows)
               3. MAC.PoliticalStates        (61 rows)
               4. MAC.PoliticalStatesAndTimeZoneMaps (75 rows)

             The MERGEs are idempotent — safe to re-run at any time.
             Source data sourced from NVL9_MAIN on 2026-05-06.

Dependencies:
  20260313_0846_Baseline_ObjectsDeployed       (MAC schema tables)
  20260505_1300_CreatePoliticalStatesAndTimeZoneMaps
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
    -- 1. MAC.PoliticalCountries  (4 rows)
    -- =========================================================================
    MERGE INTO [MAC].[PoliticalCountries] AS target
    USING (VALUES
    ('CAN', 'Canada', 'CAN', 1, 0),
    ('NON', 'NO COUNTRY', 'NON', 1, 0),
    ('UKN', 'United Kingdom', 'UK', 1, 0),
    ('USA', 'United States of America', 'USA', 1, 0)
    ) AS source ([PoliticalCountryID], [PoliticalCountryName], [CountryAB], [IsActive], [IsDeleted])
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
    -- 2. MAC.PoliticalTimeZones  (17 rows)
    --    PoliticalTimeZoneID is NOT an identity — explicit values required.
    -- =========================================================================
    MERGE INTO [MAC].[PoliticalTimeZones] AS target
    USING (VALUES
    ( 1, 'US/Eastern', '(GMT -05:00) US/Eastern', 'Atlantic Standard Time', -5, -300, -18000000, 1, 1, 0),
    ( 2, 'US/Central', '(GMT -06:00) US/Central', 'Central Standard Time', -6, -360, -21600000, 0, 1, 0),
    ( 3, 'US/Arizona', '(GMT -07:00) US/Arizona', 'Arizona Standard Time', -7, -420, -25200000, 0, 1, 0),
    ( 4, 'US/Mountain', '(GMT -07:00) US/Mountain', 'Mountain Standard Time', -7, -420, -25200000, 1, 1, 0),
    ( 5, 'US/Pacific', '(GMT -08:00) US/Pacific', 'Pacific Standard Time', -8, -480, -28800000, 0, 1, 0),
    ( 6, 'US/Alaska', '(GMT -09:00) US/Alaska', 'Alaska Standard Time', -9, -540, -32400000, 0, 1, 0),
    ( 7, 'US/Aleutian', '(GMT -10:00) US/Aleutian', 'Aleutian Standard Time', -10, -600, -36000000, 0, 1, 0),
    ( 8, 'US/Hawaii', '(GMT -10:00) US/Hawaii', 'Hawaii Standard Time', -10, -600, -36000000, 0, 1, 0),
    ( 9, 'US/Samoa', '(GMT -11:00) US/Samoa', 'Samoa Standard Time', -11, -660, -39600000, 0, 1, 0),
    (10, 'US/Guam', '(GMT +10:00) US/Guam', 'Chamarro Standard Time', 10, 600, 36000000, 0, 1, 0),
    (11, 'FM/Chuuk', '(GMT +10:00) FM/Chuuk', 'Chuuk Time', 10, 600, 36000000, 0, 1, 0),
    (12, 'FM/Kost', '(GMT +11:00) FM/Kost', 'Kosrae Time (Micronesia)', 11, 660, 39600000, 0, 1, 0),
    (13, 'FM/Pont', '(GMT +11:00) FM/Pont', 'PONAPE TIME (Micronesia)', 11, 660, 39600000, 0, 1, 0),
    (14, 'FM/Yap', '(GMT +10:00) FM/Yap', 'YAP TIME (Micronesia)', 10, 600, 36000000, 0, 1, 0),
    (15, 'MHT', '(GMT +10:00) Pacific/MHT', 'Majuro', 12, 720, 43200000, 0, 1, 0),
    (16, 'Palau', '(GMT +09:00) Pacific/Palau', 'Palau Time', 9, 540, 32400000, 0, 1, 0),
    (300, 'Canada/Mountain', '(GMT -07:00) Canada/Mountain', 'Mountain Standard Time', -7, -420, -25200000, 0, 1, 0)
    ) AS source (
        [PoliticalTimeZoneID], [PoliticalTimeZoneName], [PresentationString],
        [MSTimeZoneName], [RawTimeZoneOffset], [RawTimeZoneOffsetMinutes],
        [RawTimeZoneOffsetMilSeconds], [IsDLS], [IsActive], [IsDeleted]
    )
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
    -- 3. MAC.PoliticalStates  (61 rows)
    -- =========================================================================
    MERGE INTO [MAC].[PoliticalStates] AS target
    USING (VALUES
    ('00', 'NON', 'NO STATE', '00', NULL, 0, 0),
    ('AK', 'USA', 'ALASKA', 'AK', '010', 1, 0),
    ('AL', 'USA', 'ALABAMA', 'AL', '020', 1, 0),
    ('AR', 'USA', 'ARKANSAS', 'AR', '030', 1, 0),
    ('AS', 'USA', 'AMERICAN SAMOA', 'AS', NULL, 1, 0),
    ('AZ', 'USA', 'ARIZONA', 'AZ', '040', 1, 0),
    ('CA', 'USA', 'CALIFORNIA', 'CA', '050', 1, 0),
    ('CO', 'USA', 'COLORADO', 'CO', '060', 1, 0),
    ('CT', 'USA', 'CONNECTICUT', 'CT', '070', 1, 0),
    ('DC', 'USA', 'DISTRICT OF COLUMBIA', 'DC', '510', 1, 0),
    ('DE', 'USA', 'DELAWARE', 'DE', '080', 1, 0),
    ('FL', 'USA', 'FLORIDA', 'FL', '090', 1, 0),
    ('FM', 'USA', 'FEDERATED STATES OF MICRONESIA', 'FM', NULL, 1, 0),
    ('GA', 'USA', 'GEORGIA', 'GA', '100', 1, 0),
    ('GU', 'USA', 'GUAM', 'GU', NULL, 1, 0),
    ('HI', 'USA', 'HAWAII', 'HI', '110', 1, 0),
    ('IA', 'USA', 'IOWA', 'IA', '120', 1, 0),
    ('ID', 'USA', 'IDAHO', 'ID', '130', 1, 0),
    ('IL', 'USA', 'ILLINOIS', 'IL', '140', 1, 0),
    ('IN', 'USA', 'INDIANA', 'IN', '150', 1, 0),
    ('KS', 'USA', 'KANSAS', 'KS', '160', 1, 0),
    ('KY', 'USA', 'KENTUCKY', 'KY', '170', 1, 0),
    ('LA', 'USA', 'LOUISIANA', 'LA', '180', 1, 0),
    ('MA', 'USA', 'MASSACHUSETTS', 'MA', '190', 1, 0),
    ('MD', 'USA', 'MARYLAND', 'MD', '200', 1, 0),
    ('ME', 'USA', 'MAINE', 'ME', '210', 1, 0),
    ('MH', 'USA', 'MARSHALL ISLANDS', 'MH', NULL, 1, 0),
    ('MI', 'USA', 'MICHIGAN', 'MI', '220', 1, 0),
    ('MN', 'USA', 'MINNESOTA', 'MN', '230', 1, 0),
    ('MO', 'USA', 'MISSOURI', 'MO', '240', 1, 0),
    ('MP', 'USA', 'NORTHERN MARIANA ISLANDS', 'MP', NULL, 1, 0),
    ('MS', 'USA', 'MISSISSIPPI', 'MS', '250', 1, 0),
    ('MT', 'USA', 'MONTANA', 'MT', '260', 1, 0),
    ('NC', 'USA', 'NORTH CAROLINA', 'NC', '270', 1, 0),
    ('ND', 'USA', 'NORTH DAKOTA', 'ND', '280', 1, 0),
    ('NE', 'USA', 'NEBRASKA', 'NE', '290', 1, 0),
    ('NH', 'USA', 'NEW HAMPSHIRE', 'NH', '300', 1, 0),
    ('NJ', 'USA', 'NEW JERSEY', 'NJ', '310', 1, 0),
    ('NM', 'USA', 'NEW MEXICO', 'NM', '320', 1, 0),
    ('NN', 'NON', 'NO STATE', 'NN', NULL, 0, 1),
    ('NV', 'USA', 'NEVADA', 'NV', '330', 1, 0),
    ('NY', 'USA', 'NEW YORK', 'NY', '340', 1, 0),
    ('OH', 'USA', 'OHIO', 'OH', '350', 1, 0),
    ('OK', 'USA', 'OKLAHOMA', 'OK', '360', 1, 0),
    ('OR', 'USA', 'OREGON', 'OR', '370', 1, 0),
    ('PA', 'USA', 'PENNSYLVANIA', 'PA', '380', 1, 0),
    ('PR', 'USA', 'PUERTO RICO', 'PR', NULL, 1, 0),
    ('PW', 'USA', 'PALAU', 'PW', NULL, 1, 0),
    ('RI', 'USA', 'RHODE ISLAND', 'RI', '390', 1, 0),
    ('SC', 'USA', 'SOUTH CAROLINA', 'SC', '400', 1, 0),
    ('SD', 'USA', 'SOUTH DAKOTA', 'SD', '410', 1, 0),
    ('TN', 'USA', 'TENNESSEE', 'TN', '420', 1, 0),
    ('TX', 'USA', 'TEXAS', 'TX', '430', 1, 0),
    ('UT', 'USA', 'UTAH', 'UT', '440', 1, 0),
    ('VA', 'USA', 'VIRGINIA', 'VA', '450', 1, 0),
    ('VI', 'USA', 'VIRGIN ISLANDS', 'VI', NULL, 1, 0),
    ('VT', 'USA', 'VERMONT', 'VT', '460', 1, 0),
    ('WA', 'USA', 'WASHINGTON', 'WA', '470', 1, 0),
    ('WI', 'USA', 'WISCONSIN', 'WI', '480', 1, 0),
    ('WV', 'USA', 'WEST VIRGINIA', 'WV', '490', 1, 0),
    ('WY', 'USA', 'WYOMING', 'WY', '500', 1, 0)
    ) AS source ([PoliticalStateID], [PoliticalCountryId], [PoliticalStateName], [StateAB], [GLStateCode], [IsActive], [IsDeleted])
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
    -- 4. MAC.PoliticalStatesAndTimeZoneMaps  (75 rows)
    --    PK is identity — merge key is (StateId, TimeZoneId, OrderPriority)
    -- =========================================================================
    MERGE INTO [MAC].[PoliticalStatesAndTimeZoneMaps] AS target
    USING (VALUES
    ('AK', 6, 1, 1, 0),
    ('AK', 7, 2, 1, 0),
    ('AL', 2, 1, 1, 0),
    ('AR', 2, 1, 1, 0),
    ('AS', 9, 1, 1, 0),
    ('AZ', 3, 1, 1, 0),
    ('CA', 5, 1, 1, 0),
    ('CO', 4, 1, 1, 0),
    ('CT', 1, 1, 1, 0),
    ('DC', 1, 1, 1, 0),
    ('DE', 1, 1, 1, 0),
    ('FL', 1, 1, 1, 0),
    ('FL', 2, 2, 1, 0),
    ('FM', 11, 1, 1, 0),
    ('FM', 12, 2, 1, 0),
    ('FM', 13, 3, 1, 0),
    ('FM', 14, 4, 1, 0),
    ('GA', 1, 1, 1, 0),
    ('GU', 10, 1, 1, 0),
    ('HI', 8, 1, 1, 0),
    ('IA', 2, 1, 1, 0),
    ('ID', 4, 1, 1, 0),
    ('IL', 2, 1, 1, 0),
    ('IN', 1, 1, 1, 0),
    ('IN', 2, 2, 1, 0),
    ('KS', 2, 1, 1, 0),
    ('KS', 4, 2, 1, 0),
    ('KY', 1, 1, 1, 0),
    ('KY', 2, 2, 1, 0),
    ('LA', 2, 1, 1, 0),
    ('MA', 1, 1, 1, 0),
    ('MD', 1, 1, 1, 0),
    ('ME', 1, 1, 1, 0),
    ('MH', 15, 1, 1, 0),
    ('MI', 1, 1, 1, 0),
    ('MI', 2, 1, 1, 0),
    ('MN', 2, 1, 1, 0),
    ('MO', 2, 1, 1, 0),
    ('MP', 10, 1, 1, 0),
    ('MS', 2, 1, 1, 0),
    ('MT', 4, 1, 1, 0),
    ('NC', 1, 1, 1, 0),
    ('ND', 2, 1, 1, 0),
    ('ND', 4, 2, 1, 0),
    ('NE', 2, 1, 1, 0),
    ('NE', 4, 2, 1, 0),
    ('NH', 1, 1, 1, 0),
    ('NJ', 1, 1, 1, 0),
    ('NM', 4, 1, 1, 0),
    ('NV', 5, 1, 1, 0),
    ('NV', 4, 2, 1, 0),
    ('NY', 1, 1, 1, 0),
    ('OH', 1, 1, 1, 0),
    ('OK', 2, 1, 1, 0),
    ('OR', 5, 1, 1, 0),
    ('OR', 4, 2, 1, 0),
    ('PA', 1, 1, 1, 0),
    ('PR', 1, 1, 1, 0),
    ('PW', 16, 1, 1, 0),
    ('RI', 1, 1, 1, 0),
    ('SC', 1, 1, 1, 0),
    ('SD', 2, 1, 1, 0),
    ('SD', 4, 2, 1, 0),
    ('TN', 1, 1, 1, 0),
    ('TN', 2, 2, 1, 0),
    ('TX', 2, 1, 1, 0),
    ('TX', 4, 2, 1, 0),
    ('UT', 4, 1, 1, 0),
    ('VA', 1, 1, 1, 0),
    ('VI', 1, 1, 1, 0),
    ('VT', 1, 1, 1, 0),
    ('WA', 5, 1, 1, 0),
    ('WI', 2, 1, 1, 0),
    ('WV', 1, 1, 1, 0),
    ('WY', 4, 1, 1, 0)
    ) AS source ([PoliticalStateId], [PoliticalTimeZoneId], [OrderPriority], [IsActive], [IsDeleted])
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
