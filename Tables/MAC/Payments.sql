/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: Payments
 * Description: Money received from a customer: cash, check, card, ACH, wire, financing or other. AmountApplied is
 *              the part applied to invoices (MAC.PaymentApplications); the rest is an unapplied credit that can be
 *              applied later. Status Posted or Voided; a payment is voided only once nothing is applied.
 *              Card and ACH payments (MCH.TransactionRequests) can also be Pending (ACH not settled; nothing
 *              applied) or Failed (declined or returned before posting).
 *              Proxy prefix MAPY; number PAY-{n}, unique per tenant.
 * Author: Andres Sosa
 * Created: 2026-11-20
 * Dependencies: ACC.DealerTenants, QAL.Leads, ACE.Customers
 * Migrations: 20261120_0200_AddMAC_InvoicesAndPayments, 20261120_0300_CreateMCH_MerchantServices
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
        CONSTRAINT [CK_Payments_Status] CHECK ([Status] IN ('Pending', 'Posted', 'Failed', 'Voided')),
        CONSTRAINT [CK_Payments_Amounts] CHECK ([Amount] > 0 AND [AmountApplied] >= 0 AND [AmountApplied] <= [Amount]),
        CONSTRAINT [CK_Payments_Voided] CHECK ([Status] = 'Posted' OR [AmountApplied] = 0)
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.Payments') AND [name] = N'UQ_Payments_DealerTenantId_PaymentNumber')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Payments_DealerTenantId_PaymentNumber] ON [MAC].[Payments] ([DealerTenantId], [PaymentNumber]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.Payments') AND [name] = N'IX_Payments_DealerTenantId_PaymentDate')
    CREATE NONCLUSTERED INDEX [IX_Payments_DealerTenantId_PaymentDate] ON [MAC].[Payments] ([DealerTenantId], [PaymentDate] DESC)
        INCLUDE ([Status], [Amount], [AmountApplied], [PayerName]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.Payments') AND [name] = N'IX_Payments_LeadId')
    CREATE NONCLUSTERED INDEX [IX_Payments_LeadId] ON [MAC].[Payments] ([DealerTenantId], [LeadId]) WHERE [LeadId] IS NOT NULL;
GO
