/*
Gives an existing ACC.Users row access to another dealer tenant (after migration
20261105_0645_AddACC_UserTenantMemberships). Keep it in step with the Identity Server:
the same login also needs an AspNetUserTenantMemberships row for that tenant in GBDC_IDENTITY.

Set @Email and @TenantPrefix, then run. Safe to rerun.
*/
USE [SOL_MAIN];
GO

SET XACT_ABORT ON;

DECLARE @Email NVARCHAR(256) = N'sosawise@gmail.com';
DECLARE @TenantPrefix VARCHAR(4) = 'SOLA';   -- SOLA = Solasta Lighting, CIMT = Cimtech, QUAD, MSTR
DECLARE @SystemUserId UNIQUEIDENTIFIER = 'E6872B58-52B2-415C-A32B-45805F95A70A';

DECLARE @UserId UNIQUEIDENTIFIER = (SELECT [UserID] FROM [ACC].[Users] WHERE [Email] = @Email AND [IsActive] = 1);
DECLARE @TenantId INT = (SELECT [DealerTenantID] FROM [ACC].[DealerTenants]
                         WHERE [Proxy] LIKE @TenantPrefix + ':%' AND [IsActive] = 1);

IF @UserId IS NULL THROW 50001, 'No active ACC.Users row with that email.', 1;
IF @TenantId IS NULL THROW 50001, 'No active tenant with that prefix.', 1;

IF EXISTS (SELECT 1 FROM [ACC].[Users] WHERE [UserID] = @UserId AND [DealerTenantId] = @TenantId)
    PRINT 'That is already the user''s own tenant; no membership needed.';
ELSE IF EXISTS (SELECT 1 FROM [ACC].[UserTenantMemberships] WHERE [UserId] = @UserId AND [DealerTenantId] = @TenantId)
BEGIN
    UPDATE [ACC].[UserTenantMemberships]
    SET [IsActive] = 1, [IsDeleted] = 0, [ModifiedDate] = SYSDATETIMEOFFSET(), [ModifiedById] = @SystemUserId
    WHERE [UserId] = @UserId AND [DealerTenantId] = @TenantId;
    PRINT 'Membership reactivated.';
END
ELSE
BEGIN
    INSERT INTO [ACC].[UserTenantMemberships] ([UserId], [DealerTenantId], [ModifiedById], [CreatedById])
    VALUES (@UserId, @TenantId, @SystemUserId, @SystemUserId);
    PRINT 'Membership added.';
END;
GO
