/*
Migration: 20261128_1500_AddMAC_CameraCategory
Author: Andres Sosa
Date: 2026-11-28
Description: Cameras on the Good Faith Estimate (quadradia/Solasta_Database#61).
               MAC.Products       Category allows 'Camera': a camera system part, quoted one line each like
                                  an add-on and shown in the estimate's Camera System section.
               MAC.QuoteLines     LineType allows 'Camera'. New ItemDiscount: an amount staff take off an
                                  add-on or camera line (for example to sell a camera system at cost),
                                  taken before the percent and special discounts.
             Seeds the Solasta Lighting tenant from the Calculator tab of CamerasSystems.xlsx:
               MAC.Products       RLN16-410 (Reolink NVR + 3 cameras bundle), MC-HEAD-01 (fiber media
                                  converter kit per camera), NVL-FIBR-60 (fiber cable per camera) and
                                  NVL-INSTL-01 (camera install per camera). MC-HEAD-01, NVL-FIBR-60 and
                                  NVL-INSTL-01 are placeholder parts with estimated prices until a supplier
                                  is found. All are staff only (IsPublic 0) for now.
               INE.Vendors        Reolink.
               INE.StockItems     the three physical parts, inventory category CAMERA, linked to their
                                  products; RLN16-410 with Reolink as its default vendor. The install is a
                                  service and has no stock item.
Dependencies:
  20261117_2230_AddMAC_QuoteBuilder
  20261120_0100_AddINE_PartVariants
  20261121_1500_AddPublicEstimatesForMcp
Rollback:
  DELETE FROM [INE].[StockItems] WHERE [Sku] IN (N'RLN16-410', N'MC-HEAD-01', N'NVL-FIBR-60') AND [Category] = N'CAMERA';
  DELETE FROM [INE].[Vendors] WHERE [Code] = N'REOLINK';
  -- Only when no quote line uses them:
  DELETE FROM [MAC].[Products] WHERE [Category] = 'Camera';
  ALTER TABLE [MAC].[QuoteLines] DROP CONSTRAINT [CK_QuoteLines_ItemDiscount];
  ALTER TABLE [MAC].[QuoteLines] DROP COLUMN [ItemDiscount];
  -- Then put back CK_Products_Category ('Rail', 'Fixed', 'AddOn') and CK_QuoteLines_LineType ('Rail', 'Fixed', 'AddOn').
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261128_1500_AddMAC_CameraCategory';
Expected impact: Two CHECK constraints widened, one nullable column added, seed rows added; no existing row changes.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261128_1500_AddMAC_CameraCategory';
    DECLARE @SolastaProxy VARCHAR(100) = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6';

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MAC.QuoteLines', N'U') IS NULL OR COL_LENGTH(N'MAC.Products', N'IsPublic') IS NULL
       OR COL_LENGTH(N'INE.StockItems', N'ParentStockItemId') IS NULL
        THROW 50001, 'Camera products need MAC.QuoteLines, MAC.Products.IsPublic and INE part variants.', 1;

    ---------------------------------------------------------------------------
    -- Categories
    ---------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_Products_Category'
               AND [parent_object_id] = OBJECT_ID(N'MAC.Products'))
        ALTER TABLE [MAC].[Products] DROP CONSTRAINT [CK_Products_Category];
    ALTER TABLE [MAC].[Products] WITH CHECK ADD CONSTRAINT [CK_Products_Category]
        CHECK ([Category] IN ('Rail', 'Fixed', 'AddOn', 'Camera'));

    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_QuoteLines_LineType'
               AND [parent_object_id] = OBJECT_ID(N'MAC.QuoteLines'))
        ALTER TABLE [MAC].[QuoteLines] DROP CONSTRAINT [CK_QuoteLines_LineType];
    ALTER TABLE [MAC].[QuoteLines] WITH CHECK ADD CONSTRAINT [CK_QuoteLines_LineType]
        CHECK ([LineType] IN ('Rail', 'Fixed', 'AddOn', 'Camera'));

    ---------------------------------------------------------------------------
    -- MAC.QuoteLines.ItemDiscount
    ---------------------------------------------------------------------------
    IF COL_LENGTH(N'MAC.QuoteLines', N'ItemDiscount') IS NULL
        ALTER TABLE [MAC].[QuoteLines] ADD [ItemDiscount] [decimal](18, 2) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_QuoteLines_ItemDiscount'
                   AND [parent_object_id] = OBJECT_ID(N'MAC.QuoteLines'))
        EXEC sys.sp_executesql N'ALTER TABLE [MAC].[QuoteLines] WITH CHECK ADD CONSTRAINT [CK_QuoteLines_ItemDiscount]
            CHECK ([ItemDiscount] IS NULL OR ([ItemDiscount] >= 0 AND [LineType] IN (''AddOn'', ''Camera'')))';

    ---------------------------------------------------------------------------
    -- Seed the Solasta Lighting tenant (Calculator tab of CamerasSystems.xlsx).
    ---------------------------------------------------------------------------
    DECLARE @TenantId INT = (SELECT [DealerTenantID] FROM [ACC].[DealerTenants] WHERE [Proxy] = @SolastaProxy);
    IF @TenantId IS NULL
        PRINT 'Solasta Lighting tenant not found; skipping the camera seed.';
    ELSE
    BEGIN
        -- Price = the sheet's Price column; the internal costs are its Cost column (install as InstallCostPerUnit).
        INSERT INTO [MAC].[Products]
            ([DealerTenantId], [Sku], [Name], [Category], [Unit], [PricePerUnit], [InstallCostPerUnit], [ProductCostPerUnit],
             [SortOrder], [IsPublic])
        SELECT @TenantId, s.[Sku], s.[Name], 'Camera', 'each', s.[PricePerUnit], s.[InstallCostPerUnit], s.[ProductCostPerUnit],
               s.[SortOrder], 0
        FROM (VALUES
            ('RLN16-410',    N'Reolink NVR + Duo 3V PoE Bundle (3x 16MP UltraHD 180° Cameras)', 1599.00, NULL,   882.99, 80),
            ('MC-HEAD-01',   N'Fiber Media Converters (per camera)',                          500.00, NULL,   250.00, 81),
            ('NVL-FIBR-60',  N'Fiber Cable (per camera)',                                      65.00, NULL,    45.00, 82),
            ('NVL-INSTL-01', N'Camera Installation (per camera)',                             750.00, 350.00,  NULL,  83)
        ) AS s ([Sku], [Name], [PricePerUnit], [InstallCostPerUnit], [ProductCostPerUnit], [SortOrder])
        WHERE NOT EXISTS (SELECT 1 FROM [MAC].[Products] p WHERE p.[DealerTenantId] = @TenantId AND p.[Sku] = s.[Sku]);

        IF NOT EXISTS (SELECT 1 FROM [INE].[Vendors] WHERE [DealerTenantId] = @TenantId AND [Code] = N'REOLINK')
            INSERT INTO [INE].[Vendors] ([DealerTenantId], [Code], [Name], [Website], [Notes])
            VALUES (@TenantId, N'REOLINK', N'Reolink', N'https://reolink.com', N'Security cameras and NVRs (RLN16-410).');
        DECLARE @ReolinkId INT = (SELECT [VendorID] FROM [INE].[Vendors] WHERE [DealerTenantId] = @TenantId AND [Code] = N'REOLINK');

        INSERT INTO [INE].[StockItems]
            ([DealerTenantId], [ProductId], [DefaultVendorId], [Sku], [Name], [Description], [Category], [UnitOfMeasure],
             [VendorSku], [StandardCost])
        SELECT @TenantId, p.[ProductID], s.[VendorId], s.[Sku], s.[Name], s.[Description], N'CAMERA', 'each', s.[VendorSku], s.[Cost]
        FROM (VALUES
            (N'RLN16-410',   N'Reolink NVR + Duo 3V PoE Bundle', N'NVR with 3x 16MP UltraHD 180° Duo 3V PoE cameras.',
                @ReolinkId, N'RLN16-410', 882.99),
            (N'MC-HEAD-01',  N'Fiber Media Converters', N'Placeholder until sourced: the media converters and parts to run fiber instead of CAT6 from the controller (head) to one camera.',
                NULL, NULL, 250.00),
            (N'NVL-FIBR-60', N'Fiber Cable', N'Placeholder until sourced: fiber cable for one camera run.',
                NULL, NULL, 45.00)
        ) AS s ([Sku], [Name], [Description], [VendorId], [VendorSku], [Cost])
        INNER JOIN [MAC].[Products] p ON p.[DealerTenantId] = @TenantId AND p.[Sku] = s.[Sku]
        WHERE NOT EXISTS (SELECT 1 FROM [INE].[StockItems] i WHERE i.[DealerTenantId] = @TenantId AND i.[Sku] = s.[Sku]);
    END;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success])
    VALUES (@MigrationName, N'Camera product category, camera products and per-line quote discounts', 1);

    COMMIT TRANSACTION;
    PRINT 'Migration completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
