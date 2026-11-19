/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_StockItems_TenantGuard
 * Description: Keeps INE.StockItems inside one dealer tenant, whoever writes it (the API's
 *              plain CRUD or an INE procedure):
 *              - DealerTenantId cannot change after insert
 *              - the row's tenant must be the session's tenant when one is set
 *              - A stock item can only name a product, default vendor and parent item
 *                (variants, 20261120_0100) of its own tenant.
 *              Error codes: 04180 wrong tenant for the session, 04181 cross-tenant
 *              reference, 04182 tenant cannot change.
 * Dependencies: INE.fxGetSessionContext, INE.Vendors, MAC.Products, INE.StockItems
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_StockItems_TenantGuard]
ON [INE].[StockItems]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[StockItemID] = I.[StockItemID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N'04182|:|INE.StockItems: a row cannot move to another dealer tenant.', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N'04180|:|INE.StockItems: the row belongs to a different dealer tenant than the signed-in user.', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[ProductId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [MAC].[Products] AS P
                  WHERE P.[ProductID] = I.[ProductId] AND P.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[DefaultVendorId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Vendors] AS V
                  WHERE V.[VendorID] = I.[DefaultVendorId] AND V.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[ParentStockItemId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS PI
                  WHERE PI.[StockItemID] = I.[ParentStockItemId] AND PI.[DealerTenantId] = I.[DealerTenantId])))
        THROW 50000, N'04181|:|A stock item can only name a product, default vendor and parent item of its own tenant.', 1;
END;
GO
