/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: INE
 * Name: spStockItemConvertToVariants
 * Description: Turns an existing stock item into a parent with colors (part variants) in one
 *              transaction, so staff do not have to empty it by hand first:
 *                1. creates the first variant (@VariantName, @Sku, optional @PriceAdder) with the
 *                   item's product, tracking, unit, category, description, vendor and cost
 *                2. releases the item's open allocations
 *                3. at every stock-holding location, posts an AdjustOut of the item and an AdjustIn
 *                   of the variant (same quantities, lots by number, serial numbers), so the ledger
 *                   keeps the history; the item's serial units become Voided, its new units belong
 *                   to the variant
 *                4. re-creates the open allocations on the variant (same lead, location, lot number,
 *                   remaining quantity, date and notes)
 *                5. moves the reorder rules and the open purchase order lines to the variant
 *                6. links the variant to the item (ParentStockItemId) and gives it Color = name
 *              Stock already installed at jobs or sent to vendors stays on the item as history.
 *              Afterwards more colors are added the normal way (INE.StockItems rows with a parent).
 *              Idempotent: called again with the same color once the item is converted, it does
 *              nothing and returns that variant. An item that already has other variants is refused.
 *              Error codes: 04100 no tenant, 04112 item not found or inactive, 04191 the item is a
 *              variant, 04194 it already has variants, 04195 the SKU or name is invalid or in use.
 * Parameters:
 *   @StockItemId        the item to convert (of the session's tenant)
 *   @VariantName        the color of the stock it holds now, e.g. Black
 *   @Sku                the variant's SKU, e.g. LP-100-BLK (unique in the tenant)
 *   @PriceAdder         customer-facing extra per unit (default 0)
 *   @Name               the variant's item name; default "{item name} - {variant name}"
 *   @VariantStockItemId OUTPUT, the variant
 * Returns: 0 on success (and a one-row result set with VariantStockItemID); -1 on error
 * Dependencies: INE.fxGetSessionContext, INE.StockItems, INE.StockItemVariantAttributes,
 *               INE.StockBalances, INE.Locations, INE.LocationTypes, INE.Lots, INE.SerialUnits,
 *               INE.Allocations, INE.StockLevels, INE.PurchaseOrders, INE.PurchaseOrderLines,
 *               INE.spMovementPost, INE.tr_PurchaseOrderLines_GuardStatus (session key
 *               INE.ConvertStockItemId lets it move submitted PO lines)
 * Migrations: 20261120_0300_AddINE_ConvertToVariantsAndQuoteColorChoice
 * Author: Andres Sosa
 * Created: 2026-11-19
 * Example:
 *   DECLARE @Id INT;
 *   EXEC [INE].[spStockItemConvertToVariants] @StockItemId = 3, @VariantName = N'Black',
 *        @Sku = N'LP-100-BLK', @VariantStockItemId = @Id OUTPUT;
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [INE].[spStockItemConvertToVariants]
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
            THROW 50000, N'04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.', 1;
        SET @UserId = ISNULL(@UserId, 'E6872B58-52B2-415C-A32B-45805F95A70A');

        SET @VariantName = NULLIF(LTRIM(RTRIM(@VariantName)), N'');
        SET @Sku = UPPER(NULLIF(LTRIM(RTRIM(@Sku)), N''));
        SET @Name = NULLIF(LTRIM(RTRIM(@Name)), N'');
        SET @PriceAdder = ISNULL(@PriceAdder, 0);
        IF @VariantName IS NULL OR @Sku IS NULL
            THROW 50000, N'04195|:|Name the color (e.g. Black) and give its SKU.', 1;
        IF @PriceAdder < 0
            THROW 50000, N'04195|:|The price adder cannot be negative.', 1;

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
            THROW 50000, N'04112|:|The stock item was not found or is inactive.', 1;
        IF @ParentOfItem IS NOT NULL
            THROW 50000, N'04191|:|This item is itself a variant; variants are one level deep.', 1;

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
            THROW 50000, N'04194|:|This item already has variants. Add more colors to it instead of converting it.', 1;
        IF EXISTS (SELECT 1 FROM [INE].[StockItems] WHERE [DealerTenantId] = @TenantId AND [Sku] = @Sku)
        BEGIN
            SET @Msg = CONCAT(N'04195|:|Another stock item already uses the SKU ', @Sku, N'.');
            THROW 50000, @Msg, 1;
        END;

        SET @Name = ISNULL(@Name, LEFT(CONCAT(@ParentName, N' - ', @VariantName), 150));
        DECLARE @Ref NVARCHAR(50) = LEFT(CONCAT(N'CONVERT ', @ParentSku, N' > ', @Sku), 50);
        DECLARE @Notes NVARCHAR(2000) = CONCAT(N'Converted ', @ParentSku, N' to colors: its stock is now ', @Sku, N' (', @VariantName, N').');

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
        WHERE A.[StockItemId] = @StockItemId AND A.[DealerTenantId] = @TenantId AND A.[Status] = 'Open';

        IF EXISTS (SELECT 1 FROM @Allocations)
        BEGIN
            UPDATE A SET A.[Status] = 'Cancelled', A.[ModifiedDate] = SYSDATETIMEOFFSET(), A.[ModifiedById] = @UserId
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
            IF @TrackingMode = 'Serial'
                INSERT INTO @Serials ([SerialUnitID], [SerialNumber], [UnitCost])
                SELECT SU.[SerialUnitID], SU.[SerialNumber], SU.[UnitCost]
                FROM [INE].[SerialUnits] AS SU
                WHERE SU.[StockItemId] = @StockItemId AND SU.[CurrentLocationId] = @LocationId;

            SET @OutLines = CASE WHEN @TrackingMode = 'Serial'
                THEN (SELECT @StockItemId AS [stockItemId], S.[SerialUnitID] AS [serialUnitId] FROM @Serials AS S FOR JSON PATH)
                ELSE (SELECT @StockItemId AS [stockItemId], SB.[QuantityOnHand] AS [quantity], SB.[LotId] AS [lotId]
                      FROM [INE].[StockBalances] AS SB
                      WHERE SB.[StockItemId] = @StockItemId AND SB.[LocationId] = @LocationId AND SB.[QuantityOnHand] > 0
                      FOR JSON PATH) END;
            SET @InLines = CASE WHEN @TrackingMode = 'Serial'
                THEN (SELECT @VariantStockItemId AS [stockItemId], JSON_QUERY(CONCAT(N'["', STRING_ESCAPE(S.[SerialNumber], 'json'), N'"]')) AS [serialNumbers],
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
                SET @Json = (SELECT 'AdjustOut' AS [movementType], @LocationId AS [fromLocationId], @Ref AS [reference], @Notes AS [notes],
                                    JSON_QUERY(@OutLines) AS [lines] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
                EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @MovementId OUTPUT, @ReturnResult = 0;
                IF @Rc <> 0 THROW 50000, N'04196|:|The stock could not be moved off the item.', 1;

                SET @Json = (SELECT 'AdjustIn' AS [movementType], @LocationId AS [toLocationId], @Ref AS [reference], @Notes AS [notes],
                                    JSON_QUERY(@InLines) AS [lines] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
                EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @MovementId OUTPUT, @ReturnResult = 0;
                IF @Rc <> 0 THROW 50000, N'04196|:|The stock could not be moved onto the variant.', 1;

                -- The item's units are not missing: they now belong to the variant under the same numbers.
                UPDATE SU SET SU.[Status] = 'Voided', SU.[ModifiedDate] = SYSDATETIMEOFFSET(), SU.[ModifiedById] = @UserId
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
        EXEC sys.sp_set_session_context @key = N'INE.ConvertStockItemId', @value = @StockItemId;
        UPDATE POL SET POL.[StockItemId] = @VariantStockItemId, POL.[ModifiedDate] = SYSDATETIMEOFFSET(), POL.[ModifiedById] = @UserId
        FROM [INE].[PurchaseOrderLines] AS POL
        INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
        WHERE POL.[StockItemId] = @StockItemId AND POL.[IsDeleted] = 0 AND PO.[IsDeleted] = 0 AND PO.[DealerTenantId] = @TenantId
          AND PO.[Status] IN ('Draft', 'Submitted', 'PartiallyReceived') AND POL.[QuantityOrdered] > POL.[QuantityReceived];
        EXEC sys.sp_set_session_context @key = N'INE.ConvertStockItemId', @value = NULL;

        /** 6. the item becomes the variant's parent (tr_StockItems_VariantGuard checks it is empty) */
        UPDATE [INE].[StockItems] SET [ParentStockItemId] = @StockItemId, [VariantName] = @VariantName,
               [ModifiedDate] = SYSDATETIMEOFFSET(), [ModifiedById] = @UserId
        WHERE [StockItemID] = @VariantStockItemId;

        INSERT INTO [INE].[StockItemVariantAttributes] ([DealerTenantId], [StockItemId], [AttributeName], [AttributeValue], [ModifiedById], [CreatedById])
        VALUES (@TenantId, @VariantStockItemId, N'Color', @VariantName, @UserId, @UserId);

        IF @OwnsTransaction = 1
            COMMIT TRANSACTION;

        SELECT @VariantStockItemId AS [VariantStockItemID];
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @OwnsTransaction = 1 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        EXEC sys.sp_set_session_context @key = N'INE.ConvertStockItemId', @value = NULL;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N'{"ERROR_NUMBER":%'
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
GO
