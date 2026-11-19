/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_StockCountLines_VariantGuard
 * Description: Stock lives on variants only: a stock count line cannot name a stock item that has
 *              active variants (INE.StockItems rows with that item as ParentStockItemId). Count each variant instead.
 *              Checked when a row is written with a new StockItemId.
 *              Error code: 04190 item has variants.
 * Dependencies: INE.StockItems
 * Migrations: 20261120_0100_AddINE_PartVariants
 * Author: Andres Sosa
 * Created: 2026-11-19
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_StockCountLines_VariantGuard]
ON [INE].[StockCountLines]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) OR NOT UPDATE([StockItemId]) RETURN;

    DECLARE @Msg NVARCHAR(2048);
    SELECT TOP (1) @Msg = CONCAT(N'04190|:|Stock item ', SI.[Sku], N' has variants; stock is kept on its variants. Pick a variant.')
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockCountLineID] = I.[StockCountLineID]
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = I.[StockItemId]
    WHERE (D.[StockCountLineID] IS NULL OR D.[StockItemId] <> I.[StockItemId])
      AND EXISTS (SELECT 1 FROM [INE].[StockItems] AS C
                  WHERE C.[ParentStockItemId] = I.[StockItemId] AND C.[IsActive] = 1 AND C.[IsDeleted] = 0);
    IF @Msg IS NOT NULL
        THROW 50000, @Msg, 1;
END;
GO
