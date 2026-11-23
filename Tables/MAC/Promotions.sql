/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: Promotions
 * Description: Per-foot promo discounts (AmountPerUnit is the positive amount taken off each
 *              foot of rail). MaxValidityHours, when set, caps how long a quote using the
 *              promo stays valid (e.g. 24 or 168 hours instead of the usual 30 days).
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Dependencies: ACC.DealerTenants
 * Migrations: 20261117_0330_CreateMAC_PricingCatalog, 20261121_1500_AddPublicEstimatesForMcp
 * API mappings: Models/MAC/PricingCatalog.cs is written by hand; remove it when the
 *               AutoGenerator produces an equivalent.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.Promotions', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[Promotions]
    (
        [PromotionID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [Code] [varchar](20) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [AmountPerUnit] [decimal](19, 4) NOT NULL,
        [StartDate] [date] NULL,
        [EndDate] [date] NULL,
        [MaxValidityHours] [int] NULL,
        [SortOrder] [int] NOT NULL CONSTRAINT [DF_Promotions_SortOrder] DEFAULT ((0)),
        -- Shown in the public catalog the AI quoting MCP server reads (20261121_1500).
        [IsPublic] [bit] NOT NULL CONSTRAINT [DF_Promotions_IsPublic] DEFAULT ((0)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Promotions_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Promotions_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Promotions_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Promotions_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Promotions_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Promotions_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Promotions_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Promotions] PRIMARY KEY CLUSTERED ([PromotionID] ASC),
        CONSTRAINT [FK_Promotions_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [CK_Promotions_AmountPerUnit] CHECK ([AmountPerUnit] >= 0),
        CONSTRAINT [CK_Promotions_EndDate] CHECK ([EndDate] IS NULL OR [StartDate] IS NULL OR [EndDate] >= [StartDate]),
        CONSTRAINT [CK_Promotions_MaxValidityHours] CHECK ([MaxValidityHours] IS NULL OR [MaxValidityHours] > 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'MAC.Promotions') AND [name] = N'UQ_Promotions_DealerTenantId_Code')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Promotions_DealerTenantId_Code]
        ON [MAC].[Promotions] ([DealerTenantId], [Code]);
GO
