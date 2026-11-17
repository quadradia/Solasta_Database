/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: INE
 * Name: spStockCountPost
 * Description: Posts an Open stock count. For every counted item and lot it stores the
 *              on-hand quantity as ExpectedQuantity and posts the difference:
 *                counted > on hand  -> one AdjustIn movement for all overages
 *                counted < on hand  -> one AdjustOut movement for all shortages
 *              For serial items, a unit counted 0 that the books have at the location is
 *              adjusted out (it becomes Missing); a unit counted 1 that the books have off
 *              the books (Missing, Scrapped, Voided) is adjusted back in. A unit counted 1
 *              that the books place at another location is reported as an error so
 *              someone can post the transfer it needs. Then the count becomes Posted.
 *              Everything happens in one transaction.
 * Dependencies: INE.fxGetSessionContext, INE.StockCounts, INE.StockCountLines,
 *               INE.StockBalances, INE.SerialUnits, INE.StockItems, INE.spMovementPost,
 *               GEN.spExceptionsThrown
 * Parameters:
 *   @StockCountId - the count
 * Returns: 0 on success (and a result set with the adjustment MovementIDs); -1 on error
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Example:
 *   EXEC [INE].[spStockCountPost] @StockCountId = 3;
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [INE].[spStockCountPost]
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
            THROW 50000, N'04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.', 1;
        SET @UserId = ISNULL(@UserId, 'E6872B58-52B2-415C-A32B-45805F95A70A');

        BEGIN TRANSACTION;

        DECLARE @LocationId INT;
        SELECT @LocationId = SC.[LocationId]
        FROM [INE].[StockCounts] AS SC WITH (UPDLOCK, HOLDLOCK)
        WHERE SC.[StockCountID] = @StockCountId AND SC.[DealerTenantId] = @TenantId AND SC.[Status] = 'Open';
        IF @LocationId IS NULL
            THROW 50000, N'04160|:|The stock count was not found or is not open.', 1;

        IF EXISTS (SELECT 1 FROM [INE].[StockCountLines] AS CL
                   INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = CL.[StockItemId]
                   WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0
                     AND ((SI.[TrackingMode] = 'Serial' AND CL.[SerialUnitId] IS NULL)
                       OR (SI.[TrackingMode] <> 'Serial' AND CL.[SerialUnitId] IS NOT NULL)))
            THROW 50000, N'04161|:|Serial items are counted one line per serial unit, and only serial items name a unit.', 1;

        IF EXISTS (SELECT 1 FROM [INE].[StockCountLines] AS CL
                   INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = CL.[SerialUnitId]
                   WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0 AND CL.[CountedQuantity] = 1
                     AND SU.[CurrentLocationId] IS NOT NULL AND SU.[CurrentLocationId] <> @LocationId)
        BEGIN
            SELECT TOP (1) @Msg = CONCAT(N'04162|:|Serial number "', SU.[SerialNumber], N'" was found here but the books have it at location ',
                                         SU.[CurrentLocationId], N'. Post a transfer for it, then post the count.')
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
            SET @Json = (SELECT 'AdjustIn' AS [movementType], @LocationId AS [toLocationId], @StockCountId AS [stockCountId],
                                CONCAT(N'Stock count ', @StockCountId) AS [reference],
                                (SELECT D.[StockItemId] AS [stockItemId], D.[LotId] AS [lotId], D.[SerialUnitId] AS [serialUnitId],
                                        D.[Diff] AS [quantity]
                                 FROM @Diffs AS D WHERE D.[Diff] > 0 FOR JSON PATH) AS [lines]
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
            EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @NewId OUTPUT, @ReturnResult = 0;
            IF @Rc <> 0 THROW 50000, N'04163|:|The count overages could not be posted.', 1;
            INSERT INTO @Results VALUES (@NewId, 'AdjustIn');
        END;

        IF EXISTS (SELECT 1 FROM @Diffs WHERE [Diff] < 0)
        BEGIN
            SET @NewId = NULL;
            SET @Json = (SELECT 'AdjustOut' AS [movementType], @LocationId AS [fromLocationId], @StockCountId AS [stockCountId],
                                CONCAT(N'Stock count ', @StockCountId) AS [reference],
                                (SELECT D.[StockItemId] AS [stockItemId], D.[LotId] AS [lotId], D.[SerialUnitId] AS [serialUnitId],
                                        -D.[Diff] AS [quantity]
                                 FROM @Diffs AS D WHERE D.[Diff] < 0 FOR JSON PATH) AS [lines]
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
            EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @NewId OUTPUT, @ReturnResult = 0;
            IF @Rc <> 0 THROW 50000, N'04163|:|The count shortages could not be posted (release allocations on short items first).', 1;
            INSERT INTO @Results VALUES (@NewId, 'AdjustOut');
        END;

        UPDATE [INE].[StockCounts] SET
            [Status] = 'Posted'
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
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
GO
