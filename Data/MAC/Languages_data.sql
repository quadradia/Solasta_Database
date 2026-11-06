/*******************************************************************************
 * Object Type: Data (Seed)
 * Schema: MAC
 * Name: Languages_data
 * Description: Idempotent seed for MAC.Languages (6 rows), generated from dev
 *              SOL_MAIN on 2026-11-06 so new environments (production) get the same
 *              reference data. Merges on the primary key; never deletes rows.
 * Author: Andres Sosa
 * Created: 2026-11-06
 * Dependencies: MAC.Languages
 ******************************************************************************/
SET NOCOUNT ON;
SET XACT_ABORT ON;

MERGE INTO [MAC].[Languages] AS target
USING (VALUES
    (N'en', N'English', 1, 0, '2016-11-17 07:58:22.9625646 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2016-11-17 07:58:22.9625646 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (N'en-US', N'English (USA)', 1, 0, '2025-12-22 14:37:10.9981894 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2025-12-22 14:37:10.9981894 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (N'es', N'Spanish', 1, 0, '2016-11-17 07:58:22.9625646 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2016-11-17 07:58:22.9625646 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (N'fr', N'French', 1, 0, '2016-11-17 07:58:22.9625646 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2016-11-17 07:58:22.9625646 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (N'pt', N'Portuguese', 1, 0, '2016-11-17 07:58:22.9625646 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2016-11-17 07:58:22.9625646 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (N'zh', N'Mandarin', 1, 0, '2016-11-17 07:58:22.9625646 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2016-11-17 07:58:22.9625646 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a')
) AS source ([LanguageID], [Name], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
ON target.[LanguageID] = source.[LanguageID]
WHEN MATCHED THEN
    UPDATE SET
        target.[Name] = source.[Name],
        target.[IsActive] = source.[IsActive],
        target.[IsDeleted] = source.[IsDeleted],
        target.[ModifiedDate] = source.[ModifiedDate],
        target.[ModifiedById] = source.[ModifiedById]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([LanguageID], [Name], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
    VALUES (source.[LanguageID], source.[Name], source.[IsActive], source.[IsDeleted], source.[ModifiedDate], source.[ModifiedById], source.[CreatedDate], source.[CreatedById]);

PRINT 'MAC.Languages seeded.';
GO