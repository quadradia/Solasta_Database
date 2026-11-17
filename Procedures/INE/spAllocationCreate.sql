/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: INE
 * Name: spAllocationCreate
 * Description: Reserves stock at a stock-holding location for a job (a lead) so nobody
 *              else can take it. Fails when the location does not have enough available
 *              (on hand minus already allocated). The reservation is released when the
 *              stock is issued to the job with this allocation on the movement line, or
 *              by INE.spAllocationCancel.
 * Dependencies: INE.fxGetSessionContext, INE.Locations, INE.LocationTypes,
 *               INE.StockItems, INE.Lots, INE.StockBalances, INE.Allocations, QAL.Leads,
 *               GEN.spExceptionsThrown
 * Parameters:
 *   @LeadId, @LocationId, @StockItemId, @Quantity - what to reserve, where, for whom
 *   @LotId        - optional; for a Lot item, reserves that lot
 *   @NeededByDate - optional
 *   @Notes        - optional
 *   @AllocationId - OUTPUT, the new allocation
 * Returns: 0 on success (and a one-row result set with AllocationID); -1 on error
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Example:
 *   EXEC [INE].[spAllocationCreate] @LeadId = 1042, @LocationId = 1, @StockItemId = 3, @Quantity = 164.5;
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [INE].[spAllocationCreate]
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
            THROW 50000, N'04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.', 1;
        SET @UserId = ISNULL(@UserId, 'E6872B58-52B2-415C-A32B-45805F95A70A');

        IF @Quantity IS NULL OR @Quantity <= 0
            THROW 50000, N'04150|:|The quantity must be greater than zero.', 1;
        IF NOT EXISTS (SELECT 1 FROM [QAL].[Leads] WHERE [LeadID] = @LeadId AND [DealerTenantId] = @TenantId)
            THROW 50000, N'04108|:|The lead was not found.', 1;
        IF NOT EXISTS (SELECT 1 FROM [INE].[Locations] AS L
                       INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
                       WHERE L.[LocationID] = @LocationId AND L.[DealerTenantId] = @TenantId
                         AND L.[IsActive] = 1 AND L.[IsDeleted] = 0 AND LT.[IsStockHolding] = 1)
            THROW 50000, N'04151|:|Stock can only be allocated at an active warehouse, vehicle or staging location.', 1;

        DECLARE @TrackingMode VARCHAR(10);
        SELECT @TrackingMode = [TrackingMode] FROM [INE].[StockItems]
        WHERE [StockItemID] = @StockItemId AND [DealerTenantId] = @TenantId AND [IsActive] = 1 AND [IsDeleted] = 0;
        IF @TrackingMode IS NULL
            THROW 50000, N'04112|:|The stock item was not found or is inactive.', 1;
        IF @TrackingMode = 'Quantity' AND @LotId IS NOT NULL
            THROW 50000, N'04114|:|Quantity-tracked items do not have lots.', 1;
        IF @LotId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Lots] WHERE [LotID] = @LotId AND [StockItemId] = @StockItemId)
            THROW 50000, N'04115|:|The lot does not belong to the stock item.', 1;
        IF @TrackingMode = 'Serial' AND @Quantity <> ROUND(@Quantity, 0)
            THROW 50000, N'04150|:|Serial-tracked items are allocated in whole units.', 1;

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
            SET @Msg = CONCAT(N'04122|:|Only ', CAST(@Available AS DECIMAL(19, 2)), N' available at the location; ',
                              CAST(@Quantity AS DECIMAL(19, 2)), N' requested.',
                              CASE WHEN @TrackingMode = 'Lot' AND @LotId IS NULL THEN N' Lot-tracked items are allocated by lot.' ELSE N'' END);
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
        IF ERROR_MESSAGE() LIKE N'{"ERROR_NUMBER":%'
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
GO
