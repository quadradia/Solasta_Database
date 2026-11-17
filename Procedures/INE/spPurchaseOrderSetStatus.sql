/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: INE
 * Name: spPurchaseOrderSetStatus
 * Description: Moves a purchase order through its life cycle. Receiving moves it between
 *              Submitted, PartiallyReceived and Received on its own (INE.spMovementPost);
 *              the actions here are the ones a person takes:
 *                Submit  Draft -> Submitted        (needs at least one line)
 *                Cancel  Draft or Submitted -> Cancelled (nothing received yet)
 *                Close   Submitted, PartiallyReceived or Received -> Closed
 *                        (closing short: the outstanding quantity is no longer expected)
 *                Reopen  Closed -> Submitted / PartiallyReceived / Received, by what was received
 *              Lines can only be added or changed while the PO is Draft
 *              (tr_PurchaseOrderLines_GuardStatus).
 * Dependencies: INE.fxGetSessionContext, INE.PurchaseOrders, INE.PurchaseOrderLines,
 *               GEN.spExceptionsThrown
 * Parameters:
 *   @PurchaseOrderId - the PO
 *   @Action          - Submit, Cancel, Close or Reopen
 * Returns: 0 on success (and the PO's new Status as a result set); -1 on error
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Example:
 *   EXEC [INE].[spPurchaseOrderSetStatus] @PurchaseOrderId = 12, @Action = 'Submit';
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [INE].[spPurchaseOrderSetStatus]
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
            THROW 50000, N'04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.', 1;
        SET @UserId = ISNULL(@UserId, 'E6872B58-52B2-415C-A32B-45805F95A70A');

        BEGIN TRANSACTION;

        DECLARE @Status VARCHAR(20);
        SELECT @Status = PO.[Status]
        FROM [INE].[PurchaseOrders] AS PO WITH (UPDLOCK, HOLDLOCK)
        WHERE PO.[PurchaseOrderID] = @PurchaseOrderId AND PO.[DealerTenantId] = @TenantId AND PO.[IsDeleted] = 0;
        IF @Status IS NULL
            THROW 50000, N'04140|:|The purchase order was not found.', 1;

        DECLARE @Received DECIMAL(19, 4), @Outstanding DECIMAL(19, 4), @LineCount INT;
        SELECT @Received = ISNULL(SUM(POL.[QuantityReceived]), 0)
             , @Outstanding = ISNULL(SUM(POL.[QuantityOrdered] - POL.[QuantityReceived]), 0)
             , @LineCount = COUNT(*)
        FROM [INE].[PurchaseOrderLines] AS POL
        WHERE POL.[PurchaseOrderId] = @PurchaseOrderId AND POL.[IsDeleted] = 0;

        DECLARE @NewStatus VARCHAR(20) = CASE
            WHEN @Action = 'Submit' AND @Status = 'Draft' AND @LineCount > 0 THEN 'Submitted'
            WHEN @Action = 'Cancel' AND @Status IN ('Draft', 'Submitted') AND @Received = 0 THEN 'Cancelled'
            WHEN @Action = 'Close' AND @Status IN ('Submitted', 'PartiallyReceived', 'Received') THEN 'Closed'
            WHEN @Action = 'Reopen' AND @Status = 'Closed' THEN
                CASE WHEN @Outstanding = 0 THEN 'Received' WHEN @Received > 0 THEN 'PartiallyReceived' ELSE 'Submitted' END
            END;

        IF @NewStatus IS NULL
        BEGIN
            SET @Msg = CONCAT(N'04143|:|Cannot ', ISNULL(@Action, N'(no action)'), N' a ', @Status, N' purchase order',
                CASE WHEN @Action = 'Submit' AND @LineCount = 0 THEN N' with no lines'
                     WHEN @Action = 'Cancel' AND @Received > 0 THEN N' that has received stock' ELSE N'' END, N'.');
            THROW 50000, @Msg, 1;
        END;

        UPDATE [INE].[PurchaseOrders] SET
            [Status] = @NewStatus
            , [SubmittedDate] = CASE WHEN @NewStatus = 'Submitted' AND [SubmittedDate] IS NULL THEN SYSDATETIMEOFFSET() ELSE [SubmittedDate] END
            , [ClosedDate] = CASE WHEN @NewStatus IN ('Closed', 'Cancelled') THEN SYSDATETIMEOFFSET() ELSE NULL END
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
        IF ERROR_MESSAGE() LIKE N'{"ERROR_NUMBER":%'
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
GO
