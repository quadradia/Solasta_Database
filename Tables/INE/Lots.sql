/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: Lots
 * Description: A lot, reel or color bin of a Lot-tracked stock item, so installers can
 *              keep one job on one batch and defects can be traced back. Created by the
 *              first receipt that names the lot number.
 * Dependencies: INE.StockItems
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.Lots', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[Lots]
    (
        [LotID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [StockItemId] [int] NOT NULL,
        [LotNumber] [nvarchar](50) NOT NULL,
        [ManufacturedDate] [date] NULL,
        [ExpirationDate] [date] NULL,
        [Notes] [nvarchar](1000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Lots_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Lots_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Lots_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Lots_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Lots_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Lots_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Lots_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Lots] PRIMARY KEY CLUSTERED ([LotID] ASC),
        CONSTRAINT [FK_Lots_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Lots_StockItems] FOREIGN KEY ([StockItemId])
            REFERENCES [INE].[StockItems] ([StockItemID])
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.Lots') AND [name] = N'UQ_Lots_StockItemId_LotNumber')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Lots_StockItemId_LotNumber]
        ON [INE].[Lots] ([StockItemId], [LotNumber]);
GO
