/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: Allocations
 * Description: Stock reserved at a location for a job (a lead) before it is issued.
 *              While Open, QuantityAllocated - QuantityIssued is counted in
 *              INE.StockBalances.QuantityAllocated, so it is not available to anyone
 *              else. Issuing to the job with the allocation named on the movement line
 *              consumes it; INE.spAllocationCancel releases what is left.
 * Dependencies: ACC.DealerTenants, QAL.Leads, INE.StockItems, INE.Locations, INE.Lots
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.Allocations', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[Allocations]
    (
        [AllocationID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [LeadId] [bigint] NOT NULL,
        [StockItemId] [int] NOT NULL,
        [LocationId] [int] NOT NULL,
        [LotId] [int] NULL,
        [QuantityAllocated] [decimal](19, 4) NOT NULL,
        [QuantityIssued] [decimal](19, 4) NOT NULL CONSTRAINT [DF_Allocations_QuantityIssued] DEFAULT ((0)),
        [Status] [varchar](10) NOT NULL CONSTRAINT [DF_Allocations_Status] DEFAULT ('Open'),
        [NeededByDate] [date] NULL,
        [Notes] [nvarchar](500) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Allocations_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Allocations_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Allocations_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Allocations_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Allocations_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Allocations_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Allocations_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Allocations] PRIMARY KEY CLUSTERED ([AllocationID] ASC),
        CONSTRAINT [FK_Allocations_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Allocations_Leads] FOREIGN KEY ([LeadId])
            REFERENCES [QAL].[Leads] ([LeadID]),
        CONSTRAINT [FK_Allocations_StockItems] FOREIGN KEY ([StockItemId])
            REFERENCES [INE].[StockItems] ([StockItemID]),
        CONSTRAINT [FK_Allocations_Locations] FOREIGN KEY ([LocationId])
            REFERENCES [INE].[Locations] ([LocationID]),
        CONSTRAINT [FK_Allocations_Lots] FOREIGN KEY ([LotId])
            REFERENCES [INE].[Lots] ([LotID]),
        CONSTRAINT [CK_Allocations_Quantities]
            CHECK ([QuantityAllocated] > 0 AND [QuantityIssued] >= 0 AND [QuantityIssued] <= [QuantityAllocated]),
        CONSTRAINT [CK_Allocations_Status] CHECK ([Status] IN ('Open', 'Fulfilled', 'Cancelled'))
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.Allocations') AND [name] = N'IX_Allocations_LeadId')
    CREATE NONCLUSTERED INDEX [IX_Allocations_LeadId]
        ON [INE].[Allocations] ([LeadId], [Status]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.Allocations') AND [name] = N'IX_Allocations_Open')
    CREATE NONCLUSTERED INDEX [IX_Allocations_Open]
        ON [INE].[Allocations] ([LocationId], [StockItemId], [LotId])
        INCLUDE ([QuantityAllocated], [QuantityIssued])
        WHERE [Status] = 'Open';
GO
