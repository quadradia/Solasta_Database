/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_StockItemVariantAttributes_TenantGuard
 * Description: Keeps INE.StockItemVariantAttributes inside one dealer tenant, whoever writes it
 *              (the API's plain CRUD or a script):
 *              - DealerTenantId cannot change after insert
 *              - the row's tenant must be the session's tenant when one is set
 *              - an attribute can only name a stock item of its own tenant, and only a
 *                variant (a stock item with ParentStockItemId) has attributes.
 *              Error codes: 04180 wrong tenant for the session, 04181 cross-tenant
 *              reference, 04182 tenant cannot change, 04193 not a variant.
 * Dependencies: INE.fxGetSessionContext, INE.StockItems
 * Migrations: 20261120_0100_AddINE_PartVariants
 * Author: Andres Sosa
 * Created: 2026-11-19
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_StockItemVariantAttributes_TenantGuard]
ON [INE].[StockItemVariantAttributes]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[StockItemVariantAttributeID] = I.[StockItemVariantAttributeID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N'04182|:|INE.StockItemVariantAttributes: a row cannot move to another dealer tenant.', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N'04180|:|INE.StockItemVariantAttributes: the row belongs to a different dealer tenant than the signed-in user.', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS SI
                  WHERE SI.[StockItemID] = I.[StockItemId] AND SI.[DealerTenantId] = I.[DealerTenantId]))
        THROW 50000, N'04181|:|A variant attribute can only name a stock item of its own tenant.', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = I.[StockItemId]
               WHERE SI.[ParentStockItemId] IS NULL)
        THROW 50000, N'04193|:|Only a variant (a stock item with a parent) has variant attributes.', 1;
END;
GO
