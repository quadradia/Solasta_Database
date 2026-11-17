/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_StockCountLines_TenantGuard
 * Description: Keeps INE.StockCountLines inside one dealer tenant, whoever writes it (the API's
 *              plain CRUD or an INE procedure):
 *              - its stock count's tenant must be the session's tenant when one is set
 *              - A count line can only name a stock item of the count's tenant, and a lot or serial unit of that item.
 *              Error codes: 04180 wrong tenant for the session, 04181 cross-tenant
 *              reference, 04182 tenant cannot change.
 * Dependencies: INE.fxGetSessionContext, INE.Lots, INE.SerialUnits, INE.StockCounts, INE.StockItems
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_StockCountLines_TenantGuard]
ON [INE].[StockCountLines]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[StockCounts] AS P ON P.[StockCountID] = I.[StockCountId]
               WHERE P.[DealerTenantId] <> @SessionTenantId)
        THROW 50000, N'04180|:|INE.StockCountLines: the stock count belongs to a different dealer tenant than the signed-in user.', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[StockCounts] AS P ON P.[StockCountID] = I.[StockCountId]
               WHERE NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS SI
                  WHERE SI.[StockItemID] = I.[StockItemId] AND SI.[DealerTenantId] = P.[DealerTenantId])
           OR (I.[LotId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Lots] AS LO
                  WHERE LO.[LotID] = I.[LotId] AND LO.[StockItemId] = I.[StockItemId]))
           OR (I.[SerialUnitId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[SerialUnits] AS SU
                  WHERE SU.[SerialUnitID] = I.[SerialUnitId] AND SU.[StockItemId] = I.[StockItemId])))
        THROW 50000, N'04181|:|A count line can only name a stock item of the count''s tenant, and a lot or serial unit of that item.', 1;
END;
GO
