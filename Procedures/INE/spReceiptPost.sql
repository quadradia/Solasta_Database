/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: INE
 * Name: spReceiptPost
 * Description: Records a delivery (packing slip) and receives its stock in one
 *              transaction: creates the INE.Receipts row, then posts a Receive movement
 *              through INE.spMovementPost, which creates lots and serial units, adds the
 *              stock to the location and fills the PO lines. The location defaults to
 *              the PO's ship-to location.
 * Dependencies: INE.fxGetSessionContext, INE.Receipts, INE.PurchaseOrders,
 *               INE.Locations, INE.spMovementPost, GEN.spExceptionsThrown
 * Parameters:
 *   @ReceiptJson - the receipt (shape below)
 *   @ReceiptId   - OUTPUT, the new receipt
 *   @MovementId  - OUTPUT, its Receive movement
 *   JSON shape:
 *   {
 *     "purchaseOrderId": 12,             -- optional
 *     "locationId": 1,                   -- optional when there is a PO
 *     "packingSlipNumber": "PS-88123", "receivedDate": "2026-11-17T10:00:00-07:00", "notes": "...",
 *     "lines": [ same as INE.spMovementPost lines, usually with purchaseOrderLineId and unitCost ]
 *   }
 * Returns: 0 on success (and a one-row result set with ReceiptID and MovementID); -1 on error
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Example:
 *   EXEC [INE].[spReceiptPost] @ReceiptJson = N'{"purchaseOrderId":12,"packingSlipNumber":"PS-1",
 *        "lines":[{"stockItemId":3,"quantity":500,"purchaseOrderLineId":21,"unitCost":2.15}]}';
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [INE].[spReceiptPost]
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
            THROW 50000, N'04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.', 1;
        SET @UserId = ISNULL(@UserId, 'E6872B58-52B2-415C-A32B-45805F95A70A');

        IF @ReceiptJson IS NULL OR ISJSON(@ReceiptJson) <> 1
            THROW 50000, N'04101|:|The receipt is not valid JSON.', 1;

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
            [purchaseOrderId] BIGINT N'$.purchaseOrderId'
            , [locationId] INT N'$.locationId'
            , [packingSlipNumber] NVARCHAR(50) N'$.packingSlipNumber'
            , [receivedDate] DATETIMEOFFSET(7) N'$.receivedDate'
            , [notes] NVARCHAR(2000) N'$.notes'
            , [lines] NVARCHAR(MAX) N'$.lines' AS JSON
        ) AS J;

        IF @PurchaseOrderId IS NOT NULL
        BEGIN
            DECLARE @PoStatus VARCHAR(20), @ShipToLocationId INT;
            SELECT @PoStatus = PO.[Status], @ShipToLocationId = PO.[ShipToLocationId]
            FROM [INE].[PurchaseOrders] AS PO
            WHERE PO.[PurchaseOrderID] = @PurchaseOrderId AND PO.[DealerTenantId] = @TenantId AND PO.[IsDeleted] = 0;
            IF @PoStatus IS NULL
                THROW 50000, N'04140|:|The purchase order was not found.', 1;
            IF @PoStatus NOT IN ('Submitted', 'PartiallyReceived')
                THROW 50000, N'04119|:|Stock can only be received on a Submitted or PartiallyReceived purchase order.', 1;
            SET @LocationId = ISNULL(@LocationId, @ShipToLocationId);
        END;

        IF @LocationId IS NULL
            THROW 50000, N'04141|:|A receipt without a purchase order needs a locationId.', 1;

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
                'Receive' AS [movementType]
                , @LocationId AS [toLocationId]
                , @ReceiptId AS [receiptId]
                , @ReceivedDate AS [movementDate]
                , @PackingSlipNumber AS [reference]
                , JSON_QUERY(ISNULL(@Lines, N'[]')) AS [lines]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        DECLARE @Rc INT;
        EXEC @Rc = [INE].[spMovementPost] @MovementJson = @MovementJson, @MovementId = @MovementId OUTPUT, @ReturnResult = 0;
        IF @Rc <> 0
            THROW 50000, N'04142|:|The receipt could not be posted.', 1;

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
        IF ERROR_MESSAGE() LIKE N'{"ERROR_NUMBER":%'
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
GO
