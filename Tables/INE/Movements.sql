/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: Movements
 * Description: The inventory ledger header: one business event that moves stock (a
 *              receipt, a transfer to a van, an issue to a job, a count adjustment).
 *              Append-only: rows are written only by INE.spMovementPost and are never
 *              updated or deleted (tr_Movements_PreventChange). A mistake is corrected
 *              by INE.spMovementReverse, which posts an opposite Reversal movement that
 *              points back with ReversesMovementId.
 * Dependencies: ACC.DealerTenants, QAL.Leads, INE.MovementTypes, INE.Locations,
 *               INE.Receipts, INE.StockCounts
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.Movements', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[Movements]
    (
        [MovementID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [MovementTypeId] [int] NOT NULL,
        [MovementDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Movements_MovementDate] DEFAULT (SYSDATETIMEOFFSET()),
        [FromLocationId] [int] NULL,
        [ToLocationId] [int] NULL,
        -- The job the stock went to or came back from.
        [LeadId] [bigint] NULL,
        [ReceiptId] [bigint] NULL,
        [StockCountId] [bigint] NULL,
        [ReversesMovementId] [bigint] NULL,
        -- RMA number, transfer slip, work order, ...
        [Reference] [nvarchar](50) NULL,
        [Notes] [nvarchar](2000) NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Movements_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Movements_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Movements_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Movements] PRIMARY KEY CLUSTERED ([MovementID] ASC),
        CONSTRAINT [FK_Movements_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Movements_MovementTypes] FOREIGN KEY ([MovementTypeId])
            REFERENCES [INE].[MovementTypes] ([MovementTypeID]),
        CONSTRAINT [FK_Movements_Locations_From] FOREIGN KEY ([FromLocationId])
            REFERENCES [INE].[Locations] ([LocationID]),
        CONSTRAINT [FK_Movements_Locations_To] FOREIGN KEY ([ToLocationId])
            REFERENCES [INE].[Locations] ([LocationID]),
        CONSTRAINT [FK_Movements_Leads] FOREIGN KEY ([LeadId])
            REFERENCES [QAL].[Leads] ([LeadID]),
        CONSTRAINT [FK_Movements_Receipts] FOREIGN KEY ([ReceiptId])
            REFERENCES [INE].[Receipts] ([ReceiptID]),
        CONSTRAINT [FK_Movements_StockCounts] FOREIGN KEY ([StockCountId])
            REFERENCES [INE].[StockCounts] ([StockCountID]),
        CONSTRAINT [FK_Movements_Movements] FOREIGN KEY ([ReversesMovementId])
            REFERENCES [INE].[Movements] ([MovementID]),
        CONSTRAINT [CK_Movements_Locations]
            CHECK (([FromLocationId] IS NOT NULL OR [ToLocationId] IS NOT NULL)
                   AND ([FromLocationId] IS NULL OR [ToLocationId] IS NULL OR [FromLocationId] <> [ToLocationId]))
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.Movements') AND [name] = N'IX_Movements_DealerTenantId_MovementDate')
    CREATE NONCLUSTERED INDEX [IX_Movements_DealerTenantId_MovementDate]
        ON [INE].[Movements] ([DealerTenantId], [MovementDate] DESC)
        INCLUDE ([MovementTypeId], [FromLocationId], [ToLocationId]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.Movements') AND [name] = N'IX_Movements_LeadId')
    CREATE NONCLUSTERED INDEX [IX_Movements_LeadId]
        ON [INE].[Movements] ([LeadId])
        WHERE [LeadId] IS NOT NULL;

-- At most one reversal per movement.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.Movements') AND [name] = N'UQ_Movements_ReversesMovementId')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Movements_ReversesMovementId]
        ON [INE].[Movements] ([ReversesMovementId])
        WHERE [ReversesMovementId] IS NOT NULL;
GO
