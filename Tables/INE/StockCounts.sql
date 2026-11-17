/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: StockCounts
 * Description: A physical count of one location (the legacy "audit"). Lines are filled
 *              in while Open; INE.spStockCountPost compares counted with on-hand and
 *              posts AdjustIn / AdjustOut movements for the differences, then marks
 *              the count Posted.
 * Dependencies: ACC.DealerTenants, INE.Locations
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.StockCounts', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[StockCounts]
    (
        [StockCountID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [LocationId] [int] NOT NULL,
        [Status] [varchar](10) NOT NULL CONSTRAINT [DF_StockCounts_Status] DEFAULT ('Open'),
        [CountDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCounts_CountDate] DEFAULT (SYSDATETIMEOFFSET()),
        [PostedDate] [datetimeoffset](7) NULL,
        [Notes] [nvarchar](2000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_StockCounts_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_StockCounts_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCounts_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockCounts_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCounts_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockCounts_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockCounts_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_StockCounts] PRIMARY KEY CLUSTERED ([StockCountID] ASC),
        CONSTRAINT [FK_StockCounts_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_StockCounts_Locations] FOREIGN KEY ([LocationId])
            REFERENCES [INE].[Locations] ([LocationID]),
        CONSTRAINT [CK_StockCounts_Status] CHECK ([Status] IN ('Open', 'Posted', 'Cancelled'))
    );
END;
GO
