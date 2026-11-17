/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: tr_Locations_TenantGuard
 * Description: Keeps INE.Locations inside one dealer tenant, whoever writes it (the API's
 *              plain CRUD or an INE procedure):
 *              - DealerTenantId cannot change after insert
 *              - the row's tenant must be the session's tenant when one is set
 *              - A location can only name a vendor, lead or user (driver) of its own tenant.
 *              Error codes: 04180 wrong tenant for the session, 04181 cross-tenant
 *              reference, 04182 tenant cannot change.
 * Dependencies: INE.fxGetSessionContext, ACC.UserTenantMemberships, ACC.Users, INE.Vendors, QAL.Leads
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[tr_Locations_TenantGuard]
ON [INE].[Locations]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[LocationID] = I.[LocationID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N'04182|:|INE.Locations: a row cannot move to another dealer tenant.', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N'04180|:|INE.Locations: the row belongs to a different dealer tenant than the signed-in user.', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[VendorId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Vendors] AS V
                  WHERE V.[VendorID] = I.[VendorId] AND V.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[LeadId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [QAL].[Leads] AS LD
                  WHERE LD.[LeadID] = I.[LeadId] AND LD.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[UserId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [ACC].[Users] AS U
                  WHERE U.[UserID] = I.[UserId] AND U.[DealerTenantId] = I.[DealerTenantId])
              AND NOT EXISTS (SELECT 1 FROM [ACC].[UserTenantMemberships] AS M
                  WHERE M.[UserId] = I.[UserId] AND M.[DealerTenantId] = I.[DealerTenantId]
                    AND M.[IsActive] = 1 AND M.[IsDeleted] = 0)))
        THROW 50000, N'04181|:|A location can only name a vendor, lead or user (driver) of its own tenant.', 1;
END;
GO
