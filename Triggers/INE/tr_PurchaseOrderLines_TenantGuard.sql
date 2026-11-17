/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_PurchaseOrderLines_TenantGuard
 * Description: Keeps INE.PurchaseOrderLines inside one dealer tenant, whoever writes it (the API's
 *              plain CRUD or an INE procedure):
 *              - its purchase order's tenant must be the session's tenant when one is set
 *              - A purchase order line can only name a stock item of the purchase order's tenant.
 *              Error codes: 04180 wrong tenant for the session, 04181 cross-tenant
 *              reference, 04182 tenant cannot change.
 * Dependencies: INE.fxGetSessionContext, INE.PurchaseOrders, INE.StockItems
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_PurchaseOrderLines_TenantGuard]
ON [INE].[PurchaseOrderLines]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[PurchaseOrders] AS P ON P.[PurchaseOrderID] = I.[PurchaseOrderId]
               WHERE P.[DealerTenantId] <> @SessionTenantId)
        THROW 50000, N'04180|:|INE.PurchaseOrderLines: the purchase order belongs to a different dealer tenant than the signed-in user.', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[PurchaseOrders] AS P ON P.[PurchaseOrderID] = I.[PurchaseOrderId]
               WHERE NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS SI
                  WHERE SI.[StockItemID] = I.[StockItemId] AND SI.[DealerTenantId] = P.[DealerTenantId]))
        THROW 50000, N'04181|:|A purchase order line can only name a stock item of the purchase order''s tenant.', 1;
END;
GO
