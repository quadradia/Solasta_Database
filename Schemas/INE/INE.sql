/*******************************************************************************
 * Object Type: Schema
 * Schema: INE
 * Name: INE
 * Description: Inventory Engine bounded context: stock items, locations, purchase
 *              orders and receiving, the append-only movement ledger and the balances,
 *              serial units, allocations and stock counts projected from it.
 * Dependencies: none
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
IF SCHEMA_ID(N'INE') IS NULL
    EXEC (N'CREATE SCHEMA [INE] AUTHORIZATION [dbo]');
GO
