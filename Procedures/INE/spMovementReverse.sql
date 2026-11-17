/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: INE
 * Name: spMovementReverse
 * Description: Corrects a posted movement without editing the ledger: posts a Reversal
 *              movement with the same lines and the from/to locations swapped, linked by
 *              ReversesMovementId. Balances, serial units, PO received quantities and
 *              allocations all move back through INE.spMovementPost, so its checks apply
 *              (for example, a transfer cannot be reversed once the stock has moved on).
 *              A movement can be reversed once, and a reversal cannot be reversed.
 * Dependencies: INE.fxGetSessionContext, INE.spMovementPost, GEN.spExceptionsThrown
 * Parameters:
 *   @MovementId         - the movement to reverse
 *   @Notes              - why (stored on the reversal)
 *   @ReversalMovementId - OUTPUT, the new Reversal movement
 * Returns: 0 on success (and a one-row result set with MovementID); -1 on error
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Example:
 *   EXEC [INE].[spMovementReverse] @MovementId = 42, @Notes = N'Scanned to the wrong van';
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [INE].[spMovementReverse]
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
            THROW 50000, N'04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.', 1;

        IF @MovementId IS NULL
            THROW 50000, N'04130|:|The movement to reverse was not found.', 1;

        -- spMovementPost takes the locations, lead and lines from the original and checks
        -- that it exists, is not itself a reversal and has not been reversed yet.
        DECLARE @Json NVARCHAR(MAX) =
        (
            SELECT
                'Reversal' AS [movementType]
                , @MovementId AS [reversesMovementId]
                , @Notes AS [notes]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        DECLARE @Rc INT;
        EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @ReversalMovementId OUTPUT, @ReturnResult = 0;
        IF @Rc <> 0
            THROW 50000, N'04133|:|The reversal could not be posted.', 1;

        SELECT @ReversalMovementId AS [MovementID];
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N'{"ERROR_NUMBER":%'
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
GO
