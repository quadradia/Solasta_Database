/*******************************************************************************
 * Object Type: View
 * Schema: INE
 * Name: vwStockBalanceDrift
 * Description: Health check. Rebuilds on-hand from the ledger (into a location minus out
 *              of it) and allocated from open allocations, and returns every location /
 *              item / lot where INE.StockBalances disagrees. It should always be empty;
 *              a row here means something wrote to StockBalances outside the INE procedures.
 * Dependencies: INE.Movements, INE.MovementLines, INE.Allocations, INE.StockBalances
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [INE].[vwStockBalanceDrift]
AS
    WITH [Ledger] AS
    (
        SELECT M.[DealerTenantId], M.[ToLocationId] AS [LocationId], ML.[StockItemId], ML.[LotId], ML.[Quantity]
        FROM [INE].[Movements] AS M
        INNER JOIN [INE].[MovementLines] AS ML ON ML.[MovementId] = M.[MovementID]
        WHERE M.[ToLocationId] IS NOT NULL
        UNION ALL
        SELECT M.[DealerTenantId], M.[FromLocationId], ML.[StockItemId], ML.[LotId], -ML.[Quantity]
        FROM [INE].[Movements] AS M
        INNER JOIN [INE].[MovementLines] AS ML ON ML.[MovementId] = M.[MovementID]
        WHERE M.[FromLocationId] IS NOT NULL
    ),
    [LedgerTotals] AS
    (
        SELECT [DealerTenantId], [LocationId], [StockItemId], [LotId], SUM([Quantity]) AS [QuantityOnHand]
        FROM [Ledger]
        GROUP BY [DealerTenantId], [LocationId], [StockItemId], [LotId]
    ),
    [AllocationTotals] AS
    (
        SELECT [LocationId], [StockItemId], [LotId], SUM([QuantityAllocated] - [QuantityIssued]) AS [QuantityAllocated]
        FROM [INE].[Allocations]
        WHERE [Status] = 'Open'
        GROUP BY [LocationId], [StockItemId], [LotId]
    ),
    [Expected] AS
    (
        SELECT
            COALESCE(LT.[DealerTenantId], SB.[DealerTenantId]) AS [DealerTenantId]
            , COALESCE(LT.[LocationId], SB.[LocationId]) AS [LocationId]
            , COALESCE(LT.[StockItemId], SB.[StockItemId]) AS [StockItemId]
            , COALESCE(LT.[LotId], SB.[LotId]) AS [LotId]
            , ISNULL(LT.[QuantityOnHand], 0) AS [LedgerOnHand]
            , ISNULL(SB.[QuantityOnHand], 0) AS [BalanceOnHand]
            , ISNULL(SB.[QuantityAllocated], 0) AS [BalanceAllocated]
        FROM [LedgerTotals] AS LT
        FULL OUTER JOIN [INE].[StockBalances] AS SB
            ON SB.[LocationId] = LT.[LocationId] AND SB.[StockItemId] = LT.[StockItemId]
           AND ((SB.[LotId] = LT.[LotId]) OR (SB.[LotId] IS NULL AND LT.[LotId] IS NULL))
    )
    SELECT
        E.[DealerTenantId]
        , E.[LocationId]
        , E.[StockItemId]
        , E.[LotId]
        , E.[LedgerOnHand]
        , E.[BalanceOnHand]
        , ISNULL(AT.[QuantityAllocated], 0) AS [OpenAllocations]
        , E.[BalanceAllocated]
    FROM [Expected] AS E
    LEFT JOIN [AllocationTotals] AS AT
        ON AT.[LocationId] = E.[LocationId] AND AT.[StockItemId] = E.[StockItemId]
       AND ((AT.[LotId] = E.[LotId]) OR (AT.[LotId] IS NULL AND E.[LotId] IS NULL))
    WHERE E.[LedgerOnHand] <> E.[BalanceOnHand]
       OR ISNULL(AT.[QuantityAllocated], 0) <> E.[BalanceAllocated];
GO
