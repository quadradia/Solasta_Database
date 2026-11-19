/*
Migration: 20261120_0400_CreateMCH_MerchantServices
Author: Andres Sosa
Date: 2026-11-20
Description: Merchant services (card and ACH processing) in a new MCH schema, modelled on NVL9_MAIN's MCH but
             gateway-neutral and PCI-safe:
               MCH.MerchantGateways        lookup: 1 Authorize.Net, 2 ZiftPay (as in NVL9_MAIN), 3 Cybersource.
               MCH.MchTransactionTypes     lookup, NVL9_MAIN codes: 10000 CC, 10100 CC Refund, 10110 CC Void,
                                           50000 ACH, 50100 ACH Refund, 50110 ACH Void (new).
               MCH.TransactionStatuses     lookup, NVL9_MAIN codes plus PENDING (ACH not settled) and RETURNED.
               MCH.DealerGatewaySettings   which gateway and merchant account a tenant uses. No secrets: keys and
                                           passwords live in the API's secrets, never in this table.
               MCH.TransactionRequests     one per attempt (sale, refund, void): payer, card brand/last 4/expiry
                                           or bank last 4/account type, amount, ACH authorization (NACHA consent),
                                           its current status and the MAC.Payments row it created or reverses.
               MCH.TransactionResponses    each normalized gateway reply (status, auth code, AVS/CVV, gateway
                                           transaction id, message, raw JSON with no card or account numbers).
             Never stored: full card numbers, CVV, full bank account numbers, gateway credentials.
             MAC.Payments.Status gains Pending (an ACH debit not yet settled; nothing can be applied) and Failed
             (declined later, e.g. an ACH return before it was posted).
             Proxy prefix: MCTR (transaction request).
             No triggers: the API writes these tables with plain EF and scopes every read by DealerTenantId
             (responses through their request).
Dependencies:
  20261120_0200_AddMAC_InvoicesAndPayments (MAC.Payments)
Rollback:
  DROP TABLE [MCH].[TransactionResponses];
  DROP TABLE [MCH].[TransactionRequests];
  DROP TABLE [MCH].[DealerGatewaySettings];
  DROP TABLE [MCH].[TransactionStatuses];
  DROP TABLE [MCH].[MchTransactionTypes];
  DROP TABLE [MCH].[MerchantGateways];
  DROP SCHEMA [MCH];
  ALTER TABLE [MAC].[Payments] DROP CONSTRAINT [CK_Payments_Status];
  ALTER TABLE [MAC].[Payments] ADD CONSTRAINT [CK_Payments_Status] CHECK ([Status] IN ('Posted', 'Voided'));
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261120_0400_CreateMCH_MerchantServices';
Expected impact: a new schema with three seeded lookups and three empty tables; MAC.Payments accepts two more
                 status values. No existing row changes.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261120_0400_CreateMCH_MerchantServices';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MAC.Payments', N'U') IS NULL OR OBJECT_ID(N'QAL.Leads', N'U') IS NULL
       OR OBJECT_ID(N'ACE.Customers', N'U') IS NULL
        THROW 50001, 'Merchant services require MAC.Payments, QAL.Leads and ACE.Customers.', 1;

    IF SCHEMA_ID(N'MCH') IS NULL
        EXEC (N'CREATE SCHEMA [MCH] AUTHORIZATION [dbo]');

    ---------------------------------------------------------------------------
    -- MCH.MerchantGateways
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MCH.MerchantGateways', N'U') IS NULL
    BEGIN
        CREATE TABLE [MCH].[MerchantGateways]
        (
            [MerchantGatewayID] [smallint] NOT NULL,
            -- Stable code the API resolves its gateway implementation by: AUTHNET, ZIFTPAY, CYBS.
            [Code] [varchar](10) NOT NULL,
            [MerchantGatewayName] [varchar](50) NOT NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_MerchantGateways_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_MerchantGateways_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MerchantGateways_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MerchantGateways_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MerchantGateways_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MerchantGateways_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MerchantGateways_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_MerchantGateways] PRIMARY KEY CLUSTERED ([MerchantGatewayID] ASC),
            CONSTRAINT [UQ_MerchantGateways_Code] UNIQUE ([Code])
        );
        PRINT 'Created [MCH].[MerchantGateways]';
    END;

    MERGE [MCH].[MerchantGateways] AS T
    USING (VALUES (CAST(1 AS smallint), 'AUTHNET', 'Authorize.Net'),
                  (CAST(2 AS smallint), 'ZIFTPAY', 'ZiftPay'),
                  (CAST(3 AS smallint), 'CYBS', 'Cybersource')) AS S ([MerchantGatewayID], [Code], [MerchantGatewayName])
    ON T.[MerchantGatewayID] = S.[MerchantGatewayID]
    WHEN NOT MATCHED THEN INSERT ([MerchantGatewayID], [Code], [MerchantGatewayName])
                          VALUES (S.[MerchantGatewayID], S.[Code], S.[MerchantGatewayName]);

    ---------------------------------------------------------------------------
    -- MCH.MchTransactionTypes
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MCH.MchTransactionTypes', N'U') IS NULL
    BEGIN
        CREATE TABLE [MCH].[MchTransactionTypes]
        (
            [MchTransactionTypeID] [int] NOT NULL,
            [MchTransactionTypeName] [varchar](50) NOT NULL,
            -- Card or ACH.
            [PaymentMethod] [varchar](10) NOT NULL,
            -- Sale, Refund or Void.
            [Operation] [varchar](10) NOT NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_MchTransactionTypes_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_MchTransactionTypes_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MchTransactionTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MchTransactionTypes_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MchTransactionTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MchTransactionTypes_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MchTransactionTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_MchTransactionTypes] PRIMARY KEY CLUSTERED ([MchTransactionTypeID] ASC),
            CONSTRAINT [CK_MchTransactionTypes_PaymentMethod] CHECK ([PaymentMethod] IN ('Card', 'ACH')),
            CONSTRAINT [CK_MchTransactionTypes_Operation] CHECK ([Operation] IN ('Sale', 'Refund', 'Void'))
        );
        PRINT 'Created [MCH].[MchTransactionTypes]';
    END;

    MERGE [MCH].[MchTransactionTypes] AS T
    USING (VALUES (10000, 'CC Processing', 'Card', 'Sale'),
                  (10100, 'CC Refund', 'Card', 'Refund'),
                  (10110, 'CC Void', 'Card', 'Void'),
                  (50000, 'ACH Processing', 'ACH', 'Sale'),
                  (50100, 'ACH Refund', 'ACH', 'Refund'),
                  (50110, 'ACH Void', 'ACH', 'Void')) AS S ([MchTransactionTypeID], [MchTransactionTypeName], [PaymentMethod], [Operation])
    ON T.[MchTransactionTypeID] = S.[MchTransactionTypeID]
    WHEN NOT MATCHED THEN INSERT ([MchTransactionTypeID], [MchTransactionTypeName], [PaymentMethod], [Operation])
                          VALUES (S.[MchTransactionTypeID], S.[MchTransactionTypeName], S.[PaymentMethod], S.[Operation]);

    ---------------------------------------------------------------------------
    -- MCH.TransactionStatuses
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MCH.TransactionStatuses', N'U') IS NULL
    BEGIN
        CREATE TABLE [MCH].[TransactionStatuses]
        (
            [TransactionStatusID] [varchar](20) NOT NULL,
            [TransactionStatusName] [varchar](50) NOT NULL,
            -- 1 when nothing more will change it (OK and PENDING can still move).
            [IsFinal] [bit] NOT NULL CONSTRAINT [DF_TransactionStatuses_IsFinal] DEFAULT ((1)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_TransactionStatuses_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_TransactionStatuses_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionStatuses_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TransactionStatuses_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionStatuses_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TransactionStatuses_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionStatuses_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_TransactionStatuses] PRIMARY KEY CLUSTERED ([TransactionStatusID] ASC)
        );
        PRINT 'Created [MCH].[TransactionStatuses]';
    END;

    MERGE [MCH].[TransactionStatuses] AS T
    USING (VALUES ('OK', 'OK', CAST(0 AS bit)),
                  ('PENDING', 'Pending Settlement', CAST(0 AS bit)),
                  ('ERROR', 'Error', CAST(1 AS bit)),
                  ('DECLINED', 'Declined', CAST(1 AS bit)),
                  ('MANDECLINED', 'Manually Declined', CAST(1 AS bit)),
                  ('FAILEDSET', 'Failed Settlement', CAST(1 AS bit)),
                  ('RETURNED', 'Returned', CAST(1 AS bit)),
                  ('REFUND', 'Refunded', CAST(1 AS bit)),
                  ('VOID', 'Voided', CAST(1 AS bit)),
                  ('UND', 'Undefined', CAST(0 AS bit))) AS S ([TransactionStatusID], [TransactionStatusName], [IsFinal])
    ON T.[TransactionStatusID] = S.[TransactionStatusID]
    WHEN NOT MATCHED THEN INSERT ([TransactionStatusID], [TransactionStatusName], [IsFinal])
                          VALUES (S.[TransactionStatusID], S.[TransactionStatusName], S.[IsFinal]);

    ---------------------------------------------------------------------------
    -- MCH.DealerGatewaySettings
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MCH.DealerGatewaySettings', N'U') IS NULL
    BEGIN
        CREATE TABLE [MCH].[DealerGatewaySettings]
        (
            [DealerGatewaySettingID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [MerchantGatewayId] [smallint] NOT NULL,
            [SettingsName] [nvarchar](50) NOT NULL,
            -- The gateway's merchant account id (Cybersource Merchant ID). Not a secret.
            [MerchantAccountId] [varchar](100) NOT NULL,
            [UseSandbox] [bit] NOT NULL CONSTRAINT [DF_DealerGatewaySettings_UseSandbox] DEFAULT ((1)),
            [AcceptsCards] [bit] NOT NULL CONSTRAINT [DF_DealerGatewaySettings_AcceptsCards] DEFAULT ((1)),
            [AcceptsAch] [bit] NOT NULL CONSTRAINT [DF_DealerGatewaySettings_AcceptsAch] DEFAULT ((0)),
            -- The account new transactions use; one active default per tenant.
            [IsDefault] [bit] NOT NULL CONSTRAINT [DF_DealerGatewaySettings_IsDefault] DEFAULT ((1)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_DealerGatewaySettings_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_DealerGatewaySettings_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerGatewaySettings_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_DealerGatewaySettings_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerGatewaySettings_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_DealerGatewaySettings_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerGatewaySettings_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_DealerGatewaySettings] PRIMARY KEY CLUSTERED ([DealerGatewaySettingID] ASC),
            CONSTRAINT [FK_DealerGatewaySettings_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_DealerGatewaySettings_MerchantGateways] FOREIGN KEY ([MerchantGatewayId]) REFERENCES [MCH].[MerchantGateways] ([MerchantGatewayID])
        );
        PRINT 'Created [MCH].[DealerGatewaySettings]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.DealerGatewaySettings') AND [name] = N'UQ_DealerGatewaySettings_Default')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_DealerGatewaySettings_Default] ON [MCH].[DealerGatewaySettings] ([DealerTenantId])
            WHERE [IsDefault] = 1 AND [IsActive] = 1;

    ---------------------------------------------------------------------------
    -- MCH.TransactionRequests
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- MCH.TransactionResponses
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MCH.TransactionResponses', N'U') IS NULL
    BEGIN
        CREATE TABLE [MCH].[TransactionResponses]
        (
            [TransactionResponseID] [bigint] IDENTITY(1,1) NOT NULL,
            [TransactionRequestId] [bigint] NOT NULL,
            [MerchantGatewayId] [smallint] NOT NULL,
            [TransactionStatusId] [varchar](20) NOT NULL,
            -- Where the reply came from: Request (the call itself), Webhook or Poll.
            [Source] [varchar](10) NOT NULL CONSTRAINT [DF_TransactionResponses_Source] DEFAULT ('Request'),
            -- The gateway's transaction id (Cybersource payment id), used for later voids, refunds and lookups.
            [GatewayTransactionId] [varchar](100) NULL,
            -- The gateway's own status and reason, as sent (e.g. AUTHORIZED / PENDING, reasonCode or errorInformation.reason).
            [GatewayStatus] [varchar](50) NULL,
            [GatewayReasonCode] [varchar](50) NULL,
            [AuthCode] [varchar](20) NULL,
            [AvsCode] [varchar](10) NULL,
            [CvvCode] [varchar](10) NULL,
            [ApprovedAmount] [decimal](18, 2) NULL,
            [Message] [nvarchar](500) NULL,
            -- The reply as received. Gateways send masked numbers only; the API strips anything else.
            [ResponseJson] [nvarchar](max) NULL,
            [ResponseDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionResponses_ResponseDate] DEFAULT (SYSDATETIMEOFFSET()),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_TransactionResponses_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_TransactionResponses_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionResponses_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TransactionResponses_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionResponses_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TransactionResponses_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionResponses_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_TransactionResponses] PRIMARY KEY CLUSTERED ([TransactionResponseID] ASC),
            CONSTRAINT [FK_TransactionResponses_TransactionRequests] FOREIGN KEY ([TransactionRequestId]) REFERENCES [MCH].[TransactionRequests] ([TransactionRequestID]),
            CONSTRAINT [FK_TransactionResponses_MerchantGateways] FOREIGN KEY ([MerchantGatewayId]) REFERENCES [MCH].[MerchantGateways] ([MerchantGatewayID]),
            CONSTRAINT [FK_TransactionResponses_TransactionStatuses] FOREIGN KEY ([TransactionStatusId]) REFERENCES [MCH].[TransactionStatuses] ([TransactionStatusID]),
            CONSTRAINT [CK_TransactionResponses_Source] CHECK ([Source] IN ('Request', 'Webhook', 'Poll'))
        );
        PRINT 'Created [MCH].[TransactionResponses]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.TransactionResponses') AND [name] = N'IX_TransactionResponses_TransactionRequestId')
        CREATE NONCLUSTERED INDEX [IX_TransactionResponses_TransactionRequestId] ON [MCH].[TransactionResponses] ([TransactionRequestId], [ResponseDate] DESC);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.TransactionResponses') AND [name] = N'IX_TransactionResponses_GatewayTransactionId')
        CREATE NONCLUSTERED INDEX [IX_TransactionResponses_GatewayTransactionId] ON [MCH].[TransactionResponses] ([MerchantGatewayId], [GatewayTransactionId])
            WHERE [GatewayTransactionId] IS NOT NULL;

    ---------------------------------------------------------------------------
    -- MAC.Payments: Pending (ACH not settled) and Failed
    ---------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_Payments_Status' AND [parent_object_id] = OBJECT_ID(N'MAC.Payments')
               AND [definition] NOT LIKE N'%Pending%')
    BEGIN
        ALTER TABLE [MAC].[Payments] DROP CONSTRAINT [CK_Payments_Status];
        ALTER TABLE [MAC].[Payments] ADD CONSTRAINT [CK_Payments_Status] CHECK ([Status] IN ('Pending', 'Posted', 'Failed', 'Voided'));
        PRINT 'MAC.Payments.Status now allows Pending and Failed';
    END;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'MCH merchant services: gateways, transaction types and statuses, dealer gateway settings, transaction requests and responses',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
