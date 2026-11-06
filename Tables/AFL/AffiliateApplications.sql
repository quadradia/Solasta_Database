/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: AffiliateApplications
 * Description: Affiliate signups awaiting staff review. Status moves Pending ->
 *              Approved | Rejected. Approval creates the AFL.Affiliates row referenced by
 *              AffiliateId. At most one Pending application per tenant and email.
 * Dependencies: ACC.DealerTenants, AFL.AffiliateApplicationTypes, AFL.Affiliates
 * Author: Andres Sosa
 * Created: 2026-11-03
 ******************************************************************************/

IF OBJECT_ID(N'AFL.AffiliateApplications', N'U') IS NULL
BEGIN
    CREATE TABLE [AFL].[AffiliateApplications]
    (
        [AffiliateApplicationID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [AffiliateApplicationTypeId] [int] NOT NULL CONSTRAINT [DF_AffiliateApplications_AffiliateApplicationTypeId] DEFAULT (1),
        [AffiliateId] [bigint] NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        [Status] [varchar](20) NOT NULL CONSTRAINT [DF_AffiliateApplications_Status] DEFAULT ('Pending'),
        [FirstName] [nvarchar](50) NOT NULL,
        [LastName] [nvarchar](50) NOT NULL,
        [Email] [nvarchar](256) NOT NULL,
        [PhoneMobile] [nvarchar](20) NULL,
        [StreetAddress] [nvarchar](200) NULL,
        [City] [nvarchar](100) NULL,
        [StateCode] [char](2) NULL,
        [PostalCode] [varchar](10) NULL,
        [ReviewedDate] [datetimeoffset](7) NULL,
        [ReviewedById] [uniqueidentifier] NULL,
        [ReviewNotes] [nvarchar](1000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_AffiliateApplications_IsActive] DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_AffiliateApplications_IsDeleted] DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplications_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplications_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplications_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_AffiliateApplications] PRIMARY KEY CLUSTERED ([AffiliateApplicationID]),
        CONSTRAINT [FK_AffiliateApplications_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_AffiliateApplications_AffiliateApplicationTypes] FOREIGN KEY ([AffiliateApplicationTypeId])
            REFERENCES [AFL].[AffiliateApplicationTypes] ([AffiliateApplicationTypeID]),
        CONSTRAINT [FK_AffiliateApplications_Affiliates] FOREIGN KEY ([AffiliateId])
            REFERENCES [AFL].[Affiliates] ([AffiliateID]),
        CONSTRAINT [UQ_AffiliateApplications_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [CK_AffiliateApplications_Status] CHECK ([Status] IN ('Pending', 'Approved', 'Rejected')),
        -- Exactly the approved applications point at the affiliate they created.
        CONSTRAINT [CK_AffiliateApplications_AffiliateId] CHECK
            (([Status] = 'Approved' AND [AffiliateId] IS NOT NULL) OR ([Status] <> 'Approved' AND [AffiliateId] IS NULL)),
        CONSTRAINT [CK_AffiliateApplications_ReviewedDate] CHECK
            (([Status] = 'Pending' AND [ReviewedDate] IS NULL) OR ([Status] <> 'Pending' AND [ReviewedDate] IS NOT NULL)),
        CONSTRAINT [CK_AffiliateApplications_StateCode] CHECK
            ([StateCode] IS NULL OR [StateCode] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^A-Z]%')
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.AffiliateApplications') AND [name] = N'IX_AffiliateApplications_DealerTenantId_Email_Pending')
    -- Resubmitting the form while an application is pending returns the existing one.
    CREATE UNIQUE NONCLUSTERED INDEX [IX_AffiliateApplications_DealerTenantId_Email_Pending]
        ON [AFL].[AffiliateApplications] ([DealerTenantId], [Email])
        WHERE [Status] = 'Pending' AND [IsDeleted] = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.AffiliateApplications') AND [name] = N'IX_AffiliateApplications_DealerTenantId_Status')
    CREATE NONCLUSTERED INDEX [IX_AffiliateApplications_DealerTenantId_Status]
        ON [AFL].[AffiliateApplications] ([DealerTenantId], [Status], [AffiliateApplicationID] DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.AffiliateApplications') AND [name] = N'IX_AffiliateApplications_PartKey_AffiliateApplicationTypeId')
    CREATE NONCLUSTERED INDEX [IX_AffiliateApplications_PartKey_AffiliateApplicationTypeId]
        ON [AFL].[AffiliateApplications] ([PartKey], [AffiliateApplicationTypeId]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.AffiliateApplications') AND [name] = N'IX_AffiliateApplications_AffiliateId')
    CREATE NONCLUSTERED INDEX [IX_AffiliateApplications_AffiliateId]
        ON [AFL].[AffiliateApplications] ([AffiliateId]) WHERE [AffiliateId] IS NOT NULL;
GO
