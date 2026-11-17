/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_PurchaseOrders_TenantGuard
 * Description: Keeps INE.PurchaseOrders inside one dealer tenant, whoever writes it (the API's
 *              plain CRUD or an INE procedure):
 *              - DealerTenantId cannot change after insert
 *              - the row's tenant must be the session's tenant when one is set
 *              - A purchase order needs a vendor of its own tenant and a ship-to warehouse, vehicle or staging location of its own tenant.
 *              Error codes: 04180 wrong tenant for the session, 04181 cross-tenant
 *              reference, 04182 tenant cannot change.
 * Dependencies: INE.fxGetSessionContext, INE.LocationTypes, INE.Locations, INE.Vendors
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_PurchaseOrders_TenantGuard]
ON [INE].[PurchaseOrders]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[PurchaseOrderID] = I.[PurchaseOrderID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N'04182|:|INE.PurchaseOrders: a row cannot move to another dealer tenant.', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N'04180|:|INE.PurchaseOrders: the row belongs to a different dealer tenant than the signed-in user.', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[VendorId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Vendors] AS V
                  WHERE V.[VendorID] = I.[VendorId] AND V.[DealerTenantId] = I.[DealerTenantId]))
           OR NOT EXISTS (SELECT 1 FROM [INE].[Locations] AS L
                  INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
                  WHERE L.[LocationID] = I.[ShipToLocationId] AND L.[DealerTenantId] = I.[DealerTenantId]
                    AND LT.[IsStockHolding] = 1))
        THROW 50000, N'04181|:|A purchase order needs a vendor of its own tenant and a ship-to warehouse, vehicle or staging location of its own tenant.', 1;
END;
GO
