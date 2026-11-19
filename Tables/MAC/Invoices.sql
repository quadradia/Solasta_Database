/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: Invoices
 * Description: A bill to a lead or customer, usually made from a signed quote (MAC.Quotes): the quote's lines and
 *              totals are copied, so the invoice never reprices. Bill-to details are copied too. Status:
 *              Draft -> Issued -> PartiallyPaid -> Paid, or Void. Only a Draft's lines change. AmountPaid is the
 *              sum of the active MAC.PaymentApplications, kept by the API; the balance due is TotalAmount - AmountPaid.
 *              Proxy prefix MAIV; number INV-{n}, unique per tenant.
 * Author: Andres Sosa
 * Created: 2026-11-20
 * Dependencies: ACC.DealerTenants, MAC.Quotes, QAL.Leads, ACE.Customers
 * Migrations: 20261120_0200_AddMAC_InvoicesAndPayments
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.Invoices', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[Invoices]
    (
        [InvoiceID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        -- INV-{n}, unique per tenant.
        [InvoiceNumber] [nvarchar](30) NOT NULL,
        -- The signed quote it was made from, if any.
        [QuoteId] [bigint] NULL,
        [LeadId] [bigint] NULL,
        [CustomerId] [bigint] NULL,
        -- Draft, Issued, PartiallyPaid, Paid, Void. Only a Draft's lines and totals change.
        [Status] [varchar](20) NOT NULL CONSTRAINT [DF_Invoices_Status] DEFAULT ('Draft'),
        [InvoiceDate] [date] NOT NULL CONSTRAINT [DF_Invoices_InvoiceDate] DEFAULT (CONVERT([date], SYSDATETIMEOFFSET())),
        [DueDate] [date] NULL,
        -- Copied when the invoice is made, so later lead or customer edits never rewrite it.
        [BillToName] [nvarchar](150) NOT NULL,
        [BillToEmail] [nvarchar](256) NULL,
        [BillToPhone] [varchar](20) NULL,
        [BillToAddress] [nvarchar](500) NULL,
        -- Rate used for typed lines (IsTaxable); a quote's lines keep the tax the quote computed.
        [SalesTaxRate] [decimal](9, 6) NULL,
        [SubTotal] [decimal](18, 2) NOT NULL CONSTRAINT [DF_Invoices_SubTotal] DEFAULT ((0)),
        [DiscountTotal] [decimal](18, 2) NOT NULL CONSTRAINT [DF_Invoices_DiscountTotal] DEFAULT ((0)),
        [TaxTotal] [decimal](18, 2) NOT NULL CONSTRAINT [DF_Invoices_TaxTotal] DEFAULT ((0)),
        [TotalAmount] [decimal](18, 2) NOT NULL CONSTRAINT [DF_Invoices_TotalAmount] DEFAULT ((0)),
        -- Sum of the active MAC.PaymentApplications for this invoice.
        [AmountPaid] [decimal](18, 2) NOT NULL CONSTRAINT [DF_Invoices_AmountPaid] DEFAULT ((0)),
        -- The deposit the quote asked for (shown on the invoice; paid like any other amount).
        [DepositDue] [decimal](18, 2) NULL,
        [Terms] [nvarchar](1000) NULL,
        [Notes] [nvarchar](2000) NULL,
        [IssuedDate] [datetimeoffset](7) NULL,
        [PaidDate] [datetimeoffset](7) NULL,
        [VoidedDate] [datetimeoffset](7) NULL,
        [VoidReason] [nvarchar](500) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Invoices_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Invoices_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Invoices_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Invoices_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Invoices_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Invoices_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Invoices_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Invoices] PRIMARY KEY CLUSTERED ([InvoiceID] ASC),
        CONSTRAINT [FK_Invoices_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Invoices_Quotes] FOREIGN KEY ([QuoteId]) REFERENCES [MAC].[Quotes] ([QuoteID]),
        CONSTRAINT [FK_Invoices_Leads] FOREIGN KEY ([LeadId]) REFERENCES [QAL].[Leads] ([LeadID]),
        CONSTRAINT [FK_Invoices_Customers] FOREIGN KEY ([CustomerId]) REFERENCES [ACE].[Customers] ([CustomerID]),
        CONSTRAINT [UQ_Invoices_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [CK_Invoices_Status] CHECK ([Status] IN ('Draft', 'Issued', 'PartiallyPaid', 'Paid', 'Void')),
        CONSTRAINT [CK_Invoices_Amounts] CHECK ([SubTotal] >= 0 AND [DiscountTotal] >= 0 AND [TaxTotal] >= 0
                                              AND [TotalAmount] >= 0 AND [AmountPaid] >= 0
                                              AND [AmountPaid] <= [TotalAmount]),
        CONSTRAINT [CK_Invoices_DepositDue] CHECK ([DepositDue] IS NULL OR [DepositDue] >= 0),
        CONSTRAINT [CK_Invoices_SalesTaxRate] CHECK ([SalesTaxRate] IS NULL OR ([SalesTaxRate] >= 0 AND [SalesTaxRate] < 1)),
        CONSTRAINT [CK_Invoices_DueDate] CHECK ([DueDate] IS NULL OR [DueDate] >= [InvoiceDate])
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.Invoices') AND [name] = N'UQ_Invoices_DealerTenantId_InvoiceNumber')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Invoices_DealerTenantId_InvoiceNumber] ON [MAC].[Invoices] ([DealerTenantId], [InvoiceNumber]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.Invoices') AND [name] = N'IX_Invoices_DealerTenantId_Status')
    CREATE NONCLUSTERED INDEX [IX_Invoices_DealerTenantId_Status] ON [MAC].[Invoices] ([DealerTenantId], [Status], [InvoiceDate] DESC)
        INCLUDE ([TotalAmount], [AmountPaid], [BillToName]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.Invoices') AND [name] = N'IX_Invoices_LeadId')
    CREATE NONCLUSTERED INDEX [IX_Invoices_LeadId] ON [MAC].[Invoices] ([DealerTenantId], [LeadId]) WHERE [LeadId] IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.Invoices') AND [name] = N'IX_Invoices_QuoteId')
    CREATE NONCLUSTERED INDEX [IX_Invoices_QuoteId] ON [MAC].[Invoices] ([QuoteId]) WHERE [QuoteId] IS NOT NULL;
GO
