/*
Migration: 20261117_1810_CreateINE_InventoryEngineProcedures
Author: Andres Sosa
Date: 2026-11-17
Description: Creates the INE inventory engine's behaviour on top of the tables from
             20261117_1800_CreateINE_InventoryEngineTables:
               INE.fxGetSessionContext          tenant and user from SESSION_CONTEXT
               INE.spMovementPost               the only way stock moves (one transaction)
               INE.spMovementReverse            corrects a movement with a Reversal
               INE.spReceiptPost                packing slip + Receive movement
               INE.spPurchaseOrderSetStatus     Submit / Cancel / Close / Reopen
               INE.spAllocationCreate / Cancel  reserve stock for a job
               INE.spStockCountPost             post count differences as adjustments
               INE.vwStockOnHand, vwReorderSuggestions, vwMovementHistory, vwStockBalanceDrift
               INE.tr_Movements_PreventChange, tr_MovementLines_PreventChange (append-only ledger)
               INE.tr_PurchaseOrderLines_GuardStatus (lines editable only while Draft)
             Each object's source of truth is its file under Procedures/, Functions/, Views/
             and Triggers/ INE/; this migration embeds those files.
Dependencies:
  20261117_1800_CreateINE_InventoryEngineTables, GEN.spExceptionsThrown, ACC.spSessionContextCreate
Rollback:
  DROP TRIGGER [INE].[tr_PurchaseOrderLines_GuardStatus];
  DROP TRIGGER [INE].[tr_MovementLines_PreventChange];
  DROP TRIGGER [INE].[tr_Movements_PreventChange];
  DROP VIEW [INE].[vwStockBalanceDrift];
  DROP VIEW [INE].[vwMovementHistory];
  DROP VIEW [INE].[vwReorderSuggestions];
  DROP VIEW [INE].[vwStockOnHand];
  DROP PROCEDURE [INE].[spStockCountPost];
  DROP PROCEDURE [INE].[spAllocationCancel];
  DROP PROCEDURE [INE].[spAllocationCreate];
  DROP PROCEDURE [INE].[spPurchaseOrderSetStatus];
  DROP PROCEDURE [INE].[spReceiptPost];
  DROP PROCEDURE [INE].[spMovementReverse];
  DROP PROCEDURE [INE].[spMovementPost];
  DROP FUNCTION [INE].[fxGetSessionContext];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_1810_CreateINE_InventoryEngineProcedures';
Expected impact: New INE functions, procedures, views and triggers only.
*/

-- Module definitions keep the session's ANSI_NULLS / QUOTED_IDENTIFIER settings.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261117_1810_CreateINE_InventoryEngineProcedures';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[SchemaVersion]
                   WHERE [MigrationName] = N'20261117_1800_CreateINE_InventoryEngineTables' AND [Success] = 1)
        THROW 50001, 'Apply 20261117_1800_CreateINE_InventoryEngineTables first.', 1;

    IF OBJECT_ID(N'GEN.spExceptionsThrown', N'P') IS NULL
        THROW 50001, 'GEN.spExceptionsThrown must exist before this migration.', 1;

    -- INE.fxGetSessionContext (Functions/INE/fxGetSessionContext.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER FUNCTION [INE].[fxGetSessionContext]()
RETURNS TABLE
AS
RETURN
(
    -- spSessionContextCreate stores FOR JSON PATH output, so the object is element 0 of an array.
    SELECT
        TRY_CAST(JSON_VALUE(CTX.[Json], N''$[0].UserID'') AS UNIQUEIDENTIFIER) AS [UserId]
        , TRY_CAST(JSON_VALUE(CTX.[Json], N''$[0].TenantId'') AS INT) AS [DealerTenantId]
    FROM (SELECT CAST(SESSION_CONTEXT(N''UserContext'') AS NVARCHAR(4000)) AS [Json]) AS CTX
);';

    -- INE.spMovementPost (Procedures/INE/spMovementPost.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spMovementPost]
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
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;
        SET @UserId = ISNULL(@UserId, ''E6872B58-52B2-415C-A32B-45805F95A70A'');

        IF @MovementJson IS NULL OR ISJSON(@MovementJson) <> 1
            THROW 50000, N''04101|:|The movement is not valid JSON.'', 1;

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
            [movementType] VARCHAR(20) N''$.movementType''
            , [fromLocationId] INT N''$.fromLocationId''
            , [toLocationId] INT N''$.toLocationId''
            , [leadId] BIGINT N''$.leadId''
            , [receiptId] BIGINT N''$.receiptId''
            , [stockCountId] BIGINT N''$.stockCountId''
            , [reversesMovementId] BIGINT N''$.reversesMovementId''
            , [reference] NVARCHAR(50) N''$.reference''
            , [notes] NVARCHAR(2000) N''$.notes''
            , [movementDate] DATETIMEOFFSET(7) N''$.movementDate''
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
            SET @Msg = CONCAT(N''04102|:|Unknown movement type "'', @TypeCode, N''".'');
            THROW 50000, @Msg, 1;
        END;

        DECLARE @IsReversal BIT = CASE WHEN @TypeCode = ''Reversal'' THEN 1 ELSE 0 END;
        IF (@IsReversal = 1 AND @ReversesMovementId IS NULL) OR (@IsReversal = 0 AND @ReversesMovementId IS NOT NULL)
            THROW 50000, N''04103|:|A Reversal names the movement it reverses (reversesMovementId), and only a Reversal can.'', 1;

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
                THROW 50000, N''04130|:|The movement to reverse was not found.'', 1;
            IF @OriginalType = ''Reversal''
                THROW 50000, N''04131|:|A reversal cannot be reversed; post a new movement instead.'', 1;
            IF EXISTS (SELECT 1 FROM [INE].[Movements] WHERE [ReversesMovementId] = @ReversesMovementId)
                THROW 50000, N''04132|:|The movement has already been reversed.'', 1;

            SET @Reference = ISNULL(@Reference, @OriginalReference);
            SET @ReceiptId = NULL;
            SET @StockCountId = NULL;
            SET @MovementJson = JSON_MODIFY(@MovementJson, N''$.lines'', JSON_QUERY(ISNULL((
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
                FOR JSON PATH), N''[]'')));
        END;

        /** LOCATIONS */
        IF @IsReversal = 0
        BEGIN
            IF (@RequiresFrom = 1 AND @FromLocationId IS NULL) OR (@RequiresFrom = 0 AND @FromLocationId IS NOT NULL)
               OR (@RequiresTo = 1 AND @ToLocationId IS NULL) OR (@RequiresTo = 0 AND @ToLocationId IS NOT NULL)
            BEGIN
                SET @Msg = CONCAT(N''04104|:|A '', @TypeCode, N'' movement '',
                    CASE WHEN @RequiresFrom = 1 THEN N''needs'' ELSE N''cannot have'' END, N'' a from location and '',
                    CASE WHEN @RequiresTo = 1 THEN N''needs'' ELSE N''cannot have'' END, N'' a to location.'');
                THROW 50000, @Msg, 1;
            END;
        END
        ELSE IF @FromLocationId IS NULL AND @ToLocationId IS NULL
            THROW 50000, N''04104|:|A movement needs a from or a to location.'', 1;

        IF @FromLocationId IS NOT NULL AND @FromLocationId = @ToLocationId
            THROW 50000, N''04105|:|The from and to locations are the same.'', 1;

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
                SET @Msg = CONCAT(N''04106|:|From location '', @FromLocationId, N'' was not found.'');
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
                SET @Msg = CONCAT(N''04106|:|To location '', @ToLocationId, N'' was not found.'');
                THROW 50000, @Msg, 1;
            END;
        END;

        -- A NULL rule means any stock-holding location; otherwise the exact location type.
        IF @IsReversal = 0 AND (
               (@FromLocationId IS NOT NULL AND ((@FromTypeRule IS NULL AND @FromStockHolding = 0) OR @FromTypeCode <> @FromTypeRule))
            OR (@ToLocationId IS NOT NULL AND ((@ToTypeRule IS NULL AND @ToStockHolding = 0) OR @ToTypeCode <> @ToTypeRule)))
        BEGIN
            SET @Msg = CONCAT(N''04107|:|A '', @TypeCode, N'' movement cannot go from a '', ISNULL(@FromTypeCode, N''(none)''),
                              N'' location to a '', ISNULL(@ToTypeCode, N''(none)''), N'' location.'');
            THROW 50000, @Msg, 1;
        END;

        /** JOB (LEAD) */
        DECLARE @LocationLeadId BIGINT = COALESCE(@ToLeadId, @FromLeadId);
        IF @LeadId IS NULL SET @LeadId = @LocationLeadId;
        IF @LocationLeadId IS NOT NULL AND @LeadId <> @LocationLeadId
            THROW 50000, N''04108|:|The lead does not match the job location.'', 1;
        IF @RequiresLead = 1 AND @LeadId IS NULL
        BEGIN
            SET @Msg = CONCAT(N''04108|:|A '', @TypeCode, N'' movement needs a lead (job).'');
            THROW 50000, @Msg, 1;
        END;
        IF @LeadId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [QAL].[Leads] AS LD
                                               WHERE LD.[LeadID] = @LeadId AND LD.[DealerTenantId] = @TenantId)
            THROW 50000, N''04108|:|The lead was not found.'', 1;

        /** RECEIPT / COUNT / REVERSED MOVEMENT */
        IF @TypeCode = ''Receive'' AND @ReceiptId IS NULL
            THROW 50000, N''04109|:|A Receive movement needs a receipt (use INE.spReceiptPost).'', 1;
        IF @ReceiptId IS NOT NULL
        BEGIN
            IF @TypeCode <> ''Receive''
                THROW 50000, N''04109|:|Only a Receive movement can name a receipt.'', 1;
            IF NOT EXISTS (SELECT 1 FROM [INE].[Receipts] AS R
                           WHERE R.[ReceiptID] = @ReceiptId AND R.[DealerTenantId] = @TenantId
                             AND R.[LocationId] = @ToLocationId AND R.[IsDeleted] = 0)
                THROW 50000, N''04109|:|The receipt was not found or is for another location.'', 1;
        END;
        IF @StockCountId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[StockCounts] AS SC
                                                     WHERE SC.[StockCountID] = @StockCountId AND SC.[DealerTenantId] = @TenantId)
            THROW 50000, N''04110|:|The stock count was not found.'', 1;

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
            , NULLIF(LTRIM(RTRIM(JL.[lotNumber])), N'''')
            , JL.[serialUnitId]
            , NULLIF(LTRIM(RTRIM(SN.[value])), N'''')
            -- One line per serial number; a serial line is always quantity 1.
            , CASE WHEN SN.[value] IS NOT NULL OR JL.[serialUnitId] IS NOT NULL THEN 1 ELSE JL.[quantity] END
            , JL.[unitCost]
            , JL.[purchaseOrderLineId]
            , JL.[allocationId]
        FROM OPENJSON(@MovementJson, N''$.lines'')
        WITH (
            [stockItemId] INT N''$.stockItemId''
            , [quantity] DECIMAL(19, 4) N''$.quantity''
            , [lotId] INT N''$.lotId''
            , [lotNumber] NVARCHAR(50) N''$.lotNumber''
            , [serialUnitId] BIGINT N''$.serialUnitId''
            , [serialNumbers] NVARCHAR(MAX) N''$.serialNumbers'' AS JSON
            , [unitCost] DECIMAL(19, 4) N''$.unitCost''
            , [purchaseOrderLineId] BIGINT N''$.purchaseOrderLineId''
            , [allocationId] BIGINT N''$.allocationId''
        ) AS JL
        OUTER APPLY OPENJSON(JL.[serialNumbers]) AS SN;

        IF NOT EXISTS (SELECT 1 FROM @Lines)
            THROW 50000, N''04111|:|A movement needs at least one line.'', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [Quantity] IS NULL OR [Quantity] <= 0)
            THROW 50000, N''04111|:|Every line needs a quantity greater than zero.'', 1;

        -- Items
        UPDATE LN SET LN.[TrackingMode] = SI.[TrackingMode]
        FROM @Lines AS LN
        INNER JOIN [INE].[StockItems] AS SI
            ON SI.[StockItemID] = LN.[StockItemId] AND SI.[DealerTenantId] = @TenantId
           AND SI.[IsDeleted] = 0 AND (SI.[IsActive] = 1 OR @IsReversal = 1);

        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] IS NULL)
        BEGIN
            SELECT TOP (1) @Msg = CONCAT(N''04112|:|Stock item '', ISNULL(CAST([StockItemId] AS NVARCHAR(20)), N''(missing)''), N'' was not found or is inactive.'')
            FROM @Lines WHERE [TrackingMode] IS NULL;
            THROW 50000, @Msg, 1;
        END;

        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = ''Serial'' AND [SerialUnitId] IS NULL AND [SerialNumber] IS NULL)
            THROW 50000, N''04113|:|Serial-tracked items need serialNumbers or a serialUnitId.'', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] <> ''Serial'' AND ([SerialUnitId] IS NOT NULL OR [SerialNumber] IS NOT NULL))
            THROW 50000, N''04113|:|Only serial-tracked items can name serial numbers.'', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = ''Quantity'' AND ([LotId] IS NOT NULL OR [LotNumber] IS NOT NULL))
            THROW 50000, N''04114|:|Quantity-tracked items do not have lots.'', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = ''Lot'' AND [LotId] IS NULL AND [LotNumber] IS NULL)
            THROW 50000, N''04114|:|Lot-tracked items need a lotId or lotNumber.'', 1;

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
            THROW 50000, N''04115|:|A lot does not belong to its stock item.'', 1;

        IF @IsInbound = 0 AND EXISTS (SELECT 1 FROM @Lines WHERE [LotId] IS NULL AND [LotNumber] IS NOT NULL)
        BEGIN
            SELECT TOP (1) @Msg = CONCAT(N''04115|:|Lot "'', [LotNumber], N''" was not found.'') FROM @Lines WHERE [LotId] IS NULL AND [LotNumber] IS NOT NULL;
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
            THROW 50000, N''04116|:|A serial unit does not belong to its stock item.'', 1;

        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = ''Serial''
                   GROUP BY [StockItemId], ISNULL([SerialNumber], CAST([SerialUnitId] AS NVARCHAR(60)))
                   HAVING COUNT(*) > 1)
            THROW 50000, N''04117|:|A serial number appears more than once in the movement.'', 1;

        IF @IsInbound = 1
        BEGIN
            -- Coming onto the books: a unit that already exists must be off the books
            -- (Scrapped, Missing, Voided); otherwise it is a duplicate.
            IF EXISTS (SELECT 1 FROM @Lines AS LN
                       INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = LN.[SerialUnitId]
                       WHERE SU.[CurrentLocationId] IS NOT NULL)
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N''04118|:|Serial number "'', SU.[SerialNumber], N''" is already in stock ('', SU.[Status], N'').'')
                FROM @Lines AS LN INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = LN.[SerialUnitId]
                WHERE SU.[CurrentLocationId] IS NOT NULL;
                THROW 50000, @Msg, 1;
            END;
        END
        ELSE
        BEGIN
            IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = ''Serial'' AND [SerialUnitId] IS NULL)
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N''04118|:|Serial number "'', [SerialNumber], N''" was not found.'')
                FROM @Lines WHERE [TrackingMode] = ''Serial'' AND [SerialUnitId] IS NULL;
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
                SELECT TOP (1) @Msg = CONCAT(N''04118|:|Serial number "'', SU.[SerialNumber], N''" is not at the from location.'')
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
            IF @TypeCode NOT IN (''Receive'', ''Reversal'')
                THROW 50000, N''04119|:|Only a Receive movement can fill a purchase order line.'', 1;
            IF EXISTS (SELECT 1 FROM @Lines AS LN
                       WHERE LN.[PurchaseOrderLineId] IS NOT NULL
                         AND NOT EXISTS (SELECT 1 FROM [INE].[PurchaseOrderLines] AS POL
                                         INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
                                         WHERE POL.[PurchaseOrderLineID] = LN.[PurchaseOrderLineId]
                                           AND POL.[StockItemId] = LN.[StockItemId]
                                           AND PO.[DealerTenantId] = @TenantId
                                           AND POL.[IsDeleted] = 0))
                THROW 50000, N''04119|:|A purchase order line was not found or is for another item.'', 1;
            IF @TypeCode = ''Receive'' AND EXISTS (
                    SELECT 1 FROM @Lines AS LN
                    INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderLineID] = LN.[PurchaseOrderLineId]
                    INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
                    WHERE PO.[Status] NOT IN (''Submitted'', ''PartiallyReceived''))
                THROW 50000, N''04119|:|Stock can only be received on a Submitted or PartiallyReceived purchase order.'', 1;
            IF @TypeCode = ''Receive'' AND EXISTS (
                    SELECT 1 FROM @Lines AS LN
                    INNER JOIN [INE].[Receipts] AS R ON R.[ReceiptID] = @ReceiptId
                    INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderLineID] = LN.[PurchaseOrderLineId]
                    WHERE R.[PurchaseOrderId] IS NOT NULL AND POL.[PurchaseOrderId] <> R.[PurchaseOrderId])
                THROW 50000, N''04119|:|A line belongs to a different purchase order than the receipt.'', 1;
            IF @TypeCode = ''Receive'' AND EXISTS (
                    SELECT 1
                    FROM (SELECT [PurchaseOrderLineId], SUM([Quantity]) AS [Qty] FROM @Lines
                          WHERE [PurchaseOrderLineId] IS NOT NULL GROUP BY [PurchaseOrderLineId]) AS Q
                    INNER JOIN [INE].[PurchaseOrderLines] AS POL WITH (UPDLOCK) ON POL.[PurchaseOrderLineID] = Q.[PurchaseOrderLineId]
                    WHERE POL.[QuantityReceived] + Q.[Qty] > POL.[QuantityOrdered])
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N''04120|:|PO line '', POL.[LineNumber], N'' ordered '', CAST(POL.[QuantityOrdered] AS DECIMAL(19, 2)),
                                             N'', already received '', CAST(POL.[QuantityReceived] AS DECIMAL(19, 2)),
                                             N''; receiving '', CAST(Q.[Qty] AS DECIMAL(19, 2)), N'' more is too many.'')
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
            IF @TypeCode NOT IN (''IssueToJob'', ''Reversal'')
                THROW 50000, N''04121|:|Only an IssueToJob movement can consume an allocation.'', 1;
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
                                           AND (A.[Status] = ''Open'' OR @IsReversal = 1)))
                THROW 50000, N''04121|:|An allocation was not found, is not open, or is for a different job, item, lot or location.'', 1;
            IF @IsReversal = 0 AND EXISTS (
                    SELECT 1
                    FROM (SELECT [AllocationId], SUM([Quantity]) AS [Qty] FROM @Lines
                          WHERE [AllocationId] IS NOT NULL GROUP BY [AllocationId]) AS Q
                    INNER JOIN [INE].[Allocations] AS A WITH (UPDLOCK) ON A.[AllocationID] = Q.[AllocationId]
                    WHERE A.[QuantityIssued] + Q.[Qty] > A.[QuantityAllocated])
                THROW 50000, N''04121|:|Issuing more than the allocation reserved; issue the extra on a line without the allocation.'', 1;
        END;

        -- Lot items on an allocation line inherit the allocation''s lot when none was given.
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
        SELECT @TenantId, LN.[StockItemId], LN.[SerialNumber], LN.[LotId], @ToLocationId, ''InStock'',
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
            -- Available = on hand - allocated, plus what this movement''s own allocations free up.
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
                SELECT TOP (1) @Msg = CONCAT(N''04122|:|Not enough '', SI.[Sku],
                        CASE WHEN LO.[LotNumber] IS NOT NULL THEN CONCAT(N'' (lot '', LO.[LotNumber], N'')'') ELSE N'''' END,
                        N'' at the from location: '', CAST(ISNULL(SB.[QuantityOnHand], 0) - ISNULL(SB.[QuantityAllocated], 0) AS DECIMAL(19, 2)),
                        N'' '', SI.[UnitOfMeasure], N'' available, '', CAST(T.[Quantity] AS DECIMAL(19, 2)), N'' needed.'')
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
                WHEN @ToLocationId IS NULL AND @TypeCode = ''Scrap'' THEN ''Scrapped''
                WHEN @ToLocationId IS NULL AND @TypeCode = ''Reversal'' THEN ''Voided''
                WHEN @ToLocationId IS NULL THEN ''Missing''
                WHEN @ToTypeCode = ''Job'' THEN ''Installed''
                WHEN @ToTypeCode = ''Vendor'' THEN ''Returned''
                ELSE ''InStock'' END
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
                    WHEN S.[Outstanding] = 0 THEN ''Received''
                    WHEN S.[Received] > 0 THEN ''PartiallyReceived''
                    ELSE ''Submitted'' END
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
            WHERE PO.[Status] IN (''Submitted'', ''PartiallyReceived'', ''Received'');
        END;

        /** ALLOCATIONS */
        IF EXISTS (SELECT 1 FROM @Lines WHERE [AllocationId] IS NOT NULL)
        BEGIN
            UPDATE A SET
                A.[QuantityIssued] = A.[QuantityIssued] + CASE WHEN @IsReversal = 1 THEN -Q.[Qty] ELSE Q.[Qty] END
                , A.[Status] = CASE WHEN A.[QuantityIssued] + CASE WHEN @IsReversal = 1 THEN -Q.[Qty] ELSE Q.[Qty] END
                                         >= A.[QuantityAllocated] THEN ''Fulfilled'' ELSE ''Open'' END
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
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;';

    -- INE.spMovementReverse (Procedures/INE/spMovementReverse.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spMovementReverse]
(
    @MovementId BIGINT,
    @Notes NVARCHAR(2000) = NULL,
    @ReversalMovementId BIGINT = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @TenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());
        IF @TenantId IS NULL
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;

        IF @MovementId IS NULL
            THROW 50000, N''04130|:|The movement to reverse was not found.'', 1;

        -- spMovementPost takes the locations, lead and lines from the original and checks
        -- that it exists, is not itself a reversal and has not been reversed yet.
        DECLARE @Json NVARCHAR(MAX) =
        (
            SELECT
                ''Reversal'' AS [movementType]
                , @MovementId AS [reversesMovementId]
                , @Notes AS [notes]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        DECLARE @Rc INT;
        EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @ReversalMovementId OUTPUT, @ReturnResult = 0;
        IF @Rc <> 0
            THROW 50000, N''04133|:|The reversal could not be posted.'', 1;

        SELECT @ReversalMovementId AS [MovementID];
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;';

    -- INE.spReceiptPost (Procedures/INE/spReceiptPost.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spReceiptPost]
(
    @ReceiptJson NVARCHAR(MAX),
    @ReceiptId BIGINT = NULL OUTPUT,
    @MovementId BIGINT = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OwnsTransaction BIT = 0;

    BEGIN TRY
        DECLARE @TenantId INT, @UserId UNIQUEIDENTIFIER;
        SELECT @TenantId = SC.[DealerTenantId], @UserId = SC.[UserId] FROM [INE].[fxGetSessionContext]() AS SC;
        IF @TenantId IS NULL
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;
        SET @UserId = ISNULL(@UserId, ''E6872B58-52B2-415C-A32B-45805F95A70A'');

        IF @ReceiptJson IS NULL OR ISJSON(@ReceiptJson) <> 1
            THROW 50000, N''04101|:|The receipt is not valid JSON.'', 1;

        DECLARE @PurchaseOrderId BIGINT, @LocationId INT, @PackingSlipNumber NVARCHAR(50)
            , @ReceivedDate DATETIMEOFFSET(7), @Notes NVARCHAR(2000), @Lines NVARCHAR(MAX);
        SELECT
            @PurchaseOrderId = J.[purchaseOrderId]
            , @LocationId = J.[locationId]
            , @PackingSlipNumber = J.[packingSlipNumber]
            , @ReceivedDate = ISNULL(J.[receivedDate], SYSDATETIMEOFFSET())
            , @Notes = J.[notes]
            , @Lines = J.[lines]
        FROM OPENJSON(@ReceiptJson)
        WITH (
            [purchaseOrderId] BIGINT N''$.purchaseOrderId''
            , [locationId] INT N''$.locationId''
            , [packingSlipNumber] NVARCHAR(50) N''$.packingSlipNumber''
            , [receivedDate] DATETIMEOFFSET(7) N''$.receivedDate''
            , [notes] NVARCHAR(2000) N''$.notes''
            , [lines] NVARCHAR(MAX) N''$.lines'' AS JSON
        ) AS J;

        IF @PurchaseOrderId IS NOT NULL
        BEGIN
            DECLARE @PoStatus VARCHAR(20), @ShipToLocationId INT;
            SELECT @PoStatus = PO.[Status], @ShipToLocationId = PO.[ShipToLocationId]
            FROM [INE].[PurchaseOrders] AS PO
            WHERE PO.[PurchaseOrderID] = @PurchaseOrderId AND PO.[DealerTenantId] = @TenantId AND PO.[IsDeleted] = 0;
            IF @PoStatus IS NULL
                THROW 50000, N''04140|:|The purchase order was not found.'', 1;
            IF @PoStatus NOT IN (''Submitted'', ''PartiallyReceived'')
                THROW 50000, N''04119|:|Stock can only be received on a Submitted or PartiallyReceived purchase order.'', 1;
            SET @LocationId = ISNULL(@LocationId, @ShipToLocationId);
        END;

        IF @LocationId IS NULL
            THROW 50000, N''04141|:|A receipt without a purchase order needs a locationId.'', 1;

        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnsTransaction = 1;
        END;

        INSERT INTO [INE].[Receipts]
            ([DealerTenantId], [PurchaseOrderId], [LocationId], [PackingSlipNumber], [ReceivedDate], [Notes], [ModifiedById], [CreatedById])
        VALUES
            (@TenantId, @PurchaseOrderId, @LocationId, @PackingSlipNumber, @ReceivedDate, @Notes, @UserId, @UserId);
        SET @ReceiptId = SCOPE_IDENTITY();

        DECLARE @MovementJson NVARCHAR(MAX) =
        (
            SELECT
                ''Receive'' AS [movementType]
                , @LocationId AS [toLocationId]
                , @ReceiptId AS [receiptId]
                , @ReceivedDate AS [movementDate]
                , @PackingSlipNumber AS [reference]
                , JSON_QUERY(ISNULL(@Lines, N''[]'')) AS [lines]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        DECLARE @Rc INT;
        EXEC @Rc = [INE].[spMovementPost] @MovementJson = @MovementJson, @MovementId = @MovementId OUTPUT, @ReturnResult = 0;
        IF @Rc <> 0
            THROW 50000, N''04142|:|The receipt could not be posted.'', 1;

        IF @OwnsTransaction = 1
            COMMIT TRANSACTION;

        SELECT @ReceiptId AS [ReceiptID], @MovementId AS [MovementID];
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @OwnsTransaction = 1 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;';

    -- INE.spPurchaseOrderSetStatus (Procedures/INE/spPurchaseOrderSetStatus.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spPurchaseOrderSetStatus]
(
    @PurchaseOrderId BIGINT,
    @Action VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @TenantId INT, @UserId UNIQUEIDENTIFIER, @Msg NVARCHAR(2048);
        SELECT @TenantId = SC.[DealerTenantId], @UserId = SC.[UserId] FROM [INE].[fxGetSessionContext]() AS SC;
        IF @TenantId IS NULL
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;
        SET @UserId = ISNULL(@UserId, ''E6872B58-52B2-415C-A32B-45805F95A70A'');

        BEGIN TRANSACTION;

        DECLARE @Status VARCHAR(20);
        SELECT @Status = PO.[Status]
        FROM [INE].[PurchaseOrders] AS PO WITH (UPDLOCK, HOLDLOCK)
        WHERE PO.[PurchaseOrderID] = @PurchaseOrderId AND PO.[DealerTenantId] = @TenantId AND PO.[IsDeleted] = 0;
        IF @Status IS NULL
            THROW 50000, N''04140|:|The purchase order was not found.'', 1;

        DECLARE @Received DECIMAL(19, 4), @Outstanding DECIMAL(19, 4), @LineCount INT;
        SELECT @Received = ISNULL(SUM(POL.[QuantityReceived]), 0)
             , @Outstanding = ISNULL(SUM(POL.[QuantityOrdered] - POL.[QuantityReceived]), 0)
             , @LineCount = COUNT(*)
        FROM [INE].[PurchaseOrderLines] AS POL
        WHERE POL.[PurchaseOrderId] = @PurchaseOrderId AND POL.[IsDeleted] = 0;

        DECLARE @NewStatus VARCHAR(20) = CASE
            WHEN @Action = ''Submit'' AND @Status = ''Draft'' AND @LineCount > 0 THEN ''Submitted''
            WHEN @Action = ''Cancel'' AND @Status IN (''Draft'', ''Submitted'') AND @Received = 0 THEN ''Cancelled''
            WHEN @Action = ''Close'' AND @Status IN (''Submitted'', ''PartiallyReceived'', ''Received'') THEN ''Closed''
            WHEN @Action = ''Reopen'' AND @Status = ''Closed'' THEN
                CASE WHEN @Outstanding = 0 THEN ''Received'' WHEN @Received > 0 THEN ''PartiallyReceived'' ELSE ''Submitted'' END
            END;

        IF @NewStatus IS NULL
        BEGIN
            SET @Msg = CONCAT(N''04143|:|Cannot '', ISNULL(@Action, N''(no action)''), N'' a '', @Status, N'' purchase order'',
                CASE WHEN @Action = ''Submit'' AND @LineCount = 0 THEN N'' with no lines''
                     WHEN @Action = ''Cancel'' AND @Received > 0 THEN N'' that has received stock'' ELSE N'''' END, N''.'');
            THROW 50000, @Msg, 1;
        END;

        UPDATE [INE].[PurchaseOrders] SET
            [Status] = @NewStatus
            , [SubmittedDate] = CASE WHEN @NewStatus = ''Submitted'' AND [SubmittedDate] IS NULL THEN SYSDATETIMEOFFSET() ELSE [SubmittedDate] END
            , [ClosedDate] = CASE WHEN @NewStatus IN (''Closed'', ''Cancelled'') THEN SYSDATETIMEOFFSET() ELSE NULL END
            , [ModifiedDate] = SYSDATETIMEOFFSET()
            , [ModifiedById] = @UserId
        WHERE [PurchaseOrderID] = @PurchaseOrderId;

        COMMIT TRANSACTION;

        SELECT @PurchaseOrderId AS [PurchaseOrderID], @NewStatus AS [Status];
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;';

    -- INE.spAllocationCreate (Procedures/INE/spAllocationCreate.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spAllocationCreate]
(
    @LeadId BIGINT,
    @LocationId INT,
    @StockItemId INT,
    @Quantity DECIMAL(19, 4),
    @LotId INT = NULL,
    @NeededByDate DATE = NULL,
    @Notes NVARCHAR(500) = NULL,
    @AllocationId BIGINT = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @TenantId INT, @UserId UNIQUEIDENTIFIER, @Msg NVARCHAR(2048);
        SELECT @TenantId = SC.[DealerTenantId], @UserId = SC.[UserId] FROM [INE].[fxGetSessionContext]() AS SC;
        IF @TenantId IS NULL
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;
        SET @UserId = ISNULL(@UserId, ''E6872B58-52B2-415C-A32B-45805F95A70A'');

        IF @Quantity IS NULL OR @Quantity <= 0
            THROW 50000, N''04150|:|The quantity must be greater than zero.'', 1;
        IF NOT EXISTS (SELECT 1 FROM [QAL].[Leads] WHERE [LeadID] = @LeadId AND [DealerTenantId] = @TenantId)
            THROW 50000, N''04108|:|The lead was not found.'', 1;
        IF NOT EXISTS (SELECT 1 FROM [INE].[Locations] AS L
                       INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
                       WHERE L.[LocationID] = @LocationId AND L.[DealerTenantId] = @TenantId
                         AND L.[IsActive] = 1 AND L.[IsDeleted] = 0 AND LT.[IsStockHolding] = 1)
            THROW 50000, N''04151|:|Stock can only be allocated at an active warehouse, vehicle or staging location.'', 1;

        DECLARE @TrackingMode VARCHAR(10);
        SELECT @TrackingMode = [TrackingMode] FROM [INE].[StockItems]
        WHERE [StockItemID] = @StockItemId AND [DealerTenantId] = @TenantId AND [IsActive] = 1 AND [IsDeleted] = 0;
        IF @TrackingMode IS NULL
            THROW 50000, N''04112|:|The stock item was not found or is inactive.'', 1;
        IF @TrackingMode = ''Quantity'' AND @LotId IS NOT NULL
            THROW 50000, N''04114|:|Quantity-tracked items do not have lots.'', 1;
        IF @LotId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Lots] WHERE [LotID] = @LotId AND [StockItemId] = @StockItemId)
            THROW 50000, N''04115|:|The lot does not belong to the stock item.'', 1;
        IF @TrackingMode = ''Serial'' AND @Quantity <> ROUND(@Quantity, 0)
            THROW 50000, N''04150|:|Serial-tracked items are allocated in whole units.'', 1;

        BEGIN TRANSACTION;

        -- Without a lot, availability is across all lots of the item at the location; the
        -- reservation then sits on the lot-less balance row only when one exists.
        DECLARE @Available DECIMAL(19, 4);
        SELECT @Available = ISNULL(SUM(SB.[QuantityOnHand] - SB.[QuantityAllocated]), 0)
        FROM [INE].[StockBalances] AS SB WITH (UPDLOCK, HOLDLOCK)
        WHERE SB.[LocationId] = @LocationId AND SB.[StockItemId] = @StockItemId
          AND ((@LotId IS NULL AND SB.[LotId] IS NULL) OR SB.[LotId] = @LotId);

        IF @Available < @Quantity
        BEGIN
            SET @Msg = CONCAT(N''04122|:|Only '', CAST(@Available AS DECIMAL(19, 2)), N'' available at the location; '',
                              CAST(@Quantity AS DECIMAL(19, 2)), N'' requested.'',
                              CASE WHEN @TrackingMode = ''Lot'' AND @LotId IS NULL THEN N'' Lot-tracked items are allocated by lot.'' ELSE N'''' END);
            THROW 50000, @Msg, 1;
        END;

        INSERT INTO [INE].[Allocations]
            ([DealerTenantId], [LeadId], [StockItemId], [LocationId], [LotId], [QuantityAllocated], [NeededByDate], [Notes], [ModifiedById], [CreatedById])
        VALUES
            (@TenantId, @LeadId, @StockItemId, @LocationId, @LotId, @Quantity, @NeededByDate, @Notes, @UserId, @UserId);
        SET @AllocationId = SCOPE_IDENTITY();

        UPDATE [INE].[StockBalances] SET
            [QuantityAllocated] = [QuantityAllocated] + @Quantity
            , [ModifiedDate] = SYSDATETIMEOFFSET()
        WHERE [LocationId] = @LocationId AND [StockItemId] = @StockItemId
          AND (([LotId] IS NULL AND @LotId IS NULL) OR [LotId] = @LotId);

        COMMIT TRANSACTION;

        SELECT @AllocationId AS [AllocationID];
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;';

    -- INE.spAllocationCancel (Procedures/INE/spAllocationCancel.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spAllocationCancel]
(
    @AllocationId BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @TenantId INT, @UserId UNIQUEIDENTIFIER;
        SELECT @TenantId = SC.[DealerTenantId], @UserId = SC.[UserId] FROM [INE].[fxGetSessionContext]() AS SC;
        IF @TenantId IS NULL
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;
        SET @UserId = ISNULL(@UserId, ''E6872B58-52B2-415C-A32B-45805F95A70A'');

        BEGIN TRANSACTION;

        DECLARE @Remaining DECIMAL(19, 4), @LocationId INT, @StockItemId INT, @LotId INT;
        SELECT @Remaining = A.[QuantityAllocated] - A.[QuantityIssued], @LocationId = A.[LocationId],
               @StockItemId = A.[StockItemId], @LotId = A.[LotId]
        FROM [INE].[Allocations] AS A WITH (UPDLOCK, HOLDLOCK)
        WHERE A.[AllocationID] = @AllocationId AND A.[DealerTenantId] = @TenantId AND A.[Status] = ''Open'';

        IF @Remaining IS NULL
            THROW 50000, N''04152|:|The allocation was not found or is not open.'', 1;

        UPDATE [INE].[Allocations] SET
            [Status] = ''Cancelled''
            , [ModifiedDate] = SYSDATETIMEOFFSET()
            , [ModifiedById] = @UserId
        WHERE [AllocationID] = @AllocationId;

        UPDATE [INE].[StockBalances] SET
            [QuantityAllocated] = [QuantityAllocated] - @Remaining
            , [ModifiedDate] = SYSDATETIMEOFFSET()
        WHERE [LocationId] = @LocationId AND [StockItemId] = @StockItemId
          AND (([LotId] IS NULL AND @LotId IS NULL) OR [LotId] = @LotId);

        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;';

    -- INE.spStockCountPost (Procedures/INE/spStockCountPost.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spStockCountPost]
(
    @StockCountId BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @TenantId INT, @UserId UNIQUEIDENTIFIER, @Msg NVARCHAR(2048);
        SELECT @TenantId = SC.[DealerTenantId], @UserId = SC.[UserId] FROM [INE].[fxGetSessionContext]() AS SC;
        IF @TenantId IS NULL
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;
        SET @UserId = ISNULL(@UserId, ''E6872B58-52B2-415C-A32B-45805F95A70A'');

        BEGIN TRANSACTION;

        DECLARE @LocationId INT;
        SELECT @LocationId = SC.[LocationId]
        FROM [INE].[StockCounts] AS SC WITH (UPDLOCK, HOLDLOCK)
        WHERE SC.[StockCountID] = @StockCountId AND SC.[DealerTenantId] = @TenantId AND SC.[Status] = ''Open'';
        IF @LocationId IS NULL
            THROW 50000, N''04160|:|The stock count was not found or is not open.'', 1;

        IF EXISTS (SELECT 1 FROM [INE].[StockCountLines] AS CL
                   INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = CL.[StockItemId]
                   WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0
                     AND ((SI.[TrackingMode] = ''Serial'' AND CL.[SerialUnitId] IS NULL)
                       OR (SI.[TrackingMode] <> ''Serial'' AND CL.[SerialUnitId] IS NOT NULL)))
            THROW 50000, N''04161|:|Serial items are counted one line per serial unit, and only serial items name a unit.'', 1;

        IF EXISTS (SELECT 1 FROM [INE].[StockCountLines] AS CL
                   INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = CL.[SerialUnitId]
                   WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0 AND CL.[CountedQuantity] = 1
                     AND SU.[CurrentLocationId] IS NOT NULL AND SU.[CurrentLocationId] <> @LocationId)
        BEGIN
            SELECT TOP (1) @Msg = CONCAT(N''04162|:|Serial number "'', SU.[SerialNumber], N''" was found here but the books have it at location '',
                                         SU.[CurrentLocationId], N''. Post a transfer for it, then post the count.'')
            FROM [INE].[StockCountLines] AS CL
            INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = CL.[SerialUnitId]
            WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0 AND CL.[CountedQuantity] = 1
              AND SU.[CurrentLocationId] IS NOT NULL AND SU.[CurrentLocationId] <> @LocationId;
            THROW 50000, @Msg, 1;
        END;

        -- Expected quantity: the balance for non-serial lines, 1/0 (here or not) for serial lines.
        UPDATE CL SET
            CL.[ExpectedQuantity] = CASE
                WHEN CL.[SerialUnitId] IS NOT NULL THEN CASE WHEN SU.[CurrentLocationId] = @LocationId THEN 1 ELSE 0 END
                ELSE ISNULL(SB.[QuantityOnHand], 0) END
            , CL.[ModifiedDate] = SYSDATETIMEOFFSET()
            , CL.[ModifiedById] = @UserId
        FROM [INE].[StockCountLines] AS CL
        LEFT JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = CL.[SerialUnitId]
        LEFT JOIN [INE].[StockBalances] AS SB WITH (UPDLOCK, HOLDLOCK)
            ON CL.[SerialUnitId] IS NULL AND SB.[LocationId] = @LocationId AND SB.[StockItemId] = CL.[StockItemId]
           AND ((SB.[LotId] = CL.[LotId]) OR (SB.[LotId] IS NULL AND CL.[LotId] IS NULL))
        WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0;

        -- Non-serial lines for the same item and lot are summed (two people counted two shelves).
        DECLARE @Diffs TABLE ([StockItemId] INT NOT NULL, [LotId] INT NULL, [SerialUnitId] BIGINT NULL, [Diff] DECIMAL(19, 4) NOT NULL);
        INSERT INTO @Diffs ([StockItemId], [LotId], [SerialUnitId], [Diff])
        SELECT CL.[StockItemId], CL.[LotId], NULL, SUM(CL.[CountedQuantity]) - MAX(CL.[ExpectedQuantity])
        FROM [INE].[StockCountLines] AS CL
        WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0 AND CL.[SerialUnitId] IS NULL
        GROUP BY CL.[StockItemId], CL.[LotId]
        UNION ALL
        SELECT CL.[StockItemId], NULL, CL.[SerialUnitId], CL.[CountedQuantity] - CL.[ExpectedQuantity]
        FROM [INE].[StockCountLines] AS CL
        WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0 AND CL.[SerialUnitId] IS NOT NULL;

        DECLARE @Results TABLE ([MovementID] BIGINT NOT NULL, [MovementType] VARCHAR(20) NOT NULL);
        DECLARE @Json NVARCHAR(MAX), @NewId BIGINT, @Rc INT;

        IF EXISTS (SELECT 1 FROM @Diffs WHERE [Diff] > 0)
        BEGIN
            SET @Json = (SELECT ''AdjustIn'' AS [movementType], @LocationId AS [toLocationId], @StockCountId AS [stockCountId],
                                CONCAT(N''Stock count '', @StockCountId) AS [reference],
                                (SELECT D.[StockItemId] AS [stockItemId], D.[LotId] AS [lotId], D.[SerialUnitId] AS [serialUnitId],
                                        D.[Diff] AS [quantity]
                                 FROM @Diffs AS D WHERE D.[Diff] > 0 FOR JSON PATH) AS [lines]
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
            EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @NewId OUTPUT, @ReturnResult = 0;
            IF @Rc <> 0 THROW 50000, N''04163|:|The count overages could not be posted.'', 1;
            INSERT INTO @Results VALUES (@NewId, ''AdjustIn'');
        END;

        IF EXISTS (SELECT 1 FROM @Diffs WHERE [Diff] < 0)
        BEGIN
            SET @NewId = NULL;
            SET @Json = (SELECT ''AdjustOut'' AS [movementType], @LocationId AS [fromLocationId], @StockCountId AS [stockCountId],
                                CONCAT(N''Stock count '', @StockCountId) AS [reference],
                                (SELECT D.[StockItemId] AS [stockItemId], D.[LotId] AS [lotId], D.[SerialUnitId] AS [serialUnitId],
                                        -D.[Diff] AS [quantity]
                                 FROM @Diffs AS D WHERE D.[Diff] < 0 FOR JSON PATH) AS [lines]
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
            EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @NewId OUTPUT, @ReturnResult = 0;
            IF @Rc <> 0 THROW 50000, N''04163|:|The count shortages could not be posted (release allocations on short items first).'', 1;
            INSERT INTO @Results VALUES (@NewId, ''AdjustOut'');
        END;

        UPDATE [INE].[StockCounts] SET
            [Status] = ''Posted''
            , [PostedDate] = SYSDATETIMEOFFSET()
            , [ModifiedDate] = SYSDATETIMEOFFSET()
            , [ModifiedById] = @UserId
        WHERE [StockCountID] = @StockCountId;

        COMMIT TRANSACTION;

        SELECT [MovementID], [MovementType] FROM @Results;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;';

    -- INE.vwStockOnHand (Views/INE/vwStockOnHand.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER VIEW [INE].[vwStockOnHand]
AS
    SELECT
        SB.[DealerTenantId]
        , SB.[LocationId]
        , L.[Code] AS [LocationCode]
        , L.[Name] AS [LocationName]
        , LT.[Code] AS [LocationType]
        , LT.[IsStockHolding]
        , L.[LeadId]
        , SB.[StockItemId]
        , SI.[Sku]
        , SI.[Name] AS [StockItemName]
        , SI.[TrackingMode]
        , SI.[UnitOfMeasure]
        , SB.[LotId]
        , LO.[LotNumber]
        , SB.[QuantityOnHand]
        , SB.[QuantityAllocated]
        , SB.[QuantityOnHand] - SB.[QuantityAllocated] AS [QuantityAvailable]
        , SB.[QuantityOnHand] * SI.[StandardCost] AS [ExtendedStandardCost]
        , SB.[LastMovementId]
        , SB.[ModifiedDate] AS [LastChangedDate]
    FROM [INE].[StockBalances] AS SB
    INNER JOIN [INE].[Locations] AS L ON L.[LocationID] = SB.[LocationId]
    INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = SB.[StockItemId]
    LEFT JOIN [INE].[Lots] AS LO ON LO.[LotID] = SB.[LotId]
    WHERE SB.[QuantityOnHand] <> 0 OR SB.[QuantityAllocated] <> 0;';

    -- INE.vwReorderSuggestions (Views/INE/vwReorderSuggestions.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER VIEW [INE].[vwReorderSuggestions]
AS
    WITH [Available] AS
    (
        SELECT SB.[LocationId], SB.[StockItemId], SUM(SB.[QuantityOnHand] - SB.[QuantityAllocated]) AS [Quantity]
        FROM [INE].[StockBalances] AS SB
        GROUP BY SB.[LocationId], SB.[StockItemId]
    ),
    [OnOrder] AS
    (
        SELECT PO.[ShipToLocationId] AS [LocationId], POL.[StockItemId], SUM(POL.[QuantityOrdered] - POL.[QuantityReceived]) AS [Quantity]
        FROM [INE].[PurchaseOrders] AS PO
        INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderId] = PO.[PurchaseOrderID]
        WHERE PO.[Status] IN (''Draft'', ''Submitted'', ''PartiallyReceived'') AND PO.[IsDeleted] = 0 AND POL.[IsDeleted] = 0
        GROUP BY PO.[ShipToLocationId], POL.[StockItemId]
    )
    SELECT
        SL.[DealerTenantId]
        , SL.[StockLevelID]
        , SL.[LocationId]
        , L.[Code] AS [LocationCode]
        , L.[Name] AS [LocationName]
        , SL.[StockItemId]
        , SI.[Sku]
        , SI.[Name] AS [StockItemName]
        , SI.[UnitOfMeasure]
        , SI.[DefaultVendorId]
        , V.[Name] AS [DefaultVendorName]
        , SL.[ReorderPoint]
        , SL.[MaximumQuantity]
        , ISNULL(A.[Quantity], 0) AS [QuantityAvailable]
        , ISNULL(O.[Quantity], 0) AS [QuantityOnOrder]
        , CAST(CASE WHEN ISNULL(A.[Quantity], 0) + ISNULL(O.[Quantity], 0) <= SL.[ReorderPoint] THEN 1 ELSE 0 END AS BIT) AS [NeedsReorder]
        , CASE WHEN ISNULL(A.[Quantity], 0) + ISNULL(O.[Quantity], 0) <= SL.[ReorderPoint]
               THEN SL.[MaximumQuantity] - ISNULL(A.[Quantity], 0) - ISNULL(O.[Quantity], 0) ELSE 0 END AS [SuggestedOrderQuantity]
    FROM [INE].[StockLevels] AS SL
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = SL.[StockItemId]
    INNER JOIN [INE].[Locations] AS L ON L.[LocationID] = SL.[LocationId]
    LEFT JOIN [INE].[Vendors] AS V ON V.[VendorID] = SI.[DefaultVendorId]
    LEFT JOIN [Available] AS A ON A.[LocationId] = SL.[LocationId] AND A.[StockItemId] = SL.[StockItemId]
    LEFT JOIN [OnOrder] AS O ON O.[LocationId] = SL.[LocationId] AND O.[StockItemId] = SL.[StockItemId]
    WHERE SL.[IsActive] = 1 AND SL.[IsDeleted] = 0 AND SI.[IsActive] = 1 AND SI.[IsDeleted] = 0;';

    -- INE.vwMovementHistory (Views/INE/vwMovementHistory.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER VIEW [INE].[vwMovementHistory]
AS
    SELECT
        M.[DealerTenantId]
        , M.[MovementID]
        , ML.[MovementLineID]
        , M.[MovementDate]
        , MT.[Code] AS [MovementType]
        , M.[FromLocationId]
        , FL.[Code] AS [FromLocationCode]
        , M.[ToLocationId]
        , TL.[Code] AS [ToLocationCode]
        , M.[LeadId]
        , M.[ReceiptId]
        , M.[StockCountId]
        , M.[ReversesMovementId]
        , CAST(CASE WHEN EXISTS (SELECT 1 FROM [INE].[Movements] AS R WHERE R.[ReversesMovementId] = M.[MovementID])
                    THEN 1 ELSE 0 END AS BIT) AS [IsReversed]
        , ML.[StockItemId]
        , SI.[Sku]
        , SI.[UnitOfMeasure]
        , ML.[LotId]
        , LO.[LotNumber]
        , ML.[SerialUnitId]
        , SU.[SerialNumber]
        , ML.[Quantity]
        , ML.[UnitCost]
        , ML.[PurchaseOrderLineId]
        , ML.[AllocationId]
        , M.[Reference]
        , M.[Notes]
        , M.[CreatedById]
        , M.[CreatedDate]
    FROM [INE].[Movements] AS M
    INNER JOIN [INE].[MovementTypes] AS MT ON MT.[MovementTypeID] = M.[MovementTypeId]
    INNER JOIN [INE].[MovementLines] AS ML ON ML.[MovementId] = M.[MovementID]
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = ML.[StockItemId]
    LEFT JOIN [INE].[Locations] AS FL ON FL.[LocationID] = M.[FromLocationId]
    LEFT JOIN [INE].[Locations] AS TL ON TL.[LocationID] = M.[ToLocationId]
    LEFT JOIN [INE].[Lots] AS LO ON LO.[LotID] = ML.[LotId]
    LEFT JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = ML.[SerialUnitId];';

    -- INE.vwStockBalanceDrift (Views/INE/vwStockBalanceDrift.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER VIEW [INE].[vwStockBalanceDrift]
AS
    WITH [Ledger] AS
    (
        SELECT M.[DealerTenantId], M.[ToLocationId] AS [LocationId], ML.[StockItemId], ML.[LotId], ML.[Quantity]
        FROM [INE].[Movements] AS M
        INNER JOIN [INE].[MovementLines] AS ML ON ML.[MovementId] = M.[MovementID]
        WHERE M.[ToLocationId] IS NOT NULL
        UNION ALL
        SELECT M.[DealerTenantId], M.[FromLocationId], ML.[StockItemId], ML.[LotId], -ML.[Quantity]
        FROM [INE].[Movements] AS M
        INNER JOIN [INE].[MovementLines] AS ML ON ML.[MovementId] = M.[MovementID]
        WHERE M.[FromLocationId] IS NOT NULL
    ),
    [LedgerTotals] AS
    (
        SELECT [DealerTenantId], [LocationId], [StockItemId], [LotId], SUM([Quantity]) AS [QuantityOnHand]
        FROM [Ledger]
        GROUP BY [DealerTenantId], [LocationId], [StockItemId], [LotId]
    ),
    [AllocationTotals] AS
    (
        SELECT [LocationId], [StockItemId], [LotId], SUM([QuantityAllocated] - [QuantityIssued]) AS [QuantityAllocated]
        FROM [INE].[Allocations]
        WHERE [Status] = ''Open''
        GROUP BY [LocationId], [StockItemId], [LotId]
    ),
    [Expected] AS
    (
        SELECT
            COALESCE(LT.[DealerTenantId], SB.[DealerTenantId]) AS [DealerTenantId]
            , COALESCE(LT.[LocationId], SB.[LocationId]) AS [LocationId]
            , COALESCE(LT.[StockItemId], SB.[StockItemId]) AS [StockItemId]
            , COALESCE(LT.[LotId], SB.[LotId]) AS [LotId]
            , ISNULL(LT.[QuantityOnHand], 0) AS [LedgerOnHand]
            , ISNULL(SB.[QuantityOnHand], 0) AS [BalanceOnHand]
            , ISNULL(SB.[QuantityAllocated], 0) AS [BalanceAllocated]
        FROM [LedgerTotals] AS LT
        FULL OUTER JOIN [INE].[StockBalances] AS SB
            ON SB.[LocationId] = LT.[LocationId] AND SB.[StockItemId] = LT.[StockItemId]
           AND ((SB.[LotId] = LT.[LotId]) OR (SB.[LotId] IS NULL AND LT.[LotId] IS NULL))
    )
    SELECT
        E.[DealerTenantId]
        , E.[LocationId]
        , E.[StockItemId]
        , E.[LotId]
        , E.[LedgerOnHand]
        , E.[BalanceOnHand]
        , ISNULL(AT.[QuantityAllocated], 0) AS [OpenAllocations]
        , E.[BalanceAllocated]
    FROM [Expected] AS E
    LEFT JOIN [AllocationTotals] AS AT
        ON AT.[LocationId] = E.[LocationId] AND AT.[StockItemId] = E.[StockItemId]
       AND ((AT.[LotId] = E.[LotId]) OR (AT.[LotId] IS NULL AND E.[LotId] IS NULL))
    WHERE E.[LedgerOnHand] <> E.[BalanceOnHand]
       OR ISNULL(AT.[QuantityAllocated], 0) <> E.[BalanceAllocated];';

    -- INE.tr_Movements_PreventChange (Triggers/INE/tr_Movements_PreventChange.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_Movements_PreventChange]
ON [INE].[Movements]
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted)
        THROW 50000, N''04170|:|INE.Movements is append-only. Use INE.spMovementReverse to correct a movement.'', 1;
END;';

    -- INE.tr_MovementLines_PreventChange (Triggers/INE/tr_MovementLines_PreventChange.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_MovementLines_PreventChange]
ON [INE].[MovementLines]
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted)
        THROW 50000, N''04170|:|INE.MovementLines is append-only. Use INE.spMovementReverse to correct a movement.'', 1;
END;';

    -- INE.tr_PurchaseOrderLines_GuardStatus (Triggers/INE/tr_PurchaseOrderLines_GuardStatus.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_PurchaseOrderLines_GuardStatus]
ON [INE].[PurchaseOrderLines]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

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
              WHERE I.[PurchaseOrderId] <> D.[PurchaseOrderId] OR I.[StockItemId] <> D.[StockItemId]
                 OR I.[QuantityOrdered] <> D.[QuantityOrdered] OR I.[UnitCost] <> D.[UnitCost]
                 OR I.[IsDeleted] <> D.[IsDeleted]) AS C
        INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = C.[PurchaseOrderId]
        WHERE PO.[Status] <> ''Draft'')
        THROW 50000, N''04171|:|Purchase order lines can only be changed while the purchase order is Draft.'', 1;
END;';

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Create the INE inventory engine procedures, views and triggers',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
