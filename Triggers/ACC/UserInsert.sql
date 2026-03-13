/*******************************************************************************
 * Object Type: Trigger
 * Schema: ACC
 * Name: UserInsert
 * Type: AFTER INSERT
 * Table: ACC.Users
 * Description: After inserting a new user, updates CreatedById and ModifiedById
 *              on that same row to the newly assigned UserId.
 * Dependencies: ACC.Users
 * Author: Andrés Sosa
 * Created: 2016-10-28
 *******************************************************************************
 * Change History
 *******************************************************************************
 * Date         Author          Description
 * -----------  --------------  ------------------------------------------------
 * 2016-11-09   Andrés Sosa     Created
 ******************************************************************************/

IF OBJECT_ID('[ACC].[UserInsert]', 'TR') IS NOT NULL
    DROP TRIGGER [ACC].[UserInsert];
GO

CREATE TRIGGER [ACC].[UserInsert]
        ON [ACC].[Users]
        AFTER INSERT
AS
BEGIN
    -- Do not count as a change
    SET NOCOUNT ON;

    /** Check if this is a single row or a batch. */
    IF ((SELECT COUNT(*)
    FROM INSERTED) > 1) BEGIN
        -- Update users table with its own UserId
        UPDATE U SET
                        U.CreatedById = I.UserId
                        , U.ModifiedById = I.UserId
                FROM
            [ACC].[Users] AS U WITH (NOLOCK)
            INNER JOIN INSERTED AS I
            ON
                                (I.UserId = U.UserId)
    END ELSE BEGIN
        /** Declarations */
        DECLARE @UserId UNIQUEIDENTIFIER = (SELECT UserId
        FROM INSERTED);

        -- Update users table with its own UserId
        UPDATE U SET
                        CreatedById = @UserId
                        , ModifiedById = @UserId
                FROM
            [ACC].[Users] AS U WITH (NOLOCK)
                WHERE
                        (U.UserId = @UserId);
    END
END
GO
