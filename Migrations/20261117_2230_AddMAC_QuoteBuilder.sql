/*
Migration: 20261117_2230_AddMAC_QuoteBuilder
Author: Andres Sosa
Date: 2026-11-17
Description: Lead-to-quote phase 4, the quote builder. Office staff quote a lead (QAL.Leads) directly,
             one product per quote, from a roofline measurement (MAC.Measurements) or typed feet.
               MAC.Quotes (change)   a quote now hangs off a lead: DealerTenantId, LeadId, MeasurementId,
                                     ProductId, PromotionId, TaxRateId, Revision and RevisedFromQuoteId,
                                     the prices, discounts, tax rate, deposit and validity copied from
                                     the catalog when the quote is made (so a price change never rewrites
                                     an old quote), and its totals. EstimateId becomes optional.
                                     ValidUntil becomes a datetimeoffset so a 24-hour offer keeps its time.
                                     The audit ids become uniqueidentifier like every other table the API
                                     reads (they were bigint, which the API cannot read).
               MAC.QuoteLines (new)  one row per rail location (Front, Side-Left, ...), one per fixed cost
                                     (dormers, gables, height cost) and one per add-on (camera, DVR, ...).
               MAC.QuoteTypes        seeds the 'Lead quote' type with proxy prefix MAQT.
               MAC.Products          allows Category 'Fixed' and seeds the fixed costs the Good Faith
                                     Estimate uses: Dormers $250, Gables $200, Height Cost $500 each.
               MAC.FinancingPlans    Enhancify APRs from the PriceSheet: 12 months 7.99%, 24 months 8.9%,
                                     36 months 9.9% (21 months stays 0%). Only rows still at the original
                                     7.9% seed are changed.
             The pricing rules live in the API (QuotePricingCalculator) and match the Good Faith Estimate
             generator (calc.js) to the cent.
Dependencies:
  20261117_0330_CreateMAC_PricingCatalog
  20261117_0340_AddQAL_LeadIntake
  20261117_0400_CreateMAC_Measurements
  20261117_2200_AddMAC_MeasurementIncludeAndHeightEdits
Rollback:
  DROP TABLE [MAC].[QuoteLines];
  -- Quotes: drop the added columns, constraints and index by name (see below); EstimateId back to NOT NULL
  -- only if no quote without an estimate exists.
  UPDATE [MAC].[FinancingPlans] SET [Apr] = 0.079000 WHERE [Lender] = N'Enhancify' AND [TermMonths] IN (12, 24, 36);
  DELETE FROM [MAC].[Products] WHERE [Sku] IN ('DRM001', 'GBL001', 'HGT001');
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_2230_AddMAC_QuoteBuilder';
Expected impact: MAC.Quotes gains nullable columns (existing rows keep their values; their audit ids are
  reset to the system user because a bigint cannot become a uniqueidentifier). One new table, seed rows.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261117_2230_AddMAC_QuoteBuilder';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();
    DECLARE @SolastaProxy VARCHAR(100) = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6';
    DECLARE @SystemUser NVARCHAR(36) = N'E6872B58-52B2-415C-A32B-45805F95A70A';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Constraint SYSNAME;

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MAC.Quotes', N'U') IS NULL OR OBJECT_ID(N'MAC.QuoteTypes', N'U') IS NULL
       OR OBJECT_ID(N'MAC.Products', N'U') IS NULL OR OBJECT_ID(N'MAC.Measurements', N'U') IS NULL
       OR OBJECT_ID(N'QAL.Leads', N'U') IS NULL
        THROW 50001, 'The quote builder requires MAC.Quotes, MAC.QuoteTypes, the MAC pricing catalog, MAC.Measurements and QAL.Leads.', 1;

    ---------------------------------------------------------------------------
    -- MAC.Quotes: audit ids bigint -> uniqueidentifier
    ---------------------------------------------------------------------------
    DECLARE @AuditColumn SYSNAME;
    DECLARE audit_columns CURSOR LOCAL FAST_FORWARD FOR
        SELECT c.[name] FROM sys.columns c JOIN sys.types t ON t.[user_type_id] = c.[user_type_id]
        WHERE c.[object_id] = OBJECT_ID(N'MAC.Quotes') AND c.[name] IN (N'CreatedById', N'ModifiedById')
          AND t.[name] <> N'uniqueidentifier';
    OPEN audit_columns;
    FETCH NEXT FROM audit_columns INTO @AuditColumn;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @Constraint = dc.[name] FROM sys.default_constraints dc
        JOIN sys.columns c ON c.[object_id] = dc.[parent_object_id] AND c.[column_id] = dc.[parent_column_id]
        WHERE dc.[parent_object_id] = OBJECT_ID(N'MAC.Quotes') AND c.[name] = @AuditColumn;
        IF @Constraint IS NOT NULL
            EXEC (N'ALTER TABLE [MAC].[Quotes] DROP CONSTRAINT ' + N'[' + @Constraint + N']');
        SET @Constraint = NULL;

        SET @Sql = N'ALTER TABLE [MAC].[Quotes] ADD [' + @AuditColumn + N'_Guid] [uniqueidentifier] NOT NULL '
                 + N'CONSTRAINT [DF_Quotes_' + @AuditColumn + N'_Guid] DEFAULT (''' + @SystemUser + N''');';
        EXEC (@Sql);
        EXEC (N'ALTER TABLE [MAC].[Quotes] DROP CONSTRAINT [DF_Quotes_' + @AuditColumn + N'_Guid];');
        EXEC (N'ALTER TABLE [MAC].[Quotes] DROP COLUMN [' + @AuditColumn + N'];');
        SET @Sql = N'MAC.Quotes.' + @AuditColumn + N'_Guid';
        EXEC sp_rename @Sql, @AuditColumn, N'COLUMN';
        EXEC (N'ALTER TABLE [MAC].[Quotes] ADD CONSTRAINT [DF_Quotes_' + @AuditColumn + N'] DEFAULT ('''
              + @SystemUser + N''') FOR [' + @AuditColumn + N'];');
        PRINT 'MAC.Quotes.' + @AuditColumn + ' is now uniqueidentifier.';
        FETCH NEXT FROM audit_columns INTO @AuditColumn;
    END;
    CLOSE audit_columns;
    DEALLOCATE audit_columns;

    ---------------------------------------------------------------------------
    -- MAC.Quotes: EstimateId optional, ValidUntil keeps its time
    ---------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID(N'MAC.Quotes') AND [name] = N'EstimateId' AND [is_nullable] = 0)
        ALTER TABLE [MAC].[Quotes] ALTER COLUMN [EstimateId] [bigint] NULL;

    IF EXISTS (SELECT 1 FROM sys.columns c JOIN sys.types t ON t.[user_type_id] = c.[user_type_id]
               WHERE c.[object_id] = OBJECT_ID(N'MAC.Quotes') AND c.[name] = N'ValidUntil' AND t.[name] = N'date')
        ALTER TABLE [MAC].[Quotes] ALTER COLUMN [ValidUntil] [datetimeoffset](7) NULL;

    ---------------------------------------------------------------------------
    -- MAC.Quotes: new columns (nullable or defaulted, so existing rows stay valid)
    ---------------------------------------------------------------------------
    DECLARE @Columns TABLE ([Name] SYSNAME, [Definition] NVARCHAR(400));
    INSERT INTO @Columns ([Name], [Definition]) VALUES
        (N'DealerTenantId',              N'[int] NULL'),
        (N'LeadId',                      N'[bigint] NULL'),
        (N'MeasurementId',               N'[bigint] NULL'),
        (N'ProductId',                   N'[int] NULL'),
        (N'PromotionId',                 N'[int] NULL'),
        (N'TaxRateId',                   N'[int] NULL'),
        -- 1 for a new quote; a revision is a new row with the next number and RevisedFromQuoteId set.
        (N'Revision',                    N'[int] NOT NULL CONSTRAINT [DF_Quotes_Revision] DEFAULT ((1))'),
        (N'RevisedFromQuoteId',          N'[bigint] NULL'),
        -- When the quote was issued (QuoteDate is the day); validity counts from here.
        (N'IssuedDate',                  N'[datetimeoffset](7) NULL'),
        (N'StatusDate',                  N'[datetimeoffset](7) NULL'),
        -- Copied from the catalog when the quote is made.
        (N'ProductSku',                  N'[varchar](20) NULL'),
        (N'ProductName',                 N'[nvarchar](100) NULL'),
        (N'PricePerFoot',                N'[decimal](19, 4) NULL'),
        (N'AllowancePct',                N'[decimal](5, 2) NOT NULL CONSTRAINT [DF_Quotes_AllowancePct] DEFAULT ((10.00))'),
        (N'PromotionCode',               N'[varchar](20) NULL'),
        (N'PromotionName',               N'[nvarchar](100) NULL'),
        -- The promo''s discount per foot, or one typed in without a promo; positive.
        (N'PromotionPerFoot',            N'[decimal](19, 4) NOT NULL CONSTRAINT [DF_Quotes_PromotionPerFoot] DEFAULT ((0))'),
        (N'PromotionMaxValidityHours',   N'[int] NULL'),
        -- Extra percent off as a fraction, after the per-foot discount.
        (N'DiscountPercent',             N'[decimal](9, 6) NOT NULL CONSTRAINT [DF_Quotes_DiscountPercent] DEFAULT ((0))'),
        (N'PercentAppliesToFixedCosts',  N'[bit] NOT NULL CONSTRAINT [DF_Quotes_PercentAppliesToFixedCosts] DEFAULT ((1))'),
        -- e.g. Friends & Family: an amount, or a target subtotal or total to land on.
        (N'SpecialDiscountLabel',        N'[nvarchar](100) NULL'),
        (N'SpecialDiscountAmount',       N'[decimal](18, 2) NULL'),
        (N'SpecialDiscountTargetSubtotal', N'[decimal](18, 2) NULL'),
        (N'SpecialDiscountTargetTotal',  N'[decimal](18, 2) NULL'),
        (N'SalesTaxRate',                N'[decimal](9, 6) NULL'),
        (N'TaxCity',                     N'[nvarchar](100) NULL'),
        (N'DepositPercent',              N'[decimal](9, 6) NOT NULL CONSTRAINT [DF_Quotes_DepositPercent] DEFAULT ((0.5))'),
        (N'PaymentMethod',               N'[varchar](10) NOT NULL CONSTRAINT [DF_Quotes_PaymentMethod] DEFAULT (''Amortized'')'),
        -- How long the offer stands; both NULL means the default 30 days.
        (N'ValidityDays',                N'[int] NULL'),
        (N'ValidityHours',               N'[int] NULL'),
        -- The financing options shown, as JSON: [{"termMonths":12,"apr":0.0799,"label":"12 months"}, ...]
        (N'FinancingTerms',              N'[nvarchar](2000) NULL'),
        -- Internal only; never printed on the customer estimate.
        (N'InstallCostPerFoot',          N'[decimal](19, 4) NULL'),
        (N'ProductCostPerFoot',          N'[decimal](19, 4) NULL'),
        -- Totals (TotalAmount already exists).
        (N'TotalFeet',                   N'[decimal](9, 2) NULL'),
        (N'GrossTotal',                  N'[decimal](18, 2) NULL'),
        (N'DiscountTotal',               N'[decimal](18, 2) NULL'),
        (N'SubTotal',                    N'[decimal](18, 2) NULL'),
        (N'TaxTotal',                    N'[decimal](18, 2) NULL'),
        (N'DepositAmount',               N'[decimal](18, 2) NULL'),
        (N'InstallCost',                 N'[decimal](18, 2) NULL');

    DECLARE @Name SYSNAME, @Definition NVARCHAR(400);
    DECLARE new_columns CURSOR LOCAL FAST_FORWARD FOR SELECT [Name], [Definition] FROM @Columns;
    OPEN new_columns;
    FETCH NEXT FROM new_columns INTO @Name, @Definition;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF COL_LENGTH(N'MAC.Quotes', @Name) IS NULL
            EXEC (N'ALTER TABLE [MAC].[Quotes] ADD [' + @Name + N'] ' + @Definition + N';');
        FETCH NEXT FROM new_columns INTO @Name, @Definition;
    END;
    CLOSE new_columns;
    DEALLOCATE new_columns;

    -- Constraints on the new columns (dynamic SQL: the columns did not exist when this batch compiled).
    DECLARE @Constraints TABLE ([Name] SYSNAME, [Definition] NVARCHAR(1000));
    INSERT INTO @Constraints ([Name], [Definition]) VALUES
        (N'FK_Quotes_DealerTenants',  N'FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID])'),
        (N'FK_Quotes_Leads',          N'FOREIGN KEY ([LeadId]) REFERENCES [QAL].[Leads] ([LeadID])'),
        (N'FK_Quotes_Measurements',   N'FOREIGN KEY ([MeasurementId]) REFERENCES [MAC].[Measurements] ([MeasurementID])'),
        (N'FK_Quotes_Products',       N'FOREIGN KEY ([ProductId]) REFERENCES [MAC].[Products] ([ProductID])'),
        (N'FK_Quotes_Promotions',     N'FOREIGN KEY ([PromotionId]) REFERENCES [MAC].[Promotions] ([PromotionID])'),
        (N'FK_Quotes_TaxRates',       N'FOREIGN KEY ([TaxRateId]) REFERENCES [MAC].[TaxRates] ([TaxRateID])'),
        (N'FK_Quotes_RevisedFrom',    N'FOREIGN KEY ([RevisedFromQuoteId]) REFERENCES [MAC].[Quotes] ([QuoteID])'),
        (N'CK_Quotes_Revision',       N'CHECK ([Revision] >= 1)'),
        (N'CK_Quotes_AllowancePct',   N'CHECK ([AllowancePct] >= 0 AND [AllowancePct] <= 100)'),
        (N'CK_Quotes_PromotionPerFoot', N'CHECK ([PromotionPerFoot] >= 0)'),
        (N'CK_Quotes_DiscountPercent', N'CHECK ([DiscountPercent] >= 0 AND [DiscountPercent] <= 1)'),
        (N'CK_Quotes_SpecialDiscount', N'CHECK ((CASE WHEN [SpecialDiscountAmount] IS NULL THEN 0 ELSE 1 END
                                                + CASE WHEN [SpecialDiscountTargetSubtotal] IS NULL THEN 0 ELSE 1 END
                                                + CASE WHEN [SpecialDiscountTargetTotal] IS NULL THEN 0 ELSE 1 END) <= 1)'),
        (N'CK_Quotes_SalesTaxRate',   N'CHECK ([SalesTaxRate] IS NULL OR ([SalesTaxRate] >= 0 AND [SalesTaxRate] < 1))'),
        (N'CK_Quotes_DepositPercent', N'CHECK ([DepositPercent] >= 0 AND [DepositPercent] <= 1)'),
        (N'CK_Quotes_PaymentMethod',  N'CHECK ([PaymentMethod] IN (''Amortized'', ''Simple''))'),
        (N'CK_Quotes_Validity',       N'CHECK (([ValidityDays] IS NULL OR [ValidityDays] >= 0) AND ([ValidityHours] IS NULL OR [ValidityHours] >= 0))');

    DECLARE constraints_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT [Name], [Definition] FROM @Constraints;
    OPEN constraints_cursor;
    FETCH NEXT FROM constraints_cursor INTO @Name, @Definition;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF OBJECT_ID(N'MAC.' + @Name) IS NULL
            EXEC (N'ALTER TABLE [MAC].[Quotes] WITH CHECK ADD CONSTRAINT [' + @Name + N'] ' + @Definition + N';');
        FETCH NEXT FROM constraints_cursor INTO @Name, @Definition;
    END;
    CLOSE constraints_cursor;
    DEALLOCATE constraints_cursor;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.Quotes') AND [name] = N'IX_Quotes_DealerTenantId_LeadId')
        EXEC (N'CREATE NONCLUSTERED INDEX [IX_Quotes_DealerTenantId_LeadId]
                    ON [MAC].[Quotes] ([DealerTenantId], [LeadId]) WHERE [IsActive] = 1 AND [LeadId] IS NOT NULL;');

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.Quotes') AND [name] = N'IX_Quotes_Proxy')
        CREATE NONCLUSTERED INDEX [IX_Quotes_Proxy] ON [MAC].[Quotes] ([Proxy]);

    ---------------------------------------------------------------------------
    -- MAC.QuoteLines
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MAC.QuoteLines', N'U') IS NULL
    BEGIN
        CREATE TABLE [MAC].[QuoteLines]
        (
            [QuoteLineID] [bigint] IDENTITY(1,1) NOT NULL,
            [QuoteId] [bigint] NOT NULL,
            -- Rail (one per location), Fixed (dormers, gables, height cost) or AddOn (camera, DVR, ...).
            [LineType] [varchar](10) NOT NULL,
            [SortOrder] [int] NOT NULL CONSTRAINT [DF_QuoteLines_SortOrder] DEFAULT ((0)),
            -- Rail lines: Front, Side-Left, Side-Right, Back, Back - Low, ...
            [Location] [nvarchar](30) NULL,
            [ProductId] [int] NULL,
            [Sku] [varchar](20) NOT NULL,
            [Description] [nvarchar](200) NOT NULL,
            -- Rail lines: measured feet before the allowance, when known.
            [MeasuredFeet] [decimal](9, 2) NULL,
            -- Rail lines: billable feet (measured + allowance, rounded). Others: how many.
            [Quantity] [decimal](9, 2) NOT NULL,
            [UnitPrice] [decimal](19, 4) NOT NULL,
            [Gross] [decimal](18, 2) NOT NULL,
            -- The priced row. NULL on Fixed lines: fixed costs are priced together as one
            -- "Aux - Fixed Costs" row, as the estimate shows them.
            [PerFootDiscount] [decimal](18, 2) NULL,
            [PercentDiscount] [decimal](18, 2) NULL,
            [SpecialDiscount] [decimal](18, 2) NULL,
            [Discount] [decimal](18, 2) NULL,
            [SubTotal] [decimal](18, 2) NULL,
            [Tax] [decimal](18, 2) NULL,
            [Total] [decimal](18, 2) NULL,
            -- An excluded location is shown but left out of the totals.
            [IsIncluded] [bit] NOT NULL CONSTRAINT [DF_QuoteLines_IsIncluded] DEFAULT ((1)),
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_QuoteLines_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_QuoteLines_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_QuoteLines_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_QuoteLines_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_QuoteLines_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_QuoteLines_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_QuoteLines_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_QuoteLines] PRIMARY KEY CLUSTERED ([QuoteLineID] ASC),
            CONSTRAINT [FK_QuoteLines_Quotes] FOREIGN KEY ([QuoteId]) REFERENCES [MAC].[Quotes] ([QuoteID]),
            CONSTRAINT [FK_QuoteLines_Products] FOREIGN KEY ([ProductId]) REFERENCES [MAC].[Products] ([ProductID]),
            CONSTRAINT [CK_QuoteLines_LineType] CHECK ([LineType] IN ('Rail', 'Fixed', 'AddOn')),
            CONSTRAINT [CK_QuoteLines_Location] CHECK ([LineType] <> 'Rail' OR [Location] IS NOT NULL),
            CONSTRAINT [CK_QuoteLines_Quantity] CHECK ([Quantity] >= 0),
            CONSTRAINT [CK_QuoteLines_UnitPrice] CHECK ([UnitPrice] >= 0),
            CONSTRAINT [CK_QuoteLines_MeasuredFeet] CHECK ([MeasuredFeet] IS NULL OR [MeasuredFeet] >= 0)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.QuoteLines') AND [name] = N'IX_QuoteLines_QuoteId')
        CREATE NONCLUSTERED INDEX [IX_QuoteLines_QuoteId] ON [MAC].[QuoteLines] ([QuoteId]) WHERE [IsActive] = 1;

    ---------------------------------------------------------------------------
    -- MAC.QuoteTypes: the 'Lead quote' type (prefix MAQT)
    ---------------------------------------------------------------------------
    -- QuoteTypes still has the old audit columns; write whichever type they are.
    IF NOT EXISTS (SELECT 1 FROM [MAC].[QuoteTypes] WHERE [Prefix] = 'MAQT')
    BEGIN
        DECLARE @AuditValue NVARCHAR(50) =
            CASE WHEN EXISTS (SELECT 1 FROM sys.columns c JOIN sys.types t ON t.[user_type_id] = c.[user_type_id]
                              WHERE c.[object_id] = OBJECT_ID(N'MAC.QuoteTypes') AND c.[name] = N'CreatedById'
                                AND t.[name] = N'uniqueidentifier')
                 THEN N'''' + @SystemUser + N'''' ELSE N'0' END;
        SET @Sql = N'INSERT INTO [MAC].[QuoteTypes] ([Prefix], [Name], [Description], [IsActive], [IsDeleted], [ModifiedDate],
                         [ModifiedById], [CreatedDate], [CreatedById], [DEX_ROW_TS])
                     VALUES (''MAQT'', N''Lead quote'',
                             N''A quote for one product, made from a lead''''s roofline measurement or typed feet.'',
                             1, 0, SYSDATETIMEOFFSET(), ' + @AuditValue + N', SYSDATETIMEOFFSET(), ' + @AuditValue + N', SYSDATETIMEOFFSET());';
        EXEC (@Sql);
    END;

    ---------------------------------------------------------------------------
    -- MAC.Products: fixed costs
    ---------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_Products_Category'
               AND [parent_object_id] = OBJECT_ID(N'MAC.Products') AND [definition] NOT LIKE N'%Fixed%')
        ALTER TABLE [MAC].[Products] DROP CONSTRAINT [CK_Products_Category];
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_Products_Category' AND [parent_object_id] = OBJECT_ID(N'MAC.Products'))
        ALTER TABLE [MAC].[Products] WITH CHECK ADD CONSTRAINT [CK_Products_Category] CHECK ([Category] IN ('Rail', 'Fixed', 'AddOn'));

    DECLARE @TenantId INT = (SELECT [DealerTenantID] FROM [ACC].[DealerTenants] WHERE [Proxy] = @SolastaProxy);
    IF @TenantId IS NULL
        PRINT 'Solasta Lighting tenant not found; skipping the fixed costs and financing APRs.';
    ELSE
    BEGIN
        -- The Good Faith Estimate's fixed costs ("Fixed - not customer removable"). Its price sheet files them under
        -- DVR001, VHD001 and DVRA001, which here are the 16 Channel DVR, the camera and the AI DVR, so they get their own SKUs.
        INSERT INTO [MAC].[Products]
            ([DealerTenantId], [Sku], [Name], [Category], [Unit], [PricePerUnit], [InstallCostPerUnit], [ProductCostPerUnit], [SortOrder])
        SELECT @TenantId, s.[Sku], s.[Name], 'Fixed', 'each', s.[PricePerUnit], NULL, NULL, s.[SortOrder]
        FROM (VALUES
            ('DRM001', N'Dormers',     250.00, 35),
            ('GBL001', N'Gables',      200.00, 36),
            ('HGT001', N'Height Cost', 500.00, 37)
        ) AS s ([Sku], [Name], [PricePerUnit], [SortOrder])
        WHERE NOT EXISTS (SELECT 1 FROM [MAC].[Products] p WHERE p.[DealerTenantId] = @TenantId AND p.[Sku] = s.[Sku]);

        -- PriceSheet APRs (the first seed had 7.9% on every paid term). Rows someone already changed are left alone.
        UPDATE f SET f.[Apr] = s.[Apr], f.[ModifiedDate] = SYSDATETIMEOFFSET()
        FROM [MAC].[FinancingPlans] f
        JOIN (VALUES (12, 0.079900), (24, 0.089000), (36, 0.099000)) AS s ([TermMonths], [Apr]) ON s.[TermMonths] = f.[TermMonths]
        WHERE f.[DealerTenantId] = @TenantId AND f.[Lender] = N'Enhancify' AND f.[Apr] = 0.079000;
    END;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Quote builder: MAC.Quotes per lead, MAC.QuoteLines, fixed-cost products, PriceSheet financing APRs',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
