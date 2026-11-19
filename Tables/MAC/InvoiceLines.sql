/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: InvoiceLines
 * Description: The lines of an invoice (MAC.Invoices), copied from MAC.QuoteLines or typed by staff.
 *              Total = Gross - Discount + Tax.
 * Author: Andres Sosa
 * Created: 2026-11-20
 * Dependencies: MAC.Invoices, MAC.QuoteLines
 * Migrations: 20261120_0200_AddMAC_InvoicesAndPayments
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.InvoiceLines', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[InvoiceLines]
    (
        [InvoiceLineID] [bigint] IDENTITY(1,1) NOT NULL,
        [InvoiceId] [bigint] NOT NULL,
        -- The quote line it was copied from, if any.
        [QuoteLineId] [bigint] NULL,
        [LineNumber] [int] NOT NULL,
        [Sku] [varchar](20) NULL,
        [Description] [nvarchar](200) NOT NULL,
        [Quantity] [decimal](9, 2) NOT NULL,
        [UnitPrice] [decimal](19, 4) NOT NULL,
        -- Quantity x UnitPrice, rounded half away from zero.
        [Gross] [decimal](18, 2) NOT NULL,
        [Discount] [decimal](18, 2) NOT NULL CONSTRAINT [DF_InvoiceLines_Discount] DEFAULT ((0)),
        -- Typed lines: taxed at Invoices.SalesTaxRate when set. Quote lines: the quote's own tax.
        [IsTaxable] [bit] NOT NULL CONSTRAINT [DF_InvoiceLines_IsTaxable] DEFAULT ((1)),
        [Tax] [decimal](18, 2) NOT NULL CONSTRAINT [DF_InvoiceLines_Tax] DEFAULT ((0)),
        -- Gross - Discount + Tax.
        [Total] [decimal](18, 2) NOT NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_InvoiceLines_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_InvoiceLines_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_InvoiceLines_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_InvoiceLines_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_InvoiceLines_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_InvoiceLines_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_InvoiceLines_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_InvoiceLines] PRIMARY KEY CLUSTERED ([InvoiceLineID] ASC),
        CONSTRAINT [FK_InvoiceLines_Invoices] FOREIGN KEY ([InvoiceId]) REFERENCES [MAC].[Invoices] ([InvoiceID]),
        CONSTRAINT [FK_InvoiceLines_QuoteLines] FOREIGN KEY ([QuoteLineId]) REFERENCES [MAC].[QuoteLines] ([QuoteLineID]),
        CONSTRAINT [CK_InvoiceLines_Quantity] CHECK ([Quantity] > 0),
        CONSTRAINT [CK_InvoiceLines_UnitPrice] CHECK ([UnitPrice] >= 0),
        CONSTRAINT [CK_InvoiceLines_Amounts] CHECK ([Gross] >= 0 AND [Discount] >= 0 AND [Discount] <= [Gross]
                                                  AND [Tax] >= 0 AND [Total] >= 0)
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.InvoiceLines') AND [name] = N'IX_InvoiceLines_InvoiceId')
    CREATE NONCLUSTERED INDEX [IX_InvoiceLines_InvoiceId] ON [MAC].[InvoiceLines] ([InvoiceId], [LineNumber]) WHERE [IsActive] = 1;
GO
