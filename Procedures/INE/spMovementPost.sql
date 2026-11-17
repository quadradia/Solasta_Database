/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: INE
 * Name: spMovementPost
 * Description: The only way stock moves. Validates and posts one movement to the
 *              append-only ledger (INE.Movements + INE.MovementLines) and, in the same
 *              transaction, updates every projection that depends on it:
 *                INE.StockBalances       on-hand and allocated per location/item/lot
 *                INE.SerialUnits         current location and status of each unit
 *                INE.Lots / SerialUnits  created on the fly by Receive and AdjustIn
 *                INE.PurchaseOrderLines  QuantityReceived (Receive, and its Reversal)
 *                INE.PurchaseOrders      Status (Submitted / PartiallyReceived / Received)
 *                INE.Allocations         QuantityIssued and Status (IssueToJob)
 *              Rules enforced (the legacy INE enforced none of these):
 *                - tenant comes from SESSION_CONTEXT; every location, item, lot, serial,
 *                  PO line and allocation must belong to it
 *                - from/to locations must match the movement type (INE.MovementTypes)
 *                - stock never goes below zero and allocated stock is not available
 *                - a serial unit must be at the from location to leave it
 *                - a PO line cannot be received past its ordered quantity, and only
 *                  while the PO is Submitted or PartiallyReceived
 *              A Reversal (normally posted through INE.spMovementReverse) takes its
 *              locations, lead and lines from the movement it reverses; anything else
 *              the caller sends for it is ignored.
 * Dependencies: INE.fxGetSessionContext, INE.MovementTypes, INE.Locations,
 *               INE.LocationTypes, INE.StockItems, INE.Lots, INE.SerialUnits,
 *               INE.Receipts, INE.StockCounts, INE.PurchaseOrders,
 *               INE.PurchaseOrderLines, INE.Allocations, INE.Movements,
 *               INE.MovementLines, INE.StockBalances, QAL.Leads, GEN.spExceptionsThrown
 * Parameters:
 *   @MovementJson - the movement (shape below)
 *   @MovementId   - OUTPUT, the new INE.Movements row
 *   @ReturnResult - 1 (default) also returns MovementID as a result set; INE procedures
 *                   that call this one pass 0
 *   JSON shape (camelCase; omit what does not apply):
 *   {
 *     "movementType": "Transfer",          -- INE.MovementTypes.Code
 *     "fromLocationId": 1, "toLocationId": 4,
 *     "leadId": 1042,                      -- defaults from a Job location
 *     "receiptId": 7,                      -- required for Receive
 *     "stockCountId": null, "reversesMovementId": null,
 *     "movementDate": "2026-11-17T09:30:00-07:00",
 *     "reference": "VAN-03 restock", "notes": "...",
 *     "lines": [
 *       { "stockItemId": 3, "quantity": 164.5 },                        -- Quantity item
 *       { "stockItemId": 5, "quantity": 2, "lotNumber": "R-2611-07" },  -- Lot item
 *       { "stockItemId": 9, "serialNumbers": ["C8-0001", "C8-0002"] },  -- Serial item
 *       { "stockItemId": 9, "serialUnitId": 12 },                       -- Serial by id
 *       { "stockItemId": 3, "quantity": 100, "purchaseOrderLineId": 21, "unitCost": 2.15 },
 *       { "stockItemId": 3, "quantity": 40, "allocationId": 6 }
 *     ]
 *   }
 * Returns: 0 on success (and a one-row result set with MovementID); -1 on error
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Example:
 *   DECLARE @Id BIGINT;
 *   EXEC [INE].[spMovementPost] @MovementJson = N'{"movementType":"Transfer","fromLocationId":1,
 *        "toLocationId":4,"lines":[{"stockItemId":3,"quantity":50}]}', @MovementId = @Id OUTPUT;
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [INE].[spMovementPost]
(
    @MovementJson NVARCHAR(MAX),
    @MovementId BIGINT = NULL OUTPUT,
    @ReturnResult BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OwnsTransaction BIT = 0;

    BEGIN TRY
        /** CONTEXT */
        DECLARE @TenantId INT, @UserId UNIQUEIDENTIFIER, @Msg NVARCHAR(2048);
        SELECT @TenantId = SC.[DealerTenantId], @UserId = SC.[UserId] FROM [INE].[fxGetSessionContext]() AS SC;
        IF @TenantId IS NULL
            THROW 50000, N'04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.', 1;
        SET @UserId = ISNULL(@UserId, 'E6872B58-52B2-415C-A32B-45805F95A70A');

        IF @MovementJson IS NULL OR ISJSON(@MovementJson) <> 1
            THROW 50000, N'04101|:|The movement is not valid JSON.', 1;

        /** HEADER */
        DECLARE @TypeCode VARCHAR(20), @FromLocationId INT, @ToLocationId INT, @LeadId BIGINT
            , @ReceiptId BIGINT, @StockCountId BIGINT, @ReversesMovementId BIGINT
            , @Reference NVARCHAR(50), @Notes NVARCHAR(2000), @MovementDate DATETIMEOFFSET(7);

        SELECT
            @TypeCode = H.[movementType]
            , @FromLocationId = H.[fromLocationId]
            , @ToLocationId = H.[toLocationId]
            , @LeadId = H.[leadId]
            , @ReceiptId = H.[receiptId]
            , @StockCountId = H.[stockCountId]
            , @ReversesMovementId = H.[reversesMovementId]
            , @Reference = H.[reference]
            , @Notes = H.[notes]
            , @MovementDate = ISNULL(H.[movementDate], SYSDATETIMEOFFSET())
        FROM OPENJSON(@MovementJson)
        WITH (
            [movementType] VARCHAR(20) N'$.movementType'
            , [fromLocationId] INT N'$.fromLocationId'
            , [toLocationId] INT N'$.toLocationId'
            , [leadId] BIGINT N'$.leadId'
            , [receiptId] BIGINT N'$.receiptId'
            , [stockCountId] BIGINT N'$.stockCountId'
            , [reversesMovementId] BIGINT N'$.reversesMovementId'
            , [reference] NVARCHAR(50) N'$.reference'
            , [notes] NVARCHAR(2000) N'$.notes'
            , [movementDate] DATETIMEOFFSET(7) N'$.movementDate'
        ) AS H;

        DECLARE @MovementTypeId INT, @RequiresFrom BIT, @RequiresTo BIT, @RequiresLead BIT
            , @FromTypeRule VARCHAR(20), @ToTypeRule VARCHAR(20);
        SELECT
            @MovementTypeId = MT.[MovementTypeID]
            , @RequiresFrom = MT.[RequiresFrom]
            , @RequiresTo = MT.[RequiresTo]
            , @RequiresLead = MT.[RequiresLead]
            , @FromTypeRule = MT.[FromLocationTypeCode]
            , @ToTypeRule = MT.[ToLocationTypeCode]
        FROM [INE].[MovementTypes] AS MT
        WHERE MT.[Code] = @TypeCode AND MT.[IsActive] = 1 AND MT.[IsDeleted] = 0;

        IF @MovementTypeId IS NULL
        BEGIN
            SET @Msg = CONCAT(N'04102|:|Unknown movement type "', @TypeCode, N'".');
            THROW 50000, @Msg, 1;
        END;

        DECLARE @IsReversal BIT = CASE WHEN @TypeCode = 'Reversal' THEN 1 ELSE 0 END;
        IF (@IsReversal = 1 AND @ReversesMovementId IS NULL) OR (@IsReversal = 0 AND @ReversesMovementId IS NOT NULL)
            THROW 50000, N'04103|:|A Reversal names the movement it reverses (reversesMovementId), and only a Reversal can.', 1;

        /** REVERSAL: everything comes from the original; caller-supplied lines and locations are ignored */
        IF @IsReversal = 1
        BEGIN
            DECLARE @OriginalType VARCHAR(20), @OriginalReference NVARCHAR(50);
            SELECT @OriginalType = OMT.[Code], @FromLocationId = OM.[ToLocationId], @ToLocationId = OM.[FromLocationId],
                   @LeadId = OM.[LeadId], @OriginalReference = OM.[Reference]
            FROM [INE].[Movements] AS OM
            INNER JOIN [INE].[MovementTypes] AS OMT ON OMT.[MovementTypeID] = OM.[MovementTypeId]
            WHERE OM.[MovementID] = @ReversesMovementId AND OM.[DealerTenantId] = @TenantId;

            IF @OriginalType IS NULL
                THROW 50000, N'04130|:|The movement to reverse was not found.', 1;
            IF @OriginalType = 'Reversal'
                THROW 50000, N'04131|:|A reversal cannot be reversed; post a new movement instead.', 1;
            IF EXISTS (SELECT 1 FROM [INE].[Movements] WHERE [ReversesMovementId] = @ReversesMovementId)
                THROW 50000, N'04132|:|The movement has already been reversed.', 1;

            SET @Reference = ISNULL(@Reference, @OriginalReference);
            SET @ReceiptId = NULL;
            SET @StockCountId = NULL;
            SET @MovementJson = JSON_MODIFY(@MovementJson, N'$.lines', JSON_QUERY(ISNULL((
                SELECT
                    OML.[StockItemId] AS [stockItemId]
                    , OML.[LotId] AS [lotId]
                    , OML.[SerialUnitId] AS [serialUnitId]
                    , OML.[Quantity] AS [quantity]
                    , OML.[UnitCost] AS [unitCost]
                    , OML.[PurchaseOrderLineId] AS [purchaseOrderLineId]
                    , OML.[AllocationId] AS [allocationId]
                FROM [INE].[MovementLines] AS OML
                WHERE OML.[MovementId] = @ReversesMovementId
                ORDER BY OML.[MovementLineID]
                FOR JSON PATH), N'[]')));
        END;

        /** LOCATIONS */
        IF @IsReversal = 0
        BEGIN
            IF (@RequiresFrom = 1 AND @FromLocationId IS NULL) OR (@RequiresFrom = 0 AND @FromLocationId IS NOT NULL)
               OR (@RequiresTo = 1 AND @ToLocationId IS NULL) OR (@RequiresTo = 0 AND @ToLocationId IS NOT NULL)
            BEGIN
                SET @Msg = CONCAT(N'04104|:|A ', @TypeCode, N' movement ',
                    CASE WHEN @RequiresFrom = 1 THEN N'needs' ELSE N'cannot have' END, N' a from location and ',
                    CASE WHEN @RequiresTo = 1 THEN N'needs' ELSE N'cannot have' END, N' a to location.');
                THROW 50000, @Msg, 1;
            END;
        END
        ELSE IF @FromLocationId IS NULL AND @ToLocationId IS NULL
            THROW 50000, N'04104|:|A movement needs a from or a to location.', 1;

        IF @FromLocationId IS NOT NULL AND @FromLocationId = @ToLocationId
            THROW 50000, N'04105|:|The from and to locations are the same.', 1;

        DECLARE @FromTypeCode VARCHAR(20), @FromStockHolding BIT, @FromLeadId BIGINT
            , @ToTypeCode VARCHAR(20), @ToStockHolding BIT, @ToLeadId BIGINT;

        IF @FromLocationId IS NOT NULL
        BEGIN
            SELECT @FromTypeCode = LT.[Code], @FromStockHolding = LT.[IsStockHolding], @FromLeadId = L.[LeadId]
            FROM [INE].[Locations] AS L
            INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
            WHERE L.[LocationID] = @FromLocationId AND L.[DealerTenantId] = @TenantId
              AND L.[IsActive] = 1 AND L.[IsDeleted] = 0;
            IF @FromTypeCode IS NULL
            BEGIN
                SET @Msg = CONCAT(N'04106|:|From location ', @FromLocationId, N' was not found.');
                THROW 50000, @Msg, 1;
            END;
        END;

        IF @ToLocationId IS NOT NULL
        BEGIN
            SELECT @ToTypeCode = LT.[Code], @ToStockHolding = LT.[IsStockHolding], @ToLeadId = L.[LeadId]
            FROM [INE].[Locations] AS L
            INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
            WHERE L.[LocationID] = @ToLocationId AND L.[DealerTenantId] = @TenantId
              AND L.[IsActive] = 1 AND L.[IsDeleted] = 0;
            IF @ToTypeCode IS NULL
            BEGIN
                SET @Msg = CONCAT(N'04106|:|To location ', @ToLocationId, N' was not found.');
                THROW 50000, @Msg, 1;
            END;
        END;

        -- A NULL rule means any stock-holding location; otherwise the exact location type.
        IF @IsReversal = 0 AND (
               (@FromLocationId IS NOT NULL AND ((@FromTypeRule IS NULL AND @FromStockHolding = 0) OR @FromTypeCode <> @FromTypeRule))
            OR (@ToLocationId IS NOT NULL AND ((@ToTypeRule IS NULL AND @ToStockHolding = 0) OR @ToTypeCode <> @ToTypeRule)))
        BEGIN
            SET @Msg = CONCAT(N'04107|:|A ', @TypeCode, N' movement cannot go from a ', ISNULL(@FromTypeCode, N'(none)'),
                              N' location to a ', ISNULL(@ToTypeCode, N'(none)'), N' location.');
            THROW 50000, @Msg, 1;
        END;

        /** JOB (LEAD) */
        DECLARE @LocationLeadId BIGINT = COALESCE(@ToLeadId, @FromLeadId);
        IF @LeadId IS NULL SET @LeadId = @LocationLeadId;
        IF @LocationLeadId IS NOT NULL AND @LeadId <> @LocationLeadId
            THROW 50000, N'04108|:|The lead does not match the job location.', 1;
        IF @RequiresLead = 1 AND @LeadId IS NULL
        BEGIN
            SET @Msg = CONCAT(N'04108|:|A ', @TypeCode, N' movement needs a lead (job).');
            THROW 50000, @Msg, 1;
        END;
        IF @LeadId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [QAL].[Leads] AS LD
                                               WHERE LD.[LeadID] = @LeadId AND LD.[DealerTenantId] = @TenantId)
            THROW 50000, N'04108|:|The lead was not found.', 1;

        /** RECEIPT / COUNT / REVERSED MOVEMENT */
        IF @TypeCode = 'Receive' AND @ReceiptId IS NULL
            THROW 50000, N'04109|:|A Receive movement needs a receipt (use INE.spReceiptPost).', 1;
        IF @ReceiptId IS NOT NULL
        BEGIN
            IF @TypeCode <> 'Receive'
                THROW 50000, N'04109|:|Only a Receive movement can name a receipt.', 1;
            IF NOT EXISTS (SELECT 1 FROM [INE].[Receipts] AS R
                           WHERE R.[ReceiptID] = @ReceiptId AND R.[DealerTenantId] = @TenantId
                             AND R.[LocationId] = @ToLocationId AND R.[IsDeleted] = 0)
                THROW 50000, N'04109|:|The receipt was not found or is for another location.', 1;
        END;
        IF @StockCountId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[StockCounts] AS SC
                                                     WHERE SC.[StockCountID] = @StockCountId AND SC.[DealerTenantId] = @TenantId)
            THROW 50000, N'04110|:|The stock count was not found.', 1;

        -- The transaction opens here, before the line checks, so the UPDLOCKs taken on
        -- serial units, PO lines and allocations hold until the movement is written.
        -- (Opened after them, two posts could both see a serial at the from location.)
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnsTransaction = 1;
        END;

        /** LINES */
        DECLARE @Lines TABLE
        (
            [RowNo] INT IDENTITY(1,1) NOT NULL PRIMARY KEY
            , [StockItemId] INT NULL
            , [TrackingMode] VARCHAR(10) NULL
            , [LotId] INT NULL
            , [LotNumber] NVARCHAR(50) NULL
            , [SerialUnitId] BIGINT NULL
            , [SerialNumber] NVARCHAR(60) NULL
            , [Quantity] DECIMAL(19, 4) NULL
            , [UnitCost] DECIMAL(19, 4) NULL
            , [PurchaseOrderLineId] BIGINT NULL
            , [AllocationId] BIGINT NULL
        );

        INSERT INTO @Lines ([StockItemId], [LotId], [LotNumber], [SerialUnitId], [SerialNumber], [Quantity], [UnitCost], [PurchaseOrderLineId], [AllocationId])
        SELECT
            JL.[stockItemId]
            , JL.[lotId]
            , NULLIF(LTRIM(RTRIM(JL.[lotNumber])), N'')
            , JL.[serialUnitId]
            , NULLIF(LTRIM(RTRIM(SN.[value])), N'')
            -- One line per serial number; a serial line is always quantity 1.
            , CASE WHEN SN.[value] IS NOT NULL OR JL.[serialUnitId] IS NOT NULL THEN 1 ELSE JL.[quantity] END
            , JL.[unitCost]
            , JL.[purchaseOrderLineId]
            , JL.[allocationId]
        FROM OPENJSON(@MovementJson, N'$.lines')
        WITH (
            [stockItemId] INT N'$.stockItemId'
            , [quantity] DECIMAL(19, 4) N'$.quantity'
            , [lotId] INT N'$.lotId'
            , [lotNumber] NVARCHAR(50) N'$.lotNumber'
            , [serialUnitId] BIGINT N'$.serialUnitId'
            , [serialNumbers] NVARCHAR(MAX) N'$.serialNumbers' AS JSON
            , [unitCost] DECIMAL(19, 4) N'$.unitCost'
            , [purchaseOrderLineId] BIGINT N'$.purchaseOrderLineId'
            , [allocationId] BIGINT N'$.allocationId'
        ) AS JL
        OUTER APPLY OPENJSON(JL.[serialNumbers]) AS SN;

        IF NOT EXISTS (SELECT 1 FROM @Lines)
            THROW 50000, N'04111|:|A movement needs at least one line.', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [Quantity] IS NULL OR [Quantity] <= 0)
            THROW 50000, N'04111|:|Every line needs a quantity greater than zero.', 1;

        -- Items
        UPDATE LN SET LN.[TrackingMode] = SI.[TrackingMode]
        FROM @Lines AS LN
        INNER JOIN [INE].[StockItems] AS SI
            ON SI.[StockItemID] = LN.[StockItemId] AND SI.[DealerTenantId] = @TenantId
           AND SI.[IsDeleted] = 0 AND (SI.[IsActive] = 1 OR @IsReversal = 1);

        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] IS NULL)
        BEGIN
            SELECT TOP (1) @Msg = CONCAT(N'04112|:|Stock item ', ISNULL(CAST([StockItemId] AS NVARCHAR(20)), N'(missing)'), N' was not found or is inactive.')
            FROM @Lines WHERE [TrackingMode] IS NULL;
            THROW 50000, @Msg, 1;
        END;

        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = 'Serial' AND [SerialUnitId] IS NULL AND [SerialNumber] IS NULL)
            THROW 50000, N'04113|:|Serial-tracked items need serialNumbers or a serialUnitId.', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] <> 'Serial' AND ([SerialUnitId] IS NOT NULL OR [SerialNumber] IS NOT NULL))
            THROW 50000, N'04113|:|Only serial-tracked items can name serial numbers.', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = 'Quantity' AND ([LotId] IS NOT NULL OR [LotNumber] IS NOT NULL))
            THROW 50000, N'04114|:|Quantity-tracked items do not have lots.', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = 'Lot' AND [LotId] IS NULL AND [LotNumber] IS NULL)
            THROW 50000, N'04114|:|Lot-tracked items need a lotId or lotNumber.', 1;

        -- Stock enters the books only when there is no from location (Receive, AdjustIn,
        -- or the reversal of a movement that took it off the books).
        DECLARE @IsInbound BIT = CASE WHEN @FromLocationId IS NULL THEN 1 ELSE 0 END;

        -- Lots: resolve numbers; an inbound movement may create new lots.
        UPDATE LN SET LN.[LotId] = LO.[LotID]
        FROM @Lines AS LN
        INNER JOIN [INE].[Lots] AS LO
            ON LO.[StockItemId] = LN.[StockItemId] AND LO.[LotNumber] = LN.[LotNumber]
        WHERE LN.[LotId] IS NULL AND LN.[LotNumber] IS NOT NULL;

        IF EXISTS (SELECT 1 FROM @Lines AS LN
                   WHERE LN.[LotId] IS NOT NULL
                     AND NOT EXISTS (SELECT 1 FROM [INE].[Lots] AS LO
                                     WHERE LO.[LotID] = LN.[LotId] AND LO.[StockItemId] = LN.[StockItemId]
                                       AND LO.[DealerTenantId] = @TenantId))
            THROW 50000, N'04115|:|A lot does not belong to its stock item.', 1;

        IF @IsInbound = 0 AND EXISTS (SELECT 1 FROM @Lines WHERE [LotId] IS NULL AND [LotNumber] IS NOT NULL)
        BEGIN
            SELECT TOP (1) @Msg = CONCAT(N'04115|:|Lot "', [LotNumber], N'" was not found.') FROM @Lines WHERE [LotId] IS NULL AND [LotNumber] IS NOT NULL;
            THROW 50000, @Msg, 1;
        END;

        -- Serial units: resolve numbers to existing units.
        UPDATE LN SET LN.[SerialUnitId] = SU.[SerialUnitID]
        FROM @Lines AS LN
        INNER JOIN [INE].[SerialUnits] AS SU
            ON SU.[StockItemId] = LN.[StockItemId] AND SU.[SerialNumber] = LN.[SerialNumber]
        WHERE LN.[SerialUnitId] IS NULL AND LN.[SerialNumber] IS NOT NULL;

        IF EXISTS (SELECT 1 FROM @Lines AS LN
                   WHERE LN.[SerialUnitId] IS NOT NULL
                     AND NOT EXISTS (SELECT 1 FROM [INE].[SerialUnits] AS SU
                                     WHERE SU.[SerialUnitID] = LN.[SerialUnitId] AND SU.[StockItemId] = LN.[StockItemId]
                                       AND SU.[DealerTenantId] = @TenantId))
            THROW 50000, N'04116|:|A serial unit does not belong to its stock item.', 1;

        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = 'Serial'
                   GROUP BY [StockItemId], ISNULL([SerialNumber], CAST([SerialUnitId] AS NVARCHAR(60)))
                   HAVING COUNT(*) > 1)
            THROW 50000, N'04117|:|A serial number appears more than once in the movement.', 1;

        IF @IsInbound = 1
        BEGIN
            -- Coming onto the books: a unit that already exists must be off the books
            -- (Scrapped, Missing, Voided); otherwise it is a duplicate.
            IF EXISTS (SELECT 1 FROM @Lines AS LN
                       INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = LN.[SerialUnitId]
                       WHERE SU.[CurrentLocationId] IS NOT NULL)
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N'04118|:|Serial number "', SU.[SerialNumber], N'" is already in stock (', SU.[Status], N').')
                FROM @Lines AS LN INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = LN.[SerialUnitId]
                WHERE SU.[CurrentLocationId] IS NOT NULL;
                THROW 50000, @Msg, 1;
            END;
        END
        ELSE
        BEGIN
            IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = 'Serial' AND [SerialUnitId] IS NULL)
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N'04118|:|Serial number "', [SerialNumber], N'" was not found.')
                FROM @Lines WHERE [TrackingMode] = 'Serial' AND [SerialUnitId] IS NULL;
                THROW 50000, @Msg, 1;
            END;
            -- Lock every serial unit on the movement until it commits, so a concurrent post
            -- cannot move the same unit between this check and the update below.
            DECLARE @LockedSerialUnits INT =
            (
                SELECT COUNT(*)
                FROM [INE].[SerialUnits] AS SU WITH (UPDLOCK, HOLDLOCK)
                INNER JOIN @Lines AS LN ON LN.[SerialUnitId] = SU.[SerialUnitID]
            );
            IF EXISTS (SELECT 1 FROM @Lines AS LN
                       INNER JOIN [INE].[SerialUnits] AS SU WITH (UPDLOCK) ON SU.[SerialUnitID] = LN.[SerialUnitId]
                       WHERE ISNULL(SU.[CurrentLocationId], -1) <> @FromLocationId)
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N'04118|:|Serial number "', SU.[SerialNumber], N'" is not at the from location.')
                FROM @Lines AS LN INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = LN.[SerialUnitId]
                WHERE ISNULL(SU.[CurrentLocationId], -1) <> @FromLocationId;
                THROW 50000, @Msg, 1;
            END;
        END;

        -- An existing serial unit carries its own lot.
        UPDATE LN SET LN.[LotId] = SU.[LotId]
        FROM @Lines AS LN
        INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = LN.[SerialUnitId]
        WHERE SU.[LotId] IS NOT NULL;

        -- Purchase order lines (Receive, or the Reversal of one).
        IF EXISTS (SELECT 1 FROM @Lines WHERE [PurchaseOrderLineId] IS NOT NULL)
        BEGIN
            IF @TypeCode NOT IN ('Receive', 'Reversal')
                THROW 50000, N'04119|:|Only a Receive movement can fill a purchase order line.', 1;
            IF EXISTS (SELECT 1 FROM @Lines AS LN
                       WHERE LN.[PurchaseOrderLineId] IS NOT NULL
                         AND NOT EXISTS (SELECT 1 FROM [INE].[PurchaseOrderLines] AS POL
                                         INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
                                         WHERE POL.[PurchaseOrderLineID] = LN.[PurchaseOrderLineId]
                                           AND POL.[StockItemId] = LN.[StockItemId]
                                           AND PO.[DealerTenantId] = @TenantId
                                           AND POL.[IsDeleted] = 0))
                THROW 50000, N'04119|:|A purchase order line was not found or is for another item.', 1;
            IF @TypeCode = 'Receive' AND EXISTS (
                    SELECT 1 FROM @Lines AS LN
                    INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderLineID] = LN.[PurchaseOrderLineId]
                    INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
                    WHERE PO.[Status] NOT IN ('Submitted', 'PartiallyReceived'))
                THROW 50000, N'04119|:|Stock can only be received on a Submitted or PartiallyReceived purchase order.', 1;
            IF @TypeCode = 'Receive' AND EXISTS (
                    SELECT 1 FROM @Lines AS LN
                    INNER JOIN [INE].[Receipts] AS R ON R.[ReceiptID] = @ReceiptId
                    INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderLineID] = LN.[PurchaseOrderLineId]
                    WHERE R.[PurchaseOrderId] IS NOT NULL AND POL.[PurchaseOrderId] <> R.[PurchaseOrderId])
                THROW 50000, N'04119|:|A line belongs to a different purchase order than the receipt.', 1;
            IF @TypeCode = 'Receive' AND EXISTS (
                    SELECT 1
                    FROM (SELECT [PurchaseOrderLineId], SUM([Quantity]) AS [Qty] FROM @Lines
                          WHERE [PurchaseOrderLineId] IS NOT NULL GROUP BY [PurchaseOrderLineId]) AS Q
                    INNER JOIN [INE].[PurchaseOrderLines] AS POL WITH (UPDLOCK) ON POL.[PurchaseOrderLineID] = Q.[PurchaseOrderLineId]
                    WHERE POL.[QuantityReceived] + Q.[Qty] > POL.[QuantityOrdered])
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N'04120|:|PO line ', POL.[LineNumber], N' ordered ', CAST(POL.[QuantityOrdered] AS DECIMAL(19, 2)),
                                             N', already received ', CAST(POL.[QuantityReceived] AS DECIMAL(19, 2)),
                                             N'; receiving ', CAST(Q.[Qty] AS DECIMAL(19, 2)), N' more is too many.')
                FROM (SELECT [PurchaseOrderLineId], SUM([Quantity]) AS [Qty] FROM @Lines
                      WHERE [PurchaseOrderLineId] IS NOT NULL GROUP BY [PurchaseOrderLineId]) AS Q
                INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderLineID] = Q.[PurchaseOrderLineId]
                WHERE POL.[QuantityReceived] + Q.[Qty] > POL.[QuantityOrdered];
                THROW 50000, @Msg, 1;
            END;
        END;

        -- Allocations (IssueToJob consumes them; a Reversal gives them back).
        IF EXISTS (SELECT 1 FROM @Lines WHERE [AllocationId] IS NOT NULL)
        BEGIN
            IF @TypeCode NOT IN ('IssueToJob', 'Reversal')
                THROW 50000, N'04121|:|Only an IssueToJob movement can consume an allocation.', 1;
            IF EXISTS (SELECT 1 FROM @Lines AS LN
                       WHERE LN.[AllocationId] IS NOT NULL
                         AND NOT EXISTS (SELECT 1 FROM [INE].[Allocations] AS A
                                         WHERE A.[AllocationID] = LN.[AllocationId]
                                           AND A.[DealerTenantId] = @TenantId
                                           AND A.[StockItemId] = LN.[StockItemId]
                                           AND (A.[LotId] IS NULL OR A.[LotId] = LN.[LotId])
                                           AND A.[LeadId] = @LeadId
                                           -- issue: leaves the reserved location; reversal: comes back to it
                                           AND A.[LocationId] = CASE WHEN @IsReversal = 1 THEN @ToLocationId ELSE @FromLocationId END
                                           AND (A.[Status] = 'Open' OR @IsReversal = 1)))
                THROW 50000, N'04121|:|An allocation was not found, is not open, or is for a different job, item, lot or location.', 1;
            IF @IsReversal = 0 AND EXISTS (
                    SELECT 1
                    FROM (SELECT [AllocationId], SUM([Quantity]) AS [Qty] FROM @Lines
                          WHERE [AllocationId] IS NOT NULL GROUP BY [AllocationId]) AS Q
                    INNER JOIN [INE].[Allocations] AS A WITH (UPDLOCK) ON A.[AllocationID] = Q.[AllocationId]
                    WHERE A.[QuantityIssued] + Q.[Qty] > A.[QuantityAllocated])
                THROW 50000, N'04121|:|Issuing more than the allocation reserved; issue the extra on a line without the allocation.', 1;
        END;

        -- Lot items on an allocation line inherit the allocation's lot when none was given.
        UPDATE LN SET LN.[LotId] = A.[LotId]
        FROM @Lines AS LN INNER JOIN [INE].[Allocations] AS A ON A.[AllocationID] = LN.[AllocationId]
        WHERE LN.[LotId] IS NULL AND LN.[LotNumber] IS NULL AND A.[LotId] IS NOT NULL;

        /** WRITE */

        INSERT INTO [INE].[Movements]
            ([DealerTenantId], [MovementTypeId], [MovementDate], [FromLocationId], [ToLocationId], [LeadId],
             [ReceiptId], [StockCountId], [ReversesMovementId], [Reference], [Notes], [CreatedById])
        VALUES
            (@TenantId, @MovementTypeId, @MovementDate, @FromLocationId, @ToLocationId, @LeadId,
             @ReceiptId, @StockCountId, @ReversesMovementId, @Reference, @Notes, @UserId);
        SET @MovementId = SCOPE_IDENTITY();

        -- New lots (inbound only; checked above).
        INSERT INTO [INE].[Lots] ([DealerTenantId], [StockItemId], [LotNumber], [ModifiedById], [CreatedById])
        SELECT DISTINCT @TenantId, LN.[StockItemId], LN.[LotNumber], @UserId, @UserId
        FROM @Lines AS LN
        WHERE LN.[LotId] IS NULL AND LN.[LotNumber] IS NOT NULL;

        UPDATE LN SET LN.[LotId] = LO.[LotID]
        FROM @Lines AS LN
        INNER JOIN [INE].[Lots] AS LO ON LO.[StockItemId] = LN.[StockItemId] AND LO.[LotNumber] = LN.[LotNumber]
        WHERE LN.[LotId] IS NULL AND LN.[LotNumber] IS NOT NULL;

        -- New serial units (inbound only), created straight into the to location.
        INSERT INTO [INE].[SerialUnits]
            ([DealerTenantId], [StockItemId], [SerialNumber], [LotId], [CurrentLocationId], [Status],
             [PurchaseOrderLineId], [UnitCost], [ReceivedDate], [ModifiedById], [CreatedById])
        SELECT @TenantId, LN.[StockItemId], LN.[SerialNumber], LN.[LotId], @ToLocationId, 'InStock',
               LN.[PurchaseOrderLineId], LN.[UnitCost], @MovementDate, @UserId, @UserId
        FROM @Lines AS LN
        WHERE LN.[SerialUnitId] IS NULL AND LN.[SerialNumber] IS NOT NULL;

        UPDATE LN SET LN.[SerialUnitId] = SU.[SerialUnitID]
        FROM @Lines AS LN
        INNER JOIN [INE].[SerialUnits] AS SU ON SU.[StockItemId] = LN.[StockItemId] AND SU.[SerialNumber] = LN.[SerialNumber]
        WHERE LN.[SerialUnitId] IS NULL AND LN.[SerialNumber] IS NOT NULL;

        INSERT INTO [INE].[MovementLines]
            ([MovementId], [StockItemId], [LotId], [SerialUnitId], [Quantity], [UnitCost], [PurchaseOrderLineId], [AllocationId], [CreatedById])
        SELECT @MovementId, LN.[StockItemId], LN.[LotId], LN.[SerialUnitId], LN.[Quantity], LN.[UnitCost],
               LN.[PurchaseOrderLineId], LN.[AllocationId], @UserId
        FROM @Lines AS LN
        ORDER BY LN.[RowNo];

        -- Quantity per item and lot, and how much of it consumes (or restores) allocations.
        DECLARE @Totals TABLE
        (
            [StockItemId] INT NOT NULL
            , [LotId] INT NULL
            , [Quantity] DECIMAL(19, 4) NOT NULL
            , [AllocatedQuantity] DECIMAL(19, 4) NOT NULL
        );
        INSERT INTO @Totals ([StockItemId], [LotId], [Quantity], [AllocatedQuantity])
        SELECT [StockItemId], [LotId], SUM([Quantity]),
               SUM(CASE WHEN [AllocationId] IS NOT NULL THEN [Quantity] ELSE 0 END)
        FROM @Lines
        GROUP BY [StockItemId], [LotId];

        /** FROM: take stock out */
        IF @FromLocationId IS NOT NULL
        BEGIN
            -- Available = on hand - allocated, plus what this movement's own allocations free up.
            IF EXISTS (SELECT 1
                       FROM @Totals AS T
                       LEFT JOIN [INE].[StockBalances] AS SB WITH (UPDLOCK, HOLDLOCK)
                           ON SB.[LocationId] = @FromLocationId AND SB.[StockItemId] = T.[StockItemId]
                          AND ((SB.[LotId] = T.[LotId]) OR (SB.[LotId] IS NULL AND T.[LotId] IS NULL))
                       WHERE ISNULL(SB.[QuantityOnHand], 0)
                             - ISNULL(SB.[QuantityAllocated], 0)
                             + CASE WHEN @IsReversal = 0 THEN T.[AllocatedQuantity] ELSE 0 END
                             < T.[Quantity])
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N'04122|:|Not enough ', SI.[Sku],
                        CASE WHEN LO.[LotNumber] IS NOT NULL THEN CONCAT(N' (lot ', LO.[LotNumber], N')') ELSE N'' END,
                        N' at the from location: ', CAST(ISNULL(SB.[QuantityOnHand], 0) - ISNULL(SB.[QuantityAllocated], 0) AS DECIMAL(19, 2)),
                        N' ', SI.[UnitOfMeasure], N' available, ', CAST(T.[Quantity] AS DECIMAL(19, 2)), N' needed.')
                FROM @Totals AS T
                INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = T.[StockItemId]
                LEFT JOIN [INE].[Lots] AS LO ON LO.[LotID] = T.[LotId]
                LEFT JOIN [INE].[StockBalances] AS SB
                    ON SB.[LocationId] = @FromLocationId AND SB.[StockItemId] = T.[StockItemId]
                   AND ((SB.[LotId] = T.[LotId]) OR (SB.[LotId] IS NULL AND T.[LotId] IS NULL))
                WHERE ISNULL(SB.[QuantityOnHand], 0) - ISNULL(SB.[QuantityAllocated], 0)
                      + CASE WHEN @IsReversal = 0 THEN T.[AllocatedQuantity] ELSE 0 END < T.[Quantity];
                THROW 50000, @Msg, 1;
            END;

            UPDATE SB SET
                SB.[QuantityOnHand] = SB.[QuantityOnHand] - T.[Quantity]
                , SB.[QuantityAllocated] = SB.[QuantityAllocated] - CASE WHEN @IsReversal = 0 THEN T.[AllocatedQuantity] ELSE 0 END
                , SB.[LastMovementId] = @MovementId
                , SB.[ModifiedDate] = SYSDATETIMEOFFSET()
            FROM [INE].[StockBalances] AS SB
            INNER JOIN @Totals AS T
                ON SB.[LocationId] = @FromLocationId AND SB.[StockItemId] = T.[StockItemId]
               AND ((SB.[LotId] = T.[LotId]) OR (SB.[LotId] IS NULL AND T.[LotId] IS NULL));
        END;

        /** TO: put stock in */
        IF @ToLocationId IS NOT NULL
        BEGIN
            UPDATE SB SET
                SB.[QuantityOnHand] = SB.[QuantityOnHand] + T.[Quantity]
                -- A reversed issue puts the stock back under its allocation.
                , SB.[QuantityAllocated] = SB.[QuantityAllocated] + CASE WHEN @IsReversal = 1 THEN T.[AllocatedQuantity] ELSE 0 END
                , SB.[LastMovementId] = @MovementId
                , SB.[ModifiedDate] = SYSDATETIMEOFFSET()
            FROM [INE].[StockBalances] AS SB WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN @Totals AS T
                ON SB.[LocationId] = @ToLocationId AND SB.[StockItemId] = T.[StockItemId]
               AND ((SB.[LotId] = T.[LotId]) OR (SB.[LotId] IS NULL AND T.[LotId] IS NULL));

            INSERT INTO [INE].[StockBalances]
                ([DealerTenantId], [LocationId], [StockItemId], [LotId], [QuantityOnHand], [QuantityAllocated], [LastMovementId])
            SELECT @TenantId, @ToLocationId, T.[StockItemId], T.[LotId], T.[Quantity],
                   CASE WHEN @IsReversal = 1 THEN T.[AllocatedQuantity] ELSE 0 END, @MovementId
            FROM @Totals AS T
            WHERE NOT EXISTS (SELECT 1 FROM [INE].[StockBalances] AS SB
                              WHERE SB.[LocationId] = @ToLocationId AND SB.[StockItemId] = T.[StockItemId]
                                AND ((SB.[LotId] = T.[LotId]) OR (SB.[LotId] IS NULL AND T.[LotId] IS NULL)));
        END;

        /** SERIAL UNITS: where each unit is now */
        UPDATE SU SET
            SU.[CurrentLocationId] = @ToLocationId
            , SU.[Status] = CASE
                WHEN @ToLocationId IS NULL AND @TypeCode = 'Scrap' THEN 'Scrapped'
                WHEN @ToLocationId IS NULL AND @TypeCode = 'Reversal' THEN 'Voided'
                WHEN @ToLocationId IS NULL THEN 'Missing'
                WHEN @ToTypeCode = 'Job' THEN 'Installed'
                WHEN @ToTypeCode = 'Vendor' THEN 'Returned'
                ELSE 'InStock' END
            , SU.[ModifiedDate] = SYSDATETIMEOFFSET()
            , SU.[ModifiedById] = @UserId
        FROM [INE].[SerialUnits] AS SU
        INNER JOIN @Lines AS LN ON LN.[SerialUnitId] = SU.[SerialUnitID];

        /** PURCHASE ORDERS */
        IF EXISTS (SELECT 1 FROM @Lines WHERE [PurchaseOrderLineId] IS NOT NULL)
        BEGIN
            UPDATE POL SET
                POL.[QuantityReceived] = POL.[QuantityReceived] + CASE WHEN @IsReversal = 1 THEN -Q.[Qty] ELSE Q.[Qty] END
                , POL.[ModifiedDate] = SYSDATETIMEOFFSET()
                , POL.[ModifiedById] = @UserId
            FROM [INE].[PurchaseOrderLines] AS POL
            INNER JOIN (SELECT [PurchaseOrderLineId], SUM([Quantity]) AS [Qty] FROM @Lines
                        WHERE [PurchaseOrderLineId] IS NOT NULL GROUP BY [PurchaseOrderLineId]) AS Q
                ON Q.[PurchaseOrderLineId] = POL.[PurchaseOrderLineID];

            -- Re-derive the receiving status of every PO touched (Closed stays Closed).
            UPDATE PO SET
                PO.[Status] = CASE
                    WHEN S.[Outstanding] = 0 THEN 'Received'
                    WHEN S.[Received] > 0 THEN 'PartiallyReceived'
                    ELSE 'Submitted' END
                , PO.[ModifiedDate] = SYSDATETIMEOFFSET()
                , PO.[ModifiedById] = @UserId
            FROM [INE].[PurchaseOrders] AS PO
            INNER JOIN (SELECT POL.[PurchaseOrderId]
                               , SUM(POL.[QuantityReceived]) AS [Received]
                               , SUM(POL.[QuantityOrdered] - POL.[QuantityReceived]) AS [Outstanding]
                        FROM [INE].[PurchaseOrderLines] AS POL
                        WHERE POL.[IsDeleted] = 0
                          AND POL.[PurchaseOrderId] IN (SELECT P2.[PurchaseOrderId] FROM [INE].[PurchaseOrderLines] AS P2
                                                        INNER JOIN @Lines AS LN ON LN.[PurchaseOrderLineId] = P2.[PurchaseOrderLineID])
                        GROUP BY POL.[PurchaseOrderId]) AS S
                ON S.[PurchaseOrderId] = PO.[PurchaseOrderID]
            WHERE PO.[Status] IN ('Submitted', 'PartiallyReceived', 'Received');
        END;

        /** ALLOCATIONS */
        IF EXISTS (SELECT 1 FROM @Lines WHERE [AllocationId] IS NOT NULL)
        BEGIN
            UPDATE A SET
                A.[QuantityIssued] = A.[QuantityIssued] + CASE WHEN @IsReversal = 1 THEN -Q.[Qty] ELSE Q.[Qty] END
                , A.[Status] = CASE WHEN A.[QuantityIssued] + CASE WHEN @IsReversal = 1 THEN -Q.[Qty] ELSE Q.[Qty] END
                                         >= A.[QuantityAllocated] THEN 'Fulfilled' ELSE 'Open' END
                , A.[ModifiedDate] = SYSDATETIMEOFFSET()
                , A.[ModifiedById] = @UserId
            FROM [INE].[Allocations] AS A
            INNER JOIN (SELECT [AllocationId], SUM([Quantity]) AS [Qty] FROM @Lines
                        WHERE [AllocationId] IS NOT NULL GROUP BY [AllocationId]) AS Q
                ON Q.[AllocationId] = A.[AllocationID];
        END;

        IF @OwnsTransaction = 1
            COMMIT TRANSACTION;

        IF @ReturnResult = 1
            SELECT @MovementId AS [MovementID];
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @OwnsTransaction = 1 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N'{"ERROR_NUMBER":%'
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
GO
