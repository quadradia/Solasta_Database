/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_PurchaseOrderLines_GuardStatus
 * Description: A purchase order's lines can be added, removed or changed (item,
 *              quantity ordered, unit cost) only while the PO is Draft. QuantityReceived
 *              may change at any time; INE.spMovementPost maintains it. This closes the
 *              legacy gap where lines could be edited after the PO was submitted.
 * Dependencies: INE.PurchaseOrderLines, INE.PurchaseOrders
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_PurchaseOrderLines_GuardStatus]
ON [INE].[PurchaseOrderLines]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        -- inserted or deleted lines on a non-Draft PO
        SELECT 1
        FROM (SELECT [PurchaseOrderId] FROM inserted AS I
              WHERE NOT EXISTS (SELECT 1 FROM deleted AS D WHERE D.[PurchaseOrderLineID] = I.[PurchaseOrderLineID])
              UNION ALL
              SELECT [PurchaseOrderId] FROM deleted AS D
              WHERE NOT EXISTS (SELECT 1 FROM inserted AS I WHERE I.[PurchaseOrderLineID] = D.[PurchaseOrderLineID])
              UNION ALL
              -- updated lines whose ordering terms changed
              SELECT I.[PurchaseOrderId] FROM inserted AS I
              INNER JOIN deleted AS D ON D.[PurchaseOrderLineID] = I.[PurchaseOrderLineID]
              WHERE I.[PurchaseOrderId] <> D.[PurchaseOrderId] OR I.[StockItemId] <> D.[StockItemId]
                 OR I.[QuantityOrdered] <> D.[QuantityOrdered] OR I.[UnitCost] <> D.[UnitCost]
                 OR I.[IsDeleted] <> D.[IsDeleted]) AS C
        INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = C.[PurchaseOrderId]
        WHERE PO.[Status] <> 'Draft')
        THROW 50000, N'04171|:|Purchase order lines can only be changed while the purchase order is Draft.', 1;
END;
GO
