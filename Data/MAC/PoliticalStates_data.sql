/*******************************************************************************
 * Object Type: Data (Seed)
 * Schema: MAC
 * Name: PoliticalStates_data
 * Description: Idempotent seed for MAC.PoliticalStates sourced from NVL9_MAIN.
 *              Merges on PoliticalStateID (varchar PK). DEX_ROW (identity)
 *              is excluded — auto-generated on insert.
 * Author: Andres Sosa
 * Created: 2026-05-05
 * Dependencies:
 *   MAC.PoliticalStates, MAC.PoliticalCountries (FK),
 *   NVL9_MAIN on same server instance
 ******************************************************************************/

MERGE INTO [MAC].[PoliticalStates] AS target
USING [NVL9_MAIN].[MAC].[PoliticalStates] AS source
ON target.[PoliticalStateID] = source.[PoliticalStateID]
WHEN MATCHED THEN
    UPDATE SET
        target.[PoliticalCountryId] = source.[PoliticalCountryId],
        target.[PoliticalStateName] = source.[PoliticalStateName],
        target.[StateAB]            = source.[StateAB],
        target.[GLStateCode]        = source.[GLStateCode],
        target.[IsActive]           = source.[IsActive],
        target.[IsDeleted]          = source.[IsDeleted],
        target.[ModifiedDate]       = sysdatetimeoffset()
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([PoliticalStateID], [PoliticalCountryId], [PoliticalStateName], [StateAB], [GLStateCode], [IsActive], [IsDeleted])
    VALUES (source.[PoliticalStateID], source.[PoliticalCountryId], source.[PoliticalStateName], source.[StateAB], source.[GLStateCode], source.[IsActive], source.[IsDeleted]);
GO
