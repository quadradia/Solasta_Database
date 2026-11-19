/*******************************************************************************
 * Object Type: Table
 * Schema: MCH
 * Name: MerchantGateways
 * Description: Payment gateways the API can use (seeded: 1 AUTHNET, 2 ZIFTPAY, 3 CYBS). Code picks the implementation.
 * Author: Andres Sosa
 * Created: 2026-11-20
 * Migrations: 20261120_0300_CreateMCH_MerchantServices
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
GO
