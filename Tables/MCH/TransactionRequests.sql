/*******************************************************************************
 * Object Type: Table
 * Schema: MCH
 * Name: TransactionRequests
 * Description: One row per card or ACH attempt (sale, refund, void). Proxy prefix MCTR. Card brand/last 4 or bank last 4 only.
 * Author: Andres Sosa
 * Created: 2026-11-20
 * Migrations: 20261120_0400_CreateMCH_MerchantServices
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MCH.TransactionRequests', N'U') IS NULL
BEGIN
    CREATE TABLE [MCH].[TransactionRequests]
    (
        [TransactionRequestID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        [MchTransactionTypeId] [int] NOT NULL,
        [MerchantGatewayId] [smallint] NOT NULL,
        [DealerGatewaySettingId] [int] NULL,
        -- For a refund or void: the sale it reverses.
        [ParentTransactionRequestId] [bigint] NULL,
        [LeadId] [bigint] NULL,
        [CustomerId] [bigint] NULL,
        -- The payment a sale created, or the payment a refund or void reverses.
        [PaymentId] [bigint] NULL,
        -- Sent to the gateway as its merchant reference (Cybersource clientReferenceInformation.code);
        -- unique per tenant so a retried request is never charged twice.
        [MerchantReference] [varchar](50) NOT NULL,
        [Amount] [decimal](18, 2) NOT NULL,
        [CurrencyCode] [char](3) NOT NULL CONSTRAINT [DF_TransactionRequests_CurrencyCode] DEFAULT ('USD'),
        -- Current state: the status of the latest response (OK, PENDING, DECLINED, ERROR, VOID, REFUND, RETURNED...).
        [TransactionStatusId] [varchar](20) NOT NULL CONSTRAINT [DF_TransactionRequests_TransactionStatusId] DEFAULT ('UND'),
        [PayerFirstName] [nvarchar](50) NULL,
        [PayerLastName] [nvarchar](50) NULL,
        [PayerEmail] [nvarchar](256) NULL,
        [PayerPhone] [varchar](20) NULL,
        [BillingAddress1] [nvarchar](100) NULL,
        [BillingAddress2] [nvarchar](100) NULL,
        [BillingCity] [nvarchar](50) NULL,
        [BillingState] [varchar](4) NULL,
        [BillingPostalCode] [varchar](10) NULL,
        [BillingCountry] [char](2) NULL,
        -- Card: never the number or CVV. Brand and last four come back from the gateway.
        [CardBrand] [varchar](20) NULL,
        [CardLast4] [char](4) NULL,
        [CardExpMonth] [tinyint] NULL,
        [CardExpYear] [smallint] NULL,
        -- ACH: never the account number. The routing number is public bank data.
        [BankName] [nvarchar](100) NULL,
        [BankRoutingNumber] [char](9) NULL,
        [BankAccountLast4] [char](4) NULL,
        -- Checking or Savings.
        [BankAccountType] [varchar](10) NULL,
        -- NACHA authorization for an ACH debit: the words the payer agreed to, when and from where.
        [AchAuthorizationText] [nvarchar](2000) NULL,
        [AchAuthorizedDate] [datetimeoffset](7) NULL,
        [AchAuthorizedIp] [varchar](45) NULL,
        -- Invoices to apply the payment to once it posts (an ACH debit when it settles): JSON array of
        -- {"invoiceProxy": "...", "amount": 12.34}; amount null takes as much as fits.
        [ApplyToInvoicesJson] [nvarchar](4000) NULL,
        [Notes] [nvarchar](1000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_TransactionRequests_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_TransactionRequests_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionRequests_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TransactionRequests_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionRequests_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TransactionRequests_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionRequests_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_TransactionRequests] PRIMARY KEY CLUSTERED ([TransactionRequestID] ASC),
        CONSTRAINT [FK_TransactionRequests_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_TransactionRequests_MchTransactionTypes] FOREIGN KEY ([MchTransactionTypeId]) REFERENCES [MCH].[MchTransactionTypes] ([MchTransactionTypeID]),
        CONSTRAINT [FK_TransactionRequests_MerchantGateways] FOREIGN KEY ([MerchantGatewayId]) REFERENCES [MCH].[MerchantGateways] ([MerchantGatewayID]),
        CONSTRAINT [FK_TransactionRequests_DealerGatewaySettings] FOREIGN KEY ([DealerGatewaySettingId]) REFERENCES [MCH].[DealerGatewaySettings] ([DealerGatewaySettingID]),
        CONSTRAINT [FK_TransactionRequests_TransactionRequests] FOREIGN KEY ([ParentTransactionRequestId]) REFERENCES [MCH].[TransactionRequests] ([TransactionRequestID]),
        CONSTRAINT [FK_TransactionRequests_Leads] FOREIGN KEY ([LeadId]) REFERENCES [QAL].[Leads] ([LeadID]),
        CONSTRAINT [FK_TransactionRequests_Customers] FOREIGN KEY ([CustomerId]) REFERENCES [ACE].[Customers] ([CustomerID]),
        CONSTRAINT [FK_TransactionRequests_Payments] FOREIGN KEY ([PaymentId]) REFERENCES [MAC].[Payments] ([PaymentID]),
        CONSTRAINT [FK_TransactionRequests_TransactionStatuses] FOREIGN KEY ([TransactionStatusId]) REFERENCES [MCH].[TransactionStatuses] ([TransactionStatusID]),
        CONSTRAINT [UQ_TransactionRequests_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [CK_TransactionRequests_Amount] CHECK ([Amount] > 0),
        CONSTRAINT [CK_TransactionRequests_CardLast4] CHECK ([CardLast4] IS NULL OR [CardLast4] NOT LIKE '%[^0-9]%'),
        CONSTRAINT [CK_TransactionRequests_BankAccountLast4] CHECK ([BankAccountLast4] IS NULL OR [BankAccountLast4] NOT LIKE '%[^0-9]%'),
        CONSTRAINT [CK_TransactionRequests_BankRoutingNumber] CHECK ([BankRoutingNumber] IS NULL OR [BankRoutingNumber] NOT LIKE '%[^0-9]%'),
        CONSTRAINT [CK_TransactionRequests_BankAccountType] CHECK ([BankAccountType] IS NULL OR [BankAccountType] IN ('Checking', 'Savings')),
        CONSTRAINT [CK_TransactionRequests_CardExpMonth] CHECK ([CardExpMonth] IS NULL OR [CardExpMonth] BETWEEN 1 AND 12)
    );
    PRINT 'Created [MCH].[TransactionRequests]';
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.TransactionRequests') AND [name] = N'UQ_TransactionRequests_MerchantReference')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_TransactionRequests_MerchantReference] ON [MCH].[TransactionRequests] ([DealerTenantId], [MerchantReference]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.TransactionRequests') AND [name] = N'IX_TransactionRequests_DealerTenantId_CreatedDate')
    CREATE NONCLUSTERED INDEX [IX_TransactionRequests_DealerTenantId_CreatedDate] ON [MCH].[TransactionRequests] ([DealerTenantId], [CreatedDate] DESC)
        INCLUDE ([MchTransactionTypeId], [TransactionStatusId], [Amount], [PaymentId]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.TransactionRequests') AND [name] = N'IX_TransactionRequests_Pending')
    CREATE NONCLUSTERED INDEX [IX_TransactionRequests_Pending] ON [MCH].[TransactionRequests] ([DealerTenantId], [TransactionStatusId])
        WHERE [TransactionStatusId] = 'PENDING';

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.TransactionRequests') AND [name] = N'IX_TransactionRequests_PaymentId')
    CREATE NONCLUSTERED INDEX [IX_TransactionRequests_PaymentId] ON [MCH].[TransactionRequests] ([PaymentId]) WHERE [PaymentId] IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.TransactionRequests') AND [name] = N'IX_TransactionRequests_ParentTransactionRequestId')
    CREATE NONCLUSTERED INDEX [IX_TransactionRequests_ParentTransactionRequestId] ON [MCH].[TransactionRequests] ([ParentTransactionRequestId])
        WHERE [ParentTransactionRequestId] IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.TransactionRequests') AND [name] = N'IX_TransactionRequests_LeadId')
    CREATE NONCLUSTERED INDEX [IX_TransactionRequests_LeadId] ON [MCH].[TransactionRequests] ([DealerTenantId], [LeadId]) WHERE [LeadId] IS NOT NULL;
GO
