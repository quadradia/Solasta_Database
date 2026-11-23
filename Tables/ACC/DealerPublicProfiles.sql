/*******************************************************************************
 * Object Type: Table
 * Schema: ACC
 * Name: DealerPublicProfiles
 * Description: A dealer tenant's public face for the AI quoting MCP server (mcp.mysolasta.com): URL slug,
               contact details, estimate uncertainty and the service user the API signs in as.
 * Author: Andres Sosa
 * Created: 2026-11-21
 * Dependencies: ACC.DealerTenants, ACC.Users
 * Migrations: 20261121_1500_AddPublicEstimatesForMcp
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'ACC.DealerPublicProfiles', N'U') IS NULL
BEGIN
    CREATE TABLE [ACC].[DealerPublicProfiles]
    (
        [DealerPublicProfileID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        -- Lower-case URL name: mcp.mysolasta.com/d/{Slug}/mcp and api/public/{Slug}/...
        [Slug] [varchar](40) NOT NULL,
        [DisplayName] [nvarchar](100) NOT NULL,
        -- A few sentences an AI assistant can repeat: who the dealer is and what it installs.
        [Description] [nvarchar](1000) NULL,
        [WebsiteUrl] [varchar](255) NULL,
        [Phone] [varchar](20) NULL,
        [Email] [varchar](255) NULL,
        -- Off hides the dealer from the MCP and every api/public/{Slug} route.
        [IsMcpEnabled] [bit] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_IsMcpEnabled] DEFAULT ((0)),
        -- The share an estimate's feet can be off, by where the feet came from (0.25 is +/-25%).
        [FootprintUncertainty] [decimal](5, 4) NOT NULL CONSTRAINT [DF_DealerPublicProfiles_FootprintUncertainty] DEFAULT ((0.25)),
        [KmlUncertainty] [decimal](5, 4) NOT NULL CONSTRAINT [DF_DealerPublicProfiles_KmlUncertainty] DEFAULT ((0.10)),
        -- How long an estimate is good for.
        [EstimateValidityDays] [int] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_EstimateValidityDays] DEFAULT ((30)),
        -- The ACC.Users row the API signs in as for this dealer's public requests (audit columns, session context).
        [ServiceUserId] [uniqueidentifier] NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerPublicProfiles_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerPublicProfiles_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_DealerPublicProfiles_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerPublicProfiles_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_DealerPublicProfiles] PRIMARY KEY CLUSTERED ([DealerPublicProfileID] ASC),
        CONSTRAINT [FK_DealerPublicProfiles_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_DealerPublicProfiles_Users] FOREIGN KEY ([ServiceUserId]) REFERENCES [ACC].[Users] ([UserID]),
        CONSTRAINT [UQ_DealerPublicProfiles_DealerTenantId] UNIQUE ([DealerTenantId]),
        CONSTRAINT [UQ_DealerPublicProfiles_Slug] UNIQUE ([Slug]),
        CONSTRAINT [CK_DealerPublicProfiles_Slug] CHECK ([Slug] NOT LIKE '%[^a-z0-9-]%' AND LEN([Slug]) >= 2),
        CONSTRAINT [CK_DealerPublicProfiles_Uncertainty] CHECK ([FootprintUncertainty] >= 0 AND [FootprintUncertainty] < 1
                                                                AND [KmlUncertainty] >= 0 AND [KmlUncertainty] < 1),
        CONSTRAINT [CK_DealerPublicProfiles_EstimateValidityDays] CHECK ([EstimateValidityDays] BETWEEN 1 AND 365),
        CONSTRAINT [CK_DealerPublicProfiles_EnabledNeedsUser] CHECK ([IsMcpEnabled] = 0 OR [ServiceUserId] IS NOT NULL)
    );
END;
GO
