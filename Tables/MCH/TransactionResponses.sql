/*******************************************************************************
 * Object Type: Table
 * Schema: MCH
 * Name: TransactionResponses
 * Description: Each normalized gateway reply for a request (from the call, a webhook or a poll).
 * Author: Andres Sosa
 * Created: 2026-11-20
 * Migrations: 20261120_0400_CreateMCH_MerchantServices
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.TransactionResponses') AND [name] = N'IX_TransactionResponses_TransactionRequestId')
    CREATE NONCLUSTERED INDEX [IX_TransactionResponses_TransactionRequestId] ON [MCH].[TransactionResponses] ([TransactionRequestId], [ResponseDate] DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.TransactionResponses') AND [name] = N'IX_TransactionResponses_GatewayTransactionId')
    CREATE NONCLUSTERED INDEX [IX_TransactionResponses_GatewayTransactionId] ON [MCH].[TransactionResponses] ([MerchantGatewayId], [GatewayTransactionId])
        WHERE [GatewayTransactionId] IS NOT NULL;
GO
