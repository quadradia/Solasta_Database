/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: TaxRates
 * Description: Combined sales tax rate per city, with the state location code and the date
 *              the state chart says it took effect. One IsDefault row per tenant.
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Dependencies: ACC.DealerTenants
 * Migrations: 20261117_0330_CreateMAC_PricingCatalog
 * API mappings: Models/MAC/PricingCatalog.cs is written by hand; remove it when the
 *               AutoGenerator produces an equivalent.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.TaxRates', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[TaxRates]
    (
        [TaxRateID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [City] [nvarchar](100) NOT NULL,
        [County] [nvarchar](50) NULL,
        [StateCode] [char](2) NOT NULL,
        [LocationCode] [varchar](10) NULL,
        [Rate] [decimal](9, 6) NOT NULL,
        [EffectiveDate] [date] NULL,
        [IsDefault] [bit] NOT NULL CONSTRAINT [DF_TaxRates_IsDefault] DEFAULT ((0)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_TaxRates_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_TaxRates_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TaxRates_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TaxRates_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TaxRates_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TaxRates_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TaxRates_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_TaxRates] PRIMARY KEY CLUSTERED ([TaxRateID] ASC),
        CONSTRAINT [FK_TaxRates_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [CK_TaxRates_Rate] CHECK ([Rate] >= 0 AND [Rate] < 1)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'MAC.TaxRates') AND [name] = N'UQ_TaxRates_DealerTenantId_StateCode_City')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaxRates_DealerTenantId_StateCode_City]
        ON [MAC].[TaxRates] ([DealerTenantId], [StateCode], [City]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'MAC.TaxRates') AND [name] = N'UQ_TaxRates_DealerTenantId_IsDefault')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaxRates_DealerTenantId_IsDefault]
        ON [MAC].[TaxRates] ([DealerTenantId])
        WHERE [IsDefault] = 1 AND [IsDeleted] = 0;
GO
