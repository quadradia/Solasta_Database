/*******************************************************************************
 * Object Type: View
 * Schema: INE
 * Name: vwReorderSuggestions
 * Description: For every reorder rule (INE.StockLevels): available stock at the location,
 *              what is still coming on open POs shipping there, and, when the two
 *              together are at or below the reorder point, how much to order to get back
 *              up to the maximum. NeedsReorder = 1 marks the rows to act on.
 * Dependencies: INE.StockLevels, INE.StockBalances, INE.PurchaseOrders,
 *               INE.PurchaseOrderLines, INE.StockItems, INE.Locations, INE.Vendors
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Modified: 2026-11-19 - exposes ParentStockItemId and VariantName (part variants, 20261120_0100)
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [INE].[vwReorderSuggestions]
AS
    WITH [Available] AS
    (
        SELECT SB.[LocationId], SB.[StockItemId], SUM(SB.[QuantityOnHand] - SB.[QuantityAllocated]) AS [Quantity]
        FROM [INE].[StockBalances] AS SB
        GROUP BY SB.[LocationId], SB.[StockItemId]
    ),
    [OnOrder] AS
    (
        SELECT PO.[ShipToLocationId] AS [LocationId], POL.[StockItemId], SUM(POL.[QuantityOrdered] - POL.[QuantityReceived]) AS [Quantity]
        FROM [INE].[PurchaseOrders] AS PO
        INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderId] = PO.[PurchaseOrderID]
        WHERE PO.[Status] IN ('Draft', 'Submitted', 'PartiallyReceived') AND PO.[IsDeleted] = 0 AND POL.[IsDeleted] = 0
        GROUP BY PO.[ShipToLocationId], POL.[StockItemId]
    )
    SELECT
        SL.[DealerTenantId]
        , SL.[StockLevelID]
        , SL.[LocationId]
        , L.[Code] AS [LocationCode]
        , L.[Name] AS [LocationName]
        , SL.[StockItemId]
        , SI.[Sku]
        , SI.[Name] AS [StockItemName]
        , SI.[ParentStockItemId]
        , SI.[VariantName]
        , SI.[UnitOfMeasure]
        , SI.[DefaultVendorId]
        , V.[Name] AS [DefaultVendorName]
        , SL.[ReorderPoint]
        , SL.[MaximumQuantity]
        , ISNULL(A.[Quantity], 0) AS [QuantityAvailable]
        , ISNULL(O.[Quantity], 0) AS [QuantityOnOrder]
        , CAST(CASE WHEN ISNULL(A.[Quantity], 0) + ISNULL(O.[Quantity], 0) <= SL.[ReorderPoint] THEN 1 ELSE 0 END AS BIT) AS [NeedsReorder]
        , CASE WHEN ISNULL(A.[Quantity], 0) + ISNULL(O.[Quantity], 0) <= SL.[ReorderPoint]
               THEN SL.[MaximumQuantity] - ISNULL(A.[Quantity], 0) - ISNULL(O.[Quantity], 0) ELSE 0 END AS [SuggestedOrderQuantity]
    FROM [INE].[StockLevels] AS SL
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = SL.[StockItemId]
    INNER JOIN [INE].[Locations] AS L ON L.[LocationID] = SL.[LocationId]
    LEFT JOIN [INE].[Vendors] AS V ON V.[VendorID] = SI.[DefaultVendorId]
    LEFT JOIN [Available] AS A ON A.[LocationId] = SL.[LocationId] AND A.[StockItemId] = SL.[StockItemId]
    LEFT JOIN [OnOrder] AS O ON O.[LocationId] = SL.[LocationId] AND O.[StockItemId] = SL.[StockItemId]
    WHERE SL.[IsActive] = 1 AND SL.[IsDeleted] = 0 AND SI.[IsActive] = 1 AND SI.[IsDeleted] = 0;
GO
