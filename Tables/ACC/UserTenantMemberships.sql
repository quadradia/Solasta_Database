/*******************************************************************************
 * Object Type: Table
 * Schema: ACC
 * Name: UserTenantMemberships
 * Description: Extra dealer tenants a user may act in, besides their own
 *              ACC.Users.DealerTenantId. Mirrors the Identity Server's
 *              AspNetUserTenantMemberships, which decides which tenant_id a token
 *              may carry; ACC.spSessionContextCreate accepts either.
 *              Junction table: composite PK, DEX_ROW surrogate (Constitution Art. IV).
 * Dependencies: ACC.Users, ACC.DealerTenants
 * Author: Andres Sosa
 * Created: 2026-11-05
 ******************************************************************************/

IF OBJECT_ID(N'ACC.UserTenantMemberships', N'U') IS NULL
BEGIN
    CREATE TABLE [ACC].[UserTenantMemberships]
    (
        [UserId] [uniqueidentifier] NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_UserTenantMemberships_IsActive] DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_UserTenantMemberships_IsDeleted] DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_UserTenantMemberships_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_UserTenantMemberships_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_UserTenantMemberships_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        [DEX_ROW] [bigint] IDENTITY(1,1) NOT NULL,
        CONSTRAINT [PK_UserTenantMemberships] PRIMARY KEY CLUSTERED ([UserId], [DealerTenantId]),
        CONSTRAINT [FK_UserTenantMemberships_Users] FOREIGN KEY ([UserId])
            REFERENCES [ACC].[Users] ([UserID]),
        CONSTRAINT [FK_UserTenantMemberships_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'ACC.UserTenantMemberships') AND [name] = N'IX_UserTenantMemberships_DealerTenantId')
    CREATE NONCLUSTERED INDEX [IX_UserTenantMemberships_DealerTenantId]
        ON [ACC].[UserTenantMemberships] ([DealerTenantId]);
GO
