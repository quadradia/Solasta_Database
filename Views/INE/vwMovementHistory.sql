/*******************************************************************************
 * Object Type: View
 * Schema: INE
 * Name: vwMovementHistory
 * Description: The ledger, flattened: one row per movement line with the movement type,
 *              both locations, item, lot and serial number. Filter by SerialUnitId for a
 *              unit's history, by LeadId for a job, by a location for its activity.
 *              IsReversed marks movements that a later Reversal undid.
 * Dependencies: INE.Movements, INE.MovementLines, INE.MovementTypes, INE.Locations,
 *               INE.StockItems, INE.Lots, INE.SerialUnits
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [INE].[vwMovementHistory]
AS
    SELECT
        M.[DealerTenantId]
        , M.[MovementID]
        , ML.[MovementLineID]
        , M.[MovementDate]
        , MT.[Code] AS [MovementType]
        , M.[FromLocationId]
        , FL.[Code] AS [FromLocationCode]
        , M.[ToLocationId]
        , TL.[Code] AS [ToLocationCode]
        , M.[LeadId]
        , M.[ReceiptId]
        , M.[StockCountId]
        , M.[ReversesMovementId]
        , CAST(CASE WHEN EXISTS (SELECT 1 FROM [INE].[Movements] AS R WHERE R.[ReversesMovementId] = M.[MovementID])
                    THEN 1 ELSE 0 END AS BIT) AS [IsReversed]
        , ML.[StockItemId]
        , SI.[Sku]
        , SI.[UnitOfMeasure]
        , ML.[LotId]
        , LO.[LotNumber]
        , ML.[SerialUnitId]
        , SU.[SerialNumber]
        , ML.[Quantity]
        , ML.[UnitCost]
        , ML.[PurchaseOrderLineId]
        , ML.[AllocationId]
        , M.[Reference]
        , M.[Notes]
        , M.[CreatedById]
        , M.[CreatedDate]
    FROM [INE].[Movements] AS M
    INNER JOIN [INE].[MovementTypes] AS MT ON MT.[MovementTypeID] = M.[MovementTypeId]
    INNER JOIN [INE].[MovementLines] AS ML ON ML.[MovementId] = M.[MovementID]
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = ML.[StockItemId]
    LEFT JOIN [INE].[Locations] AS FL ON FL.[LocationID] = M.[FromLocationId]
    LEFT JOIN [INE].[Locations] AS TL ON TL.[LocationID] = M.[ToLocationId]
    LEFT JOIN [INE].[Lots] AS LO ON LO.[LotID] = ML.[LotId]
    LEFT JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = ML.[SerialUnitId];
GO
