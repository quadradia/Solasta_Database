/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: SerialUnits
 * Description: One physical unit of a Serial-tracked stock item. CurrentLocationId and
 *              Status are a projection of the movement ledger, kept in step by
 *              INE.spMovementPost in the same transaction as the movement:
 *                InStock    at a stock-holding location
 *                Installed  issued to a job
 *                Returned   sent back to a vendor
 *                Scrapped   written off
 *                Missing    not found by a stock count (AdjustOut)
 *                Voided     its receipt was reversed
 *              CurrentLocationId is NULL for Scrapped, Missing and Voided units; only
 *              those can be brought back in by a Receive or AdjustIn.
 * Dependencies: ACC.DealerTenants, INE.StockItems, INE.Lots, INE.Locations,
 *               INE.PurchaseOrderLines
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.SerialUnits', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[SerialUnits]
    (
        [SerialUnitID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [StockItemId] [int] NOT NULL,
        [LotId] [int] NULL,
        [CurrentLocationId] [int] NULL,
        -- The PO line it was bought on, when there was one.
        [PurchaseOrderLineId] [bigint] NULL,
        [SerialNumber] [nvarchar](60) NOT NULL,
        [Status] [varchar](10) NOT NULL CONSTRAINT [DF_SerialUnits_Status] DEFAULT ('InStock'),
        [UnitCost] [decimal](19, 4) NULL,
        [ReceivedDate] [datetimeoffset](7) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_SerialUnits_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_SerialUnits_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_SerialUnits_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SerialUnits_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_SerialUnits_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SerialUnits_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_SerialUnits_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_SerialUnits] PRIMARY KEY CLUSTERED ([SerialUnitID] ASC),
        CONSTRAINT [FK_SerialUnits_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_SerialUnits_StockItems] FOREIGN KEY ([StockItemId])
            REFERENCES [INE].[StockItems] ([StockItemID]),
        CONSTRAINT [FK_SerialUnits_Lots] FOREIGN KEY ([LotId])
            REFERENCES [INE].[Lots] ([LotID]),
        CONSTRAINT [FK_SerialUnits_Locations] FOREIGN KEY ([CurrentLocationId])
            REFERENCES [INE].[Locations] ([LocationID]),
        CONSTRAINT [FK_SerialUnits_PurchaseOrderLines] FOREIGN KEY ([PurchaseOrderLineId])
            REFERENCES [INE].[PurchaseOrderLines] ([PurchaseOrderLineID]),
        CONSTRAINT [CK_SerialUnits_Status]
            CHECK ([Status] IN ('InStock', 'Installed', 'Returned', 'Scrapped', 'Missing', 'Voided')),
        CONSTRAINT [CK_SerialUnits_CurrentLocationId]
            CHECK (([Status] IN ('Scrapped', 'Missing', 'Voided') AND [CurrentLocationId] IS NULL)
                   OR ([Status] IN ('InStock', 'Installed', 'Returned') AND [CurrentLocationId] IS NOT NULL))
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.SerialUnits') AND [name] = N'UQ_SerialUnits_StockItemId_SerialNumber')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_SerialUnits_StockItemId_SerialNumber]
        ON [INE].[SerialUnits] ([StockItemId], [SerialNumber]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.SerialUnits') AND [name] = N'IX_SerialUnits_DealerTenantId_SerialNumber')
    CREATE NONCLUSTERED INDEX [IX_SerialUnits_DealerTenantId_SerialNumber]
        ON [INE].[SerialUnits] ([DealerTenantId], [SerialNumber]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.SerialUnits') AND [name] = N'IX_SerialUnits_CurrentLocationId')
    CREATE NONCLUSTERED INDEX [IX_SerialUnits_CurrentLocationId]
        ON [INE].[SerialUnits] ([CurrentLocationId], [StockItemId])
        WHERE [CurrentLocationId] IS NOT NULL;
GO
