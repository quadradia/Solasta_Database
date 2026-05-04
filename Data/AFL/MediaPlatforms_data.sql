/*******************************************************************************
 * Object Type: Data (Seed)
 * Schema: AFL
 * Name: MediaPlatforms_data
 * Description: Seed data for AFL.MediaPlatforms. Contains the standard set of
 *              social media and advertising platforms supported by the affiliate
 *              marketing tracking system. MediaPlatformCode is the short code
 *              embedded in tracking tokens (e.g., AFL-LI-00042).
 * Author:
 * Created: 2026-05-04
 * Dependencies: AFL.MediaPlatforms
 ******************************************************************************/

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
GO
