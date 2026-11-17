/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: INE
 * Name: spAllocationCancel
 * Description: Releases what is left of an open allocation (allocated - issued) back to
 *              available stock and marks it Cancelled. Stock already issued stays issued.
 * Dependencies: INE.fxGetSessionContext, INE.Allocations, INE.StockBalances,
 *               GEN.spExceptionsThrown
 * Parameters:
 *   @AllocationId - the allocation
 * Returns: 0 on success; -1 on error
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Example:
 *   EXEC [INE].[spAllocationCancel] @AllocationId = 6;
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [INE].[spAllocationCancel]
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
            THROW 50000, N'04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.', 1;
        SET @UserId = ISNULL(@UserId, 'E6872B58-52B2-415C-A32B-45805F95A70A');

        BEGIN TRANSACTION;

        DECLARE @Remaining DECIMAL(19, 4), @LocationId INT, @StockItemId INT, @LotId INT;
        SELECT @Remaining = A.[QuantityAllocated] - A.[QuantityIssued], @LocationId = A.[LocationId],
               @StockItemId = A.[StockItemId], @LotId = A.[LotId]
        FROM [INE].[Allocations] AS A WITH (UPDLOCK, HOLDLOCK)
        WHERE A.[AllocationID] = @AllocationId AND A.[DealerTenantId] = @TenantId AND A.[Status] = 'Open';

        IF @Remaining IS NULL
            THROW 50000, N'04152|:|The allocation was not found or is not open.', 1;

        UPDATE [INE].[Allocations] SET
            [Status] = 'Cancelled'
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
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
GO
