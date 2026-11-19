/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: StockItemVariantAttributes
 * Description: What makes a variant (INE.StockItems with ParentStockItemId) different from
 *              its siblings, as name/value pairs: Color = Black, Finish = Matte. One value per
 *              attribute name per variant. Only variants have attributes (04193); the row's
 *              tenant is the variant's tenant (tr_StockItemVariantAttributes_TenantGuard).
 * Dependencies: ACC.DealerTenants, INE.StockItems
 * Migrations: 20261120_0100_AddINE_PartVariants
 * Author: Andres Sosa
 * Created: 2026-11-19
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.StockItemVariantAttributes', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[StockItemVariantAttributes]
    (
        [StockItemVariantAttributeID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [StockItemId] [int] NOT NULL,
        -- e.g. Color
        [AttributeName] [nvarchar](30) NOT NULL,
        -- e.g. Black
        [AttributeValue] [nvarchar](50) NOT NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_StockItemVariantAttributes_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_StockItemVariantAttributes_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockItemVariantAttributes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockItemVariantAttributes_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockItemVariantAttributes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_StockItemVariantAttributes_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_StockItemVariantAttributes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_StockItemVariantAttributes] PRIMARY KEY CLUSTERED ([StockItemVariantAttributeID] ASC),
        CONSTRAINT [FK_StockItemVariantAttributes_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_StockItemVariantAttributes_StockItems] FOREIGN KEY ([StockItemId])
            REFERENCES [INE].[StockItems] ([StockItemID]),
        CONSTRAINT [CK_StockItemVariantAttributes_AttributeName] CHECK (LEN([AttributeName]) > 0),
        CONSTRAINT [CK_StockItemVariantAttributes_AttributeValue] CHECK (LEN([AttributeValue]) > 0)
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.StockItemVariantAttributes')
                 AND [name] = N'UQ_StockItemVariantAttributes_StockItemId_AttributeName')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_StockItemVariantAttributes_StockItemId_AttributeName]
        ON [INE].[StockItemVariantAttributes] ([StockItemId], [AttributeName]);
GO
