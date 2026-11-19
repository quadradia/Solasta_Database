/*
Migration: 20261120_0200_AddMAC_InvoicesAndPayments
Author: Andres Sosa
Date: 2026-11-20
Description: Customer invoices and payments (accounts receivable), next to quotes in MAC:
               MAC.Invoices             a bill to a lead or customer, usually made from a signed quote (its lines
                                        and totals are copied, so the invoice never reprices). Status:
                                        Draft -> Issued -> PartiallyPaid -> Paid, or Void.
               MAC.InvoiceLines         the invoice's lines (copied from MAC.QuoteLines, or typed by staff)
               MAC.Payments             money received (cash, check, card, ACH, wire, financing, other).
                                        AmountApplied is the part applied to invoices; the rest is an unapplied
                                        credit that can be applied later. Status: Posted or Voided.
               MAC.PaymentApplications  how much of a payment pays which invoice. Many to many: one payment can
                                        pay several invoices and one invoice can be paid by several payments.
                                        Unapplying keeps the row (IsActive = 0, UnappliedDate).
             The API keeps Invoices.AmountPaid, Invoices.Status and Payments.AmountApplied in step with the active
             applications, in one transaction; the CHECK constraints stop over-application.
             Proxy prefixes: MAIV (invoice), MAPY (payment).
             No triggers: the API writes these tables with plain EF and scopes every read and write by
             DealerTenantId (applications through their payment and invoice).
Dependencies:
  20261117_2230_AddMAC_QuoteBuilder (MAC.Quotes, MAC.QuoteLines)
  20261117_2330_AddMAC_QuoteSigning (ACE.Customers usable)
Rollback:
  DROP TABLE [MAC].[PaymentApplications];
  DROP TABLE [MAC].[Payments];
  DROP TABLE [MAC].[InvoiceLines];
  DROP TABLE [MAC].[Invoices];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261120_0200_AddMAC_InvoicesAndPayments';
Expected impact: four new, empty tables. No existing object or data changes.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261120_0200_AddMAC_InvoicesAndPayments';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MAC.Quotes', N'U') IS NULL OR OBJECT_ID(N'MAC.QuoteLines', N'U') IS NULL
       OR OBJECT_ID(N'QAL.Leads', N'U') IS NULL OR OBJECT_ID(N'ACE.Customers', N'U') IS NULL
        THROW 50001, 'Invoices require MAC.Quotes, MAC.QuoteLines, QAL.Leads and ACE.Customers.', 1;

    ---------------------------------------------------------------------------
    -- MAC.Invoices
    ---------------------------------------------------------------------------
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
        PRINT 'Created [MAC].[Invoices]';
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

    ---------------------------------------------------------------------------
    -- MAC.InvoiceLines
    ---------------------------------------------------------------------------
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
        PRINT 'Created [MAC].[InvoiceLines]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.InvoiceLines') AND [name] = N'IX_InvoiceLines_InvoiceId')
        CREATE NONCLUSTERED INDEX [IX_InvoiceLines_InvoiceId] ON [MAC].[InvoiceLines] ([InvoiceId], [LineNumber]) WHERE [IsActive] = 1;

    ---------------------------------------------------------------------------
    -- MAC.Payments
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MAC.Payments', N'U') IS NULL
    BEGIN
        CREATE TABLE [MAC].[Payments]
        (
            [PaymentID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [Proxy] [varchar](100) NOT NULL,
            [PartKey] [varchar](6) NOT NULL,
            -- PAY-{n}, unique per tenant.
            [PaymentNumber] [nvarchar](30) NOT NULL,
            [LeadId] [bigint] NULL,
            [CustomerId] [bigint] NULL,
            [PayerName] [nvarchar](150) NOT NULL,
            [PaymentDate] [date] NOT NULL CONSTRAINT [DF_Payments_PaymentDate] DEFAULT (CONVERT([date], SYSDATETIMEOFFSET())),
            -- Cash, Check, Card, ACH, Wire, Financing, Other.
            [Method] [varchar](15) NOT NULL,
            -- Check number, card last four, transaction or financing reference.
            [Reference] [nvarchar](100) NULL,
            [Amount] [decimal](18, 2) NOT NULL,
            -- Sum of the active MAC.PaymentApplications; Amount - AmountApplied is the unapplied credit.
            [AmountApplied] [decimal](18, 2) NOT NULL CONSTRAINT [DF_Payments_AmountApplied] DEFAULT ((0)),
            -- Posted or Voided. A payment is voided only after every application is removed.
            [Status] [varchar](10) NOT NULL CONSTRAINT [DF_Payments_Status] DEFAULT ('Posted'),
            [Notes] [nvarchar](2000) NULL,
            [VoidedDate] [datetimeoffset](7) NULL,
            [VoidReason] [nvarchar](500) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Payments_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Payments_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Payments_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Payments_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Payments_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Payments_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Payments_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Payments] PRIMARY KEY CLUSTERED ([PaymentID] ASC),
            CONSTRAINT [FK_Payments_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Payments_Leads] FOREIGN KEY ([LeadId]) REFERENCES [QAL].[Leads] ([LeadID]),
            CONSTRAINT [FK_Payments_Customers] FOREIGN KEY ([CustomerId]) REFERENCES [ACE].[Customers] ([CustomerID]),
            CONSTRAINT [UQ_Payments_Proxy] UNIQUE ([Proxy]),
            CONSTRAINT [CK_Payments_Method] CHECK ([Method] IN ('Cash', 'Check', 'Card', 'ACH', 'Wire', 'Financing', 'Other')),
            CONSTRAINT [CK_Payments_Status] CHECK ([Status] IN ('Posted', 'Voided')),
            CONSTRAINT [CK_Payments_Amounts] CHECK ([Amount] > 0 AND [AmountApplied] >= 0 AND [AmountApplied] <= [Amount]),
            CONSTRAINT [CK_Payments_Voided] CHECK ([Status] = 'Posted' OR [AmountApplied] = 0)
        );
        PRINT 'Created [MAC].[Payments]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.Payments') AND [name] = N'UQ_Payments_DealerTenantId_PaymentNumber')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Payments_DealerTenantId_PaymentNumber] ON [MAC].[Payments] ([DealerTenantId], [PaymentNumber]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.Payments') AND [name] = N'IX_Payments_DealerTenantId_PaymentDate')
        CREATE NONCLUSTERED INDEX [IX_Payments_DealerTenantId_PaymentDate] ON [MAC].[Payments] ([DealerTenantId], [PaymentDate] DESC)
            INCLUDE ([Status], [Amount], [AmountApplied], [PayerName]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.Payments') AND [name] = N'IX_Payments_LeadId')
        CREATE NONCLUSTERED INDEX [IX_Payments_LeadId] ON [MAC].[Payments] ([DealerTenantId], [LeadId]) WHERE [LeadId] IS NOT NULL;

    ---------------------------------------------------------------------------
    -- MAC.PaymentApplications
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MAC.PaymentApplications', N'U') IS NULL
    BEGIN
        CREATE TABLE [MAC].[PaymentApplications]
        (
            [PaymentApplicationID] [bigint] IDENTITY(1,1) NOT NULL,
            [PaymentId] [bigint] NOT NULL,
            [InvoiceId] [bigint] NOT NULL,
            [Amount] [decimal](18, 2) NOT NULL,
            [AppliedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PaymentApplications_AppliedDate] DEFAULT (SYSDATETIMEOFFSET()),
            -- Set, with IsActive = 0, when staff remove the application; the row is kept as history.
            [UnappliedDate] [datetimeoffset](7) NULL,
            [Notes] [nvarchar](500) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_PaymentApplications_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_PaymentApplications_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PaymentApplications_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PaymentApplications_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PaymentApplications_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PaymentApplications_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PaymentApplications_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_PaymentApplications] PRIMARY KEY CLUSTERED ([PaymentApplicationID] ASC),
            CONSTRAINT [FK_PaymentApplications_Payments] FOREIGN KEY ([PaymentId]) REFERENCES [MAC].[Payments] ([PaymentID]),
            CONSTRAINT [FK_PaymentApplications_Invoices] FOREIGN KEY ([InvoiceId]) REFERENCES [MAC].[Invoices] ([InvoiceID]),
            CONSTRAINT [CK_PaymentApplications_Amount] CHECK ([Amount] > 0),
            CONSTRAINT [CK_PaymentApplications_Unapplied] CHECK (([IsActive] = 1 AND [UnappliedDate] IS NULL)
                                                                 OR ([IsActive] = 0 AND [UnappliedDate] IS NOT NULL))
        );
        PRINT 'Created [MAC].[PaymentApplications]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.PaymentApplications') AND [name] = N'IX_PaymentApplications_PaymentId')
        CREATE NONCLUSTERED INDEX [IX_PaymentApplications_PaymentId] ON [MAC].[PaymentApplications] ([PaymentId]) INCLUDE ([InvoiceId], [Amount], [IsActive]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.PaymentApplications') AND [name] = N'IX_PaymentApplications_InvoiceId')
        CREATE NONCLUSTERED INDEX [IX_PaymentApplications_InvoiceId] ON [MAC].[PaymentApplications] ([InvoiceId]) INCLUDE ([PaymentId], [Amount], [IsActive]);

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Customer invoices, invoice lines, payments and payment applications in MAC',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
