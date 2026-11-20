/*******************************************************************************
 * Object Type: Table
 * Schema: MCH
 * Name: DealerGatewaySettings
 * Description: Which gateway and merchant account a tenant uses. No secrets: keys live in the API secrets.
 * Author: Andres Sosa
 * Created: 2026-11-20
 * Migrations: 20261120_0400_CreateMCH_MerchantServices
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MCH.DealerGatewaySettings') AND [name] = N'UQ_DealerGatewaySettings_Default')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_DealerGatewaySettings_Default] ON [MCH].[DealerGatewaySettings] ([DealerTenantId])
        WHERE [IsDefault] = 1 AND [IsActive] = 1;
GO
