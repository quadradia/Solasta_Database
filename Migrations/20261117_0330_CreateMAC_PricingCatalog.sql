/*
Migration: 20261117_0330_CreateMAC_PricingCatalog
Author: Andres Sosa
Date: 2026-11-17
Description: Creates the tenant-scoped pricing catalog the quote pricing engine reads
             (lead-to-quote Phase 1) and seeds it for the Solasta Lighting tenant from
             the PriceSheet tab of the estimating workbook:
               MAC.Products        rails priced per foot (P001, D001, D002) and add-ons
                                   (VHD001, DVR001, DVRA001 each; V001 per foot), with
                                   internal install and product cost per unit.
               MAC.Promotions      per-foot promo discounts (PMT0xx, PSE00x), optional
                                   date window and a cap on how long a quote stays valid.
               MAC.TaxRates        combined sales tax per city: every city in Salt Lake and
                                   Utah counties plus Park City, from the Utah State Tax
                                   Commission's October 1, 2026 chart. Spanish Fork (7.45%)
                                   is the default.
               MAC.FinancingPlans  Enhancify payment options: 12, 24 and 36 months at
                                   7.9% APR and 21 months at 0%.
             Quotes copy prices and rates when they are created, so later changes here
             do not rewrite old quotes. Quote tables are a later phase.
Dependencies:
  20261106_1600_SeedACC_SolastaLightingTenant
Rollback:
  DROP TABLE [MAC].[FinancingPlans];
  DROP TABLE [MAC].[TaxRates];
  DROP TABLE [MAC].[Promotions];
  DROP TABLE [MAC].[Products];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_0330_CreateMAC_PricingCatalog';
Expected impact: Four new tables and their seed rows; no existing object changes.
*/

-- Filtered indexes require these; sqlcmd defaults QUOTED_IDENTIFIER to OFF.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261117_0330_CreateMAC_PricingCatalog';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();
    DECLARE @SolastaProxy VARCHAR(100) = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6';

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL
        THROW 50001, 'The MAC pricing catalog requires ACC.DealerTenants.', 1;

    ---------------------------------------------------------------------------
    -- MAC.Products
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MAC.Products', N'U') IS NULL
    BEGIN
        CREATE TABLE [MAC].[Products]
        (
            [ProductID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [Sku] [varchar](20) NOT NULL,
            [Name] [nvarchar](100) NOT NULL,
            [Category] [varchar](10) NOT NULL,
            [Unit] [varchar](4) NOT NULL,
            [PricePerUnit] [decimal](19, 4) NOT NULL,
            [InstallCostPerUnit] [decimal](19, 4) NULL,
            [ProductCostPerUnit] [decimal](19, 4) NULL,
            [SortOrder] [int] NOT NULL CONSTRAINT [DF_Products_SortOrder] DEFAULT ((0)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Products_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Products_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Products_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Products_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Products_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Products_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Products_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED ([ProductID] ASC),
            CONSTRAINT [FK_Products_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [CK_Products_Category] CHECK ([Category] IN ('Rail', 'AddOn')),
            CONSTRAINT [CK_Products_Unit] CHECK ([Unit] IN ('ft', 'each')),
            CONSTRAINT [CK_Products_PricePerUnit] CHECK ([PricePerUnit] >= 0),
            CONSTRAINT [CK_Products_InstallCostPerUnit] CHECK ([InstallCostPerUnit] IS NULL OR [InstallCostPerUnit] >= 0),
            CONSTRAINT [CK_Products_ProductCostPerUnit] CHECK ([ProductCostPerUnit] IS NULL OR [ProductCostPerUnit] >= 0)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.Products') AND [name] = N'UQ_Products_DealerTenantId_Sku')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Products_DealerTenantId_Sku]
            ON [MAC].[Products] ([DealerTenantId], [Sku]);

    ---------------------------------------------------------------------------
    -- MAC.Promotions
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MAC.Promotions', N'U') IS NULL
    BEGIN
        CREATE TABLE [MAC].[Promotions]
        (
            [PromotionID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [Code] [varchar](20) NOT NULL,
            [Name] [nvarchar](100) NOT NULL,
            [AmountPerUnit] [decimal](19, 4) NOT NULL,
            [StartDate] [date] NULL,
            [EndDate] [date] NULL,
            [MaxValidityHours] [int] NULL,
            [SortOrder] [int] NOT NULL CONSTRAINT [DF_Promotions_SortOrder] DEFAULT ((0)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Promotions_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Promotions_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Promotions_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Promotions_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Promotions_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Promotions_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Promotions_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Promotions] PRIMARY KEY CLUSTERED ([PromotionID] ASC),
            CONSTRAINT [FK_Promotions_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [CK_Promotions_AmountPerUnit] CHECK ([AmountPerUnit] >= 0),
            CONSTRAINT [CK_Promotions_EndDate] CHECK ([EndDate] IS NULL OR [StartDate] IS NULL OR [EndDate] >= [StartDate]),
            CONSTRAINT [CK_Promotions_MaxValidityHours] CHECK ([MaxValidityHours] IS NULL OR [MaxValidityHours] > 0)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.Promotions') AND [name] = N'UQ_Promotions_DealerTenantId_Code')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Promotions_DealerTenantId_Code]
            ON [MAC].[Promotions] ([DealerTenantId], [Code]);

    ---------------------------------------------------------------------------
    -- MAC.TaxRates
    ---------------------------------------------------------------------------
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

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.TaxRates') AND [name] = N'UQ_TaxRates_DealerTenantId_StateCode_City')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaxRates_DealerTenantId_StateCode_City]
            ON [MAC].[TaxRates] ([DealerTenantId], [StateCode], [City]);

    -- At most one default rate per tenant.
    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.TaxRates') AND [name] = N'UQ_TaxRates_DealerTenantId_IsDefault')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaxRates_DealerTenantId_IsDefault]
            ON [MAC].[TaxRates] ([DealerTenantId])
            WHERE [IsDefault] = 1 AND [IsDeleted] = 0;

    ---------------------------------------------------------------------------
    -- MAC.FinancingPlans
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MAC.FinancingPlans', N'U') IS NULL
    BEGIN
        CREATE TABLE [MAC].[FinancingPlans]
        (
            [FinancingPlanID] [int] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [Lender] [nvarchar](100) NOT NULL,
            [Name] [nvarchar](100) NOT NULL,
            [TermMonths] [int] NOT NULL,
            [Apr] [decimal](9, 6) NOT NULL,
            [Note] [nvarchar](400) NULL,
            [SortOrder] [int] NOT NULL CONSTRAINT [DF_FinancingPlans_SortOrder] DEFAULT ((0)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_FinancingPlans_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_FinancingPlans_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_FinancingPlans_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FinancingPlans_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_FinancingPlans_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FinancingPlans_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_FinancingPlans_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_FinancingPlans] PRIMARY KEY CLUSTERED ([FinancingPlanID] ASC),
            CONSTRAINT [FK_FinancingPlans_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [CK_FinancingPlans_TermMonths] CHECK ([TermMonths] > 0),
            CONSTRAINT [CK_FinancingPlans_Apr] CHECK ([Apr] >= 0 AND [Apr] < 1)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.FinancingPlans') AND [name] = N'UQ_FinancingPlans_DealerTenantId_Lender_TermMonths')
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_FinancingPlans_DealerTenantId_Lender_TermMonths]
            ON [MAC].[FinancingPlans] ([DealerTenantId], [Lender], [TermMonths]);

    ---------------------------------------------------------------------------
    -- Seed the Solasta Lighting tenant from the workbook's PriceSheet tab.
    ---------------------------------------------------------------------------
    DECLARE @TenantId INT = (SELECT [DealerTenantID] FROM [ACC].[DealerTenants] WHERE [Proxy] = @SolastaProxy);
    IF @TenantId IS NULL
        PRINT 'Solasta Lighting tenant not found; skipping the pricing seed.';
    ELSE
    BEGIN
        -- Install cost: Master Electricians $9/ft. Product cost: Standard $11.50/ft, Deluxe $14.50/ft;
        -- the sheet has no product cost for Premium Double Rail or the add-ons yet.
        INSERT INTO [MAC].[Products]
            ([DealerTenantId], [Sku], [Name], [Category], [Unit], [PricePerUnit], [InstallCostPerUnit], [ProductCostPerUnit], [SortOrder])
        SELECT @TenantId, s.[Sku], s.[Name], s.[Category], s.[Unit], s.[PricePerUnit], s.[InstallCostPerUnit], s.[ProductCostPerUnit], s.[SortOrder]
        FROM (VALUES
            ('P001',    N'Standard Rail System', 'Rail',  'ft',     30.00, 9.00, 11.50, 10),
            ('D001',    N'Deluxe Single Rail',   'Rail',  'ft',     35.00, 9.00, 14.50, 20),
            ('D002',    N'Premium Double Rail',  'Rail',  'ft',     40.00, 9.00, NULL,  30),
            ('VHD001',  N'8K UltraHD Camera',    'AddOn', 'each',  350.00, NULL, NULL,  40),
            ('DVR001',  N'16 Channel DVR',       'AddOn', 'each', 1499.00, NULL, NULL,  50),
            ('DVRA001', N'8 Channel DVR - AI',   'AddOn', 'each', 3199.00, NULL, NULL,  60),
            ('V001',    N'Video Install',        'AddOn', 'ft',     10.00, NULL, NULL,  70)
        ) AS s ([Sku], [Name], [Category], [Unit], [PricePerUnit], [InstallCostPerUnit], [ProductCostPerUnit], [SortOrder])
        WHERE NOT EXISTS (SELECT 1 FROM [MAC].[Products] p WHERE p.[DealerTenantId] = @TenantId AND p.[Sku] = s.[Sku]);

        -- The sheet stores promos as negative prices; here AmountPerUnit is the discount per foot.
        INSERT INTO [MAC].[Promotions] ([DealerTenantId], [Code], [Name], [AmountPerUnit], [SortOrder])
        SELECT @TenantId, s.[Code], s.[Name], s.[AmountPerUnit], s.[SortOrder]
        FROM (VALUES
            ('PMT010', N'Training Promo 10',             10.00,  10),
            ('PMT005', N'Training Promo 5',               5.00,  20),
            ('PMT001', N'Training Promo 1',               1.00,  30),
            ('PSE001', N'Pre-Season Promo (20% off)',     7.00,  40),
            ('PSE002', N'Pre-Season Promo 2 (29% off)',  10.00,  50),
            ('PSE003', N'Pre-Season Promo 3',            11.50,  60),
            ('PSE004', N'Pre-Season Promo 3 (33% off)',  12.00,  70),
            ('PSE005', N'Pre-Season Promo 4',            14.00,  80),
            ('PSE006', N'Pre-Season Promo 5',            15.00,  90),
            ('PSE007', N'Pre-Season Promo 6 (Owners)',   18.50, 100)
        ) AS s ([Code], [Name], [AmountPerUnit], [SortOrder])
        WHERE NOT EXISTS (SELECT 1 FROM [MAC].[Promotions] p WHERE p.[DealerTenantId] = @TenantId AND p.[Code] = s.[Code]);

        -- Combined sales and use tax rates from the Utah State Tax Commission's rate chart
        -- in effect October 1, 2026 (files.tax.utah.gov/tax/salestax/rate/26q4combined.xlsx):
        -- every city and township in Salt Lake and Utah counties, the unincorporated county
        -- areas, and Park City. Special districts (MIDA, inland port, convention hotel) are left out.
        -- Utah changes rates quarterly; update with a new migration. Spanish Fork is the default.
        INSERT INTO [MAC].[TaxRates] ([DealerTenantId], [City], [County], [StateCode], [LocationCode], [Rate], [EffectiveDate], [IsDefault])
        SELECT @TenantId, s.[City], s.[County], 'UT', s.[LocationCode], s.[Rate], '2026-10-01', s.[IsDefault]
        FROM (VALUES
            (N'Salt Lake County (unincorporated)', N'Salt Lake', '18-000', 0.074500, 0),
            (N'Alta', N'Salt Lake', '18-003', 0.090500, 0),
            (N'Brighton', N'Salt Lake', '18-010', 0.085500, 0),
            (N'Bluffdale', N'Salt Lake', '18-019', 0.074500, 0),
            (N'Cottonwood Heights', N'Salt Lake', '18-020', 0.074500, 0),
            (N'Draper', N'Salt Lake', '18-039', 0.074500, 0),
            (N'Herriman', N'Salt Lake', '18-060', 0.074500, 0),
            (N'Holladay', N'Salt Lake', '18-065', 0.074500, 0),
            (N'Midvale', N'Salt Lake', '18-093', 0.074500, 0),
            (N'Millcreek', N'Salt Lake', '18-094', 0.074500, 0),
            (N'Murray', N'Salt Lake', '18-096', 0.076500, 0),
            (N'Riverton', N'Salt Lake', '18-118', 0.074500, 0),
            (N'Salt Lake City', N'Salt Lake', '18-122', 0.084500, 0),
            (N'Sandy', N'Salt Lake', '18-131', 0.074500, 0),
            (N'South Jordan', N'Salt Lake', '18-138', 0.074500, 0),
            (N'South Salt Lake', N'Salt Lake', '18-139', 0.076500, 0),
            (N'Taylorsville', N'Salt Lake', '18-142', 0.074500, 0),
            (N'West Jordan', N'Salt Lake', '18-155', 0.074500, 0),
            (N'West Valley City', N'Salt Lake', '18-167', 0.074500, 0),
            (N'Copperton', N'Salt Lake', '18-401', 0.074500, 0),
            (N'Emigration Canyon', N'Salt Lake', '18-402', 0.074500, 0),
            (N'Kearns', N'Salt Lake', '18-403', 0.074500, 0),
            (N'Magna', N'Salt Lake', '18-404', 0.074500, 0),
            (N'White City', N'Salt Lake', '18-405', 0.074500, 0),
            (N'Park City', N'Summit', '22-030', 0.095500, 0),
            (N'Utah County (unincorporated)', N'Utah', '25-000', 0.073500, 0),
            (N'Alpine', N'Utah', '25-001', 0.074500, 0),
            (N'American Fork', N'Utah', '25-002', 0.074500, 0),
            (N'Bluffdale (Utah County part)', N'Utah', '25-010', 0.073500, 0),
            (N'Cedar Fort', N'Utah', '25-019', 0.073500, 0),
            (N'Draper (Utah County part)', N'Utah', '25-029', 0.073500, 0),
            (N'Eagle Mountain', N'Utah', '25-030', 0.074500, 0),
            (N'Fairfield', N'Utah', '25-035', 0.073500, 0),
            (N'Genola', N'Utah', '25-038', 0.073500, 0),
            (N'Goshen', N'Utah', '25-043', 0.073500, 0),
            (N'Lehi', N'Utah', '25-066', 0.074500, 0),
            (N'Lindon', N'Utah', '25-070', 0.074500, 0),
            (N'Mapleton', N'Utah', '25-073', 0.074500, 0),
            (N'Orem', N'Utah', '25-083', 0.074500, 0),
            (N'Payson', N'Utah', '25-085', 0.074500, 0),
            (N'Pleasant Grove', N'Utah', '25-088', 0.074500, 0),
            (N'Provo', N'Utah', '25-090', 0.074500, 0),
            (N'Salem', N'Utah', '25-096', 0.073500, 0),
            (N'Santaquin', N'Utah', '25-097', 0.074500, 0),
            (N'Saratoga Springs', N'Utah', '25-098', 0.074500, 0),
            (N'Highland', N'Utah', '25-099', 0.074500, 0),
            (N'Spanish Fork', N'Utah', '25-103', 0.074500, 1),
            (N'Springville', N'Utah', '25-106', 0.074500, 0),
            (N'Vineyard', N'Utah', '25-117', 0.074500, 0),
            (N'Cedar Hills', N'Utah', '25-123', 0.074500, 0),
            (N'Elk Ridge', N'Utah', '25-124', 0.073500, 0),
            (N'Woodland Hills', N'Utah', '25-125', 0.073500, 0)
        ) AS s ([City], [County], [LocationCode], [Rate], [IsDefault])
        WHERE NOT EXISTS (SELECT 1 FROM [MAC].[TaxRates] t
                          WHERE t.[DealerTenantId] = @TenantId AND t.[StateCode] = 'UT' AND t.[City] = s.[City]);

        INSERT INTO [MAC].[FinancingPlans] ([DealerTenantId], [Lender], [Name], [TermMonths], [Apr], [Note], [SortOrder])
        SELECT @TenantId, s.[Lender], s.[Name], s.[TermMonths], s.[Apr], s.[Note], s.[SortOrder]
        FROM (VALUES
            (N'Enhancify', N'12 months', 12, 0.079000, NULL, 10),
            (N'Enhancify', N'21 months 0%', 21, 0.000000,
             N'0% interest for qualified buyers with good credit. No early payoff penalty.', 20),
            (N'Enhancify', N'24 months', 24, 0.079000, NULL, 30),
            (N'Enhancify', N'36 months', 36, 0.079000, NULL, 40)
        ) AS s ([Lender], [Name], [TermMonths], [Apr], [Note], [SortOrder])
        WHERE NOT EXISTS (SELECT 1 FROM [MAC].[FinancingPlans] f
                          WHERE f.[DealerTenantId] = @TenantId AND f.[Lender] = s.[Lender] AND f.[TermMonths] = s.[TermMonths]);
    END;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Create MAC.Products, Promotions, TaxRates and FinancingPlans and seed them from the PriceSheet',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
