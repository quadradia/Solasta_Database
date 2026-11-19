/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_StockItems_VariantGuard
 * Description: Keeps part variants (INE.StockItems rows with ParentStockItemId) consistent,
 *              whoever writes them:
 *              - one level deep: a parent cannot itself be a variant, and an item that has
 *                variants cannot become a variant (04191)
 *              - an item can only get its first variant while it holds no stock: nothing on
 *                hand or allocated at a stock-holding location, no open allocation, no open
 *                purchase order line and no active reorder rule (04192). Stock lives on variants
 *                only; stock installed at jobs or sent to vendors stays as history.
 *                INE.spStockItemConvertToVariants empties an item onto its first variant.
 *              - a variant takes its parent's ProductId: written variants are set to their
 *                parent's product, and a parent's product change is copied to its variants.
 *              The same tenant for parent and variant is checked by tr_StockItems_TenantGuard.
 *              Error codes: 04191 nesting, 04192 parent holds stock.
 * Dependencies: INE.StockItems, INE.StockBalances, INE.Allocations, INE.PurchaseOrders,
 *               INE.PurchaseOrderLines, INE.StockLevels
 * Migrations: 20261120_0100_AddINE_PartVariants
 * Author: Andres Sosa
 * Created: 2026-11-19
 * Modified: 2026-11-19 - only stock-holding locations count (20261120_0300)
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_StockItems_VariantGuard]
ON [INE].[StockItems]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- One level deep.
    IF EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[StockItems] AS P ON P.[StockItemID] = I.[ParentStockItemId]
               WHERE P.[ParentStockItemId] IS NOT NULL)
       OR EXISTS (SELECT 1 FROM inserted AS I
                  WHERE I.[ParentStockItemId] IS NOT NULL
                    AND EXISTS (SELECT 1 FROM [INE].[StockItems] AS C WHERE C.[ParentStockItemId] = I.[StockItemID]))
        THROW 50000, N'04191|:|Variants are one level deep: a variant cannot have variants of its own, and an item with variants cannot become a variant.', 1;

    -- Parents that just gained a variant must not hold stock.
    DECLARE @NewParents TABLE ([StockItemId] INT NOT NULL PRIMARY KEY);
    INSERT INTO @NewParents ([StockItemId])
    SELECT DISTINCT I.[ParentStockItemId]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockItemID] = I.[StockItemID]
    WHERE I.[ParentStockItemId] IS NOT NULL
      AND (D.[StockItemID] IS NULL OR D.[ParentStockItemId] IS NULL OR D.[ParentStockItemId] <> I.[ParentStockItemId]);

    IF EXISTS (SELECT 1 FROM @NewParents)
    BEGIN
        DECLARE @Msg NVARCHAR(2048);
        SELECT TOP (1) @Msg = CONCAT(N'04192|:|Stock item ', P.[Sku], N' still holds stock (on hand, allocated, on an open purchase order or a reorder rule). ',
                                     N'Move or adjust it out, close those first, then add variants; stock lives on variants only.')
        FROM @NewParents AS NP
        INNER JOIN [INE].[StockItems] AS P ON P.[StockItemID] = NP.[StockItemId]
        WHERE EXISTS (SELECT 1 FROM [INE].[StockBalances] AS SB
                      INNER JOIN [INE].[Locations] AS L ON L.[LocationID] = SB.[LocationId]
                      INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
                      WHERE SB.[StockItemId] = NP.[StockItemId] AND LT.[IsStockHolding] = 1
                        AND (SB.[QuantityOnHand] <> 0 OR SB.[QuantityAllocated] <> 0))
           OR EXISTS (SELECT 1 FROM [INE].[Allocations] AS A
                      WHERE A.[StockItemId] = NP.[StockItemId] AND A.[Status] = 'Open')
           OR EXISTS (SELECT 1 FROM [INE].[PurchaseOrderLines] AS POL
                      INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
                      WHERE POL.[StockItemId] = NP.[StockItemId] AND POL.[IsDeleted] = 0 AND PO.[IsDeleted] = 0
                        AND PO.[Status] IN ('Draft', 'Submitted', 'PartiallyReceived')
                        AND POL.[QuantityOrdered] > POL.[QuantityReceived])
           OR EXISTS (SELECT 1 FROM [INE].[StockLevels] AS SL
                      WHERE SL.[StockItemId] = NP.[StockItemId] AND SL.[IsActive] = 1 AND SL.[IsDeleted] = 0);
        IF @Msg IS NOT NULL
            THROW 50000, @Msg, 1;
    END;

    -- A variant takes its parent's product (both for written variants and written parents).
    IF UPDATE([ProductId]) OR UPDATE([ParentStockItemId])
        UPDATE C SET C.[ProductId] = P.[ProductId]
        FROM [INE].[StockItems] AS C
        INNER JOIN [INE].[StockItems] AS P ON P.[StockItemID] = C.[ParentStockItemId]
        WHERE (C.[StockItemID] IN (SELECT [StockItemID] FROM inserted) OR P.[StockItemID] IN (SELECT [StockItemID] FROM inserted))
          AND (C.[ProductId] <> P.[ProductId] OR (C.[ProductId] IS NULL AND P.[ProductId] IS NOT NULL)
               OR (C.[ProductId] IS NOT NULL AND P.[ProductId] IS NULL));
END;
GO
