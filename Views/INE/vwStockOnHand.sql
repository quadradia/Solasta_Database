/*******************************************************************************
 * Object Type: View
 * Schema: INE
 * Name: vwStockOnHand
 * Description: What is where right now: one row per location, stock item and lot with
 *              on hand, allocated and available (on hand - allocated). Includes job and
 *              vendor locations (IsStockHolding = 0) so "what is installed at this job"
 *              is the same query; filter on IsStockHolding = 1 for sellable stock.
 *              Rows at zero are left out. Filter by DealerTenantId.
 * Dependencies: INE.StockBalances, INE.Locations, INE.LocationTypes, INE.StockItems, INE.Lots
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [INE].[vwStockOnHand]
AS
    SELECT
        SB.[DealerTenantId]
        , SB.[LocationId]
        , L.[Code] AS [LocationCode]
        , L.[Name] AS [LocationName]
        , LT.[Code] AS [LocationType]
        , LT.[IsStockHolding]
        , L.[LeadId]
        , SB.[StockItemId]
        , SI.[Sku]
        , SI.[Name] AS [StockItemName]
        , SI.[TrackingMode]
        , SI.[UnitOfMeasure]
        , SB.[LotId]
        , LO.[LotNumber]
        , SB.[QuantityOnHand]
        , SB.[QuantityAllocated]
        , SB.[QuantityOnHand] - SB.[QuantityAllocated] AS [QuantityAvailable]
        , SB.[QuantityOnHand] * SI.[StandardCost] AS [ExtendedStandardCost]
        , SB.[LastMovementId]
        , SB.[ModifiedDate] AS [LastChangedDate]
    FROM [INE].[StockBalances] AS SB
    INNER JOIN [INE].[Locations] AS L ON L.[LocationID] = SB.[LocationId]
    INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = SB.[StockItemId]
    LEFT JOIN [INE].[Lots] AS LO ON LO.[LotID] = SB.[LotId]
    WHERE SB.[QuantityOnHand] <> 0 OR SB.[QuantityAllocated] <> 0;
GO
