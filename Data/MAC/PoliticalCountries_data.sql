/*******************************************************************************
 * Object Type: Data (Seed)
 * Schema: MAC
 * Name: PoliticalCountries_data
 * Description: Idempotent seed for MAC.PoliticalCountries sourced from
 *              NVL9_MAIN. Merges on PoliticalCountryID (nvarchar PK).
 *              DEX_ROW (identity) is excluded — auto-generated on insert.
 * Author: Andres Sosa
 * Created: 2026-05-05
 * Dependencies: MAC.PoliticalCountries, NVL9_MAIN on same server instance
 ******************************************************************************/

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
GO
