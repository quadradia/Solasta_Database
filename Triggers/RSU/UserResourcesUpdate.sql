/*******************************************************************************
 * Object Type: Trigger
 * Schema: RSU
 * Name: UserResourcesUpdate
 * Type: AFTER UPDATE
 * Table: RSU.UserResources
 * Description: After updating a UserResource row, syncs FirstName, LastName,
 *              Email, UserName, PhoneCell, GPEmployeeId and HRUserId back to
 *              the corresponding ACC.Users record. Also validates that the
 *              username is not already taken by another user.
 * Dependencies: RSU.UserResources, ACC.Users
 * Author: Andrés Sosa
 * Created: 2017-05-08
 *******************************************************************************
 * Change History
 *******************************************************************************
 * Date         Author          Description
 * -----------  --------------  ------------------------------------------------
 * 2017-05-08   Andrés Sosa     Created
 ******************************************************************************/

IF OBJECT_ID('[RSU].[UserResourcesUpdate]', 'TR') IS NOT NULL
    DROP TRIGGER [RSU].[UserResourcesUpdate];
GO

CREATE TRIGGER [RSU].[UserResourcesUpdate]
        ON [RSU].[UserResources]
        AFTER UPDATE
AS
BEGIN
    -- Do not count as a change
    SET NOCOUNT ON;

    /** INITIALIZE */
    DECLARE @UserID UNIQUEIDENTIFIER-- = (SELECT Inserted.UserId FROM INSERTED);
                , @Username NVARCHAR(256);
    -- = (SELECT Inserted.UserName FROM INSERTED);

    DECLARE SomeCursor CURSOR LOCAL READ_ONLY FORWARD_ONLY FOR
        SELECT UserID
    FROM INSERTED;

    OPEN SomeCursor;
    FETCH NEXT FROM SomeCursor
        INTO @UserID;

    WHILE (@@FETCH_STATUS <> 0) BEGIN
        -- ** Init local block

        /** Check that the username is not being used already */
        IF (EXISTS(SELECT TOP(1)
            1
        FROM [ACC].[Users]
        WHERE UserID <> @UserID AND Username = @Username)) BEGIN
            -- ** Close Cursor
            CLOSE SomeCursor;
            DEALLOCATE SomeCursor;
            -- ** Raise Error
            RAISERROR(N'Sorry, the username ''%s'' has already been taken.', 18, 1, @Username);
        END

        /** Sync user fields from UserResources back to ACC.Users */
        UPDATE U SET
                        U.FirstName = I.FirstName
                        , U.HRUserId = I.UserResourceID
                        , U.LastName = I.LastName
                        , U.GPEmployeeID = I.GPEmployeeId
                        , U.Email = I.Email
                        , U.Username = I.UserName
                        , U.PhoneNumber = I.PhoneCell
                FROM
            [ACC].[Users] AS U WITH(NOLOCK)
            INNER JOIN Inserted AS I
            ON
                                (I.UserId = U.UserID)
                WHERE
                        (U.UserID = @UserID);

        -- ** Move Next
        FETCH NEXT FROM SomeCursor
                INTO @UserID;
    END;

    -- ** Close Cursor
    CLOSE SomeCursor;
    DEALLOCATE SomeCursor;
END
GO
