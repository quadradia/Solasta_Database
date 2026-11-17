/*******************************************************************************
 * Object Type: Test Script
 * Schema: INE
 * Name: INE_EndToEnd_Tests
 * Description: End-to-end tests of the INE inventory engine: PO submit and line locking,
 *              receiving (partial, over-receipt, duplicate serials), transfers, location
 *              rules, allocations, issuing to a job, reversals, the append-only ledger,
 *              stock counts, scrap, returns to vendor, PO close/reopen and a final
 *              ledger-vs-balance drift check. Prints PASS/FAIL per check.
 *              DESTRUCTIVE: it writes test rows and relaxes QAL.Leads FKs. Run it only in
 *              a throwaway copy of the database whose name contains TEST, e.g.
 *                BACKUP DATABASE SOL_MAIN TO DISK = N'...\SOL_MAIN.bak' WITH COPY_ONLY;
 *                RESTORE DATABASE SOL_INE_TEST FROM DISK = N'...\SOL_MAIN.bak' WITH MOVE ...;
 *              then apply the INE migrations and run:
 *                sqlcmd -E -S . -d SOL_INE_TEST -i Scripts\Tests\INE\INE_EndToEnd_Tests.sql
 *              Uses the dev Solasta Lighting tenant and its first user.
 * Dependencies: INE migrations 20261117_1800, 20261117_1810 and 20261117_1900,
 *               ACC.spSessionContextCreate
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
DECLARE @OkX BIT;
IF DB_NAME() NOT LIKE N'%TEST%' THROW 50000, 'Run this only in a throwaway database whose name contains TEST.', 1;
GO
DECLARE @OkX BIT;
-- A lead to act as the job (FKs relaxed in the scratch copy only).
ALTER TABLE [QAL].[Leads] NOCHECK CONSTRAINT ALL;
SET IDENTITY_INSERT [QAL].[Leads] ON;
IF NOT EXISTS (SELECT 1 FROM QAL.Leads WHERE LeadID = 900001)
    INSERT INTO [QAL].[Leads] ([LeadID], [CustomerTypeId], [MasterFileId], [DealerTenantId], [LanguageId], [LeadSourceId], [LeadDispositionId], [FirstName], [LastName])
    VALUES (900001, 'X', 0, 3, N'en', 0, 0, N'Test', N'Job');
SET IDENTITY_INSERT [QAL].[Leads] OFF;
GO
CREATE OR ALTER PROCEDURE #Expect @Sql NVARCHAR(MAX), @Code NVARCHAR(10), @Label NVARCHAR(200)
AS
BEGIN
    BEGIN TRY
        EXEC sys.sp_executesql @Sql;
    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() LIKE N'%' + @Code + N'%' BEGIN PRINT CONCAT(N'PASS  ', @Label, N'  -> ', @Code); RETURN; END;
        PRINT CONCAT(N'FAIL  ', @Label, N'  wrong error: ', LEFT(ERROR_MESSAGE(), 400)); RETURN;
    END CATCH;
    PRINT CONCAT(N'FAIL  ', @Label, N'  expected ', @Code, N' but it succeeded');
END;
GO
CREATE OR ALTER PROCEDURE #Check @Ok BIT, @Label NVARCHAR(200)
AS PRINT CONCAT(CASE WHEN @Ok = 1 THEN N'PASS  ' ELSE N'FAIL  ' END, @Label);
GO
DECLARE @OkX BIT;

-- 0. no session context
EXEC sys.sp_set_session_context @key = N'UserContext', @value = NULL;
EXEC #Expect N'EXEC INE.spMovementPost N''{"movementType":"AdjustIn","toLocationId":1,"lines":[{"stockItemId":1,"quantity":1}]}''', N'04100', N'no session context is rejected';
GO
DECLARE @OkX BIT;
DECLARE @Rc INT, @TestUser UNIQUEIDENTIFIER = (SELECT TOP (1) UserID FROM ACC.Users WHERE DealerTenantId = 3 AND IsActive = 1 AND IsDeleted = 0 ORDER BY CreatedDate);
EXEC @Rc = ACC.spSessionContextCreate @IdentityID = @TestUser, @TenantProxy = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6';
EXEC #Check @Ok = 1, @Label = N'session context set';
DECLARE @T INT = (SELECT DealerTenantId FROM INE.fxGetSessionContext());
EXEC #Check @Ok = @T, @Label = N'fxGetSessionContext returns tenant 3';
GO
DECLARE @OkX BIT;

-- 1. master data
DECLARE @T INT = 3;
INSERT INTO INE.Vendors (DealerTenantId, Code, Name, LeadTimeDays) VALUES (@T, N'GVL', N'Govee Lighting Supply', 10);
DECLARE @V INT = SCOPE_IDENTITY();
INSERT INTO INE.Locations (DealerTenantId, LocationTypeId, Code, Name, UserId) VALUES (@T, 2, N'VAN-01', N'Install Van 1', (SELECT UserId FROM INE.fxGetSessionContext()));
INSERT INTO INE.Locations (DealerTenantId, LocationTypeId, Code, Name, LeadId) VALUES (@T, 4, N'JOB-900001', N'Test Job', 900001);
INSERT INTO INE.Locations (DealerTenantId, LocationTypeId, Code, Name, VendorId) VALUES (@T, 5, N'RTV-GVL', N'Returns to GVL', @V);
INSERT INTO INE.StockItems (DealerTenantId, Sku, Name, TrackingMode, UnitOfMeasure, DefaultVendorId, StandardCost) VALUES
    (@T, N'RAIL-STD', N'Standard rail track', 'Quantity', 'ft', @V, 2.15),
    (@T, N'POD-RGBW', N'RGBW light pod', 'Lot', 'each', @V, 4.80),
    (@T, N'CTRL-WIFI', N'Wi-Fi controller', 'Serial', 'each', @V, 89.00);
EXEC #Check @Ok = 1, @Label = N'master data created';
GO
DECLARE @OkX BIT;
EXEC #Expect N'INSERT INTO INE.StockItems (DealerTenantId, Sku, Name, TrackingMode, UnitOfMeasure) VALUES (3, N''BAD'', N''Bad'', ''Serial'', ''ft'')', N'CK_StockItems_SerialUnit', N'serial items must be counted each';
GO
DECLARE @OkX BIT;

-- 2. purchase order
DECLARE @MAIN INT = (SELECT LocationID FROM INE.Locations WHERE DealerTenantId = 3 AND Code = N'MAIN');
DECLARE @V INT = (SELECT VendorID FROM INE.Vendors WHERE Code = N'GVL');
INSERT INTO INE.PurchaseOrders (DealerTenantId, VendorId, ShipToLocationId, PONumber) VALUES (3, @V, @MAIN, N'PO-0001');
DECLARE @PO BIGINT = SCOPE_IDENTITY();
INSERT INTO INE.PurchaseOrderLines (PurchaseOrderId, LineNumber, StockItemId, QuantityOrdered, UnitCost)
SELECT @PO, 1, StockItemID, 500, 2.10 FROM INE.StockItems WHERE Sku = N'RAIL-STD' UNION ALL
SELECT @PO, 2, StockItemID, 100, 4.75 FROM INE.StockItems WHERE Sku = N'POD-RGBW' UNION ALL
SELECT @PO, 3, StockItemID, 2, 85.00 FROM INE.StockItems WHERE Sku = N'CTRL-WIFI';
UPDATE INE.PurchaseOrderLines SET UnitCost = 2.05 WHERE PurchaseOrderId = @PO AND LineNumber = 1;
EXEC #Check @Ok = 1, @Label = N'draft PO lines editable';
EXEC INE.spPurchaseOrderSetStatus @PurchaseOrderId = @PO, @Action = 'Submit';
DECLARE @Sql NVARCHAR(MAX) = CONCAT(N'UPDATE INE.PurchaseOrderLines SET QuantityOrdered = 600 WHERE PurchaseOrderId = ', @PO, N' AND LineNumber = 1');
EXEC #Expect @Sql, N'04171', N'submitted PO lines are locked';
SET @Sql = CONCAT(N'EXEC INE.spPurchaseOrderSetStatus @PurchaseOrderId = ', @PO, N', @Action = ''Submit''');
EXEC #Expect @Sql, N'04143', N'cannot submit twice';
GO
DECLARE @OkX BIT;

-- 3. receiving
DECLARE @PO BIGINT = (SELECT PurchaseOrderID FROM INE.PurchaseOrders WHERE PONumber = N'PO-0001');
DECLARE @L1 BIGINT = (SELECT PurchaseOrderLineID FROM INE.PurchaseOrderLines WHERE PurchaseOrderId = @PO AND LineNumber = 1);
DECLARE @L2 BIGINT = (SELECT PurchaseOrderLineID FROM INE.PurchaseOrderLines WHERE PurchaseOrderId = @PO AND LineNumber = 2);
DECLARE @L3 BIGINT = (SELECT PurchaseOrderLineID FROM INE.PurchaseOrderLines WHERE PurchaseOrderId = @PO AND LineNumber = 3);
DECLARE @RAIL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'RAIL-STD');
DECLARE @POD INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'POD-RGBW');
DECLARE @CTRL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'CTRL-WIFI');
DECLARE @J NVARCHAR(MAX) = CONCAT(N'{"purchaseOrderId":', @PO, N',"packingSlipNumber":"PS-1","lines":[',
    N'{"stockItemId":', @RAIL, N',"quantity":300,"purchaseOrderLineId":', @L1, N',"unitCost":2.05},',
    N'{"stockItemId":', @POD, N',"quantity":100,"lotNumber":"R-2611-07","purchaseOrderLineId":', @L2, N'},',
    N'{"stockItemId":', @CTRL, N',"serialNumbers":["C8-0001","C8-0002"],"purchaseOrderLineId":', @L3, N'}]}');
DECLARE @R BIGINT, @M BIGINT;
EXEC INE.spReceiptPost @ReceiptJson = @J, @ReceiptId = @R OUTPUT, @MovementId = @M OUTPUT;
DECLARE @S VARCHAR(20) = (SELECT Status FROM INE.PurchaseOrders WHERE PurchaseOrderID = @PO);
SET @OkX = CASE WHEN @S = 'PartiallyReceived' THEN 1 ELSE 0 END; EXEC #Check @Ok = @OkX, @Label = N'partial receipt -> PartiallyReceived';
DECLARE @Ok BIT = CASE WHEN (SELECT QuantityOnHand FROM INE.StockBalances WHERE StockItemId = @RAIL AND LotId IS NULL) = 300
                        AND (SELECT COUNT(*) FROM INE.SerialUnits WHERE StockItemId = @CTRL AND Status = 'InStock') = 2
                        AND (SELECT COUNT(*) FROM INE.Lots WHERE StockItemId = @POD) = 1 THEN 1 ELSE 0 END;
EXEC #Check @Ok = @Ok, @Label = N'receipt created balances, lot and serial units';
SET @J = CONCAT(N'{"purchaseOrderId":', @PO, N',"lines":[{"stockItemId":', @RAIL, N',"quantity":250,"purchaseOrderLineId":', @L1, N'}]}');
DECLARE @Sql NVARCHAR(MAX) = CONCAT(N'EXEC INE.spReceiptPost @ReceiptJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04120', N'over-receipt rejected';
SET @OkX = CASE WHEN (SELECT COUNT(*) FROM INE.Receipts) = 1 THEN 1 ELSE 0 END; EXEC #Check @Ok = @OkX, @Label = N'failed receipt left nothing behind';
SET @J = CONCAT(N'{"purchaseOrderId":', @PO, N',"lines":[{"stockItemId":', @CTRL, N',"serialNumbers":["C8-0001"]}]}');
SET @Sql = CONCAT(N'EXEC INE.spReceiptPost @ReceiptJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04118', N'duplicate serial rejected';
SET @J = CONCAT(N'{"purchaseOrderId":', @PO, N',"lines":[{"stockItemId":', @RAIL, N',"quantity":200,"purchaseOrderLineId":', @L1, N'}]}');
EXEC INE.spReceiptPost @ReceiptJson = @J;
SET @S = (SELECT Status FROM INE.PurchaseOrders WHERE PurchaseOrderID = @PO);
SET @OkX = CASE WHEN @S = 'Received' THEN 1 ELSE 0 END; EXEC #Check @Ok = @OkX, @Label = N'fully received -> Received';
GO
DECLARE @OkX BIT;

-- 4/5. transfers
DECLARE @MAIN INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'MAIN' AND DealerTenantId = 3);
DECLARE @VAN INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'VAN-01');
DECLARE @RAIL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'RAIL-STD');
DECLARE @POD INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'POD-RGBW');
DECLARE @CTRL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'CTRL-WIFI');
DECLARE @J NVARCHAR(MAX) = CONCAT(N'{"movementType":"Transfer","fromLocationId":', @MAIN, N',"toLocationId":', @VAN, N',"lines":[',
    N'{"stockItemId":', @RAIL, N',"quantity":164.5},{"stockItemId":', @POD, N',"quantity":40,"lotNumber":"R-2611-07"},',
    N'{"stockItemId":', @CTRL, N',"serialNumbers":["C8-0001"]}]}');
EXEC INE.spMovementPost @MovementJson = @J;
DECLARE @Ok BIT = CASE WHEN (SELECT QuantityOnHand FROM INE.StockBalances WHERE LocationId = @VAN AND StockItemId = @RAIL) = 164.5
                        AND (SELECT QuantityOnHand FROM INE.StockBalances WHERE LocationId = @MAIN AND StockItemId = @RAIL) = 335.5
                        AND (SELECT CurrentLocationId FROM INE.SerialUnits WHERE SerialNumber = N'C8-0001') = @VAN THEN 1 ELSE 0 END;
EXEC #Check @Ok = @Ok, @Label = N'transfer moved footage, lot and serial';
SET @J = CONCAT(N'{"movementType":"Transfer","fromLocationId":', @MAIN, N',"toLocationId":', @VAN, N',"lines":[{"stockItemId":', @RAIL, N',"quantity":1000}]}');
DECLARE @Sql NVARCHAR(MAX) = CONCAT(N'EXEC INE.spMovementPost @MovementJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04122', N'cannot move more than on hand';
SET @J = CONCAT(N'{"movementType":"Transfer","fromLocationId":', @MAIN, N',"lines":[{"stockItemId":', @RAIL, N',"quantity":1}]}');
SET @Sql = CONCAT(N'EXEC INE.spMovementPost @MovementJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04104', N'transfer needs both ends';
SET @J = CONCAT(N'{"movementType":"Transfer","fromLocationId":', @MAIN, N',"toLocationId":', (SELECT LocationID FROM INE.Locations WHERE Code = N'JOB-900001'), N',"lines":[{"stockItemId":', @RAIL, N',"quantity":1}]}');
SET @Sql = CONCAT(N'EXEC INE.spMovementPost @MovementJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04107', N'transfer cannot go to a job';
SET @J = CONCAT(N'{"movementType":"Transfer","fromLocationId":', @MAIN, N',"toLocationId":', @VAN, N',"lines":[{"stockItemId":', @POD, N',"quantity":1}]}');
SET @Sql = CONCAT(N'EXEC INE.spMovementPost @MovementJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04114', N'lot item needs a lot';
GO
DECLARE @OkX BIT;

-- 6/7. allocations and issue to job
DECLARE @MAIN INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'MAIN' AND DealerTenantId = 3);
DECLARE @VAN INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'VAN-01');
DECLARE @JOB INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'JOB-900001');
DECLARE @RAIL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'RAIL-STD');
DECLARE @A BIGINT;
EXEC INE.spAllocationCreate @LeadId = 900001, @LocationId = @MAIN, @StockItemId = @RAIL, @Quantity = 100, @AllocationId = @A OUTPUT;
DECLARE @J NVARCHAR(MAX) = CONCAT(N'{"movementType":"Transfer","fromLocationId":', @MAIN, N',"toLocationId":', @VAN, N',"lines":[{"stockItemId":', @RAIL, N',"quantity":300}]}');
DECLARE @Sql NVARCHAR(MAX) = CONCAT(N'EXEC INE.spMovementPost @MovementJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04122', N'allocated stock is not available to others';
SET @Sql = CONCAT(N'EXEC INE.spAllocationCreate @LeadId = 900001, @LocationId = ', @MAIN, N', @StockItemId = ', @RAIL, N', @Quantity = 300');
EXEC #Expect @Sql, N'04122', N'cannot over-allocate';
SET @J = CONCAT(N'{"movementType":"IssueToJob","fromLocationId":', @MAIN, N',"toLocationId":', @JOB, N',"lines":[',
    N'{"stockItemId":', @RAIL, N',"quantity":100,"allocationId":', @A, N'},{"stockItemId":', @RAIL, N',"quantity":10}]}');
EXEC INE.spMovementPost @MovementJson = @J;
DECLARE @Ok BIT = CASE WHEN (SELECT Status FROM INE.Allocations WHERE AllocationID = @A) = 'Fulfilled'
                        AND (SELECT QuantityAllocated FROM INE.StockBalances WHERE LocationId = @MAIN AND StockItemId = @RAIL) = 0
                        AND (SELECT QuantityOnHand FROM INE.StockBalances WHERE LocationId = @MAIN AND StockItemId = @RAIL) = 225.5
                        AND (SELECT QuantityOnHand FROM INE.StockBalances WHERE LocationId = @JOB AND StockItemId = @RAIL) = 110
                        AND (SELECT LeadId FROM INE.Movements WHERE MovementID = (SELECT MAX(MovementID) FROM INE.Movements)) = 900001
                   THEN 1 ELSE 0 END;
EXEC #Check @Ok = @Ok, @Label = N'issue consumed the allocation; lead filled from the job location';
-- allocate then cancel
EXEC INE.spAllocationCreate @LeadId = 900001, @LocationId = @MAIN, @StockItemId = @RAIL, @Quantity = 20, @AllocationId = @A OUTPUT;
EXEC INE.spAllocationCancel @AllocationId = @A;
SET @OkX = CASE WHEN (SELECT QuantityAllocated FROM INE.StockBalances WHERE LocationId = @MAIN AND StockItemId = @RAIL) = 0 THEN 1 ELSE 0 END; EXEC #Check @Ok = @OkX, @Label = N'cancelled allocation released';
GO
DECLARE @OkX BIT;

-- 8/9/10. serial issue, reversal, append-only
DECLARE @MAIN INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'MAIN' AND DealerTenantId = 3);
DECLARE @VAN INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'VAN-01');
DECLARE @JOB INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'JOB-900001');
DECLARE @CTRL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'CTRL-WIFI');
DECLARE @J NVARCHAR(MAX) = CONCAT(N'{"movementType":"IssueToJob","fromLocationId":', @VAN, N',"toLocationId":', @JOB, N',"reference":"WO-1","lines":[{"stockItemId":', @CTRL, N',"serialNumbers":["C8-0001"]}]}');
DECLARE @M BIGINT;
EXEC INE.spMovementPost @MovementJson = @J, @MovementId = @M OUTPUT, @ReturnResult = 0;
SET @OkX = CASE WHEN (SELECT Status FROM INE.SerialUnits WHERE SerialNumber = N'C8-0001') = 'Installed' THEN 1 ELSE 0 END; EXEC #Check @Ok = @OkX, @Label = N'issued serial is Installed';
SET @J = CONCAT(N'{"movementType":"Transfer","fromLocationId":', @MAIN, N',"toLocationId":', @VAN, N',"lines":[{"stockItemId":', @CTRL, N',"serialNumbers":["C8-0001"]}]}');
DECLARE @Sql NVARCHAR(MAX) = CONCAT(N'EXEC INE.spMovementPost @MovementJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04118', N'serial must be at the from location';
DECLARE @Rev BIGINT;
EXEC INE.spMovementReverse @MovementId = @M, @Notes = N'Wrong job', @ReversalMovementId = @Rev OUTPUT;
SET @OkX = CASE WHEN (SELECT CurrentLocationId FROM INE.SerialUnits WHERE SerialNumber = N'C8-0001') = @VAN
                            AND (SELECT Status FROM INE.SerialUnits WHERE SerialNumber = N'C8-0001') = 'InStock' THEN 1 ELSE 0 END; EXEC #Check @Ok = @OkX, @Label = N'reversal put the serial back in the van';
SET @Sql = CONCAT(N'EXEC INE.spMovementReverse @MovementId = ', @M);
EXEC #Expect @Sql, N'04132', N'cannot reverse twice';
SET @Sql = CONCAT(N'EXEC INE.spMovementReverse @MovementId = ', @Rev);
EXEC #Expect @Sql, N'04131', N'cannot reverse a reversal';
SET @Sql = CONCAT(N'UPDATE INE.Movements SET Notes = N''x'' WHERE MovementID = ', @M);
EXEC #Expect @Sql, N'04170', N'ledger update blocked';
SET @Sql = CONCAT(N'DELETE FROM INE.MovementLines WHERE MovementId = ', @M);
EXEC #Expect @Sql, N'04170', N'ledger delete blocked';
SET @J = CONCAT(N'{"movementType":"Reversal","reversesMovementId":', @M, N',"toLocationId":1,"lines":[{"stockItemId":1,"quantity":999}]}');
SET @Sql = CONCAT(N'EXEC INE.spMovementPost @MovementJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04132', N'direct Reversal still checked (lines come from the original)';
SET @J = N'{"movementType":"Transfer","reversesMovementId":1,"fromLocationId":1,"toLocationId":2,"lines":[{"stockItemId":1,"quantity":1}]}';
SET @Sql = CONCAT(N'EXEC INE.spMovementPost @MovementJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04103', N'only a Reversal can name reversesMovementId';
GO
DECLARE @OkX BIT;

-- 11. stock count of the van
DECLARE @VAN INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'VAN-01');
DECLARE @RAIL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'RAIL-STD');
DECLARE @POD INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'POD-RGBW');
DECLARE @CTRL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'CTRL-WIFI');
DECLARE @LOT INT = (SELECT LotID FROM INE.Lots WHERE LotNumber = N'R-2611-07');
DECLARE @SU BIGINT = (SELECT SerialUnitID FROM INE.SerialUnits WHERE SerialNumber = N'C8-0001');
INSERT INTO INE.StockCounts (DealerTenantId, LocationId) VALUES (3, @VAN);
DECLARE @SC BIGINT = SCOPE_IDENTITY();
INSERT INTO INE.StockCountLines (StockCountId, StockItemId, LotId, SerialUnitId, CountedQuantity) VALUES
    (@SC, @RAIL, NULL, NULL, 100), (@SC, @RAIL, NULL, NULL, 60),     -- two shelves: 160 ft vs 164.5
    (@SC, @POD, @LOT, NULL, 41),                                       -- one extra pod
    (@SC, @CTRL, NULL, @SU, 0);                                         -- controller missing
EXEC INE.spStockCountPost @StockCountId = @SC;
DECLARE @Ok BIT = CASE WHEN (SELECT QuantityOnHand FROM INE.StockBalances WHERE LocationId = @VAN AND StockItemId = @RAIL) = 160
                        AND (SELECT QuantityOnHand FROM INE.StockBalances WHERE LocationId = @VAN AND StockItemId = @POD) = 41
                        AND (SELECT Status FROM INE.SerialUnits WHERE SerialUnitID = @SU) = 'Missing'
                        AND (SELECT Status FROM INE.StockCounts WHERE StockCountID = @SC) = 'Posted'
                        AND (SELECT COUNT(*) FROM INE.Movements WHERE StockCountId = @SC) = 2 THEN 1 ELSE 0 END;
EXEC #Check @Ok = @Ok, @Label = N'count posted AdjustIn + AdjustOut, serial now Missing';
DECLARE @Sql NVARCHAR(MAX) = CONCAT(N'EXEC INE.spStockCountPost @StockCountId = ', @SC);
EXEC #Expect @Sql, N'04160', N'cannot post a count twice';
GO
DECLARE @OkX BIT;

-- 12/13. scrap, return to vendor, bring a missing unit back
DECLARE @MAIN INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'MAIN' AND DealerTenantId = 3);
DECLARE @RTV INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'RTV-GVL');
DECLARE @POD INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'POD-RGBW');
DECLARE @CTRL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'CTRL-WIFI');
DECLARE @J NVARCHAR(MAX) = CONCAT(N'{"movementType":"Scrap","fromLocationId":', @MAIN, N',"lines":[{"stockItemId":', @POD, N',"quantity":1,"lotNumber":"R-2611-07"}]}');
EXEC INE.spMovementPost @MovementJson = @J, @ReturnResult = 0;
SET @J = CONCAT(N'{"movementType":"ReturnToVendor","fromLocationId":', @MAIN, N',"toLocationId":', @RTV, N',"reference":"RMA-77","lines":[{"stockItemId":', @CTRL, N',"serialNumbers":["C8-0002"]}]}');
EXEC INE.spMovementPost @MovementJson = @J, @ReturnResult = 0;
SET @OkX = CASE WHEN (SELECT Status FROM INE.SerialUnits WHERE SerialNumber = N'C8-0002') = 'Returned' THEN 1 ELSE 0 END; EXEC #Check @Ok = @OkX, @Label = N'returned serial is Returned';
SET @J = CONCAT(N'{"locationId":', @MAIN, N',"notes":"found it","lines":[{"stockItemId":', @CTRL, N',"serialNumbers":["C8-0001"]}]}');
EXEC INE.spReceiptPost @ReceiptJson = @J;
SET @OkX = CASE WHEN (SELECT Status FROM INE.SerialUnits WHERE SerialNumber = N'C8-0001') = 'InStock' THEN 1 ELSE 0 END; EXEC #Check @Ok = @OkX, @Label = N'missing serial can be received back';
SET @J = CONCAT(N'{"locationId":', @MAIN, N',"lines":[{"stockItemId":', @CTRL, N',"serialNumbers":["C8-0002"]}]}');
DECLARE @Sql NVARCHAR(MAX) = CONCAT(N'EXEC INE.spReceiptPost @ReceiptJson = N''', @J, N'''');
EXEC #Expect @Sql, N'04118', N'a unit at the vendor cannot be received again';
GO
DECLARE @OkX BIT;

-- 13b. reversing a PO receipt and an allocated issue
DECLARE @MAIN INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'MAIN' AND DealerTenantId = 3);
DECLARE @JOB INT = (SELECT LocationID FROM INE.Locations WHERE Code = N'JOB-900001');
DECLARE @V INT = (SELECT VendorID FROM INE.Vendors WHERE Code = N'GVL');
DECLARE @RAIL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'RAIL-STD');
DECLARE @CTRL INT = (SELECT StockItemID FROM INE.StockItems WHERE Sku = N'CTRL-WIFI');
INSERT INTO INE.PurchaseOrders (DealerTenantId, VendorId, ShipToLocationId, PONumber) VALUES (3, @V, @MAIN, N'PO-0002');
DECLARE @PO BIGINT = SCOPE_IDENTITY();
INSERT INTO INE.PurchaseOrderLines (PurchaseOrderId, LineNumber, StockItemId, QuantityOrdered, UnitCost) VALUES (@PO, 1, @CTRL, 1, 85);
DECLARE @L BIGINT = SCOPE_IDENTITY();
EXEC INE.spPurchaseOrderSetStatus @PurchaseOrderId = @PO, @Action = 'Submit';
DECLARE @J NVARCHAR(MAX) = CONCAT(N'{"purchaseOrderId":', @PO, N',"lines":[{"stockItemId":', @CTRL, N',"serialNumbers":["C8-0003"],"purchaseOrderLineId":', @L, N'}]}');
DECLARE @R BIGINT, @M BIGINT, @Rev BIGINT;
EXEC INE.spReceiptPost @ReceiptJson = @J, @ReceiptId = @R OUTPUT, @MovementId = @M OUTPUT;
EXEC INE.spMovementReverse @MovementId = @M, @Notes = N'Wrong PO', @ReversalMovementId = @Rev OUTPUT;
SET @OkX = CASE WHEN (SELECT Status FROM INE.PurchaseOrders WHERE PurchaseOrderID = @PO) = 'Submitted'
                 AND (SELECT QuantityReceived FROM INE.PurchaseOrderLines WHERE PurchaseOrderLineID = @L) = 0
                 AND (SELECT Status FROM INE.SerialUnits WHERE SerialNumber = N'C8-0003') = 'Voided' THEN 1 ELSE 0 END;
EXEC #Check @Ok = @OkX, @Label = N'reversed receipt: PO back to Submitted, serial Voided';
DECLARE @A BIGINT;
EXEC INE.spAllocationCreate @LeadId = 900001, @LocationId = @MAIN, @StockItemId = @RAIL, @Quantity = 25, @AllocationId = @A OUTPUT;
SET @J = CONCAT(N'{"movementType":"IssueToJob","fromLocationId":', @MAIN, N',"toLocationId":', @JOB, N',"lines":[{"stockItemId":', @RAIL, N',"quantity":25,"allocationId":', @A, N'}]}');
EXEC INE.spMovementPost @MovementJson = @J, @MovementId = @M OUTPUT, @ReturnResult = 0;
EXEC INE.spMovementReverse @MovementId = @M, @ReversalMovementId = @Rev OUTPUT;
SET @OkX = CASE WHEN (SELECT Status FROM INE.Allocations WHERE AllocationID = @A) = 'Open'
                 AND (SELECT QuantityAllocated FROM INE.StockBalances WHERE LocationId = @MAIN AND StockItemId = @RAIL) = 25 THEN 1 ELSE 0 END;
EXEC #Check @Ok = @OkX, @Label = N'reversed issue: allocation re-opened and stock reserved again';
EXEC INE.spAllocationCancel @AllocationId = @A;
GO
-- a reversed issue does not bring back an allocation that was cancelled in between
EXEC INE.spAllocationCreate @LeadId = 900001, @LocationId = @MAIN, @StockItemId = @RAIL, @Quantity = 25, @AllocationId = @A OUTPUT;
SET @J = CONCAT(N'{"movementType":"IssueToJob","fromLocationId":', @MAIN, N',"toLocationId":', @JOB, N',"lines":[{"stockItemId":', @RAIL, N',"quantity":10,"allocationId":', @A, N'}]}');
EXEC INE.spMovementPost @MovementJson = @J, @MovementId = @M OUTPUT, @ReturnResult = 0;
EXEC INE.spAllocationCancel @AllocationId = @A;
EXEC INE.spMovementReverse @MovementId = @M, @ReversalMovementId = @Rev OUTPUT;
SET @OkX = CASE WHEN (SELECT Status FROM INE.Allocations WHERE AllocationID = @A) = 'Cancelled'
                 AND (SELECT QuantityAllocated FROM INE.StockBalances WHERE LocationId = @MAIN AND StockItemId = @RAIL) = 0
                 AND NOT EXISTS (SELECT 1 FROM INE.vwStockBalanceDrift) THEN 1 ELSE 0 END;
EXEC #Check @Ok = @OkX, @Label = N'reversed issue on a cancelled allocation: stays Cancelled, stock comes back unreserved';
GO

-- tenant guards and audit triggers (20261117_1900)
DECLARE @OkX BIT;
EXEC #Expect N'INSERT INTO INE.Vendors (DealerTenantId, Code, Name) SELECT MIN(DealerTenantID), N''OTHER'', N''Other tenant vendor'' FROM ACC.DealerTenants WHERE DealerTenantID <> 3', N'04180', N'row for another tenant than the session is rejected';
EXEC #Expect N'UPDATE INE.Vendors SET DealerTenantId = (SELECT MIN(DealerTenantID) FROM ACC.DealerTenants WHERE DealerTenantID <> 3) WHERE Code = N''GVL''', N'04182', N'a row cannot change tenant';
SET IDENTITY_INSERT [QAL].[Leads] ON;
IF NOT EXISTS (SELECT 1 FROM QAL.Leads WHERE LeadID = 900002)
    INSERT INTO [QAL].[Leads] ([LeadID], [CustomerTypeId], [MasterFileId], [DealerTenantId], [LanguageId], [LeadSourceId], [LeadDispositionId], [FirstName], [LastName])
    VALUES (900002, 'X', 0, (SELECT MIN(DealerTenantID) FROM ACC.DealerTenants WHERE DealerTenantID <> 3), N'en', 0, 0, N'Other', N'Tenant');
SET IDENTITY_INSERT [QAL].[Leads] OFF;
EXEC #Expect N'INSERT INTO INE.Locations (DealerTenantId, LocationTypeId, Code, Name, LeadId) VALUES (3, 4, N''JOB-900002'', N''Other tenant job'', 900002)', N'04181', N'location cannot point at another tenant''s lead';
EXEC #Expect N'INSERT INTO INE.PurchaseOrders (DealerTenantId, VendorId, ShipToLocationId, PONumber) SELECT 3, (SELECT VendorID FROM INE.Vendors WHERE Code = N''GVL''), LocationID, N''PO-BAD'' FROM INE.Locations WHERE Code = N''JOB-900001''', N'04181', N'PO cannot ship to a job location';
DECLARE @User UNIQUEIDENTIFIER = (SELECT UserId FROM INE.fxGetSessionContext());
UPDATE INE.Vendors SET PaymentTerms = N'Net 30' WHERE Code = N'GVL';
SET @OkX = CASE WHEN EXISTS (SELECT 1 FROM AUD.AuditActions AS A
                             INNER JOIN AUD.AuditActionColumns AS C ON C.AuditActionId = A.AuditActionID
                             WHERE A.SchemaName = 'INE' AND A.TableName = 'Vendors' AND A.AuditActionTypeId = 'UPDATE'
                               AND A.CreatedById = @User AND C.ColumnName = N'PaymentTerms' AND C.OldValue IS NULL AND C.NewValue = N'Net 30')
                 AND EXISTS (SELECT 1 FROM AUD.AuditActions WHERE SchemaName = 'INE' AND TableName = 'PurchaseOrders' AND AuditActionTypeId = 'INSERT')
            THEN 1 ELSE 0 END;
EXEC #Check @Ok = @OkX, @Label = N'audit triggers record inserts and updates (NULL -> value) with the session user';
GO

-- 14. PO close / reopen; 15. drift and on-hand
DECLARE @OkX BIT;
DECLARE @PO BIGINT = (SELECT PurchaseOrderID FROM INE.PurchaseOrders WHERE PONumber = N'PO-0001');
EXEC INE.spPurchaseOrderSetStatus @PurchaseOrderId = @PO, @Action = 'Close';
EXEC INE.spPurchaseOrderSetStatus @PurchaseOrderId = @PO, @Action = 'Reopen';
SET @OkX = CASE WHEN (SELECT Status FROM INE.PurchaseOrders WHERE PurchaseOrderID = @PO) = 'Received' THEN 1 ELSE 0 END; EXEC #Check @Ok = @OkX, @Label = N'close then reopen -> Received';
SET @OkX = CASE WHEN NOT EXISTS (SELECT 1 FROM INE.vwStockBalanceDrift) THEN 1 ELSE 0 END; EXEC #Check @Ok = @OkX, @Label = N'StockBalances match the ledger (no drift)';
GO
DECLARE @OkX BIT;
INSERT INTO INE.StockLevels (DealerTenantId, StockItemId, LocationId, ReorderPoint, MaximumQuantity)
SELECT 3, StockItemID, (SELECT LocationID FROM INE.Locations WHERE Code = N'MAIN' AND DealerTenantId = 3), 300, 1000 FROM INE.StockItems WHERE Sku = N'RAIL-STD';
GO
DECLARE @OkX BIT;
PRINT '--- vwStockOnHand';
SELECT LocationCode, LocationType, Sku, LotNumber, QuantityOnHand, QuantityAllocated, QuantityAvailable FROM INE.vwStockOnHand ORDER BY LocationCode, Sku;
PRINT '--- vwReorderSuggestions';
SELECT LocationCode, Sku, ReorderPoint, QuantityAvailable, QuantityOnOrder, NeedsReorder, SuggestedOrderQuantity FROM INE.vwReorderSuggestions;
PRINT '--- serial history C8-0001';
SELECT MovementID, MovementType, FromLocationCode, ToLocationCode, IsReversed, Reference FROM INE.vwMovementHistory WHERE SerialNumber = N'C8-0001' ORDER BY MovementID;
GO
DECLARE @OkX BIT;
