/*******************************************************************************
 * Object Type: Seed Data
 * Schema: INE
 * Name: MovementTypes_data
 * Description: The nine movement types and the location rules INE.spMovementPost enforces for each.
 * Dependencies: INE.MovementTypes
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET NOCOUNT ON;
BEGIN TRANSACTION;
    -- From/To rule NULL = any stock-holding location (Warehouse, Vehicle, Staging).
    MERGE INTO [INE].[MovementTypes] AS T
    USING (VALUES
        (1, 'Receive', N'Receive', N'Stock arrives from a vendor (posted with a receipt).', 0, 1, NULL, NULL, 0, 10),
        (2, 'Transfer', N'Transfer', N'Stock moves between warehouses, vehicles and staging areas.', 1, 1, NULL, NULL, 0, 20),
        (3, 'IssueToJob', N'Issue to Job', N'Stock goes out to a customer''s job and is installed.', 1, 1, NULL, 'Job', 1, 30),
        (4, 'ReturnFromJob', N'Return from Job', N'Unused or removed stock comes back from a job.', 1, 1, 'Job', NULL, 1, 40),
        (5, 'ReturnToVendor', N'Return to Vendor', N'Defective or excess stock goes back to a supplier (Reference = RMA number).', 1, 1, NULL, 'Vendor', 0, 50),
        (6, 'AdjustIn', N'Adjust In', N'Stock found or an opening balance.', 0, 1, NULL, NULL, 0, 60),
        (7, 'AdjustOut', N'Adjust Out', N'Stock that cannot be found.', 1, 0, NULL, NULL, 0, 70),
        (8, 'Scrap', N'Scrap', N'Damaged stock written off.', 1, 0, NULL, NULL, 0, 80),
        (9, 'Reversal', N'Reversal', N'Undoes an earlier movement; its ends mirror the original (INE.spMovementReverse).', 0, 0, NULL, NULL, 0, 90)
    ) AS S ([MovementTypeID], [Code], [Name], [Description], [RequiresFrom], [RequiresTo], [FromLocationTypeCode], [ToLocationTypeCode], [RequiresLead], [SortOrder])
    ON T.[MovementTypeID] = S.[MovementTypeID]
    WHEN MATCHED THEN UPDATE SET T.[Code] = S.[Code], T.[Name] = S.[Name], T.[Description] = S.[Description],
        T.[RequiresFrom] = S.[RequiresFrom], T.[RequiresTo] = S.[RequiresTo], T.[FromLocationTypeCode] = S.[FromLocationTypeCode],
        T.[ToLocationTypeCode] = S.[ToLocationTypeCode], T.[RequiresLead] = S.[RequiresLead], T.[SortOrder] = S.[SortOrder],
        T.[ModifiedDate] = SYSDATETIMEOFFSET()
    WHEN NOT MATCHED THEN INSERT ([MovementTypeID], [Code], [Name], [Description], [RequiresFrom], [RequiresTo],
        [FromLocationTypeCode], [ToLocationTypeCode], [RequiresLead], [SortOrder])
        VALUES (S.[MovementTypeID], S.[Code], S.[Name], S.[Description], S.[RequiresFrom], S.[RequiresTo],
        S.[FromLocationTypeCode], S.[ToLocationTypeCode], S.[RequiresLead], S.[SortOrder]);
COMMIT TRANSACTION;
GO
