/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_StockLevels_TenantGuard
 * Description: Keeps INE.StockLevels inside one dealer tenant, whoever writes it (the API's
 *              plain CRUD or an INE procedure):
 *              - DealerTenantId cannot change after insert
 *              - the row's tenant must be the session's tenant when one is set
 *              - A reorder rule can only name a stock item and location of its own tenant.
 *              Error codes: 04180 wrong tenant for the session, 04181 cross-tenant
 *              reference, 04182 tenant cannot change.
 * Dependencies: INE.fxGetSessionContext, INE.Locations, INE.StockItems
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_StockLevels_TenantGuard]
ON [INE].[StockLevels]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[StockLevelID] = I.[StockLevelID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N'04182|:|INE.StockLevels: a row cannot move to another dealer tenant.', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N'04180|:|INE.StockLevels: the row belongs to a different dealer tenant than the signed-in user.', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[StockItemId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS SI
                  WHERE SI.[StockItemID] = I.[StockItemId] AND SI.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[LocationId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Locations] AS L
                  WHERE L.[LocationID] = I.[LocationId] AND L.[DealerTenantId] = I.[DealerTenantId])))
        THROW 50000, N'04181|:|A reorder rule can only name a stock item and location of its own tenant.', 1;
END;
GO
