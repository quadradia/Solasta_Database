/*******************************************************************************
 * Object Type: Table
 * Schema: MCH
 * Name: MchTransactionTypes
 * Description: Kinds of transaction, with NVL9_MAIN codes: 10000/10100/10110 card sale/refund/void, 50000/50100/50110 ACH.
 * Author: Andres Sosa
 * Created: 2026-11-20
 * Migrations: 20261120_0400_CreateMCH_MerchantServices
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
GO
