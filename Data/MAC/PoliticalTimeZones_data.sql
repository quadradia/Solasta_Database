/*******************************************************************************
 * Object Type: Data (Seed)
 * Schema: MAC
 * Name: PoliticalTimeZones_data
 * Description: Idempotent seed for MAC.PoliticalTimeZones sourced from
 *              NVL9_MAIN. Merges on PoliticalTimeZoneID (plain int PK — not
 *              an identity column). Computed columns (TimezoneOffset,
 *              TimeZoneOffsetMinutes, etc.) are excluded; they are derived
 *              automatically from the Raw* columns via UTL functions.
 * Author: Andres Sosa
 * Created: 2026-05-05
 * Dependencies: MAC.PoliticalTimeZones, NVL9_MAIN on same server instance
 ******************************************************************************/

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
GO
