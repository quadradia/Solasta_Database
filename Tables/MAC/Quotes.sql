/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: Quotes
 * Description: A quote for one product, made for a lead (QAL.Leads) from a roofline measurement
 *              (MAC.Measurements) or typed feet. Prices, discounts, tax rate, deposit share, validity
 *              and financing terms are copied from the catalog when the quote is made, so a catalog
 *              change never rewrites an old quote. A revision is a new row (Revision + 1,
 *              RevisedFromQuoteId). Older quotes made from an Estimate keep EstimateId.
 *              Status: Draft, Sent, Signed, Declined, Superseded (revised), Closed (another quote
 *              of the lead was signed).
 * Author:
 * Created: 2026-03-13
 * Dependencies: ACC.DealerTenants, QAL.Leads, MAC.Measurements, MAC.Products, MAC.Promotions,
 *               MAC.TaxRates, MAC.QuoteTypes, MAC.Estimates
 * Migrations: 20261117_2230_AddMAC_QuoteBuilder
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.Quotes', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[Quotes]
    (
        [QuoteID] [bigint] IDENTITY(1,1) NOT NULL,
        [Proxy] [nvarchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        [QuoteTypeId] [int] NOT NULL,
        [EstimateId] [bigint] NULL,
        [QuoteNumber] [nvarchar](50) NOT NULL,
        [QuoteDate] [date] NOT NULL,
        [ValidUntil] [datetimeoffset](7) NULL,
        [TotalAmount] [decimal](18, 2) NULL,
        [Status] [nvarchar](50) NULL,
        [Terms] [nvarchar](max) NULL,
        [Notes] [nvarchar](max) NULL,
        [DealerTenantId] [int] NULL,
        [LeadId] [bigint] NULL,
        [MeasurementId] [bigint] NULL,
        [ProductId] [int] NULL,
        [PromotionId] [int] NULL,
        [TaxRateId] [int] NULL,
        [Revision] [int] NOT NULL CONSTRAINT [DF_Quotes_Revision] DEFAULT ((1)),
        [RevisedFromQuoteId] [bigint] NULL,
        [IssuedDate] [datetimeoffset](7) NULL,
        [StatusDate] [datetimeoffset](7) NULL,
        [ProductSku] [varchar](20) NULL,
        [ProductName] [nvarchar](100) NULL,
        [PricePerFoot] [decimal](19, 4) NULL,
        [AllowancePct] [decimal](5, 2) NOT NULL CONSTRAINT [DF_Quotes_AllowancePct] DEFAULT ((10.00)),
        [PromotionCode] [varchar](20) NULL,
        [PromotionName] [nvarchar](100) NULL,
        [PromotionPerFoot] [decimal](19, 4) NOT NULL CONSTRAINT [DF_Quotes_PromotionPerFoot] DEFAULT ((0)),
        [PromotionMaxValidityHours] [int] NULL,
        [DiscountPercent] [decimal](9, 6) NOT NULL CONSTRAINT [DF_Quotes_DiscountPercent] DEFAULT ((0)),
        [PercentAppliesToFixedCosts] [bit] NOT NULL CONSTRAINT [DF_Quotes_PercentAppliesToFixedCosts] DEFAULT ((1)),
        [SpecialDiscountLabel] [nvarchar](100) NULL,
        [SpecialDiscountAmount] [decimal](18, 2) NULL,
        [SpecialDiscountTargetSubtotal] [decimal](18, 2) NULL,
        [SpecialDiscountTargetTotal] [decimal](18, 2) NULL,
        [SalesTaxRate] [decimal](9, 6) NULL,
        [TaxCity] [nvarchar](100) NULL,
        [DepositPercent] [decimal](9, 6) NOT NULL CONSTRAINT [DF_Quotes_DepositPercent] DEFAULT ((0.5)),
        [PaymentMethod] [varchar](10) NOT NULL CONSTRAINT [DF_Quotes_PaymentMethod] DEFAULT ('Amortized'),
        [ValidityDays] [int] NULL,
        [ValidityHours] [int] NULL,
        -- JSON: [{"termMonths":12,"apr":0.0799,"label":"12 months"}, ...]
        [FinancingTerms] [nvarchar](2000) NULL,
        -- Internal only; never printed on the customer estimate.
        [InstallCostPerFoot] [decimal](19, 4) NULL,
        [ProductCostPerFoot] [decimal](19, 4) NULL,
        [TotalFeet] [decimal](9, 2) NULL,
        [GrossTotal] [decimal](18, 2) NULL,
        [DiscountTotal] [decimal](18, 2) NULL,
        [SubTotal] [decimal](18, 2) NULL,
        [TaxTotal] [decimal](18, 2) NULL,
        [DepositAmount] [decimal](18, 2) NULL,
        [InstallCost] [decimal](18, 2) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Quotes_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Quotes_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Quotes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Quotes_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Quotes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Quotes_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Quotes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Quotes] PRIMARY KEY CLUSTERED ([QuoteID] ASC),
        CONSTRAINT [FK_Quotes_Estimates] FOREIGN KEY ([EstimateId]) REFERENCES [MAC].[Estimates] ([EstimateID]),
        CONSTRAINT [FK_Quotes_QuoteTypes] FOREIGN KEY ([QuoteTypeId]) REFERENCES [MAC].[QuoteTypes] ([QuoteTypeID]),
        CONSTRAINT [FK_Quotes_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Quotes_Leads] FOREIGN KEY ([LeadId]) REFERENCES [QAL].[Leads] ([LeadID]),
        CONSTRAINT [FK_Quotes_Measurements] FOREIGN KEY ([MeasurementId]) REFERENCES [MAC].[Measurements] ([MeasurementID]),
        CONSTRAINT [FK_Quotes_Products] FOREIGN KEY ([ProductId]) REFERENCES [MAC].[Products] ([ProductID]),
        CONSTRAINT [FK_Quotes_Promotions] FOREIGN KEY ([PromotionId]) REFERENCES [MAC].[Promotions] ([PromotionID]),
        CONSTRAINT [FK_Quotes_TaxRates] FOREIGN KEY ([TaxRateId]) REFERENCES [MAC].[TaxRates] ([TaxRateID]),
        CONSTRAINT [FK_Quotes_RevisedFrom] FOREIGN KEY ([RevisedFromQuoteId]) REFERENCES [MAC].[Quotes] ([QuoteID]),
        CONSTRAINT [CK_Quotes_Revision] CHECK ([Revision] >= 1),
        CONSTRAINT [CK_Quotes_AllowancePct] CHECK ([AllowancePct] >= 0 AND [AllowancePct] <= 100),
        CONSTRAINT [CK_Quotes_PromotionPerFoot] CHECK ([PromotionPerFoot] >= 0),
        CONSTRAINT [CK_Quotes_DiscountPercent] CHECK ([DiscountPercent] >= 0 AND [DiscountPercent] <= 1),
        CONSTRAINT [CK_Quotes_SpecialDiscount] CHECK ((CASE WHEN [SpecialDiscountAmount] IS NULL THEN 0 ELSE 1 END
                                                     + CASE WHEN [SpecialDiscountTargetSubtotal] IS NULL THEN 0 ELSE 1 END
                                                     + CASE WHEN [SpecialDiscountTargetTotal] IS NULL THEN 0 ELSE 1 END) <= 1),
        CONSTRAINT [CK_Quotes_SalesTaxRate] CHECK ([SalesTaxRate] IS NULL OR ([SalesTaxRate] >= 0 AND [SalesTaxRate] < 1)),
        CONSTRAINT [CK_Quotes_DepositPercent] CHECK ([DepositPercent] >= 0 AND [DepositPercent] <= 1),
        CONSTRAINT [CK_Quotes_PaymentMethod] CHECK ([PaymentMethod] IN ('Amortized', 'Simple')),
        CONSTRAINT [CK_Quotes_Validity] CHECK (([ValidityDays] IS NULL OR [ValidityDays] >= 0) AND ([ValidityHours] IS NULL OR [ValidityHours] >= 0))
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'MAC.Quotes') AND [name] = N'IX_Quotes_DealerTenantId_LeadId')
    CREATE NONCLUSTERED INDEX [IX_Quotes_DealerTenantId_LeadId]
        ON [MAC].[Quotes] ([DealerTenantId], [LeadId])
        WHERE [IsActive] = 1 AND [LeadId] IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'MAC.Quotes') AND [name] = N'IX_Quotes_Proxy')
    CREATE NONCLUSTERED INDEX [IX_Quotes_Proxy] ON [MAC].[Quotes] ([Proxy]);
GO
