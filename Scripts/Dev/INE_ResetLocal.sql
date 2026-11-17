/*******************************************************************************
 * INE_ResetLocal.sql
 * Removes everything the two INE migrations created so they can be applied again:
 *   20261117_1810_CreateINE_InventoryEngineProcedures (rolled back first)
 *   20261117_1800_CreateINE_InventoryEngineTables
 * LOCAL DEV ONLY: it drops every INE table and the stock data in it.
 * Safe to run more than once (everything is IF EXISTS).
 ******************************************************************************/
SET XACT_ABORT ON;
PRINT CONCAT(N'Resetting INE in database ', DB_NAME(), N' on ', @@SERVERNAME);
BEGIN TRANSACTION;

-- 1810: triggers, views, procedures, function
DROP TRIGGER IF EXISTS [INE].[tr_PurchaseOrderLines_GuardStatus];
DROP TRIGGER IF EXISTS [INE].[tr_MovementLines_PreventChange];
DROP TRIGGER IF EXISTS [INE].[tr_Movements_PreventChange];
DROP VIEW IF EXISTS [INE].[vwStockBalanceDrift];
DROP VIEW IF EXISTS [INE].[vwMovementHistory];
DROP VIEW IF EXISTS [INE].[vwReorderSuggestions];
DROP VIEW IF EXISTS [INE].[vwStockOnHand];
DROP PROCEDURE IF EXISTS [INE].[spStockCountPost];
DROP PROCEDURE IF EXISTS [INE].[spAllocationCancel];
DROP PROCEDURE IF EXISTS [INE].[spAllocationCreate];
DROP PROCEDURE IF EXISTS [INE].[spPurchaseOrderSetStatus];
DROP PROCEDURE IF EXISTS [INE].[spReceiptPost];
DROP PROCEDURE IF EXISTS [INE].[spMovementReverse];
DROP PROCEDURE IF EXISTS [INE].[spMovementPost];
DROP FUNCTION IF EXISTS [INE].[fxGetSessionContext];
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_1810_CreateINE_InventoryEngineProcedures';

-- 1800: tables (children before parents), then the schema
DROP TABLE IF EXISTS [INE].[StockBalances];
DROP TABLE IF EXISTS [INE].[MovementLines];
DROP TABLE IF EXISTS [INE].[Movements];
DROP TABLE IF EXISTS [INE].[Allocations];
DROP TABLE IF EXISTS [INE].[StockCountLines];
DROP TABLE IF EXISTS [INE].[StockCounts];
DROP TABLE IF EXISTS [INE].[SerialUnits];
DROP TABLE IF EXISTS [INE].[Receipts];
DROP TABLE IF EXISTS [INE].[PurchaseOrderLines];
DROP TABLE IF EXISTS [INE].[PurchaseOrders];
DROP TABLE IF EXISTS [INE].[Lots];
DROP TABLE IF EXISTS [INE].[StockLevels];
DROP TABLE IF EXISTS [INE].[StockItems];
DROP TABLE IF EXISTS [INE].[Locations];
DROP TABLE IF EXISTS [INE].[Vendors];
DROP TABLE IF EXISTS [INE].[MovementTypes];
DROP TABLE IF EXISTS [INE].[LocationTypes];
IF SCHEMA_ID(N'INE') IS NOT NULL EXEC (N'DROP SCHEMA [INE]');
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_1800_CreateINE_InventoryEngineTables';

COMMIT TRANSACTION;
PRINT N'INE removed. Now apply 20261117_1800 and then 20261117_1810.';

-- Afterwards, check it worked:
--   SELECT [MigrationName], [Success] FROM [dbo].[SchemaVersion] WHERE [MigrationName] LIKE N'20261117_18%';
--   SELECT * FROM [INE].[vwStockBalanceDrift];   -- must be empty
