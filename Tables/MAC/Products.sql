/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: Products
 * Description: Products a tenant sells: rails priced per foot (P001, D001, D002), fixed costs
 *              (dormers, gables, height cost) and add-ons
 *              such as cameras and DVRs. InstallCostPerUnit and ProductCostPerUnit are
 *              internal and never printed on the customer estimate.
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Dependencies: ACC.DealerTenants
 * Migrations: 20261117_0330_CreateMAC_PricingCatalog, 20261117_2230_AddMAC_QuoteBuilder, 20261121_1500_AddPublicEstimatesForMcp
 * API mappings: Models/MAC/PricingCatalog.cs is written by hand; remove it when the
 *               AutoGenerator produces an equivalent.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.Products', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[Products]
    (
        [ProductID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [Sku] [varchar](20) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Category] [varchar](10) NOT NULL,
        [Unit] [varchar](4) NOT NULL,
        [PricePerUnit] [decimal](19, 4) NOT NULL,
        [InstallCostPerUnit] [decimal](19, 4) NULL,
        [ProductCostPerUnit] [decimal](19, 4) NULL,
        [SortOrder] [int] NOT NULL CONSTRAINT [DF_Products_SortOrder] DEFAULT ((0)),
        -- Shown in the public catalog the AI quoting MCP server reads (20261121_1500).
        [IsPublic] [bit] NOT NULL CONSTRAINT [DF_Products_IsPublic] DEFAULT ((1)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Products_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Products_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Products_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Products_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Products_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Products_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Products_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED ([ProductID] ASC),
        CONSTRAINT [FK_Products_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [CK_Products_Category] CHECK ([Category] IN ('Rail', 'Fixed', 'AddOn')),
        CONSTRAINT [CK_Products_Unit] CHECK ([Unit] IN ('ft', 'each')),
        CONSTRAINT [CK_Products_PricePerUnit] CHECK ([PricePerUnit] >= 0),
        CONSTRAINT [CK_Products_InstallCostPerUnit] CHECK ([InstallCostPerUnit] IS NULL OR [InstallCostPerUnit] >= 0),
        CONSTRAINT [CK_Products_ProductCostPerUnit] CHECK ([ProductCostPerUnit] IS NULL OR [ProductCostPerUnit] >= 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'MAC.Products') AND [name] = N'UQ_Products_DealerTenantId_Sku')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Products_DealerTenantId_Sku]
        ON [MAC].[Products] ([DealerTenantId], [Sku]);
GO
