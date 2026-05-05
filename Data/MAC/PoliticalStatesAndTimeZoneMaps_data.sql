/*******************************************************************************
 * Object Type: Data (Seed)
 * Schema: MAC
 * Name: PoliticalStatesAndTimeZoneMaps_data
 * Description: Idempotent seed for MAC.PoliticalStatesAndTimeZoneMaps sourced
 *              from NVL9_MAIN. PoliticalStatesAndTimeZoneMapID is an identity
 *              column and is excluded from INSERT (auto-generated). Merge key
 *              is (PoliticalStateId, PoliticalTimeZoneId, OrderPriority).
 * Author: Andres Sosa
 * Created: 2026-05-05
 * Dependencies:
 *   MAC.PoliticalStatesAndTimeZoneMaps,
 *   MAC.PoliticalStates (FK), MAC.PoliticalTimeZones (FK),
 *   NVL9_MAIN on same server instance
 ******************************************************************************/

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
GO
