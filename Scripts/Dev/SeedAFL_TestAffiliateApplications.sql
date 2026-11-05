/*
Dev-only test data: affiliate applications for the Solasta Lighting tenant, so the admin app
(solasta-lighting-admin) has something to review. NEVER run this against production.

  - 5 Pending applications, spread over the last few days (the review queue shows oldest first)
  - 1 Rejected application with a reason
  - Approved ones are not seeded: approve a Pending one in the admin app, which creates the
    AFL.Affiliates row and referral code the way production will.

All emails end in @example.com. Safe to rerun: an application is skipped when the same tenant
already has one with that email. Cleanup is at the bottom (commented out).
*/
USE [SOL_MAIN];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

DECLARE @SystemUserId UNIQUEIDENTIFIER = 'E6872B58-52B2-415C-A32B-45805F95A70A';
DECLARE @TenantId INT = (SELECT [DealerTenantID] FROM [ACC].[DealerTenants]
                         WHERE [Proxy] = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6');
DECLARE @TypeId INT = (SELECT [AffiliateApplicationTypeID] FROM [AFL].[AffiliateApplicationTypes] WHERE [Prefix] = 'AFAW');

IF @TenantId IS NULL THROW 50001, 'Solasta Lighting tenant not found. Is this SOL_MAIN?', 1;
IF @TypeId IS NULL THROW 50001, 'AFAW application type missing. Run migration 20261103_2132 first.', 1;

DECLARE @Seed TABLE
(
    [FirstName] NVARCHAR(50), [LastName] NVARCHAR(50), [Email] NVARCHAR(256), [PhoneMobile] NVARCHAR(20),
    [StreetAddress] NVARCHAR(200), [City] NVARCHAR(100), [StateCode] CHAR(2), [PostalCode] VARCHAR(10),
    [Status] VARCHAR(20), [ReviewNotes] NVARCHAR(1000), [DaysAgo] INT
);
INSERT INTO @Seed VALUES
    (N'Maria',  N'Lopez',     N'maria.lopez@example.com',     N'602-555-0101', N'1420 E Camelback Rd',  N'Phoenix',    'AZ', '85014', 'Pending',  NULL, 6),
    (N'Tom',    N'Nguyen',    N'tom.nguyen@example.com',      N'480-555-0144', N'88 W Main St',         N'Mesa',       'AZ', '85201', 'Pending',  NULL, 4),
    (N'Priya',  N'Shah',      N'priya.shah@example.com',      N'480-555-0177', NULL,                    N'Scottsdale', 'AZ', '85251', 'Pending',  NULL, 3),
    (N'José',   N'Ramírez',   N'jose.ramirez@example.com',    N'623-555-0190', N'301 N Litchfield Rd',  N'Goodyear',   'AZ', '85338', 'Pending',  NULL, 1),
    (N'Kelly',  N'O''Brien',  N'kelly.obrien@example.com',    NULL,            NULL,                    NULL,          NULL, NULL,    'Pending',  NULL, 0),
    (N'Derek',  N'Hall',      N'derek.hall@example.com',      N'702-555-0123', N'5 Fremont St',         N'Las Vegas',  'NV', '89101', 'Rejected',
        N'Outside our current service area (Nevada).', 5);

BEGIN TRANSACTION;

INSERT INTO [AFL].[AffiliateApplications]
    ([DealerTenantId], [AffiliateApplicationTypeId], [Proxy], [PartKey], [Status],
     [FirstName], [LastName], [Email], [PhoneMobile], [StreetAddress], [City], [StateCode], [PostalCode],
     [ReviewedDate], [ReviewedById], [ReviewNotes],
     [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
SELECT
    @TenantId, @TypeId, P.[Proxy],
    SUBSTRING(P.[Proxy], 6, CHARINDEX(':', P.[Proxy], 6) - 6),   -- PREFIX:PARTKEY:GUID -> PARTKEY
    S.[Status],
    S.[FirstName], S.[LastName], S.[Email], S.[PhoneMobile], S.[StreetAddress], S.[City], S.[StateCode], S.[PostalCode],
    CASE WHEN S.[Status] = 'Pending' THEN NULL ELSE DATEADD(DAY, -S.[DaysAgo] + 1, SYSDATETIMEOFFSET()) END,
    CASE WHEN S.[Status] = 'Pending' THEN NULL ELSE @SystemUserId END,
    S.[ReviewNotes],
    DATEADD(DAY, -S.[DaysAgo], SYSDATETIMEOFFSET()), @SystemUserId,
    DATEADD(DAY, -S.[DaysAgo], SYSDATETIMEOFFSET()), @SystemUserId
FROM @Seed AS S
CROSS APPLY (SELECT [MAC].[fxGeneratePrefixProxy]('AffiliateApplication', @TypeId) + CAST(NEWID() AS NVARCHAR(36)) AS [Proxy]) AS P
WHERE NOT EXISTS (SELECT 1 FROM [AFL].[AffiliateApplications] AS X
                  WHERE X.[DealerTenantId] = @TenantId AND X.[Email] = S.[Email])
ORDER BY S.[DaysAgo] DESC;   -- oldest first, so IDs follow submission order

PRINT CONCAT(@@ROWCOUNT, ' test application(s) inserted.');
COMMIT TRANSACTION;

SELECT [Proxy], [Status], [FirstName], [LastName], [Email], [CreatedDate]
FROM [AFL].[AffiliateApplications]
WHERE [DealerTenantId] = @TenantId AND [Email] LIKE N'%@example.com'
ORDER BY [AffiliateApplicationID];
GO

/* Cleanup (dev only). Approved test applications point at affiliates, so remove those links first.
BEGIN TRANSACTION;
DECLARE @Created TABLE ([AffiliateId] BIGINT);
INSERT INTO @Created SELECT [AffiliateId] FROM [AFL].[AffiliateApplications]
WHERE [Email] LIKE N'%@example.com' AND [AffiliateId] IS NOT NULL;
DELETE FROM [AFL].[AffiliateApplications] WHERE [Email] LIKE N'%@example.com';
DELETE FROM [AFL].[Affiliates] WHERE [AffiliateID] IN (SELECT [AffiliateId] FROM @Created);
COMMIT TRANSACTION;
*/
