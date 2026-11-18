/*
Adds Nandin Sosa (nandin@mysolasta.com) to ACC.Users in SOL_MAIN as a user of the Solasta Lighting tenant.

Why: NOAHIdentityServer migration 20261118_0010_AddStaffUser_NandinSosa created the login in GBDC_IDENTITY only.
Signing in works, but every API call runs ACC.spSessionContextCreate, which needs an ACC.Users row whose UserID is
the identity user's Id. Without it the procedure raises 03021 and the admin site shows "A valid user identity and
active tenant are required."

How to run (prod):
  1. On GBDC_IDENTITY, get Nandin's identity Id:
       SELECT [Id], [TenantId] FROM [dbo].[AspNetUsers] WHERE [NormalizedEmail] = N'NANDIN@MYSOLASTA.COM';
     TenantId should be SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6.
  2. Paste the Id into @IdentityUserId below and run this script on SOL_MAIN.
  3. Nandin signs out of admin.mysolasta.com and signs in again.

Safe to rerun. ACC.Users' UserInsert trigger runs as it does for any new user.
*/
USE [SOL_MAIN];
GO

SET XACT_ABORT ON;

DECLARE @IdentityUserId UNIQUEIDENTIFIER = NULL;   -- <-- paste [AspNetUsers].[Id] from GBDC_IDENTITY here
DECLARE @Email          NVARCHAR(256)    = N'nandin@mysolasta.com';
DECLARE @FirstName      NVARCHAR(100)    = N'Nandin';
DECLARE @LastName       NVARCHAR(100)    = N'Sosa';
DECLARE @SolastaProxy   VARCHAR(100)     = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6';
DECLARE @SystemUserId   UNIQUEIDENTIFIER = 'E6872B58-52B2-415C-A32B-45805F95A70A';

IF @IdentityUserId IS NULL
    THROW 50001, 'Set @IdentityUserId to Nandin''s [AspNetUsers].[Id] from GBDC_IDENTITY first.', 1;

DECLARE @TenantId INT = (SELECT [DealerTenantID] FROM [ACC].[DealerTenants] WHERE [Proxy] = @SolastaProxy AND [IsActive] = 1);
IF @TenantId IS NULL
    THROW 50001, 'The Solasta Lighting tenant is missing or inactive.', 1;

IF EXISTS (SELECT 1 FROM [ACC].[Users] WHERE [Email] = @Email AND [UserID] <> @IdentityUserId)
    THROW 50001, 'ACC.Users already has nandin@mysolasta.com under a different UserID. Check it before going on.', 1;

BEGIN TRANSACTION;

IF EXISTS (SELECT 1 FROM [ACC].[Users] WHERE [UserID] = @IdentityUserId)
BEGIN
    UPDATE [ACC].[Users]
    SET [IsActive] = 1, [IsDeleted] = 0, [ModifiedDate] = SYSDATETIMEOFFSET(), [ModifiedById] = @SystemUserId
    WHERE [UserID] = @IdentityUserId AND ([IsActive] = 0 OR [IsDeleted] = 1);
    PRINT 'ACC.Users row already exists; made sure it is active.';
END
ELSE
BEGIN
    DECLARE @Now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();
    INSERT INTO [ACC].[Users]
        ([UserID], [DealerTenantId], [LanguageId], [FirstName], [LastName], [Email], [EmailConfirmed],
         [Username], [PasswordHash], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEnabled],
         [AccessFailedCount], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
    VALUES
        (@IdentityUserId, @TenantId, 'en-US', @FirstName, @LastName, @Email, 1,
         @Email, NULL, 0, 0, 1,
         0, 1, 0, @Now, @SystemUserId, @Now, @SystemUserId);
    PRINT 'Added ACC.Users row for ' + @Email + '.';
END;

COMMIT TRANSACTION;

-- Check: one active row on the Solasta tenant.
SELECT U.[UserID], U.[Email], T.[Proxy] AS TenantProxy, U.[IsActive], U.[IsDeleted]
FROM [ACC].[Users] AS U
INNER JOIN [ACC].[DealerTenants] AS T ON T.[DealerTenantID] = U.[DealerTenantId]
WHERE U.[UserID] = @IdentityUserId;
GO
