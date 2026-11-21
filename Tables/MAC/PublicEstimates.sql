/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: PublicEstimates
 * Description: Price ranges the public AI quoting MCP server gave. No personal data; LeadId is set when
               the person asks for a quote.
 * Author: Andres Sosa
 * Created: 2026-11-21
 * Dependencies: ACC.DealerTenants, MAC.Products, MAC.Promotions, QAL.Leads
 * Migrations: 20261121_1500_AddPublicEstimatesForMcp
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.PublicEstimates', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[PublicEstimates]
    (
        [PublicEstimateID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        -- Where the feet came from: Footprint (building outline), Kml (the person's pins) or Typed.
        [Source] [varchar](10) NOT NULL,
        -- The feet measured or estimated, before the uncertainty and the allowance.
        [Feet] [decimal](10, 2) NOT NULL,
        [Uncertainty] [decimal](5, 4) NOT NULL,
        [ProductId] [int] NOT NULL,
        -- The color or other variant chosen, if any (INE.StockItems).
        [VariantStockItemId] [int] NULL,
        [PromotionId] [int] NULL,
        [TaxRate] [decimal](9, 6) NOT NULL,
        -- Totals with tax, rounded to $50.
        [LowTotal] [decimal](12, 2) NOT NULL,
        [HighTotal] [decimal](12, 2) NOT NULL,
        [City] [nvarchar](100) NULL,
        [StateCode] [char](2) NULL,
        [PostalCode] [varchar](10) NULL,
        [ValidUntil] [datetimeoffset](7) NOT NULL,
        -- The KML's pins, runs and warnings as the person sent them (JSON), when Source = Kml.
        [DetailJson] [nvarchar](max) NULL,
        -- Set when the person asks for a quote.
        [LeadId] [bigint] NULL,
        -- The MCP session that asked, for rate limits and support. Not personal data.
        [ClientSessionId] [varchar](100) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_PublicEstimates_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_PublicEstimates_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PublicEstimates_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PublicEstimates_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PublicEstimates_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PublicEstimates_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PublicEstimates_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_PublicEstimates] PRIMARY KEY CLUSTERED ([PublicEstimateID] ASC),
        CONSTRAINT [FK_PublicEstimates_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_PublicEstimates_Products] FOREIGN KEY ([ProductId]) REFERENCES [MAC].[Products] ([ProductID]),
        CONSTRAINT [FK_PublicEstimates_Promotions] FOREIGN KEY ([PromotionId]) REFERENCES [MAC].[Promotions] ([PromotionID]),
        CONSTRAINT [FK_PublicEstimates_Leads] FOREIGN KEY ([LeadId]) REFERENCES [QAL].[Leads] ([LeadID]),
        CONSTRAINT [UQ_PublicEstimates_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [CK_PublicEstimates_Source] CHECK ([Source] IN ('Footprint', 'Kml', 'Typed')),
        CONSTRAINT [CK_PublicEstimates_Amounts] CHECK ([Feet] > 0 AND [Uncertainty] >= 0 AND [Uncertainty] < 1
                                                   AND [TaxRate] >= 0 AND [LowTotal] >= 0 AND [HighTotal] >= [LowTotal])
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.PublicEstimates') AND [name] = N'IX_PublicEstimates_DealerTenantId_CreatedDate')
    CREATE NONCLUSTERED INDEX [IX_PublicEstimates_DealerTenantId_CreatedDate] ON [MAC].[PublicEstimates] ([DealerTenantId], [CreatedDate]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.PublicEstimates') AND [name] = N'IX_PublicEstimates_LeadId')
    CREATE NONCLUSTERED INDEX [IX_PublicEstimates_LeadId] ON [MAC].[PublicEstimates] ([LeadId]) WHERE [LeadId] IS NOT NULL;
GO
