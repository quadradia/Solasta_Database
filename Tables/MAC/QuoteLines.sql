/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: QuoteLines
 * Description: The lines of a quote (MAC.Quotes): one per rail location (Front, Side-Left, ...),
 *              one per fixed cost (dormers, gables, height cost) and one per add-on (camera, DVR, ...).
 *              Prices are copied from MAC.Products when the quote is made. Fixed lines carry only
 *              their gross: the estimate prices every fixed cost together as one "Aux - Fixed Costs" row.
 * Author: Andres Sosa
 * Created: 2026-11-17
 *              A line whose product has variants (INE.StockItems parents linked by ProductId) names
 *              the chosen variant in StockItemId and snapshots its VariantName and PriceAdder
 *              (VariantPriceAdder); UnitPrice is then the product price plus that adder. The API
 *              blocks signing while such a line has no variant chosen.
 * Dependencies: MAC.Quotes, MAC.Products, INE.StockItems
 * Migrations: 20261117_2230_AddMAC_QuoteBuilder, 20261120_0100_AddINE_PartVariants
 * API mappings: Models/MAC/QuoteLine.cs is written by hand; remove it when the
 *               AutoGenerator produces an equivalent.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.QuoteLines', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[QuoteLines]
    (
        [QuoteLineID] [bigint] IDENTITY(1,1) NOT NULL,
        [QuoteId] [bigint] NOT NULL,
        -- Rail (one per location), Fixed (dormers, gables, height cost) or AddOn (camera, DVR, ...).
        [LineType] [varchar](10) NOT NULL,
        [SortOrder] [int] NOT NULL CONSTRAINT [DF_QuoteLines_SortOrder] DEFAULT ((0)),
        -- Rail lines: Front, Side-Left, Side-Right, Back, Back - Low, ...
        [Location] [nvarchar](30) NULL,
        [ProductId] [int] NULL,
        -- The chosen variant (INE.StockItems child) when the product comes in colors/options.
        [StockItemId] [int] NULL,
        -- Snapshots of the variant at quote time: its name (e.g. Black) and per-unit price adder.
        [VariantName] [nvarchar](50) NULL,
        [VariantPriceAdder] [decimal](19, 4) NULL,
        [Sku] [varchar](20) NOT NULL,
        [Description] [nvarchar](200) NOT NULL,
        -- Rail lines: measured feet before the allowance, when known.
        [MeasuredFeet] [decimal](9, 2) NULL,
        -- Rail lines: billable feet (measured + allowance, rounded). Others: how many.
        [Quantity] [decimal](9, 2) NOT NULL,
        [UnitPrice] [decimal](19, 4) NOT NULL,
        [Gross] [decimal](18, 2) NOT NULL,
        -- The priced row; NULL on Fixed lines (priced together as "Aux - Fixed Costs").
        [PerFootDiscount] [decimal](18, 2) NULL,
        [PercentDiscount] [decimal](18, 2) NULL,
        [SpecialDiscount] [decimal](18, 2) NULL,
        [Discount] [decimal](18, 2) NULL,
        [SubTotal] [decimal](18, 2) NULL,
        [Tax] [decimal](18, 2) NULL,
        [Total] [decimal](18, 2) NULL,
        -- An excluded location is shown but left out of the totals.
        [IsIncluded] [bit] NOT NULL CONSTRAINT [DF_QuoteLines_IsIncluded] DEFAULT ((1)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_QuoteLines_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_QuoteLines_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_QuoteLines_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_QuoteLines_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_QuoteLines_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_QuoteLines_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_QuoteLines_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_QuoteLines] PRIMARY KEY CLUSTERED ([QuoteLineID] ASC),
        CONSTRAINT [FK_QuoteLines_Quotes] FOREIGN KEY ([QuoteId]) REFERENCES [MAC].[Quotes] ([QuoteID]),
        CONSTRAINT [FK_QuoteLines_Products] FOREIGN KEY ([ProductId]) REFERENCES [MAC].[Products] ([ProductID]),
        CONSTRAINT [FK_QuoteLines_StockItems] FOREIGN KEY ([StockItemId]) REFERENCES [INE].[StockItems] ([StockItemID]),
        CONSTRAINT [CK_QuoteLines_LineType] CHECK ([LineType] IN ('Rail', 'Fixed', 'AddOn')),
        CONSTRAINT [CK_QuoteLines_Location] CHECK ([LineType] <> 'Rail' OR [Location] IS NOT NULL),
        CONSTRAINT [CK_QuoteLines_Quantity] CHECK ([Quantity] >= 0),
        CONSTRAINT [CK_QuoteLines_UnitPrice] CHECK ([UnitPrice] >= 0),
        CONSTRAINT [CK_QuoteLines_MeasuredFeet] CHECK ([MeasuredFeet] IS NULL OR [MeasuredFeet] >= 0),
        CONSTRAINT [CK_QuoteLines_VariantPriceAdder] CHECK ([VariantPriceAdder] IS NULL OR [VariantPriceAdder] >= 0),
        CONSTRAINT [CK_QuoteLines_VariantSnapshot] CHECK ([StockItemId] IS NOT NULL OR ([VariantName] IS NULL AND [VariantPriceAdder] IS NULL))
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'MAC.QuoteLines') AND [name] = N'IX_QuoteLines_QuoteId')
    CREATE NONCLUSTERED INDEX [IX_QuoteLines_QuoteId] ON [MAC].[QuoteLines] ([QuoteId]) WHERE [IsActive] = 1;
GO
