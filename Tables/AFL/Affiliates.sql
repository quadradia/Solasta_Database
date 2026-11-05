/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: Affiliates
 * Description: Registered affiliates who promote dealer products and earn rewards. Each
 *              affiliate is tied to a DealerTenant, has a unique AffiliateCode used in
 *              tracking tokens, and optionally a portal login (UserId = Identity Server
 *              `sub`). Suspended affiliates have IsActive = 0.
 * Dependencies: ACC.DealerTenants, AFL.AffiliateTypes
 * Author: Andres Sosa
 * Created: 2026-05-04
 ******************************************************************************/

IF OBJECT_ID(N'AFL.Affiliates', N'U') IS NULL
BEGIN
    CREATE TABLE [AFL].[Affiliates]
    (
        [AffiliateID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [AffiliateTypeId] [int] NOT NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        [UserId] [uniqueidentifier] NULL,
        [AffiliateCode] [varchar](20) NOT NULL,
        [FirstName] [nvarchar](50) NOT NULL,
        [LastName] [nvarchar](50) NOT NULL,
        [Email] [nvarchar](256) NOT NULL,
        [PhoneMobile] [nvarchar](20) NULL,
        [CommissionRate] [decimal](5,4) NULL,
        [Notes] [nvarchar](max) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Affiliates_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Affiliates_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Affiliates_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Affiliates_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Affiliates_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Affiliates_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Affiliates_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Affiliates] PRIMARY KEY CLUSTERED ([AffiliateID] ASC),
        CONSTRAINT [FK_Affiliates_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Affiliates_AffiliateTypeId] FOREIGN KEY ([AffiliateTypeId])
            REFERENCES [AFL].[AffiliateTypes] ([AffiliateTypeID]),
        CONSTRAINT [UQ_Affiliates_AffiliateCode] UNIQUE ([AffiliateCode]),
        CONSTRAINT [UQ_Affiliates_Proxy] UNIQUE ([Proxy])
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.Affiliates') AND [name] = N'IX_Affiliates_UserId')
    -- One portal login maps to at most one affiliate.
    CREATE UNIQUE NONCLUSTERED INDEX [IX_Affiliates_UserId]
        ON [AFL].[Affiliates] ([UserId]) WHERE [UserId] IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.Affiliates') AND [name] = N'IX_Affiliates_DealerTenantId_Email')
    CREATE NONCLUSTERED INDEX [IX_Affiliates_DealerTenantId_Email]
        ON [AFL].[Affiliates] ([DealerTenantId], [Email]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.Affiliates') AND [name] = N'IX_Affiliates_PartKey_AffiliateTypeId')
    CREATE NONCLUSTERED INDEX [IX_Affiliates_PartKey_AffiliateTypeId]
        ON [AFL].[Affiliates] ([PartKey], [AffiliateTypeId]);
GO
