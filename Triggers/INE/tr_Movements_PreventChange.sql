/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_Movements_PreventChange
 * Description: Keeps the ledger append-only. Any UPDATE or DELETE of INE.Movements is
 *              rejected; correct a movement with INE.spMovementReverse instead. (The
 *              legacy INE soft-deleted ledger rows, which left units pointing at
 *              deleted history.)
 * Dependencies: INE.Movements
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_Movements_PreventChange]
ON [INE].[Movements]
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted)
        THROW 50000, N'04170|:|INE.Movements is append-only. Use INE.spMovementReverse to correct a movement.', 1;
END;
GO
