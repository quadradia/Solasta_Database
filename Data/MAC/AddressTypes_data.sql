/*******************************************************************************
 * Object Type: Data (Seed)
 * Schema: MAC
 * Name: AddressTypes_data
 * Description: Idempotent seed for MAC.AddressTypes (2 rows), generated from dev
 *              SOL_MAIN on 2026-11-06 so new environments (production) get the same
 *              reference data. Merges on the primary key; never deletes rows.
 * Author: Andres Sosa
 * Created: 2026-11-06
 * Dependencies: MAC.AddressTypes
 ******************************************************************************/
SET NOCOUNT ON;
SET XACT_ABORT ON;

MERGE INTO [MAC].[AddressTypes] AS target
USING (VALUES
    (N'N', N'Non Standard', 1, 0, '2016-10-22 16:53:46.2585358 -06:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2016-10-22 16:53:46.2585358 -06:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (N'S', N'Standard Address', 1, 0, '2016-10-22 16:53:46.2585358 -06:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2016-10-22 16:53:46.2585358 -06:00', 'e6872b58-52b2-415c-a32b-45805f95a70a')
) AS source ([AddressTypeID], [AddressTypeName], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
ON target.[AddressTypeID] = source.[AddressTypeID]
WHEN MATCHED THEN
    UPDATE SET
        target.[AddressTypeName] = source.[AddressTypeName],
        target.[IsActive] = source.[IsActive],
        target.[IsDeleted] = source.[IsDeleted],
        target.[ModifiedDate] = source.[ModifiedDate],
        target.[ModifiedById] = source.[ModifiedById]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([AddressTypeID], [AddressTypeName], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
    VALUES (source.[AddressTypeID], source.[AddressTypeName], source.[IsActive], source.[IsDeleted], source.[ModifiedDate], source.[ModifiedById], source.[CreatedDate], source.[CreatedById]);

PRINT 'MAC.AddressTypes seeded.';
GO