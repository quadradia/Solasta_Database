/*******************************************************************************
 * Object Type: Seed Data
 * Schema: INE
 * Name: LocationTypes_data
 * Description: The five location types, with fixed IDs. Code reads them by Code.
 * Dependencies: INE.LocationTypes
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET NOCOUNT ON;
BEGIN TRANSACTION;
    MERGE INTO [INE].[LocationTypes] AS T
    USING (VALUES
        (1, 'Warehouse', N'Warehouse', N'A building or yard where stock is kept.', 1),
        (2, 'Vehicle', N'Vehicle', N'An installer''s truck or van; stock there is on hand but out in the field.', 1),
        (3, 'Staging', N'Staging Area', N'Where a job''s materials are kitted before they go out.', 1),
        (4, 'Job', N'Job Site', N'A customer''s installation (one per lead). Stock issued here is installed, not on hand.', 0),
        (5, 'Vendor', N'Vendor', N'A supplier that stock is returned to.', 0)
    ) AS S ([LocationTypeID], [Code], [Name], [Description], [IsStockHolding])
    ON T.[LocationTypeID] = S.[LocationTypeID]
    WHEN MATCHED THEN UPDATE SET T.[Code] = S.[Code], T.[Name] = S.[Name], T.[Description] = S.[Description],
        T.[IsStockHolding] = S.[IsStockHolding], T.[ModifiedDate] = SYSDATETIMEOFFSET()
    WHEN NOT MATCHED THEN INSERT ([LocationTypeID], [Code], [Name], [Description], [IsStockHolding])
        VALUES (S.[LocationTypeID], S.[Code], S.[Name], S.[Description], S.[IsStockHolding]);
COMMIT TRANSACTION;
GO
