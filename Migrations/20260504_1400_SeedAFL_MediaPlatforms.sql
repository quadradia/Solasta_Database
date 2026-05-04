/*
Migration: 20260504_1400_SeedAFL_MediaPlatforms
Author:
Date: 2026-05-04
Description: Seeds AFL.MediaPlatforms with the standard set of social media
             and advertising platforms supported by the affiliate marketing
             tracking system:
               LinkedIn (LI), Facebook (FB), Instagram (IG), TikTok (TT),
               X (X), YouTube (YT), Google Ads (GA), Email (EM)
             Uses MERGE so the script is safe to re-run (idempotent).
Dependencies: 20260504_1200_CreateAFL_AffiliateMarketingSchema
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260504_1400_SeedAFL_MediaPlatforms';

    -- Check if already applied
    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- Verify target table exists
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'MediaPlatforms' AND schema_id = SCHEMA_ID('AFL'))
        RAISERROR('AFL.MediaPlatforms does not exist. Run 20260504_1200 first.', 16, 1);

    -- Seed platform data
    MERGE INTO [AFL].[MediaPlatforms] AS target
    USING (VALUES
    ('LinkedIn', 'LI', 'https://cdn.solasta.com/icons/platforms/linkedin.svg'),
    ('Facebook', 'FB', 'https://cdn.solasta.com/icons/platforms/facebook.svg'),
    ('Instagram', 'IG', 'https://cdn.solasta.com/icons/platforms/instagram.svg'),
    ('TikTok', 'TT', 'https://cdn.solasta.com/icons/platforms/tiktok.svg'),
    ('X', 'X', 'https://cdn.solasta.com/icons/platforms/x.svg'),
    ('YouTube', 'YT', 'https://cdn.solasta.com/icons/platforms/youtube.svg'),
    ('Google Ads', 'GA', 'https://cdn.solasta.com/icons/platforms/googleads.svg'),
    ('Email', 'EM', NULL)
    ) AS source ([MediaPlatformName], [MediaPlatformCode], [IconUrl])
    ON target.[MediaPlatformCode] = source.[MediaPlatformCode]
    WHEN MATCHED THEN
        UPDATE SET
            target.[MediaPlatformName] = source.[MediaPlatformName],
            target.[IconUrl]           = source.[IconUrl],
            target.[ModifiedDate]      = sysdatetimeoffset()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([MediaPlatformName], [MediaPlatformCode], [IconUrl])
        VALUES (source.[MediaPlatformName], source.[MediaPlatformCode], source.[IconUrl]);

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName, 'Seeds AFL.MediaPlatforms with 8 standard advertising platforms: LI, FB, IG, TT, X, YT, GA, EM');

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
DELETE FROM [AFL].[MediaPlatforms]
WHERE [MediaPlatformCode] IN ('LI', 'FB', 'IG', 'TT', 'X', 'YT', 'GA', 'EM');

DELETE FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = '20260504_1400_SeedAFL_MediaPlatforms';
*/
