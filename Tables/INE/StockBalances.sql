/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: StockBalances
 * Description: On-hand and allocated quantity per location, item and lot. A projection
 *              of INE.MovementLines (and open INE.Allocations), maintained only by the
 *              INE procedures in the same transaction as the movement. The CHECKs are
 *              the core inventory invariants: stock never goes negative and never more
 *              is reserved than is on hand. LotId is NULL for Quantity and Serial items
 *              without a lot. INE.vwStockBalanceDrift rebuilds it from the ledger to
 *              prove it matches.
 * Dependencies: ACC.DealerTenants, INE.Locations, INE.StockItems, INE.Lots
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.StockBalances', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[StockBalances]
    (
        [StockBalanceID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [LocationId] [int] NOT NULL,
        [StockItemId] [int] NOT NULL,
        [LotId] [int] NULL,
        [LastMovementId] [bigint] NULL,
        [QuantityOnHand] [decimal](19, 4) NOT NULL CONSTRAINT [DF_StockBalances_QuantityOnHand] DEFAULT ((0)),
        [QuantityAllocated] [decimal](19, 4) NOT NULL CONSTRAINT [DF_StockBalances_QuantityAllocated] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockBalances_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockBalances_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockBalances_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_StockBalances] PRIMARY KEY CLUSTERED ([StockBalanceID] ASC),
        CONSTRAINT [FK_StockBalances_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_StockBalances_Locations] FOREIGN KEY ([LocationId])
            REFERENCES [INE].[Locations] ([LocationID]),
        CONSTRAINT [FK_StockBalances_StockItems] FOREIGN KEY ([StockItemId])
            REFERENCES [INE].[StockItems] ([StockItemID]),
        CONSTRAINT [FK_StockBalances_Lots] FOREIGN KEY ([LotId])
            REFERENCES [INE].[Lots] ([LotID]),
        CONSTRAINT [FK_StockBalances_Movements] FOREIGN KEY ([LastMovementId])
            REFERENCES [INE].[Movements] ([MovementID]),
        CONSTRAINT [CK_StockBalances_QuantityOnHand] CHECK ([QuantityOnHand] >= 0),
        CONSTRAINT [CK_StockBalances_QuantityAllocated]
            CHECK ([QuantityAllocated] >= 0 AND [QuantityAllocated] <= [QuantityOnHand])
    );
END;

-- One row per location, item and lot (a unique index treats NULL LotId as one value).
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.StockBalances') AND [name] = N'UQ_StockBalances_LocationId_StockItemId_LotId')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_StockBalances_LocationId_StockItemId_LotId]
        ON [INE].[StockBalances] ([LocationId], [StockItemId], [LotId])
        INCLUDE ([QuantityOnHand], [QuantityAllocated]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.StockBalances') AND [name] = N'IX_StockBalances_StockItemId')
    CREATE NONCLUSTERED INDEX [IX_StockBalances_StockItemId]
        ON [INE].[StockBalances] ([StockItemId], [LocationId])
        INCLUDE ([LotId], [QuantityOnHand], [QuantityAllocated]);
GO
