/*
Migration: 20261120_0300_AddINE_ConvertToVariantsAndQuoteColorChoice
Author: Andres Sosa
Date: 2026-11-19
Description: Follow-up to 20261120_0100_AddINE_PartVariants:
               INE.spStockItemConvertToVariants (new)  turns a stocked item into a parent with its first
                                           color in one transaction: creates the variant, moves the stock at
                                           every stock-holding location with AdjustOut/AdjustIn movements (lots
                                           by number, serial numbers; the item's units become Voided), re-creates
                                           open allocations, moves reorder rules and open PO lines, then links
                                           the variant. Idempotent for the same color; 04194 when the item
                                           already has variants, 04195 bad or taken SKU, 04196 a move failed.
               tr_StockItems_VariantGuard  04192 now counts only stock-holding locations: stock installed at
                                           jobs or sent to vendors stays on the item as history.
               tr_PurchaseOrderLines_GuardStatus  a submitted line's item may change only while the session key
                                           INE.ConvertStockItemId names that item (set by the procedure).
               MAC.QuoteLines              + VariantChosenBy ('Staff' or 'Customer'), VariantChosenDate and
                                           VariantChosenSignatureId (FK MAC.QuoteSignatures): who picked the
                                           color, the customer picking it on the signing page with that link.
             Each object's source of truth is its file under Tables/, Triggers/ and Procedures/; this
             migration embeds those files. Rerun the AutoGenerator for the procedure's SPROC wrapper and the
             new QuoteLines columns.
Dependencies:
  20261120_0100_AddINE_PartVariants
  20261117_2330_AddMAC_QuoteSigning
Rollback:
  DROP PROCEDURE [INE].[spStockItemConvertToVariants];
  Re-apply tr_StockItems_VariantGuard from 20261120_0100_AddINE_PartVariants and
  tr_PurchaseOrderLines_GuardStatus from 20261117_1810_CreateINE_InventoryEngineProcedures.
  ALTER TABLE [MAC].[QuoteLines] DROP CONSTRAINT [FK_QuoteLines_QuoteSignatures], [CK_QuoteLines_VariantChosenBy];
  ALTER TABLE [MAC].[QuoteLines] DROP COLUMN [VariantChosenBy], [VariantChosenDate], [VariantChosenSignatureId];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261120_0300_AddINE_ConvertToVariantsAndQuoteColorChoice';
Expected impact: one new procedure, two triggers altered, three nullable columns on MAC.QuoteLines. No data changes.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261120_0300_AddINE_ConvertToVariantsAndQuoteColorChoice';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[SchemaVersion]
                   WHERE [MigrationName] = N'20261120_0100_AddINE_PartVariants' AND [Success] = 1)
        THROW 50001, 'Apply 20261120_0100_AddINE_PartVariants first.', 1;
    IF OBJECT_ID(N'MAC.QuoteSignatures', N'U') IS NULL
        THROW 50001, 'MAC.QuoteSignatures is missing. Apply 20261117_2330_AddMAC_QuoteSigning first.', 1;

    ---------------------------------------------------------------------------
    -- MAC.QuoteLines: who chose the variant
    ---------------------------------------------------------------------------
    IF COL_LENGTH(N'MAC.QuoteLines', N'VariantChosenBy') IS NULL
        ALTER TABLE [MAC].[QuoteLines] ADD [VariantChosenBy] [varchar](10) NULL;
    IF COL_LENGTH(N'MAC.QuoteLines', N'VariantChosenDate') IS NULL
        ALTER TABLE [MAC].[QuoteLines] ADD [VariantChosenDate] [datetimeoffset](7) NULL;
    IF COL_LENGTH(N'MAC.QuoteLines', N'VariantChosenSignatureId') IS NULL
        ALTER TABLE [MAC].[QuoteLines] ADD [VariantChosenSignatureId] [bigint] NULL;

    IF OBJECT_ID(N'MAC.FK_QuoteLines_QuoteSignatures', N'F') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE [MAC].[QuoteLines] WITH CHECK ADD CONSTRAINT [FK_QuoteLines_QuoteSignatures]
            FOREIGN KEY ([VariantChosenSignatureId]) REFERENCES [MAC].[QuoteSignatures] ([QuoteSignatureID]);';
    IF OBJECT_ID(N'MAC.CK_QuoteLines_VariantChosenBy', N'C') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE [MAC].[QuoteLines] WITH CHECK ADD CONSTRAINT [CK_QuoteLines_VariantChosenBy]
            CHECK ([VariantChosenBy] IS NULL OR [VariantChosenBy] IN (''Staff'', ''Customer''));';

    ---------------------------------------------------------------------------
    -- Triggers and procedures (embedded from their source files)
    ---------------------------------------------------------------------------
    -- INE.tr_StockItems_VariantGuard: stock-holding locations only (Triggers/INE/tr_StockItems_VariantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_StockItems_VariantGuard]
ON [INE].[StockItems]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- One level deep.
    IF EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[StockItems] AS P ON P.[StockItemID] = I.[ParentStockItemId]
               WHERE P.[ParentStockItemId] IS NOT NULL)
       OR EXISTS (SELECT 1 FROM inserted AS I
                  WHERE I.[ParentStockItemId] IS NOT NULL
                    AND EXISTS (SELECT 1 FROM [INE].[StockItems] AS C WHERE C.[ParentStockItemId] = I.[StockItemID]))
        THROW 50000, N''04191|:|Variants are one level deep: a variant cannot have variants of its own, and an item with variants cannot become a variant.'', 1;

    -- Parents that just gained a variant must not hold stock.
    DECLARE @NewParents TABLE ([StockItemId] INT NOT NULL PRIMARY KEY);
    INSERT INTO @NewParents ([StockItemId])
    SELECT DISTINCT I.[ParentStockItemId]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockItemID] = I.[StockItemID]
    WHERE I.[ParentStockItemId] IS NOT NULL
      AND (D.[StockItemID] IS NULL OR D.[ParentStockItemId] IS NULL OR D.[ParentStockItemId] <> I.[ParentStockItemId]);

    IF EXISTS (SELECT 1 FROM @NewParents)
    BEGIN
        DECLARE @Msg NVARCHAR(2048);
        SELECT TOP (1) @Msg = CONCAT(N''04192|:|Stock item '', P.[Sku], N'' still holds stock (on hand, allocated, on an open purchase order or a reorder rule). '',
                                     N''Move or adjust it out, close those first, then add variants; stock lives on variants only.'')
        FROM @NewParents AS NP
        INNER JOIN [INE].[StockItems] AS P ON P.[StockItemID] = NP.[StockItemId]
        WHERE EXISTS (SELECT 1 FROM [INE].[StockBalances] AS SB
                      INNER JOIN [INE].[Locations] AS L ON L.[LocationID] = SB.[LocationId]
                      INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
                      WHERE SB.[StockItemId] = NP.[StockItemId] AND LT.[IsStockHolding] = 1
                        AND (SB.[QuantityOnHand] <> 0 OR SB.[QuantityAllocated] <> 0))
           OR EXISTS (SELECT 1 FROM [INE].[Allocations] AS A
                      WHERE A.[StockItemId] = NP.[StockItemId] AND A.[Status] = ''Open'')
           OR EXISTS (SELECT 1 FROM [INE].[PurchaseOrderLines] AS POL
                      INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
                      WHERE POL.[StockItemId] = NP.[StockItemId] AND POL.[IsDeleted] = 0 AND PO.[IsDeleted] = 0
                        AND PO.[Status] IN (''Draft'', ''Submitted'', ''PartiallyReceived'')
                        AND POL.[QuantityOrdered] > POL.[QuantityReceived])
           OR EXISTS (SELECT 1 FROM [INE].[StockLevels] AS SL
                      WHERE SL.[StockItemId] = NP.[StockItemId] AND SL.[IsActive] = 1 AND SL.[IsDeleted] = 0);
        IF @Msg IS NOT NULL
            THROW 50000, @Msg, 1;
    END;

    -- A variant takes its parent''s product (both for written variants and written parents).
    IF UPDATE([ProductId]) OR UPDATE([ParentStockItemId])
        UPDATE C SET C.[ProductId] = P.[ProductId]
        FROM [INE].[StockItems] AS C
        INNER JOIN [INE].[StockItems] AS P ON P.[StockItemID] = C.[ParentStockItemId]
        WHERE (C.[StockItemID] IN (SELECT [StockItemID] FROM inserted) OR P.[StockItemID] IN (SELECT [StockItemID] FROM inserted))
          AND (C.[ProductId] <> P.[ProductId] OR (C.[ProductId] IS NULL AND P.[ProductId] IS NOT NULL)
               OR (C.[ProductId] IS NOT NULL AND P.[ProductId] IS NULL));
END;
';

    -- INE.tr_PurchaseOrderLines_GuardStatus: lines move with a conversion (Triggers/INE/tr_PurchaseOrderLines_GuardStatus.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_PurchaseOrderLines_GuardStatus]
ON [INE].[PurchaseOrderLines]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Set only by INE.spStockItemConvertToVariants while it moves an item''s lines to its variant.
    DECLARE @ConvertingItemId INT = TRY_CAST(SESSION_CONTEXT(N''INE.ConvertStockItemId'') AS INT);

    IF EXISTS (
        -- inserted or deleted lines on a non-Draft PO
        SELECT 1
        FROM (SELECT [PurchaseOrderId] FROM inserted AS I
              WHERE NOT EXISTS (SELECT 1 FROM deleted AS D WHERE D.[PurchaseOrderLineID] = I.[PurchaseOrderLineID])
              UNION ALL
              SELECT [PurchaseOrderId] FROM deleted AS D
              WHERE NOT EXISTS (SELECT 1 FROM inserted AS I WHERE I.[PurchaseOrderLineID] = D.[PurchaseOrderLineID])
              UNION ALL
              -- updated lines whose ordering terms changed
              SELECT I.[PurchaseOrderId] FROM inserted AS I
              INNER JOIN deleted AS D ON D.[PurchaseOrderLineID] = I.[PurchaseOrderLineID]
              WHERE I.[PurchaseOrderId] <> D.[PurchaseOrderId]
                 OR (I.[StockItemId] <> D.[StockItemId] AND (@ConvertingItemId IS NULL OR D.[StockItemId] <> @ConvertingItemId))
                 OR I.[QuantityOrdered] <> D.[QuantityOrdered] OR I.[UnitCost] <> D.[UnitCost]
                 OR I.[IsDeleted] <> D.[IsDeleted]) AS C
        INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = C.[PurchaseOrderId]
        WHERE PO.[Status] <> ''Draft'')
        THROW 50000, N''04171|:|Purchase order lines can only be changed while the purchase order is Draft.'', 1;
END;
';

    -- INE.spStockItemConvertToVariants (new) (Procedures/INE/spStockItemConvertToVariants.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spStockItemConvertToVariants]
(
    @StockItemId INT,
    @VariantName NVARCHAR(50),
    @Sku NVARCHAR(30),
    @PriceAdder DECIMAL(19, 4) = 0,
    @Name NVARCHAR(150) = NULL,
    @VariantStockItemId INT = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OwnsTransaction BIT = 0;

    BEGIN TRY
        DECLARE @TenantId INT, @UserId UNIQUEIDENTIFIER, @Msg NVARCHAR(2048), @Rc INT, @MovementId BIGINT;
        SELECT @TenantId = SC.[DealerTenantId], @UserId = SC.[UserId] FROM [INE].[fxGetSessionContext]() AS SC;
        IF @TenantId IS NULL
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;
        SET @UserId = ISNULL(@UserId, ''E6872B58-52B2-415C-A32B-45805F95A70A'');

        SET @VariantName = NULLIF(LTRIM(RTRIM(@VariantName)), N'''');
        SET @Sku = UPPER(NULLIF(LTRIM(RTRIM(@Sku)), N''''));
        SET @Name = NULLIF(LTRIM(RTRIM(@Name)), N'''');
        SET @PriceAdder = ISNULL(@PriceAdder, 0);
        IF @VariantName IS NULL OR @Sku IS NULL
            THROW 50000, N''04195|:|Name the color (e.g. Black) and give its SKU.'', 1;
        IF @PriceAdder < 0
            THROW 50000, N''04195|:|The price adder cannot be negative.'', 1;

        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnsTransaction = 1;
        END;

        DECLARE @ParentSku NVARCHAR(30), @ParentName NVARCHAR(150), @ParentOfItem INT, @TrackingMode VARCHAR(10), @StandardCost DECIMAL(19, 4);
        SELECT @ParentSku = SI.[Sku], @ParentName = SI.[Name], @ParentOfItem = SI.[ParentStockItemId],
               @TrackingMode = SI.[TrackingMode], @StandardCost = SI.[StandardCost]
        FROM [INE].[StockItems] AS SI WITH (UPDLOCK, HOLDLOCK)
        WHERE SI.[StockItemID] = @StockItemId AND SI.[DealerTenantId] = @TenantId AND SI.[IsActive] = 1 AND SI.[IsDeleted] = 0;
        IF @ParentSku IS NULL
            THROW 50000, N''04112|:|The stock item was not found or is inactive.'', 1;
        IF @ParentOfItem IS NOT NULL
            THROW 50000, N''04191|:|This item is itself a variant; variants are one level deep.'', 1;

        -- Already converted to this color: nothing to do (idempotent).
        SELECT @VariantStockItemId = V.[StockItemID]
        FROM [INE].[StockItems] AS V
        WHERE V.[ParentStockItemId] = @StockItemId AND V.[VariantName] = @VariantName AND V.[IsDeleted] = 0;
        IF @VariantStockItemId IS NOT NULL
        BEGIN
            IF @OwnsTransaction = 1 COMMIT TRANSACTION;
            SELECT @VariantStockItemId AS [VariantStockItemID];
            RETURN 0;
        END;
        IF EXISTS (SELECT 1 FROM [INE].[StockItems] WHERE [ParentStockItemId] = @StockItemId AND [IsDeleted] = 0)
            THROW 50000, N''04194|:|This item already has variants. Add more colors to it instead of converting it.'', 1;
        IF EXISTS (SELECT 1 FROM [INE].[StockItems] WHERE [DealerTenantId] = @TenantId AND [Sku] = @Sku)
        BEGIN
            SET @Msg = CONCAT(N''04195|:|Another stock item already uses the SKU '', @Sku, N''.'');
            THROW 50000, @Msg, 1;
        END;

        SET @Name = ISNULL(@Name, LEFT(CONCAT(@ParentName, N'' - '', @VariantName), 150));
        DECLARE @Ref NVARCHAR(50) = LEFT(CONCAT(N''CONVERT '', @ParentSku, N'' > '', @Sku), 50);
        DECLARE @Notes NVARCHAR(2000) = CONCAT(N''Converted '', @ParentSku, N'' to colors: its stock is now '', @Sku, N'' ('', @VariantName, N'').'');

        /** 1. the variant, standalone until the item is empty (tr_StockItems_VariantGuard, 04192) */
        INSERT INTO [INE].[StockItems]
            ([DealerTenantId], [ProductId], [DefaultVendorId], [Sku], [Name], [Description], [Category], [TrackingMode],
             [UnitOfMeasure], [VendorSku], [StandardCost], [PriceAdder], [ModifiedById], [CreatedById])
        SELECT [DealerTenantId], [ProductId], [DefaultVendorId], @Sku, @Name, [Description], [Category], [TrackingMode],
               [UnitOfMeasure], NULL, [StandardCost], @PriceAdder, @UserId, @UserId
        FROM [INE].[StockItems] WHERE [StockItemID] = @StockItemId;
        SET @VariantStockItemId = SCOPE_IDENTITY();

        /** 2. release the open allocations (re-created on the variant in step 4) */
        DECLARE @Allocations TABLE
        (
            [AllocationID] BIGINT NOT NULL PRIMARY KEY, [LeadId] BIGINT NOT NULL, [LocationId] INT NOT NULL,
            [LotNumber] NVARCHAR(50) NULL, [Remaining] DECIMAL(19, 4) NOT NULL, [NeededByDate] DATE NULL, [Notes] NVARCHAR(500) NULL
        );
        INSERT INTO @Allocations ([AllocationID], [LeadId], [LocationId], [LotNumber], [Remaining], [NeededByDate], [Notes])
        SELECT A.[AllocationID], A.[LeadId], A.[LocationId], LO.[LotNumber], A.[QuantityAllocated] - A.[QuantityIssued], A.[NeededByDate], A.[Notes]
        FROM [INE].[Allocations] AS A WITH (UPDLOCK, HOLDLOCK)
        LEFT JOIN [INE].[Lots] AS LO ON LO.[LotID] = A.[LotId]
        WHERE A.[StockItemId] = @StockItemId AND A.[DealerTenantId] = @TenantId AND A.[Status] = ''Open'';

        IF EXISTS (SELECT 1 FROM @Allocations)
        BEGIN
            UPDATE A SET A.[Status] = ''Cancelled'', A.[ModifiedDate] = SYSDATETIMEOFFSET(), A.[ModifiedById] = @UserId
            FROM [INE].[Allocations] AS A INNER JOIN @Allocations AS X ON X.[AllocationID] = A.[AllocationID];

            UPDATE SB SET SB.[QuantityAllocated] = SB.[QuantityAllocated] - R.[Qty], SB.[ModifiedDate] = SYSDATETIMEOFFSET()
            FROM [INE].[StockBalances] AS SB
            INNER JOIN (SELECT A.[LocationId], A.[LotId], SUM(X.[Remaining]) AS [Qty]
                        FROM @Allocations AS X INNER JOIN [INE].[Allocations] AS A ON A.[AllocationID] = X.[AllocationID]
                        GROUP BY A.[LocationId], A.[LotId]) AS R
                ON R.[LocationId] = SB.[LocationId] AND ((SB.[LotId] IS NULL AND R.[LotId] IS NULL) OR SB.[LotId] = R.[LotId])
            WHERE SB.[StockItemId] = @StockItemId;
        END;

        /** 3. move the stock, one AdjustOut and one AdjustIn per stock-holding location */
        DECLARE @Locations TABLE ([LocationId] INT NOT NULL PRIMARY KEY);
        INSERT INTO @Locations ([LocationId])
        SELECT DISTINCT SB.[LocationId]
        FROM [INE].[StockBalances] AS SB
        INNER JOIN [INE].[Locations] AS L ON L.[LocationID] = SB.[LocationId]
        INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
        WHERE SB.[StockItemId] = @StockItemId AND SB.[QuantityOnHand] > 0 AND LT.[IsStockHolding] = 1;

        DECLARE @LocationId INT = (SELECT MIN([LocationId]) FROM @Locations);
        WHILE @LocationId IS NOT NULL
        BEGIN
            DECLARE @OutLines NVARCHAR(MAX), @InLines NVARCHAR(MAX), @Json NVARCHAR(MAX);
            DECLARE @Serials TABLE ([SerialUnitID] BIGINT NOT NULL PRIMARY KEY, [SerialNumber] NVARCHAR(60) NOT NULL, [UnitCost] DECIMAL(19, 4) NULL);
            DELETE FROM @Serials;
            IF @TrackingMode = ''Serial''
                INSERT INTO @Serials ([SerialUnitID], [SerialNumber], [UnitCost])
                SELECT SU.[SerialUnitID], SU.[SerialNumber], SU.[UnitCost]
                FROM [INE].[SerialUnits] AS SU
                WHERE SU.[StockItemId] = @StockItemId AND SU.[CurrentLocationId] = @LocationId;

            SET @OutLines = CASE WHEN @TrackingMode = ''Serial''
                THEN (SELECT @StockItemId AS [stockItemId], S.[SerialUnitID] AS [serialUnitId] FROM @Serials AS S FOR JSON PATH)
                ELSE (SELECT @StockItemId AS [stockItemId], SB.[QuantityOnHand] AS [quantity], SB.[LotId] AS [lotId]
                      FROM [INE].[StockBalances] AS SB
                      WHERE SB.[StockItemId] = @StockItemId AND SB.[LocationId] = @LocationId AND SB.[QuantityOnHand] > 0
                      FOR JSON PATH) END;
            SET @InLines = CASE WHEN @TrackingMode = ''Serial''
                THEN (SELECT @VariantStockItemId AS [stockItemId], JSON_QUERY(CONCAT(N''["'', STRING_ESCAPE(S.[SerialNumber], ''json''), N''"]'')) AS [serialNumbers],
                             ISNULL(S.[UnitCost], @StandardCost) AS [unitCost]
                      FROM @Serials AS S FOR JSON PATH)
                ELSE (SELECT @VariantStockItemId AS [stockItemId], SB.[QuantityOnHand] AS [quantity], LO.[LotNumber] AS [lotNumber],
                             @StandardCost AS [unitCost]
                      FROM [INE].[StockBalances] AS SB
                      LEFT JOIN [INE].[Lots] AS LO ON LO.[LotID] = SB.[LotId]
                      WHERE SB.[StockItemId] = @StockItemId AND SB.[LocationId] = @LocationId AND SB.[QuantityOnHand] > 0
                      FOR JSON PATH) END;

            IF @OutLines IS NOT NULL
            BEGIN
                SET @Json = (SELECT ''AdjustOut'' AS [movementType], @LocationId AS [fromLocationId], @Ref AS [reference], @Notes AS [notes],
                                    JSON_QUERY(@OutLines) AS [lines] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
                EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @MovementId OUTPUT, @ReturnResult = 0;
                IF @Rc <> 0 THROW 50000, N''04196|:|The stock could not be moved off the item.'', 1;

                SET @Json = (SELECT ''AdjustIn'' AS [movementType], @LocationId AS [toLocationId], @Ref AS [reference], @Notes AS [notes],
                                    JSON_QUERY(@InLines) AS [lines] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
                EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @MovementId OUTPUT, @ReturnResult = 0;
                IF @Rc <> 0 THROW 50000, N''04196|:|The stock could not be moved onto the variant.'', 1;

                -- The item''s units are not missing: they now belong to the variant under the same numbers.
                UPDATE SU SET SU.[Status] = ''Voided'', SU.[ModifiedDate] = SYSDATETIMEOFFSET(), SU.[ModifiedById] = @UserId
                FROM [INE].[SerialUnits] AS SU INNER JOIN @Serials AS S ON S.[SerialUnitID] = SU.[SerialUnitID];
            END;

            SET @LocationId = (SELECT MIN([LocationId]) FROM @Locations WHERE [LocationId] > @LocationId);
        END;

        -- Lot details follow the lot number.
        UPDATE VL SET VL.[ManufacturedDate] = PL.[ManufacturedDate], VL.[ExpirationDate] = PL.[ExpirationDate], VL.[Notes] = PL.[Notes]
        FROM [INE].[Lots] AS VL
        INNER JOIN [INE].[Lots] AS PL ON PL.[StockItemId] = @StockItemId AND PL.[LotNumber] = VL.[LotNumber]
        WHERE VL.[StockItemId] = @VariantStockItemId;

        /** 4. the allocations again, on the variant */
        IF EXISTS (SELECT 1 FROM @Allocations)
        BEGIN
            DECLARE @NewAllocations TABLE ([LocationId] INT NOT NULL, [LotId] INT NULL, [Qty] DECIMAL(19, 4) NOT NULL);
            INSERT INTO [INE].[Allocations]
                ([DealerTenantId], [LeadId], [StockItemId], [LocationId], [LotId], [QuantityAllocated], [NeededByDate], [Notes], [ModifiedById], [CreatedById])
            OUTPUT INSERTED.[LocationId], INSERTED.[LotId], INSERTED.[QuantityAllocated] INTO @NewAllocations ([LocationId], [LotId], [Qty])
            SELECT @TenantId, X.[LeadId], @VariantStockItemId, X.[LocationId], VL.[LotID], X.[Remaining], X.[NeededByDate], X.[Notes], @UserId, @UserId
            FROM @Allocations AS X
            LEFT JOIN [INE].[Lots] AS VL ON VL.[StockItemId] = @VariantStockItemId AND VL.[LotNumber] = X.[LotNumber]
            WHERE X.[Remaining] > 0;

            UPDATE SB SET SB.[QuantityAllocated] = SB.[QuantityAllocated] + R.[Qty], SB.[ModifiedDate] = SYSDATETIMEOFFSET()
            FROM [INE].[StockBalances] AS SB
            INNER JOIN (SELECT [LocationId], [LotId], SUM([Qty]) AS [Qty] FROM @NewAllocations GROUP BY [LocationId], [LotId]) AS R
                ON R.[LocationId] = SB.[LocationId] AND ((SB.[LotId] IS NULL AND R.[LotId] IS NULL) OR SB.[LotId] = R.[LotId])
            WHERE SB.[StockItemId] = @VariantStockItemId;
        END;

        /** 5. reorder rules and open purchase order lines */
        UPDATE [INE].[StockLevels] SET [StockItemId] = @VariantStockItemId, [ModifiedDate] = SYSDATETIMEOFFSET(), [ModifiedById] = @UserId
        WHERE [StockItemId] = @StockItemId;

        -- Submitted lines are locked (tr_PurchaseOrderLines_GuardStatus); this key lets only their item change.
        EXEC sys.sp_set_session_context @key = N''INE.ConvertStockItemId'', @value = @StockItemId;
        UPDATE POL SET POL.[StockItemId] = @VariantStockItemId, POL.[ModifiedDate] = SYSDATETIMEOFFSET(), POL.[ModifiedById] = @UserId
        FROM [INE].[PurchaseOrderLines] AS POL
        INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
        WHERE POL.[StockItemId] = @StockItemId AND POL.[IsDeleted] = 0 AND PO.[IsDeleted] = 0 AND PO.[DealerTenantId] = @TenantId
          AND PO.[Status] IN (''Draft'', ''Submitted'', ''PartiallyReceived'') AND POL.[QuantityOrdered] > POL.[QuantityReceived];
        EXEC sys.sp_set_session_context @key = N''INE.ConvertStockItemId'', @value = NULL;

        /** 6. the item becomes the variant''s parent (tr_StockItems_VariantGuard checks it is empty) */
        UPDATE [INE].[StockItems] SET [ParentStockItemId] = @StockItemId, [VariantName] = @VariantName,
               [ModifiedDate] = SYSDATETIMEOFFSET(), [ModifiedById] = @UserId
        WHERE [StockItemID] = @VariantStockItemId;

        INSERT INTO [INE].[StockItemVariantAttributes] ([DealerTenantId], [StockItemId], [AttributeName], [AttributeValue], [ModifiedById], [CreatedById])
        VALUES (@TenantId, @VariantStockItemId, N''Color'', @VariantName, @UserId, @UserId);

        IF @OwnsTransaction = 1
            COMMIT TRANSACTION;

        SELECT @VariantStockItemId AS [VariantStockItemID];
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @OwnsTransaction = 1 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        EXEC sys.sp_set_session_context @key = N''INE.ConvertStockItemId'', @value = NULL;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
';

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'INE.spStockItemConvertToVariants, variant guards for it, MAC.QuoteLines VariantChosenBy/Date/SignatureId',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success])
    VALUES (N'20261120_0300_AddINE_ConvertToVariantsAndQuoteColorChoice', N'FAILED: ' + LEFT(@ErrorMessage, 490), 0);

    PRINT 'Migration failed: ' + @ErrorMessage;
    THROW;
END CATCH;
GO
