/*
Migration: 20261117_1900_AddINE_AuditAndTenantGuards
Author: Andres Sosa
Date: 2026-11-17
Description: Follow-ups from the review of the INE inventory engine:
               1. INE.spMovementPost: reversing an IssueToJob no longer reopens an allocation
                  that was Cancelled; the returned stock comes back unreserved.
               2. Audit triggers (trgAutoGen_*_CUD, writing AUD.AuditActions and
                  AUD.AuditActionColumns) on the purchase order and master data tables:
                  Vendors, Locations, StockItems, StockLevels, PurchaseOrders, PurchaseOrderLines.
               3. Tenant guard triggers (tr_*_TenantGuard) on every INE table the API writes
                  with plain CRUD: Vendors, Locations, StockItems, StockLevels, Lots, PurchaseOrders, PurchaseOrderLines, StockCounts, StockCountLines.
                  A row must belong to the session's tenant (04180), may only reference rows
                  of its own tenant (04181), and cannot change tenant (04182).
             Each object's source of truth is its file under Procedures/INE and Triggers/INE;
             this migration embeds those files. The API must list the new triggers in
             SolastaDbContext.TableTriggers before it maps these tables.
Dependencies:
  20261117_1810_CreateINE_InventoryEngineProcedures, AUD.AuditActions, AUD.AuditActionColumns,
  ACC.fxGetContextUserTable
Rollback:
  DROP TRIGGER [INE].[tr_Vendors_TenantGuard];
  DROP TRIGGER [INE].[tr_Locations_TenantGuard];
  DROP TRIGGER [INE].[tr_StockItems_TenantGuard];
  DROP TRIGGER [INE].[tr_StockLevels_TenantGuard];
  DROP TRIGGER [INE].[tr_Lots_TenantGuard];
  DROP TRIGGER [INE].[tr_PurchaseOrders_TenantGuard];
  DROP TRIGGER [INE].[tr_PurchaseOrderLines_TenantGuard];
  DROP TRIGGER [INE].[tr_StockCounts_TenantGuard];
  DROP TRIGGER [INE].[tr_StockCountLines_TenantGuard];
  DROP TRIGGER [INE].[trgAutoGen_Vendors_CUD];
  DROP TRIGGER [INE].[trgAutoGen_Locations_CUD];
  DROP TRIGGER [INE].[trgAutoGen_StockItems_CUD];
  DROP TRIGGER [INE].[trgAutoGen_StockLevels_CUD];
  DROP TRIGGER [INE].[trgAutoGen_PurchaseOrders_CUD];
  DROP TRIGGER [INE].[trgAutoGen_PurchaseOrderLines_CUD];
  Re-apply INE.spMovementPost from 20261117_1810_CreateINE_InventoryEngineProcedures.
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_1900_AddINE_AuditAndTenantGuards';
Expected impact: New triggers on INE tables (no data changes); spMovementPost altered.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261117_1900_AddINE_AuditAndTenantGuards';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[SchemaVersion]
                   WHERE [MigrationName] = N'20261117_1810_CreateINE_InventoryEngineProcedures' AND [Success] = 1)
        THROW 50001, 'Apply 20261117_1810_CreateINE_InventoryEngineProcedures first.', 1;

    IF OBJECT_ID(N'AUD.AuditActions', N'U') IS NULL OR OBJECT_ID(N'AUD.AuditActionColumns', N'U') IS NULL
       OR OBJECT_ID(N'ACC.fxGetContextUserTable') IS NULL
        THROW 50001, 'AUD.AuditActions, AUD.AuditActionColumns and ACC.fxGetContextUserTable must exist.', 1;

    -- The audit triggers write these action types (AuditActions has an FK to them).
    INSERT INTO [AUD].[AuditActionTypes] ([AuditActionTypeID], [AuditActionTypeName])
    SELECT S.[Id], S.[Name]
    FROM (VALUES ('INSERT', 'Insert'), ('UPDATE', 'Update'), ('DELETE', 'Delete'), ('UNDELETE', 'Undelete')) AS S ([Id], [Name])
    WHERE NOT EXISTS (SELECT 1 FROM [AUD].[AuditActionTypes] AS T WHERE T.[AuditActionTypeID] = S.[Id]);

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
        -- A reversed issue gives stock back to its allocation only while the allocation is
        -- still live; stock from a Cancelled allocation comes back unreserved.
        INSERT INTO @Totals ([StockItemId], [LotId], [Quantity], [AllocatedQuantity])
        SELECT LN.[StockItemId], LN.[LotId], SUM(LN.[Quantity]),
               SUM(CASE WHEN LN.[AllocationId] IS NOT NULL AND ISNULL(A.[Status], '''') <> ''Cancelled'' THEN LN.[Quantity] ELSE 0 END)
        FROM @Lines AS LN
        LEFT JOIN [INE].[Allocations] AS A ON A.[AllocationID] = LN.[AllocationId]
        GROUP BY LN.[StockItemId], LN.[LotId];

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
                -- A Cancelled allocation stays Cancelled when an issue against it is reversed.
                , A.[Status] = CASE WHEN A.[Status] = ''Cancelled'' THEN ''Cancelled''
                                    WHEN A.[QuantityIssued] + CASE WHEN @IsReversal = 1 THEN -Q.[Qty] ELSE Q.[Qty] END
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

    -- INE.trgAutoGen_Vendors_CUD (Triggers/INE/trgAutoGen_Vendors_CUD.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[trgAutoGen_Vendors_CUD]
ON [INE].[Vendors]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    DECLARE @UserID UNIQUEIDENTIFIER = (SELECT [UserId] FROM [INE].[fxGetSessionContext]());
    IF @UserID IS NULL
        SELECT @UserID = [UserID] FROM [ACC].[fxGetContextUserTable]();

    DECLARE @Changes TABLE
    (
        [PKID] BIGINT NOT NULL
        , [IsInsert] BIT NOT NULL
        , [ColumnName] NVARCHAR(500) NOT NULL
        , [OldValue] NVARCHAR(500) NULL
        , [NewValue] NVARCHAR(500) NULL
    );

    INSERT INTO @Changes ([PKID], [IsInsert], [ColumnName], [OldValue], [NewValue])
    SELECT I.[VendorID], CASE WHEN D.[VendorID] IS NULL THEN 1 ELSE 0 END, V.[ColumnName], V.[OldValue], V.[NewValue]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[VendorID] = I.[VendorID]
    CROSS APPLY (VALUES
            (N''VendorID'', CAST(D.[VendorID] AS NVARCHAR(500)), CAST(I.[VendorID] AS NVARCHAR(500))),
            (N''DealerTenantId'', CAST(D.[DealerTenantId] AS NVARCHAR(500)), CAST(I.[DealerTenantId] AS NVARCHAR(500))),
            (N''PoliticalStateId'', CAST(D.[PoliticalStateId] AS NVARCHAR(500)), CAST(I.[PoliticalStateId] AS NVARCHAR(500))),
            (N''Code'', CAST(D.[Code] AS NVARCHAR(500)), CAST(I.[Code] AS NVARCHAR(500))),
            (N''Name'', CAST(D.[Name] AS NVARCHAR(500)), CAST(I.[Name] AS NVARCHAR(500))),
            (N''ContactName'', CAST(D.[ContactName] AS NVARCHAR(500)), CAST(I.[ContactName] AS NVARCHAR(500))),
            (N''Email'', CAST(D.[Email] AS NVARCHAR(500)), CAST(I.[Email] AS NVARCHAR(500))),
            (N''Phone'', CAST(D.[Phone] AS NVARCHAR(500)), CAST(I.[Phone] AS NVARCHAR(500))),
            (N''Website'', CAST(D.[Website] AS NVARCHAR(500)), CAST(I.[Website] AS NVARCHAR(500))),
            (N''StreetAddress'', CAST(D.[StreetAddress] AS NVARCHAR(500)), CAST(I.[StreetAddress] AS NVARCHAR(500))),
            (N''StreetAddress2'', CAST(D.[StreetAddress2] AS NVARCHAR(500)), CAST(I.[StreetAddress2] AS NVARCHAR(500))),
            (N''City'', CAST(D.[City] AS NVARCHAR(500)), CAST(I.[City] AS NVARCHAR(500))),
            (N''PostalCode'', CAST(D.[PostalCode] AS NVARCHAR(500)), CAST(I.[PostalCode] AS NVARCHAR(500))),
            (N''LeadTimeDays'', CAST(D.[LeadTimeDays] AS NVARCHAR(500)), CAST(I.[LeadTimeDays] AS NVARCHAR(500))),
            (N''PaymentTerms'', CAST(D.[PaymentTerms] AS NVARCHAR(500)), CAST(I.[PaymentTerms] AS NVARCHAR(500))),
            (N''Notes'', CAST(D.[Notes] AS NVARCHAR(500)), CAST(I.[Notes] AS NVARCHAR(500))),
            (N''IsActive'', CAST(D.[IsActive] AS NVARCHAR(500)), CAST(I.[IsActive] AS NVARCHAR(500))),
            (N''IsDeleted'', CAST(D.[IsDeleted] AS NVARCHAR(500)), CAST(I.[IsDeleted] AS NVARCHAR(500)))
    ) AS V ([ColumnName], [OldValue], [NewValue])
    WHERE (D.[VendorID] IS NULL AND V.[NewValue] IS NOT NULL)
       OR (D.[VendorID] IS NOT NULL
           -- binary compare, so a change in letter case is recorded too
           AND (V.[OldValue] COLLATE Latin1_General_BIN2 <> V.[NewValue] COLLATE Latin1_General_BIN2
                OR (V.[OldValue] IS NULL AND V.[NewValue] IS NOT NULL)
                OR (V.[OldValue] IS NOT NULL AND V.[NewValue] IS NULL)));

    IF NOT EXISTS (SELECT 1 FROM @Changes) RETURN;

    DECLARE @Actions TABLE ([AuditActionID] BIGINT NOT NULL, [PKID] VARCHAR(50) NOT NULL);

    INSERT INTO [AUD].[AuditActions] ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.[AuditActionID], INSERTED.[PrimaryKeyIdentifier] INTO @Actions ([AuditActionID], [PKID])
    SELECT
        CASE
            WHEN MAX(CAST(C.[IsInsert] AS INT)) = 1 THEN ''INSERT''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''1'' THEN 1 ELSE 0 END) = 1 THEN ''DELETE''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''0'' THEN 1 ELSE 0 END) = 1 THEN ''UNDELETE''
            ELSE ''UPDATE''
        END
        , ''INE''
        , ''Vendors''
        , CAST(C.[PKID] AS VARCHAR(50))
        , @UserID
    FROM @Changes AS C
    GROUP BY C.[PKID];

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT A.[AuditActionID], C.[ColumnName], C.[OldValue], C.[NewValue]
    FROM @Changes AS C
    INNER JOIN @Actions AS A ON A.[PKID] = CAST(C.[PKID] AS VARCHAR(50));
END;';

    -- INE.trgAutoGen_Locations_CUD (Triggers/INE/trgAutoGen_Locations_CUD.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[trgAutoGen_Locations_CUD]
ON [INE].[Locations]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    DECLARE @UserID UNIQUEIDENTIFIER = (SELECT [UserId] FROM [INE].[fxGetSessionContext]());
    IF @UserID IS NULL
        SELECT @UserID = [UserID] FROM [ACC].[fxGetContextUserTable]();

    DECLARE @Changes TABLE
    (
        [PKID] BIGINT NOT NULL
        , [IsInsert] BIT NOT NULL
        , [ColumnName] NVARCHAR(500) NOT NULL
        , [OldValue] NVARCHAR(500) NULL
        , [NewValue] NVARCHAR(500) NULL
    );

    INSERT INTO @Changes ([PKID], [IsInsert], [ColumnName], [OldValue], [NewValue])
    SELECT I.[LocationID], CASE WHEN D.[LocationID] IS NULL THEN 1 ELSE 0 END, V.[ColumnName], V.[OldValue], V.[NewValue]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[LocationID] = I.[LocationID]
    CROSS APPLY (VALUES
            (N''LocationID'', CAST(D.[LocationID] AS NVARCHAR(500)), CAST(I.[LocationID] AS NVARCHAR(500))),
            (N''DealerTenantId'', CAST(D.[DealerTenantId] AS NVARCHAR(500)), CAST(I.[DealerTenantId] AS NVARCHAR(500))),
            (N''LocationTypeId'', CAST(D.[LocationTypeId] AS NVARCHAR(500)), CAST(I.[LocationTypeId] AS NVARCHAR(500))),
            (N''UserId'', CAST(D.[UserId] AS NVARCHAR(500)), CAST(I.[UserId] AS NVARCHAR(500))),
            (N''LeadId'', CAST(D.[LeadId] AS NVARCHAR(500)), CAST(I.[LeadId] AS NVARCHAR(500))),
            (N''VendorId'', CAST(D.[VendorId] AS NVARCHAR(500)), CAST(I.[VendorId] AS NVARCHAR(500))),
            (N''PoliticalStateId'', CAST(D.[PoliticalStateId] AS NVARCHAR(500)), CAST(I.[PoliticalStateId] AS NVARCHAR(500))),
            (N''Code'', CAST(D.[Code] AS NVARCHAR(500)), CAST(I.[Code] AS NVARCHAR(500))),
            (N''Name'', CAST(D.[Name] AS NVARCHAR(500)), CAST(I.[Name] AS NVARCHAR(500))),
            (N''StreetAddress'', CAST(D.[StreetAddress] AS NVARCHAR(500)), CAST(I.[StreetAddress] AS NVARCHAR(500))),
            (N''StreetAddress2'', CAST(D.[StreetAddress2] AS NVARCHAR(500)), CAST(I.[StreetAddress2] AS NVARCHAR(500))),
            (N''City'', CAST(D.[City] AS NVARCHAR(500)), CAST(I.[City] AS NVARCHAR(500))),
            (N''PostalCode'', CAST(D.[PostalCode] AS NVARCHAR(500)), CAST(I.[PostalCode] AS NVARCHAR(500))),
            (N''Notes'', CAST(D.[Notes] AS NVARCHAR(500)), CAST(I.[Notes] AS NVARCHAR(500))),
            (N''IsActive'', CAST(D.[IsActive] AS NVARCHAR(500)), CAST(I.[IsActive] AS NVARCHAR(500))),
            (N''IsDeleted'', CAST(D.[IsDeleted] AS NVARCHAR(500)), CAST(I.[IsDeleted] AS NVARCHAR(500)))
    ) AS V ([ColumnName], [OldValue], [NewValue])
    WHERE (D.[LocationID] IS NULL AND V.[NewValue] IS NOT NULL)
       OR (D.[LocationID] IS NOT NULL
           -- binary compare, so a change in letter case is recorded too
           AND (V.[OldValue] COLLATE Latin1_General_BIN2 <> V.[NewValue] COLLATE Latin1_General_BIN2
                OR (V.[OldValue] IS NULL AND V.[NewValue] IS NOT NULL)
                OR (V.[OldValue] IS NOT NULL AND V.[NewValue] IS NULL)));

    IF NOT EXISTS (SELECT 1 FROM @Changes) RETURN;

    DECLARE @Actions TABLE ([AuditActionID] BIGINT NOT NULL, [PKID] VARCHAR(50) NOT NULL);

    INSERT INTO [AUD].[AuditActions] ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.[AuditActionID], INSERTED.[PrimaryKeyIdentifier] INTO @Actions ([AuditActionID], [PKID])
    SELECT
        CASE
            WHEN MAX(CAST(C.[IsInsert] AS INT)) = 1 THEN ''INSERT''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''1'' THEN 1 ELSE 0 END) = 1 THEN ''DELETE''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''0'' THEN 1 ELSE 0 END) = 1 THEN ''UNDELETE''
            ELSE ''UPDATE''
        END
        , ''INE''
        , ''Locations''
        , CAST(C.[PKID] AS VARCHAR(50))
        , @UserID
    FROM @Changes AS C
    GROUP BY C.[PKID];

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT A.[AuditActionID], C.[ColumnName], C.[OldValue], C.[NewValue]
    FROM @Changes AS C
    INNER JOIN @Actions AS A ON A.[PKID] = CAST(C.[PKID] AS VARCHAR(50));
END;';

    -- INE.trgAutoGen_StockItems_CUD (Triggers/INE/trgAutoGen_StockItems_CUD.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[trgAutoGen_StockItems_CUD]
ON [INE].[StockItems]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    DECLARE @UserID UNIQUEIDENTIFIER = (SELECT [UserId] FROM [INE].[fxGetSessionContext]());
    IF @UserID IS NULL
        SELECT @UserID = [UserID] FROM [ACC].[fxGetContextUserTable]();

    DECLARE @Changes TABLE
    (
        [PKID] BIGINT NOT NULL
        , [IsInsert] BIT NOT NULL
        , [ColumnName] NVARCHAR(500) NOT NULL
        , [OldValue] NVARCHAR(500) NULL
        , [NewValue] NVARCHAR(500) NULL
    );

    INSERT INTO @Changes ([PKID], [IsInsert], [ColumnName], [OldValue], [NewValue])
    SELECT I.[StockItemID], CASE WHEN D.[StockItemID] IS NULL THEN 1 ELSE 0 END, V.[ColumnName], V.[OldValue], V.[NewValue]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockItemID] = I.[StockItemID]
    CROSS APPLY (VALUES
            (N''StockItemID'', CAST(D.[StockItemID] AS NVARCHAR(500)), CAST(I.[StockItemID] AS NVARCHAR(500))),
            (N''DealerTenantId'', CAST(D.[DealerTenantId] AS NVARCHAR(500)), CAST(I.[DealerTenantId] AS NVARCHAR(500))),
            (N''ProductId'', CAST(D.[ProductId] AS NVARCHAR(500)), CAST(I.[ProductId] AS NVARCHAR(500))),
            (N''DefaultVendorId'', CAST(D.[DefaultVendorId] AS NVARCHAR(500)), CAST(I.[DefaultVendorId] AS NVARCHAR(500))),
            (N''Sku'', CAST(D.[Sku] AS NVARCHAR(500)), CAST(I.[Sku] AS NVARCHAR(500))),
            (N''Name'', CAST(D.[Name] AS NVARCHAR(500)), CAST(I.[Name] AS NVARCHAR(500))),
            (N''Description'', CAST(D.[Description] AS NVARCHAR(500)), CAST(I.[Description] AS NVARCHAR(500))),
            (N''Category'', CAST(D.[Category] AS NVARCHAR(500)), CAST(I.[Category] AS NVARCHAR(500))),
            (N''TrackingMode'', CAST(D.[TrackingMode] AS NVARCHAR(500)), CAST(I.[TrackingMode] AS NVARCHAR(500))),
            (N''UnitOfMeasure'', CAST(D.[UnitOfMeasure] AS NVARCHAR(500)), CAST(I.[UnitOfMeasure] AS NVARCHAR(500))),
            (N''VendorSku'', CAST(D.[VendorSku] AS NVARCHAR(500)), CAST(I.[VendorSku] AS NVARCHAR(500))),
            (N''StandardCost'', CAST(D.[StandardCost] AS NVARCHAR(500)), CAST(I.[StandardCost] AS NVARCHAR(500))),
            (N''IsActive'', CAST(D.[IsActive] AS NVARCHAR(500)), CAST(I.[IsActive] AS NVARCHAR(500))),
            (N''IsDeleted'', CAST(D.[IsDeleted] AS NVARCHAR(500)), CAST(I.[IsDeleted] AS NVARCHAR(500)))
    ) AS V ([ColumnName], [OldValue], [NewValue])
    WHERE (D.[StockItemID] IS NULL AND V.[NewValue] IS NOT NULL)
       OR (D.[StockItemID] IS NOT NULL
           -- binary compare, so a change in letter case is recorded too
           AND (V.[OldValue] COLLATE Latin1_General_BIN2 <> V.[NewValue] COLLATE Latin1_General_BIN2
                OR (V.[OldValue] IS NULL AND V.[NewValue] IS NOT NULL)
                OR (V.[OldValue] IS NOT NULL AND V.[NewValue] IS NULL)));

    IF NOT EXISTS (SELECT 1 FROM @Changes) RETURN;

    DECLARE @Actions TABLE ([AuditActionID] BIGINT NOT NULL, [PKID] VARCHAR(50) NOT NULL);

    INSERT INTO [AUD].[AuditActions] ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.[AuditActionID], INSERTED.[PrimaryKeyIdentifier] INTO @Actions ([AuditActionID], [PKID])
    SELECT
        CASE
            WHEN MAX(CAST(C.[IsInsert] AS INT)) = 1 THEN ''INSERT''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''1'' THEN 1 ELSE 0 END) = 1 THEN ''DELETE''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''0'' THEN 1 ELSE 0 END) = 1 THEN ''UNDELETE''
            ELSE ''UPDATE''
        END
        , ''INE''
        , ''StockItems''
        , CAST(C.[PKID] AS VARCHAR(50))
        , @UserID
    FROM @Changes AS C
    GROUP BY C.[PKID];

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT A.[AuditActionID], C.[ColumnName], C.[OldValue], C.[NewValue]
    FROM @Changes AS C
    INNER JOIN @Actions AS A ON A.[PKID] = CAST(C.[PKID] AS VARCHAR(50));
END;';

    -- INE.trgAutoGen_StockLevels_CUD (Triggers/INE/trgAutoGen_StockLevels_CUD.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[trgAutoGen_StockLevels_CUD]
ON [INE].[StockLevels]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    DECLARE @UserID UNIQUEIDENTIFIER = (SELECT [UserId] FROM [INE].[fxGetSessionContext]());
    IF @UserID IS NULL
        SELECT @UserID = [UserID] FROM [ACC].[fxGetContextUserTable]();

    DECLARE @Changes TABLE
    (
        [PKID] BIGINT NOT NULL
        , [IsInsert] BIT NOT NULL
        , [ColumnName] NVARCHAR(500) NOT NULL
        , [OldValue] NVARCHAR(500) NULL
        , [NewValue] NVARCHAR(500) NULL
    );

    INSERT INTO @Changes ([PKID], [IsInsert], [ColumnName], [OldValue], [NewValue])
    SELECT I.[StockLevelID], CASE WHEN D.[StockLevelID] IS NULL THEN 1 ELSE 0 END, V.[ColumnName], V.[OldValue], V.[NewValue]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockLevelID] = I.[StockLevelID]
    CROSS APPLY (VALUES
            (N''StockLevelID'', CAST(D.[StockLevelID] AS NVARCHAR(500)), CAST(I.[StockLevelID] AS NVARCHAR(500))),
            (N''DealerTenantId'', CAST(D.[DealerTenantId] AS NVARCHAR(500)), CAST(I.[DealerTenantId] AS NVARCHAR(500))),
            (N''StockItemId'', CAST(D.[StockItemId] AS NVARCHAR(500)), CAST(I.[StockItemId] AS NVARCHAR(500))),
            (N''LocationId'', CAST(D.[LocationId] AS NVARCHAR(500)), CAST(I.[LocationId] AS NVARCHAR(500))),
            (N''ReorderPoint'', CAST(D.[ReorderPoint] AS NVARCHAR(500)), CAST(I.[ReorderPoint] AS NVARCHAR(500))),
            (N''MaximumQuantity'', CAST(D.[MaximumQuantity] AS NVARCHAR(500)), CAST(I.[MaximumQuantity] AS NVARCHAR(500))),
            (N''IsActive'', CAST(D.[IsActive] AS NVARCHAR(500)), CAST(I.[IsActive] AS NVARCHAR(500))),
            (N''IsDeleted'', CAST(D.[IsDeleted] AS NVARCHAR(500)), CAST(I.[IsDeleted] AS NVARCHAR(500)))
    ) AS V ([ColumnName], [OldValue], [NewValue])
    WHERE (D.[StockLevelID] IS NULL AND V.[NewValue] IS NOT NULL)
       OR (D.[StockLevelID] IS NOT NULL
           -- binary compare, so a change in letter case is recorded too
           AND (V.[OldValue] COLLATE Latin1_General_BIN2 <> V.[NewValue] COLLATE Latin1_General_BIN2
                OR (V.[OldValue] IS NULL AND V.[NewValue] IS NOT NULL)
                OR (V.[OldValue] IS NOT NULL AND V.[NewValue] IS NULL)));

    IF NOT EXISTS (SELECT 1 FROM @Changes) RETURN;

    DECLARE @Actions TABLE ([AuditActionID] BIGINT NOT NULL, [PKID] VARCHAR(50) NOT NULL);

    INSERT INTO [AUD].[AuditActions] ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.[AuditActionID], INSERTED.[PrimaryKeyIdentifier] INTO @Actions ([AuditActionID], [PKID])
    SELECT
        CASE
            WHEN MAX(CAST(C.[IsInsert] AS INT)) = 1 THEN ''INSERT''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''1'' THEN 1 ELSE 0 END) = 1 THEN ''DELETE''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''0'' THEN 1 ELSE 0 END) = 1 THEN ''UNDELETE''
            ELSE ''UPDATE''
        END
        , ''INE''
        , ''StockLevels''
        , CAST(C.[PKID] AS VARCHAR(50))
        , @UserID
    FROM @Changes AS C
    GROUP BY C.[PKID];

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT A.[AuditActionID], C.[ColumnName], C.[OldValue], C.[NewValue]
    FROM @Changes AS C
    INNER JOIN @Actions AS A ON A.[PKID] = CAST(C.[PKID] AS VARCHAR(50));
END;';

    -- INE.trgAutoGen_PurchaseOrders_CUD (Triggers/INE/trgAutoGen_PurchaseOrders_CUD.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[trgAutoGen_PurchaseOrders_CUD]
ON [INE].[PurchaseOrders]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    DECLARE @UserID UNIQUEIDENTIFIER = (SELECT [UserId] FROM [INE].[fxGetSessionContext]());
    IF @UserID IS NULL
        SELECT @UserID = [UserID] FROM [ACC].[fxGetContextUserTable]();

    DECLARE @Changes TABLE
    (
        [PKID] BIGINT NOT NULL
        , [IsInsert] BIT NOT NULL
        , [ColumnName] NVARCHAR(500) NOT NULL
        , [OldValue] NVARCHAR(500) NULL
        , [NewValue] NVARCHAR(500) NULL
    );

    INSERT INTO @Changes ([PKID], [IsInsert], [ColumnName], [OldValue], [NewValue])
    SELECT I.[PurchaseOrderID], CASE WHEN D.[PurchaseOrderID] IS NULL THEN 1 ELSE 0 END, V.[ColumnName], V.[OldValue], V.[NewValue]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[PurchaseOrderID] = I.[PurchaseOrderID]
    CROSS APPLY (VALUES
            (N''PurchaseOrderID'', CAST(D.[PurchaseOrderID] AS NVARCHAR(500)), CAST(I.[PurchaseOrderID] AS NVARCHAR(500))),
            (N''DealerTenantId'', CAST(D.[DealerTenantId] AS NVARCHAR(500)), CAST(I.[DealerTenantId] AS NVARCHAR(500))),
            (N''VendorId'', CAST(D.[VendorId] AS NVARCHAR(500)), CAST(I.[VendorId] AS NVARCHAR(500))),
            (N''ShipToLocationId'', CAST(D.[ShipToLocationId] AS NVARCHAR(500)), CAST(I.[ShipToLocationId] AS NVARCHAR(500))),
            (N''PONumber'', CAST(D.[PONumber] AS NVARCHAR(500)), CAST(I.[PONumber] AS NVARCHAR(500))),
            (N''Status'', CAST(D.[Status] AS NVARCHAR(500)), CAST(I.[Status] AS NVARCHAR(500))),
            (N''OrderDate'', CAST(D.[OrderDate] AS NVARCHAR(500)), CAST(I.[OrderDate] AS NVARCHAR(500))),
            (N''ExpectedDate'', CAST(D.[ExpectedDate] AS NVARCHAR(500)), CAST(I.[ExpectedDate] AS NVARCHAR(500))),
            (N''VendorReference'', CAST(D.[VendorReference] AS NVARCHAR(500)), CAST(I.[VendorReference] AS NVARCHAR(500))),
            (N''ShippingAmount'', CAST(D.[ShippingAmount] AS NVARCHAR(500)), CAST(I.[ShippingAmount] AS NVARCHAR(500))),
            (N''TaxAmount'', CAST(D.[TaxAmount] AS NVARCHAR(500)), CAST(I.[TaxAmount] AS NVARCHAR(500))),
            (N''Notes'', CAST(D.[Notes] AS NVARCHAR(500)), CAST(I.[Notes] AS NVARCHAR(500))),
            (N''SubmittedDate'', CAST(D.[SubmittedDate] AS NVARCHAR(500)), CAST(I.[SubmittedDate] AS NVARCHAR(500))),
            (N''ClosedDate'', CAST(D.[ClosedDate] AS NVARCHAR(500)), CAST(I.[ClosedDate] AS NVARCHAR(500))),
            (N''IsActive'', CAST(D.[IsActive] AS NVARCHAR(500)), CAST(I.[IsActive] AS NVARCHAR(500))),
            (N''IsDeleted'', CAST(D.[IsDeleted] AS NVARCHAR(500)), CAST(I.[IsDeleted] AS NVARCHAR(500)))
    ) AS V ([ColumnName], [OldValue], [NewValue])
    WHERE (D.[PurchaseOrderID] IS NULL AND V.[NewValue] IS NOT NULL)
       OR (D.[PurchaseOrderID] IS NOT NULL
           -- binary compare, so a change in letter case is recorded too
           AND (V.[OldValue] COLLATE Latin1_General_BIN2 <> V.[NewValue] COLLATE Latin1_General_BIN2
                OR (V.[OldValue] IS NULL AND V.[NewValue] IS NOT NULL)
                OR (V.[OldValue] IS NOT NULL AND V.[NewValue] IS NULL)));

    IF NOT EXISTS (SELECT 1 FROM @Changes) RETURN;

    DECLARE @Actions TABLE ([AuditActionID] BIGINT NOT NULL, [PKID] VARCHAR(50) NOT NULL);

    INSERT INTO [AUD].[AuditActions] ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.[AuditActionID], INSERTED.[PrimaryKeyIdentifier] INTO @Actions ([AuditActionID], [PKID])
    SELECT
        CASE
            WHEN MAX(CAST(C.[IsInsert] AS INT)) = 1 THEN ''INSERT''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''1'' THEN 1 ELSE 0 END) = 1 THEN ''DELETE''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''0'' THEN 1 ELSE 0 END) = 1 THEN ''UNDELETE''
            ELSE ''UPDATE''
        END
        , ''INE''
        , ''PurchaseOrders''
        , CAST(C.[PKID] AS VARCHAR(50))
        , @UserID
    FROM @Changes AS C
    GROUP BY C.[PKID];

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT A.[AuditActionID], C.[ColumnName], C.[OldValue], C.[NewValue]
    FROM @Changes AS C
    INNER JOIN @Actions AS A ON A.[PKID] = CAST(C.[PKID] AS VARCHAR(50));
END;';

    -- INE.trgAutoGen_PurchaseOrderLines_CUD (Triggers/INE/trgAutoGen_PurchaseOrderLines_CUD.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[trgAutoGen_PurchaseOrderLines_CUD]
ON [INE].[PurchaseOrderLines]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    DECLARE @UserID UNIQUEIDENTIFIER = (SELECT [UserId] FROM [INE].[fxGetSessionContext]());
    IF @UserID IS NULL
        SELECT @UserID = [UserID] FROM [ACC].[fxGetContextUserTable]();

    DECLARE @Changes TABLE
    (
        [PKID] BIGINT NOT NULL
        , [IsInsert] BIT NOT NULL
        , [ColumnName] NVARCHAR(500) NOT NULL
        , [OldValue] NVARCHAR(500) NULL
        , [NewValue] NVARCHAR(500) NULL
    );

    INSERT INTO @Changes ([PKID], [IsInsert], [ColumnName], [OldValue], [NewValue])
    SELECT I.[PurchaseOrderLineID], CASE WHEN D.[PurchaseOrderLineID] IS NULL THEN 1 ELSE 0 END, V.[ColumnName], V.[OldValue], V.[NewValue]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[PurchaseOrderLineID] = I.[PurchaseOrderLineID]
    CROSS APPLY (VALUES
            (N''PurchaseOrderLineID'', CAST(D.[PurchaseOrderLineID] AS NVARCHAR(500)), CAST(I.[PurchaseOrderLineID] AS NVARCHAR(500))),
            (N''PurchaseOrderId'', CAST(D.[PurchaseOrderId] AS NVARCHAR(500)), CAST(I.[PurchaseOrderId] AS NVARCHAR(500))),
            (N''StockItemId'', CAST(D.[StockItemId] AS NVARCHAR(500)), CAST(I.[StockItemId] AS NVARCHAR(500))),
            (N''LineNumber'', CAST(D.[LineNumber] AS NVARCHAR(500)), CAST(I.[LineNumber] AS NVARCHAR(500))),
            (N''QuantityOrdered'', CAST(D.[QuantityOrdered] AS NVARCHAR(500)), CAST(I.[QuantityOrdered] AS NVARCHAR(500))),
            (N''QuantityReceived'', CAST(D.[QuantityReceived] AS NVARCHAR(500)), CAST(I.[QuantityReceived] AS NVARCHAR(500))),
            (N''UnitCost'', CAST(D.[UnitCost] AS NVARCHAR(500)), CAST(I.[UnitCost] AS NVARCHAR(500))),
            (N''Notes'', CAST(D.[Notes] AS NVARCHAR(500)), CAST(I.[Notes] AS NVARCHAR(500))),
            (N''IsActive'', CAST(D.[IsActive] AS NVARCHAR(500)), CAST(I.[IsActive] AS NVARCHAR(500))),
            (N''IsDeleted'', CAST(D.[IsDeleted] AS NVARCHAR(500)), CAST(I.[IsDeleted] AS NVARCHAR(500)))
    ) AS V ([ColumnName], [OldValue], [NewValue])
    WHERE (D.[PurchaseOrderLineID] IS NULL AND V.[NewValue] IS NOT NULL)
       OR (D.[PurchaseOrderLineID] IS NOT NULL
           -- binary compare, so a change in letter case is recorded too
           AND (V.[OldValue] COLLATE Latin1_General_BIN2 <> V.[NewValue] COLLATE Latin1_General_BIN2
                OR (V.[OldValue] IS NULL AND V.[NewValue] IS NOT NULL)
                OR (V.[OldValue] IS NOT NULL AND V.[NewValue] IS NULL)));

    IF NOT EXISTS (SELECT 1 FROM @Changes) RETURN;

    DECLARE @Actions TABLE ([AuditActionID] BIGINT NOT NULL, [PKID] VARCHAR(50) NOT NULL);

    INSERT INTO [AUD].[AuditActions] ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.[AuditActionID], INSERTED.[PrimaryKeyIdentifier] INTO @Actions ([AuditActionID], [PKID])
    SELECT
        CASE
            WHEN MAX(CAST(C.[IsInsert] AS INT)) = 1 THEN ''INSERT''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''1'' THEN 1 ELSE 0 END) = 1 THEN ''DELETE''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''0'' THEN 1 ELSE 0 END) = 1 THEN ''UNDELETE''
            ELSE ''UPDATE''
        END
        , ''INE''
        , ''PurchaseOrderLines''
        , CAST(C.[PKID] AS VARCHAR(50))
        , @UserID
    FROM @Changes AS C
    GROUP BY C.[PKID];

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT A.[AuditActionID], C.[ColumnName], C.[OldValue], C.[NewValue]
    FROM @Changes AS C
    INNER JOIN @Actions AS A ON A.[PKID] = CAST(C.[PKID] AS VARCHAR(50));
END;';

    -- INE.tr_Vendors_TenantGuard (Triggers/INE/tr_Vendors_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_Vendors_TenantGuard]
ON [INE].[Vendors]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[VendorID] = I.[VendorID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N''04182|:|INE.Vendors: a row cannot move to another dealer tenant.'', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.Vendors: the row belongs to a different dealer tenant than the signed-in user.'', 1;
END;';

    -- INE.tr_Locations_TenantGuard (Triggers/INE/tr_Locations_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_Locations_TenantGuard]
ON [INE].[Locations]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[LocationID] = I.[LocationID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N''04182|:|INE.Locations: a row cannot move to another dealer tenant.'', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.Locations: the row belongs to a different dealer tenant than the signed-in user.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[VendorId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Vendors] AS V
                  WHERE V.[VendorID] = I.[VendorId] AND V.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[LeadId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [QAL].[Leads] AS LD
                  WHERE LD.[LeadID] = I.[LeadId] AND LD.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[UserId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [ACC].[Users] AS U
                  WHERE U.[UserID] = I.[UserId] AND U.[DealerTenantId] = I.[DealerTenantId])
              AND NOT EXISTS (SELECT 1 FROM [ACC].[UserTenantMemberships] AS M
                  WHERE M.[UserId] = I.[UserId] AND M.[DealerTenantId] = I.[DealerTenantId]
                    AND M.[IsActive] = 1 AND M.[IsDeleted] = 0)))
        THROW 50000, N''04181|:|A location can only name a vendor, lead or user (driver) of its own tenant.'', 1;
END;';

    -- INE.tr_StockItems_TenantGuard (Triggers/INE/tr_StockItems_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_StockItems_TenantGuard]
ON [INE].[StockItems]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[StockItemID] = I.[StockItemID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N''04182|:|INE.StockItems: a row cannot move to another dealer tenant.'', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.StockItems: the row belongs to a different dealer tenant than the signed-in user.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[ProductId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [MAC].[Products] AS P
                  WHERE P.[ProductID] = I.[ProductId] AND P.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[DefaultVendorId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Vendors] AS V
                  WHERE V.[VendorID] = I.[DefaultVendorId] AND V.[DealerTenantId] = I.[DealerTenantId])))
        THROW 50000, N''04181|:|A stock item can only name a product and default vendor of its own tenant.'', 1;
END;';

    -- INE.tr_StockLevels_TenantGuard (Triggers/INE/tr_StockLevels_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_StockLevels_TenantGuard]
ON [INE].[StockLevels]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[StockLevelID] = I.[StockLevelID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N''04182|:|INE.StockLevels: a row cannot move to another dealer tenant.'', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.StockLevels: the row belongs to a different dealer tenant than the signed-in user.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[StockItemId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS SI
                  WHERE SI.[StockItemID] = I.[StockItemId] AND SI.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[LocationId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Locations] AS L
                  WHERE L.[LocationID] = I.[LocationId] AND L.[DealerTenantId] = I.[DealerTenantId])))
        THROW 50000, N''04181|:|A reorder rule can only name a stock item and location of its own tenant.'', 1;
END;';

    -- INE.tr_Lots_TenantGuard (Triggers/INE/tr_Lots_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_Lots_TenantGuard]
ON [INE].[Lots]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[LotID] = I.[LotID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N''04182|:|INE.Lots: a row cannot move to another dealer tenant.'', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.Lots: the row belongs to a different dealer tenant than the signed-in user.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[StockItemId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS SI
                  WHERE SI.[StockItemID] = I.[StockItemId] AND SI.[DealerTenantId] = I.[DealerTenantId])))
        THROW 50000, N''04181|:|A lot can only belong to a stock item of its own tenant.'', 1;
END;';

    -- INE.tr_PurchaseOrders_TenantGuard (Triggers/INE/tr_PurchaseOrders_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_PurchaseOrders_TenantGuard]
ON [INE].[PurchaseOrders]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[PurchaseOrderID] = I.[PurchaseOrderID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N''04182|:|INE.PurchaseOrders: a row cannot move to another dealer tenant.'', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.PurchaseOrders: the row belongs to a different dealer tenant than the signed-in user.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[VendorId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Vendors] AS V
                  WHERE V.[VendorID] = I.[VendorId] AND V.[DealerTenantId] = I.[DealerTenantId]))
           OR NOT EXISTS (SELECT 1 FROM [INE].[Locations] AS L
                  INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
                  WHERE L.[LocationID] = I.[ShipToLocationId] AND L.[DealerTenantId] = I.[DealerTenantId]
                    AND LT.[IsStockHolding] = 1))
        THROW 50000, N''04181|:|A purchase order needs a vendor of its own tenant and a ship-to warehouse, vehicle or staging location of its own tenant.'', 1;
END;';

    -- INE.tr_PurchaseOrderLines_TenantGuard (Triggers/INE/tr_PurchaseOrderLines_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_PurchaseOrderLines_TenantGuard]
ON [INE].[PurchaseOrderLines]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[PurchaseOrders] AS P ON P.[PurchaseOrderID] = I.[PurchaseOrderId]
               WHERE P.[DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.PurchaseOrderLines: the purchase order belongs to a different dealer tenant than the signed-in user.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[PurchaseOrders] AS P ON P.[PurchaseOrderID] = I.[PurchaseOrderId]
               WHERE NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS SI
                  WHERE SI.[StockItemID] = I.[StockItemId] AND SI.[DealerTenantId] = P.[DealerTenantId]))
        THROW 50000, N''04181|:|A purchase order line can only name a stock item of the purchase order''''s tenant.'', 1;
END;';

    -- INE.tr_StockCounts_TenantGuard (Triggers/INE/tr_StockCounts_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_StockCounts_TenantGuard]
ON [INE].[StockCounts]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[StockCountID] = I.[StockCountID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N''04182|:|INE.StockCounts: a row cannot move to another dealer tenant.'', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.StockCounts: the row belongs to a different dealer tenant than the signed-in user.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[LocationId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Locations] AS L
                  WHERE L.[LocationID] = I.[LocationId] AND L.[DealerTenantId] = I.[DealerTenantId])))
        THROW 50000, N''04181|:|A stock count can only be for a location of its own tenant.'', 1;
END;';

    -- INE.tr_StockCountLines_TenantGuard (Triggers/INE/tr_StockCountLines_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_StockCountLines_TenantGuard]
ON [INE].[StockCountLines]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[StockCounts] AS P ON P.[StockCountID] = I.[StockCountId]
               WHERE P.[DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.StockCountLines: the stock count belongs to a different dealer tenant than the signed-in user.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[StockCounts] AS P ON P.[StockCountID] = I.[StockCountId]
               WHERE NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS SI
                  WHERE SI.[StockItemID] = I.[StockItemId] AND SI.[DealerTenantId] = P.[DealerTenantId])
           OR (I.[LotId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Lots] AS LO
                  WHERE LO.[LotID] = I.[LotId] AND LO.[StockItemId] = I.[StockItemId]))
           OR (I.[SerialUnitId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[SerialUnits] AS SU
                  WHERE SU.[SerialUnitID] = I.[SerialUnitId] AND SU.[StockItemId] = I.[StockItemId])))
        THROW 50000, N''04181|:|A count line can only name a stock item of the count''''s tenant, and a lot or serial unit of that item.'', 1;
END;';

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'INE review follow-ups: cancelled allocation reversal, audit triggers, tenant guards',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
