/*
Migration: 20261120_0100_AddINE_PartVariants
Author: Andres Sosa
Date: 2026-11-19
Description: Part variants: items the customer must pick a color (or other option) for.
             A parent INE.StockItems row is a catalog entry only; each choice is a child row
             (a variant) that holds the stock, has its own SKU (e.g. LP-100-BLK) and an optional
             customer-facing price adder per unit.
               INE.StockItems              + ParentStockItemId (FK to itself, same tenant), VariantName,
                                           PriceAdder (default 0, >= 0); CHECKs: not its own parent,
                                           VariantName required on a variant; unique (ParentStockItemId,
                                           VariantName) for variants.
               INE.StockItemVariantAttributes (new)  name/value pairs per variant (Color = Black),
                                           unique per variant and name, with audit and tenant guard triggers.
               Triggers                    tr_StockItems_VariantGuard (one level deep 04191; an item gets its
                                           first variant only while it holds no stock 04192; a variant takes
                                           its parent's ProductId); tr_StockItems_TenantGuard (parent of the
                                           same tenant, 04181); trgAutoGen_StockItems_CUD audits the new
                                           columns; tr_PurchaseOrderLines_, tr_StockCountLines_ and
                                           tr_StockLevels_VariantGuard refuse an item with active variants (04190).
               Procedures                  spMovementPost (so also spReceiptPost and count postings),
                                           spAllocationCreate and spStockCountPost refuse an item with active
                                           variants (04190); a Reversal may still undo an older movement.
               Views                       vwStockOnHand, vwReorderSuggestions, vwMovementHistory expose
                                           ParentStockItemId and VariantName.
               MAC.QuoteLines              + StockItemId (FK INE.StockItems, the chosen variant), VariantName and
                                           VariantPriceAdder snapshots. UnitPrice = product price + adder.
             Each object's source of truth is its file under Tables/, Triggers/, Procedures/ and Views/;
             this migration embeds those files. The API must list INE.StockItemVariantAttributes in
             SolastaDbContext.TableTriggers (StockItems, PurchaseOrderLines, StockCountLines and
             StockLevels already have triggers).
Dependencies:
  20261117_1900_AddINE_AuditAndTenantGuards
  20261117_2230_AddMAC_QuoteBuilder
Rollback:
  DROP TRIGGER [INE].[tr_StockItems_VariantGuard];
  DROP TRIGGER [INE].[tr_PurchaseOrderLines_VariantGuard];
  DROP TRIGGER [INE].[tr_StockCountLines_VariantGuard];
  DROP TRIGGER [INE].[tr_StockLevels_VariantGuard];
  DROP TABLE [INE].[StockItemVariantAttributes];
  ALTER TABLE [MAC].[QuoteLines] DROP CONSTRAINT [FK_QuoteLines_StockItems], [CK_QuoteLines_VariantPriceAdder], [CK_QuoteLines_VariantSnapshot];
  ALTER TABLE [MAC].[QuoteLines] DROP COLUMN [StockItemId], [VariantName], [VariantPriceAdder];
  Re-apply tr_StockItems_TenantGuard, trgAutoGen_StockItems_CUD and spMovementPost from
  20261117_1900_AddINE_AuditAndTenantGuards, and spAllocationCreate, spStockCountPost and the three views
  from 20261117_1810_CreateINE_InventoryEngineProcedures, then:
  DROP INDEX [UQ_StockItems_ParentStockItemId_VariantName] ON [INE].[StockItems];
  ALTER TABLE [INE].[StockItems] DROP CONSTRAINT [FK_StockItems_ParentStockItems], [CK_StockItems_ParentNotSelf],
      [CK_StockItems_VariantName], [CK_StockItems_PriceAdder], [DF_StockItems_PriceAdder];
  ALTER TABLE [INE].[StockItems] DROP COLUMN [ParentStockItemId], [VariantName], [PriceAdder];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261120_0100_AddINE_PartVariants';
Expected impact: new nullable/defaulted columns on INE.StockItems and MAC.QuoteLines, one new empty table,
                 new triggers; procedures and views altered. Existing rows are not changed.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261120_0100_AddINE_PartVariants';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[SchemaVersion]
                   WHERE [MigrationName] = N'20261117_1900_AddINE_AuditAndTenantGuards' AND [Success] = 1)
        THROW 50001, 'Apply 20261117_1900_AddINE_AuditAndTenantGuards first.', 1;
    IF OBJECT_ID(N'MAC.QuoteLines', N'U') IS NULL
        THROW 50001, 'MAC.QuoteLines is missing. Apply 20261117_2230_AddMAC_QuoteBuilder first.', 1;

    ---------------------------------------------------------------------------
    -- INE.StockItems: ParentStockItemId, VariantName, PriceAdder
    -- (statements naming the new columns run through sp_executesql so this batch compiles)
    ---------------------------------------------------------------------------
    IF COL_LENGTH(N'INE.StockItems', N'ParentStockItemId') IS NULL
        ALTER TABLE [INE].[StockItems] ADD [ParentStockItemId] [int] NULL;
    IF COL_LENGTH(N'INE.StockItems', N'VariantName') IS NULL
        ALTER TABLE [INE].[StockItems] ADD [VariantName] [nvarchar](50) NULL;
    IF COL_LENGTH(N'INE.StockItems', N'PriceAdder') IS NULL
        ALTER TABLE [INE].[StockItems] ADD [PriceAdder] [decimal](19, 4) NOT NULL
            CONSTRAINT [DF_StockItems_PriceAdder] DEFAULT ((0)) WITH VALUES;

    IF OBJECT_ID(N'INE.FK_StockItems_ParentStockItems', N'F') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE [INE].[StockItems] WITH CHECK ADD CONSTRAINT [FK_StockItems_ParentStockItems]
            FOREIGN KEY ([ParentStockItemId]) REFERENCES [INE].[StockItems] ([StockItemID]);';
    IF OBJECT_ID(N'INE.CK_StockItems_ParentNotSelf', N'C') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE [INE].[StockItems] WITH CHECK ADD CONSTRAINT [CK_StockItems_ParentNotSelf]
            CHECK ([ParentStockItemId] IS NULL OR [ParentStockItemId] <> [StockItemID]);';
    IF OBJECT_ID(N'INE.CK_StockItems_VariantName', N'C') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE [INE].[StockItems] WITH CHECK ADD CONSTRAINT [CK_StockItems_VariantName]
            CHECK ([ParentStockItemId] IS NULL OR [VariantName] IS NOT NULL);';
    IF OBJECT_ID(N'INE.CK_StockItems_PriceAdder', N'C') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE [INE].[StockItems] WITH CHECK ADD CONSTRAINT [CK_StockItems_PriceAdder]
            CHECK ([PriceAdder] >= 0);';
    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'INE.StockItems') AND [name] = N'UQ_StockItems_ParentStockItemId_VariantName')
        EXEC sys.sp_executesql N'CREATE UNIQUE NONCLUSTERED INDEX [UQ_StockItems_ParentStockItemId_VariantName]
            ON [INE].[StockItems] ([ParentStockItemId], [VariantName]) WHERE [ParentStockItemId] IS NOT NULL;';

    ---------------------------------------------------------------------------
    -- INE.StockItemVariantAttributes (Tables/INE/StockItemVariantAttributes.sql)
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- MAC.QuoteLines: StockItemId, VariantName, VariantPriceAdder
    ---------------------------------------------------------------------------
    IF COL_LENGTH(N'MAC.QuoteLines', N'StockItemId') IS NULL
        ALTER TABLE [MAC].[QuoteLines] ADD [StockItemId] [int] NULL;
    IF COL_LENGTH(N'MAC.QuoteLines', N'VariantName') IS NULL
        ALTER TABLE [MAC].[QuoteLines] ADD [VariantName] [nvarchar](50) NULL;
    IF COL_LENGTH(N'MAC.QuoteLines', N'VariantPriceAdder') IS NULL
        ALTER TABLE [MAC].[QuoteLines] ADD [VariantPriceAdder] [decimal](19, 4) NULL;

    IF OBJECT_ID(N'MAC.FK_QuoteLines_StockItems', N'F') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE [MAC].[QuoteLines] WITH CHECK ADD CONSTRAINT [FK_QuoteLines_StockItems]
            FOREIGN KEY ([StockItemId]) REFERENCES [INE].[StockItems] ([StockItemID]);';
    IF OBJECT_ID(N'MAC.CK_QuoteLines_VariantPriceAdder', N'C') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE [MAC].[QuoteLines] WITH CHECK ADD CONSTRAINT [CK_QuoteLines_VariantPriceAdder]
            CHECK ([VariantPriceAdder] IS NULL OR [VariantPriceAdder] >= 0);';
    IF OBJECT_ID(N'MAC.CK_QuoteLines_VariantSnapshot', N'C') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE [MAC].[QuoteLines] WITH CHECK ADD CONSTRAINT [CK_QuoteLines_VariantSnapshot]
            CHECK ([StockItemId] IS NOT NULL OR ([VariantName] IS NULL AND [VariantPriceAdder] IS NULL));';

    ---------------------------------------------------------------------------
    -- Triggers, procedures and views (embedded from their source files)
    ---------------------------------------------------------------------------
    -- INE.tr_StockItems_TenantGuard: parent item of the same tenant (Triggers/INE/tr_StockItems_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_StockItems_TenantGuard]
ON [INE].[StockItems]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[StockItemID] = I.[StockItemID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N''04182|:|INE.StockItems: a row cannot move to another dealer tenant.'', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.StockItems: the row belongs to a different dealer tenant than the signed-in user.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE (I.[ProductId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [MAC].[Products] AS P
                  WHERE P.[ProductID] = I.[ProductId] AND P.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[DefaultVendorId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Vendors] AS V
                  WHERE V.[VendorID] = I.[DefaultVendorId] AND V.[DealerTenantId] = I.[DealerTenantId]))
           OR (I.[ParentStockItemId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS PI
                  WHERE PI.[StockItemID] = I.[ParentStockItemId] AND PI.[DealerTenantId] = I.[DealerTenantId])))
        THROW 50000, N''04181|:|A stock item can only name a product, default vendor and parent item of its own tenant.'', 1;
END;
';

    -- INE.trgAutoGen_StockItems_CUD: audits the new columns (Triggers/INE/trgAutoGen_StockItems_CUD.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[trgAutoGen_StockItems_CUD]
ON [INE].[StockItems]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    DECLARE @UserID UNIQUEIDENTIFIER = (SELECT [UserId] FROM [INE].[fxGetSessionContext]());
    IF @UserID IS NULL
        SELECT @UserID = [UserID] FROM [ACC].[fxGetContextUserTable]();

    DECLARE @Changes TABLE
    (
        [PKID] BIGINT NOT NULL
        , [IsInsert] BIT NOT NULL
        , [ColumnName] NVARCHAR(500) NOT NULL
        , [OldValue] NVARCHAR(500) NULL
        , [NewValue] NVARCHAR(500) NULL
    );

    INSERT INTO @Changes ([PKID], [IsInsert], [ColumnName], [OldValue], [NewValue])
    SELECT I.[StockItemID], CASE WHEN D.[StockItemID] IS NULL THEN 1 ELSE 0 END, V.[ColumnName], V.[OldValue], V.[NewValue]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockItemID] = I.[StockItemID]
    CROSS APPLY (VALUES
            (N''StockItemID'', CAST(D.[StockItemID] AS NVARCHAR(500)), CAST(I.[StockItemID] AS NVARCHAR(500))),
            (N''DealerTenantId'', CAST(D.[DealerTenantId] AS NVARCHAR(500)), CAST(I.[DealerTenantId] AS NVARCHAR(500))),
            (N''ProductId'', CAST(D.[ProductId] AS NVARCHAR(500)), CAST(I.[ProductId] AS NVARCHAR(500))),
            (N''ParentStockItemId'', CAST(D.[ParentStockItemId] AS NVARCHAR(500)), CAST(I.[ParentStockItemId] AS NVARCHAR(500))),
            (N''VariantName'', CAST(D.[VariantName] AS NVARCHAR(500)), CAST(I.[VariantName] AS NVARCHAR(500))),
            (N''PriceAdder'', CAST(D.[PriceAdder] AS NVARCHAR(500)), CAST(I.[PriceAdder] AS NVARCHAR(500))),
            (N''DefaultVendorId'', CAST(D.[DefaultVendorId] AS NVARCHAR(500)), CAST(I.[DefaultVendorId] AS NVARCHAR(500))),
            (N''Sku'', CAST(D.[Sku] AS NVARCHAR(500)), CAST(I.[Sku] AS NVARCHAR(500))),
            (N''Name'', CAST(D.[Name] AS NVARCHAR(500)), CAST(I.[Name] AS NVARCHAR(500))),
            (N''Description'', CAST(D.[Description] AS NVARCHAR(500)), CAST(I.[Description] AS NVARCHAR(500))),
            (N''Category'', CAST(D.[Category] AS NVARCHAR(500)), CAST(I.[Category] AS NVARCHAR(500))),
            (N''TrackingMode'', CAST(D.[TrackingMode] AS NVARCHAR(500)), CAST(I.[TrackingMode] AS NVARCHAR(500))),
            (N''UnitOfMeasure'', CAST(D.[UnitOfMeasure] AS NVARCHAR(500)), CAST(I.[UnitOfMeasure] AS NVARCHAR(500))),
            (N''VendorSku'', CAST(D.[VendorSku] AS NVARCHAR(500)), CAST(I.[VendorSku] AS NVARCHAR(500))),
            (N''StandardCost'', CAST(D.[StandardCost] AS NVARCHAR(500)), CAST(I.[StandardCost] AS NVARCHAR(500))),
            (N''IsActive'', CAST(D.[IsActive] AS NVARCHAR(500)), CAST(I.[IsActive] AS NVARCHAR(500))),
            (N''IsDeleted'', CAST(D.[IsDeleted] AS NVARCHAR(500)), CAST(I.[IsDeleted] AS NVARCHAR(500)))
    ) AS V ([ColumnName], [OldValue], [NewValue])
    WHERE (D.[StockItemID] IS NULL AND V.[NewValue] IS NOT NULL)
       OR (D.[StockItemID] IS NOT NULL
           -- binary compare, so a change in letter case is recorded too
           AND (V.[OldValue] COLLATE Latin1_General_BIN2 <> V.[NewValue] COLLATE Latin1_General_BIN2
                OR (V.[OldValue] IS NULL AND V.[NewValue] IS NOT NULL)
                OR (V.[OldValue] IS NOT NULL AND V.[NewValue] IS NULL)));

    IF NOT EXISTS (SELECT 1 FROM @Changes) RETURN;

    DECLARE @Actions TABLE ([AuditActionID] BIGINT NOT NULL, [PKID] VARCHAR(50) NOT NULL);

    INSERT INTO [AUD].[AuditActions] ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.[AuditActionID], INSERTED.[PrimaryKeyIdentifier] INTO @Actions ([AuditActionID], [PKID])
    SELECT
        CASE
            WHEN MAX(CAST(C.[IsInsert] AS INT)) = 1 THEN ''INSERT''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''1'' THEN 1 ELSE 0 END) = 1 THEN ''DELETE''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''0'' THEN 1 ELSE 0 END) = 1 THEN ''UNDELETE''
            ELSE ''UPDATE''
        END
        , ''INE''
        , ''StockItems''
        , CAST(C.[PKID] AS VARCHAR(50))
        , @UserID
    FROM @Changes AS C
    GROUP BY C.[PKID];

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT A.[AuditActionID], C.[ColumnName], C.[OldValue], C.[NewValue]
    FROM @Changes AS C
    INNER JOIN @Actions AS A ON A.[PKID] = CAST(C.[PKID] AS VARCHAR(50));
END;
';

    -- INE.tr_StockItems_VariantGuard (new) (Triggers/INE/tr_StockItems_VariantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_StockItems_VariantGuard]
ON [INE].[StockItems]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- One level deep.
    IF EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[StockItems] AS P ON P.[StockItemID] = I.[ParentStockItemId]
               WHERE P.[ParentStockItemId] IS NOT NULL)
       OR EXISTS (SELECT 1 FROM inserted AS I
                  WHERE I.[ParentStockItemId] IS NOT NULL
                    AND EXISTS (SELECT 1 FROM [INE].[StockItems] AS C WHERE C.[ParentStockItemId] = I.[StockItemID]))
        THROW 50000, N''04191|:|Variants are one level deep: a variant cannot have variants of its own, and an item with variants cannot become a variant.'', 1;

    -- Parents that just gained a variant must not hold stock.
    DECLARE @NewParents TABLE ([StockItemId] INT NOT NULL PRIMARY KEY);
    INSERT INTO @NewParents ([StockItemId])
    SELECT DISTINCT I.[ParentStockItemId]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockItemID] = I.[StockItemID]
    WHERE I.[ParentStockItemId] IS NOT NULL
      AND (D.[StockItemID] IS NULL OR D.[ParentStockItemId] IS NULL OR D.[ParentStockItemId] <> I.[ParentStockItemId]);

    IF EXISTS (SELECT 1 FROM @NewParents)
    BEGIN
        DECLARE @Msg NVARCHAR(2048);
        SELECT TOP (1) @Msg = CONCAT(N''04192|:|Stock item '', P.[Sku], N'' still holds stock (on hand, allocated, on an open purchase order or a reorder rule). '',
                                     N''Move or adjust it out, close those first, then add variants; stock lives on variants only.'')
        FROM @NewParents AS NP
        INNER JOIN [INE].[StockItems] AS P ON P.[StockItemID] = NP.[StockItemId]
        WHERE EXISTS (SELECT 1 FROM [INE].[StockBalances] AS SB
                      WHERE SB.[StockItemId] = NP.[StockItemId] AND (SB.[QuantityOnHand] <> 0 OR SB.[QuantityAllocated] <> 0))
           OR EXISTS (SELECT 1 FROM [INE].[Allocations] AS A
                      WHERE A.[StockItemId] = NP.[StockItemId] AND A.[Status] = ''Open'')
           OR EXISTS (SELECT 1 FROM [INE].[PurchaseOrderLines] AS POL
                      INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
                      WHERE POL.[StockItemId] = NP.[StockItemId] AND POL.[IsDeleted] = 0 AND PO.[IsDeleted] = 0
                        AND PO.[Status] IN (''Draft'', ''Submitted'', ''PartiallyReceived'')
                        AND POL.[QuantityOrdered] > POL.[QuantityReceived])
           OR EXISTS (SELECT 1 FROM [INE].[StockLevels] AS SL
                      WHERE SL.[StockItemId] = NP.[StockItemId] AND SL.[IsActive] = 1 AND SL.[IsDeleted] = 0);
        IF @Msg IS NOT NULL
            THROW 50000, @Msg, 1;
    END;

    -- A variant takes its parent''s product (both for written variants and written parents).
    IF UPDATE([ProductId]) OR UPDATE([ParentStockItemId])
        UPDATE C SET C.[ProductId] = P.[ProductId]
        FROM [INE].[StockItems] AS C
        INNER JOIN [INE].[StockItems] AS P ON P.[StockItemID] = C.[ParentStockItemId]
        WHERE (C.[StockItemID] IN (SELECT [StockItemID] FROM inserted) OR P.[StockItemID] IN (SELECT [StockItemID] FROM inserted))
          AND (C.[ProductId] <> P.[ProductId] OR (C.[ProductId] IS NULL AND P.[ProductId] IS NOT NULL)
               OR (C.[ProductId] IS NOT NULL AND P.[ProductId] IS NULL));
END;
';

    -- INE.tr_StockItemVariantAttributes_TenantGuard (new) (Triggers/INE/tr_StockItemVariantAttributes_TenantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_StockItemVariantAttributes_TenantGuard]
ON [INE].[StockItemVariantAttributes]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Set by ACC.spSessionContextCreate on every API request; NULL for migrations and jobs.
    DECLARE @SessionTenantId INT = (SELECT [DealerTenantId] FROM [INE].[fxGetSessionContext]());

    IF EXISTS (SELECT 1 FROM inserted AS I INNER JOIN deleted AS D ON D.[StockItemVariantAttributeID] = I.[StockItemVariantAttributeID]
               WHERE D.[DealerTenantId] <> I.[DealerTenantId])
        THROW 50000, N''04182|:|INE.StockItemVariantAttributes: a row cannot move to another dealer tenant.'', 1;

    IF @SessionTenantId IS NOT NULL AND EXISTS (SELECT 1 FROM inserted WHERE [DealerTenantId] <> @SessionTenantId)
        THROW 50000, N''04180|:|INE.StockItemVariantAttributes: the row belongs to a different dealer tenant than the signed-in user.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               WHERE NOT EXISTS (SELECT 1 FROM [INE].[StockItems] AS SI
                  WHERE SI.[StockItemID] = I.[StockItemId] AND SI.[DealerTenantId] = I.[DealerTenantId]))
        THROW 50000, N''04181|:|A variant attribute can only name a stock item of its own tenant.'', 1;

    IF EXISTS (SELECT 1 FROM inserted AS I
               INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = I.[StockItemId]
               WHERE SI.[ParentStockItemId] IS NULL)
        THROW 50000, N''04193|:|Only a variant (a stock item with a parent) has variant attributes.'', 1;
END;
';

    -- INE.trgAutoGen_StockItemVariantAttributes_CUD (new) (Triggers/INE/trgAutoGen_StockItemVariantAttributes_CUD.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[trgAutoGen_StockItemVariantAttributes_CUD]
ON [INE].[StockItemVariantAttributes]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    DECLARE @UserID UNIQUEIDENTIFIER = (SELECT [UserId] FROM [INE].[fxGetSessionContext]());
    IF @UserID IS NULL
        SELECT @UserID = [UserID] FROM [ACC].[fxGetContextUserTable]();

    DECLARE @Changes TABLE
    (
        [PKID] BIGINT NOT NULL
        , [IsInsert] BIT NOT NULL
        , [ColumnName] NVARCHAR(500) NOT NULL
        , [OldValue] NVARCHAR(500) NULL
        , [NewValue] NVARCHAR(500) NULL
    );

    INSERT INTO @Changes ([PKID], [IsInsert], [ColumnName], [OldValue], [NewValue])
    SELECT I.[StockItemVariantAttributeID], CASE WHEN D.[StockItemVariantAttributeID] IS NULL THEN 1 ELSE 0 END, V.[ColumnName], V.[OldValue], V.[NewValue]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockItemVariantAttributeID] = I.[StockItemVariantAttributeID]
    CROSS APPLY (VALUES
            (N''StockItemVariantAttributeID'', CAST(D.[StockItemVariantAttributeID] AS NVARCHAR(500)), CAST(I.[StockItemVariantAttributeID] AS NVARCHAR(500))),
            (N''DealerTenantId'', CAST(D.[DealerTenantId] AS NVARCHAR(500)), CAST(I.[DealerTenantId] AS NVARCHAR(500))),
            (N''StockItemId'', CAST(D.[StockItemId] AS NVARCHAR(500)), CAST(I.[StockItemId] AS NVARCHAR(500))),
            (N''AttributeName'', CAST(D.[AttributeName] AS NVARCHAR(500)), CAST(I.[AttributeName] AS NVARCHAR(500))),
            (N''AttributeValue'', CAST(D.[AttributeValue] AS NVARCHAR(500)), CAST(I.[AttributeValue] AS NVARCHAR(500))),
            (N''IsActive'', CAST(D.[IsActive] AS NVARCHAR(500)), CAST(I.[IsActive] AS NVARCHAR(500))),
            (N''IsDeleted'', CAST(D.[IsDeleted] AS NVARCHAR(500)), CAST(I.[IsDeleted] AS NVARCHAR(500)))
    ) AS V ([ColumnName], [OldValue], [NewValue])
    WHERE (D.[StockItemVariantAttributeID] IS NULL AND V.[NewValue] IS NOT NULL)
       OR (D.[StockItemVariantAttributeID] IS NOT NULL
           -- binary compare, so a change in letter case is recorded too
           AND (V.[OldValue] COLLATE Latin1_General_BIN2 <> V.[NewValue] COLLATE Latin1_General_BIN2
                OR (V.[OldValue] IS NULL AND V.[NewValue] IS NOT NULL)
                OR (V.[OldValue] IS NOT NULL AND V.[NewValue] IS NULL)));

    IF NOT EXISTS (SELECT 1 FROM @Changes) RETURN;

    DECLARE @Actions TABLE ([AuditActionID] BIGINT NOT NULL, [PKID] VARCHAR(50) NOT NULL);

    INSERT INTO [AUD].[AuditActions] ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.[AuditActionID], INSERTED.[PrimaryKeyIdentifier] INTO @Actions ([AuditActionID], [PKID])
    SELECT
        CASE
            WHEN MAX(CAST(C.[IsInsert] AS INT)) = 1 THEN ''INSERT''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''1'' THEN 1 ELSE 0 END) = 1 THEN ''DELETE''
            WHEN MAX(CASE WHEN C.[ColumnName] = N''IsDeleted'' AND C.[NewValue] = N''0'' THEN 1 ELSE 0 END) = 1 THEN ''UNDELETE''
            ELSE ''UPDATE''
        END
        , ''INE''
        , ''StockItemVariantAttributes''
        , CAST(C.[PKID] AS VARCHAR(50))
        , @UserID
    FROM @Changes AS C
    GROUP BY C.[PKID];

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT A.[AuditActionID], C.[ColumnName], C.[OldValue], C.[NewValue]
    FROM @Changes AS C
    INNER JOIN @Actions AS A ON A.[PKID] = CAST(C.[PKID] AS VARCHAR(50));
END;
';

    -- INE.tr_PurchaseOrderLines_VariantGuard (new) (Triggers/INE/tr_PurchaseOrderLines_VariantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_PurchaseOrderLines_VariantGuard]
ON [INE].[PurchaseOrderLines]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) OR NOT UPDATE([StockItemId]) RETURN;

    DECLARE @Msg NVARCHAR(2048);
    SELECT TOP (1) @Msg = CONCAT(N''04190|:|Stock item '', SI.[Sku], N'' has variants; stock is kept on its variants. Pick a variant.'')
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[PurchaseOrderLineID] = I.[PurchaseOrderLineID]
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = I.[StockItemId]
    WHERE (D.[PurchaseOrderLineID] IS NULL OR D.[StockItemId] <> I.[StockItemId])
      AND EXISTS (SELECT 1 FROM [INE].[StockItems] AS C
                  WHERE C.[ParentStockItemId] = I.[StockItemId] AND C.[IsActive] = 1 AND C.[IsDeleted] = 0);
    IF @Msg IS NOT NULL
        THROW 50000, @Msg, 1;
END;
';

    -- INE.tr_StockCountLines_VariantGuard (new) (Triggers/INE/tr_StockCountLines_VariantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_StockCountLines_VariantGuard]
ON [INE].[StockCountLines]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) OR NOT UPDATE([StockItemId]) RETURN;

    DECLARE @Msg NVARCHAR(2048);
    SELECT TOP (1) @Msg = CONCAT(N''04190|:|Stock item '', SI.[Sku], N'' has variants; stock is kept on its variants. Pick a variant.'')
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockCountLineID] = I.[StockCountLineID]
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = I.[StockItemId]
    WHERE (D.[StockCountLineID] IS NULL OR D.[StockItemId] <> I.[StockItemId])
      AND EXISTS (SELECT 1 FROM [INE].[StockItems] AS C
                  WHERE C.[ParentStockItemId] = I.[StockItemId] AND C.[IsActive] = 1 AND C.[IsDeleted] = 0);
    IF @Msg IS NOT NULL
        THROW 50000, @Msg, 1;
END;
';

    -- INE.tr_StockLevels_VariantGuard (new) (Triggers/INE/tr_StockLevels_VariantGuard.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER [INE].[tr_StockLevels_VariantGuard]
ON [INE].[StockLevels]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) OR NOT UPDATE([StockItemId]) RETURN;

    DECLARE @Msg NVARCHAR(2048);
    SELECT TOP (1) @Msg = CONCAT(N''04190|:|Stock item '', SI.[Sku], N'' has variants; stock is kept on its variants. Pick a variant.'')
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockLevelID] = I.[StockLevelID]
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = I.[StockItemId]
    WHERE (D.[StockLevelID] IS NULL OR D.[StockItemId] <> I.[StockItemId])
      AND EXISTS (SELECT 1 FROM [INE].[StockItems] AS C
                  WHERE C.[ParentStockItemId] = I.[StockItemId] AND C.[IsActive] = 1 AND C.[IsDeleted] = 0);
    IF @Msg IS NOT NULL
        THROW 50000, @Msg, 1;
END;
';

    -- INE.spMovementPost: 04190 (Procedures/INE/spMovementPost.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spMovementPost]
(
    @MovementJson NVARCHAR(MAX),
    @MovementId BIGINT = NULL OUTPUT,
    @ReturnResult BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OwnsTransaction BIT = 0;

    BEGIN TRY
        /** CONTEXT */
        DECLARE @TenantId INT, @UserId UNIQUEIDENTIFIER, @Msg NVARCHAR(2048);
        SELECT @TenantId = SC.[DealerTenantId], @UserId = SC.[UserId] FROM [INE].[fxGetSessionContext]() AS SC;
        IF @TenantId IS NULL
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;
        SET @UserId = ISNULL(@UserId, ''E6872B58-52B2-415C-A32B-45805F95A70A'');

        IF @MovementJson IS NULL OR ISJSON(@MovementJson) <> 1
            THROW 50000, N''04101|:|The movement is not valid JSON.'', 1;

        /** HEADER */
        DECLARE @TypeCode VARCHAR(20), @FromLocationId INT, @ToLocationId INT, @LeadId BIGINT
            , @ReceiptId BIGINT, @StockCountId BIGINT, @ReversesMovementId BIGINT
            , @Reference NVARCHAR(50), @Notes NVARCHAR(2000), @MovementDate DATETIMEOFFSET(7);

        SELECT
            @TypeCode = H.[movementType]
            , @FromLocationId = H.[fromLocationId]
            , @ToLocationId = H.[toLocationId]
            , @LeadId = H.[leadId]
            , @ReceiptId = H.[receiptId]
            , @StockCountId = H.[stockCountId]
            , @ReversesMovementId = H.[reversesMovementId]
            , @Reference = H.[reference]
            , @Notes = H.[notes]
            , @MovementDate = ISNULL(H.[movementDate], SYSDATETIMEOFFSET())
        FROM OPENJSON(@MovementJson)
        WITH (
            [movementType] VARCHAR(20) N''$.movementType''
            , [fromLocationId] INT N''$.fromLocationId''
            , [toLocationId] INT N''$.toLocationId''
            , [leadId] BIGINT N''$.leadId''
            , [receiptId] BIGINT N''$.receiptId''
            , [stockCountId] BIGINT N''$.stockCountId''
            , [reversesMovementId] BIGINT N''$.reversesMovementId''
            , [reference] NVARCHAR(50) N''$.reference''
            , [notes] NVARCHAR(2000) N''$.notes''
            , [movementDate] DATETIMEOFFSET(7) N''$.movementDate''
        ) AS H;

        DECLARE @MovementTypeId INT, @RequiresFrom BIT, @RequiresTo BIT, @RequiresLead BIT
            , @FromTypeRule VARCHAR(20), @ToTypeRule VARCHAR(20);
        SELECT
            @MovementTypeId = MT.[MovementTypeID]
            , @RequiresFrom = MT.[RequiresFrom]
            , @RequiresTo = MT.[RequiresTo]
            , @RequiresLead = MT.[RequiresLead]
            , @FromTypeRule = MT.[FromLocationTypeCode]
            , @ToTypeRule = MT.[ToLocationTypeCode]
        FROM [INE].[MovementTypes] AS MT
        WHERE MT.[Code] = @TypeCode AND MT.[IsActive] = 1 AND MT.[IsDeleted] = 0;

        IF @MovementTypeId IS NULL
        BEGIN
            SET @Msg = CONCAT(N''04102|:|Unknown movement type "'', @TypeCode, N''".'');
            THROW 50000, @Msg, 1;
        END;

        DECLARE @IsReversal BIT = CASE WHEN @TypeCode = ''Reversal'' THEN 1 ELSE 0 END;
        IF (@IsReversal = 1 AND @ReversesMovementId IS NULL) OR (@IsReversal = 0 AND @ReversesMovementId IS NOT NULL)
            THROW 50000, N''04103|:|A Reversal names the movement it reverses (reversesMovementId), and only a Reversal can.'', 1;

        /** REVERSAL: everything comes from the original; caller-supplied lines and locations are ignored */
        IF @IsReversal = 1
        BEGIN
            DECLARE @OriginalType VARCHAR(20), @OriginalReference NVARCHAR(50);
            SELECT @OriginalType = OMT.[Code], @FromLocationId = OM.[ToLocationId], @ToLocationId = OM.[FromLocationId],
                   @LeadId = OM.[LeadId], @OriginalReference = OM.[Reference]
            FROM [INE].[Movements] AS OM
            INNER JOIN [INE].[MovementTypes] AS OMT ON OMT.[MovementTypeID] = OM.[MovementTypeId]
            WHERE OM.[MovementID] = @ReversesMovementId AND OM.[DealerTenantId] = @TenantId;

            IF @OriginalType IS NULL
                THROW 50000, N''04130|:|The movement to reverse was not found.'', 1;
            IF @OriginalType = ''Reversal''
                THROW 50000, N''04131|:|A reversal cannot be reversed; post a new movement instead.'', 1;
            IF EXISTS (SELECT 1 FROM [INE].[Movements] WHERE [ReversesMovementId] = @ReversesMovementId)
                THROW 50000, N''04132|:|The movement has already been reversed.'', 1;

            SET @Reference = ISNULL(@Reference, @OriginalReference);
            SET @ReceiptId = NULL;
            SET @StockCountId = NULL;
            SET @MovementJson = JSON_MODIFY(@MovementJson, N''$.lines'', JSON_QUERY(ISNULL((
                SELECT
                    OML.[StockItemId] AS [stockItemId]
                    , OML.[LotId] AS [lotId]
                    , OML.[SerialUnitId] AS [serialUnitId]
                    , OML.[Quantity] AS [quantity]
                    , OML.[UnitCost] AS [unitCost]
                    , OML.[PurchaseOrderLineId] AS [purchaseOrderLineId]
                    , OML.[AllocationId] AS [allocationId]
                FROM [INE].[MovementLines] AS OML
                WHERE OML.[MovementId] = @ReversesMovementId
                ORDER BY OML.[MovementLineID]
                FOR JSON PATH), N''[]'')));
        END;

        /** LOCATIONS */
        IF @IsReversal = 0
        BEGIN
            IF (@RequiresFrom = 1 AND @FromLocationId IS NULL) OR (@RequiresFrom = 0 AND @FromLocationId IS NOT NULL)
               OR (@RequiresTo = 1 AND @ToLocationId IS NULL) OR (@RequiresTo = 0 AND @ToLocationId IS NOT NULL)
            BEGIN
                SET @Msg = CONCAT(N''04104|:|A '', @TypeCode, N'' movement '',
                    CASE WHEN @RequiresFrom = 1 THEN N''needs'' ELSE N''cannot have'' END, N'' a from location and '',
                    CASE WHEN @RequiresTo = 1 THEN N''needs'' ELSE N''cannot have'' END, N'' a to location.'');
                THROW 50000, @Msg, 1;
            END;
        END
        ELSE IF @FromLocationId IS NULL AND @ToLocationId IS NULL
            THROW 50000, N''04104|:|A movement needs a from or a to location.'', 1;

        IF @FromLocationId IS NOT NULL AND @FromLocationId = @ToLocationId
            THROW 50000, N''04105|:|The from and to locations are the same.'', 1;

        DECLARE @FromTypeCode VARCHAR(20), @FromStockHolding BIT, @FromLeadId BIGINT
            , @ToTypeCode VARCHAR(20), @ToStockHolding BIT, @ToLeadId BIGINT;

        IF @FromLocationId IS NOT NULL
        BEGIN
            SELECT @FromTypeCode = LT.[Code], @FromStockHolding = LT.[IsStockHolding], @FromLeadId = L.[LeadId]
            FROM [INE].[Locations] AS L
            INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
            WHERE L.[LocationID] = @FromLocationId AND L.[DealerTenantId] = @TenantId
              AND L.[IsActive] = 1 AND L.[IsDeleted] = 0;
            IF @FromTypeCode IS NULL
            BEGIN
                SET @Msg = CONCAT(N''04106|:|From location '', @FromLocationId, N'' was not found.'');
                THROW 50000, @Msg, 1;
            END;
        END;

        IF @ToLocationId IS NOT NULL
        BEGIN
            SELECT @ToTypeCode = LT.[Code], @ToStockHolding = LT.[IsStockHolding], @ToLeadId = L.[LeadId]
            FROM [INE].[Locations] AS L
            INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
            WHERE L.[LocationID] = @ToLocationId AND L.[DealerTenantId] = @TenantId
              AND L.[IsActive] = 1 AND L.[IsDeleted] = 0;
            IF @ToTypeCode IS NULL
            BEGIN
                SET @Msg = CONCAT(N''04106|:|To location '', @ToLocationId, N'' was not found.'');
                THROW 50000, @Msg, 1;
            END;
        END;

        -- A NULL rule means any stock-holding location; otherwise the exact location type.
        IF @IsReversal = 0 AND (
               (@FromLocationId IS NOT NULL AND ((@FromTypeRule IS NULL AND @FromStockHolding = 0) OR @FromTypeCode <> @FromTypeRule))
            OR (@ToLocationId IS NOT NULL AND ((@ToTypeRule IS NULL AND @ToStockHolding = 0) OR @ToTypeCode <> @ToTypeRule)))
        BEGIN
            SET @Msg = CONCAT(N''04107|:|A '', @TypeCode, N'' movement cannot go from a '', ISNULL(@FromTypeCode, N''(none)''),
                              N'' location to a '', ISNULL(@ToTypeCode, N''(none)''), N'' location.'');
            THROW 50000, @Msg, 1;
        END;

        /** JOB (LEAD) */
        DECLARE @LocationLeadId BIGINT = COALESCE(@ToLeadId, @FromLeadId);
        IF @LeadId IS NULL SET @LeadId = @LocationLeadId;
        IF @LocationLeadId IS NOT NULL AND @LeadId <> @LocationLeadId
            THROW 50000, N''04108|:|The lead does not match the job location.'', 1;
        IF @RequiresLead = 1 AND @LeadId IS NULL
        BEGIN
            SET @Msg = CONCAT(N''04108|:|A '', @TypeCode, N'' movement needs a lead (job).'');
            THROW 50000, @Msg, 1;
        END;
        IF @LeadId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [QAL].[Leads] AS LD
                                               WHERE LD.[LeadID] = @LeadId AND LD.[DealerTenantId] = @TenantId)
            THROW 50000, N''04108|:|The lead was not found.'', 1;

        /** RECEIPT / COUNT / REVERSED MOVEMENT */
        IF @TypeCode = ''Receive'' AND @ReceiptId IS NULL
            THROW 50000, N''04109|:|A Receive movement needs a receipt (use INE.spReceiptPost).'', 1;
        IF @ReceiptId IS NOT NULL
        BEGIN
            IF @TypeCode <> ''Receive''
                THROW 50000, N''04109|:|Only a Receive movement can name a receipt.'', 1;
            IF NOT EXISTS (SELECT 1 FROM [INE].[Receipts] AS R
                           WHERE R.[ReceiptID] = @ReceiptId AND R.[DealerTenantId] = @TenantId
                             AND R.[LocationId] = @ToLocationId AND R.[IsDeleted] = 0)
                THROW 50000, N''04109|:|The receipt was not found or is for another location.'', 1;
        END;
        IF @StockCountId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[StockCounts] AS SC
                                                     WHERE SC.[StockCountID] = @StockCountId AND SC.[DealerTenantId] = @TenantId)
            THROW 50000, N''04110|:|The stock count was not found.'', 1;

        -- The transaction opens here, before the line checks, so the UPDLOCKs taken on
        -- serial units, PO lines and allocations hold until the movement is written.
        -- (Opened after them, two posts could both see a serial at the from location.)
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnsTransaction = 1;
        END;

        /** LINES */
        DECLARE @Lines TABLE
        (
            [RowNo] INT IDENTITY(1,1) NOT NULL PRIMARY KEY
            , [StockItemId] INT NULL
            , [TrackingMode] VARCHAR(10) NULL
            , [LotId] INT NULL
            , [LotNumber] NVARCHAR(50) NULL
            , [SerialUnitId] BIGINT NULL
            , [SerialNumber] NVARCHAR(60) NULL
            , [Quantity] DECIMAL(19, 4) NULL
            , [UnitCost] DECIMAL(19, 4) NULL
            , [PurchaseOrderLineId] BIGINT NULL
            , [AllocationId] BIGINT NULL
        );

        INSERT INTO @Lines ([StockItemId], [LotId], [LotNumber], [SerialUnitId], [SerialNumber], [Quantity], [UnitCost], [PurchaseOrderLineId], [AllocationId])
        SELECT
            JL.[stockItemId]
            , JL.[lotId]
            , NULLIF(LTRIM(RTRIM(JL.[lotNumber])), N'''')
            , JL.[serialUnitId]
            , NULLIF(LTRIM(RTRIM(SN.[value])), N'''')
            -- One line per serial number; a serial line is always quantity 1.
            , CASE WHEN SN.[value] IS NOT NULL OR JL.[serialUnitId] IS NOT NULL THEN 1 ELSE JL.[quantity] END
            , JL.[unitCost]
            , JL.[purchaseOrderLineId]
            , JL.[allocationId]
        FROM OPENJSON(@MovementJson, N''$.lines'')
        WITH (
            [stockItemId] INT N''$.stockItemId''
            , [quantity] DECIMAL(19, 4) N''$.quantity''
            , [lotId] INT N''$.lotId''
            , [lotNumber] NVARCHAR(50) N''$.lotNumber''
            , [serialUnitId] BIGINT N''$.serialUnitId''
            , [serialNumbers] NVARCHAR(MAX) N''$.serialNumbers'' AS JSON
            , [unitCost] DECIMAL(19, 4) N''$.unitCost''
            , [purchaseOrderLineId] BIGINT N''$.purchaseOrderLineId''
            , [allocationId] BIGINT N''$.allocationId''
        ) AS JL
        OUTER APPLY OPENJSON(JL.[serialNumbers]) AS SN;

        IF NOT EXISTS (SELECT 1 FROM @Lines)
            THROW 50000, N''04111|:|A movement needs at least one line.'', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [Quantity] IS NULL OR [Quantity] <= 0)
            THROW 50000, N''04111|:|Every line needs a quantity greater than zero.'', 1;

        -- Items
        UPDATE LN SET LN.[TrackingMode] = SI.[TrackingMode]
        FROM @Lines AS LN
        INNER JOIN [INE].[StockItems] AS SI
            ON SI.[StockItemID] = LN.[StockItemId] AND SI.[DealerTenantId] = @TenantId
           AND SI.[IsDeleted] = 0 AND (SI.[IsActive] = 1 OR @IsReversal = 1);

        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] IS NULL)
        BEGIN
            SELECT TOP (1) @Msg = CONCAT(N''04112|:|Stock item '', ISNULL(CAST([StockItemId] AS NVARCHAR(20)), N''(missing)''), N'' was not found or is inactive.'')
            FROM @Lines WHERE [TrackingMode] IS NULL;
            THROW 50000, @Msg, 1;
        END;

        -- Stock lives on variants only: an item with active variants is a catalog entry.
        -- A reversal may still undo a movement posted before the item got variants.
        IF @IsReversal = 0 AND EXISTS (SELECT 1 FROM @Lines AS LN
                   WHERE EXISTS (SELECT 1 FROM [INE].[StockItems] AS C
                                 WHERE C.[ParentStockItemId] = LN.[StockItemId] AND C.[IsActive] = 1 AND C.[IsDeleted] = 0))
        BEGIN
            SELECT TOP (1) @Msg = CONCAT(N''04190|:|Stock item '', SI.[Sku], N'' has variants; stock is kept on its variants. Pick a variant.'')
            FROM @Lines AS LN
            INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = LN.[StockItemId]
            WHERE EXISTS (SELECT 1 FROM [INE].[StockItems] AS C
                          WHERE C.[ParentStockItemId] = LN.[StockItemId] AND C.[IsActive] = 1 AND C.[IsDeleted] = 0);
            THROW 50000, @Msg, 1;
        END;

        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = ''Serial'' AND [SerialUnitId] IS NULL AND [SerialNumber] IS NULL)
            THROW 50000, N''04113|:|Serial-tracked items need serialNumbers or a serialUnitId.'', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] <> ''Serial'' AND ([SerialUnitId] IS NOT NULL OR [SerialNumber] IS NOT NULL))
            THROW 50000, N''04113|:|Only serial-tracked items can name serial numbers.'', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = ''Quantity'' AND ([LotId] IS NOT NULL OR [LotNumber] IS NOT NULL))
            THROW 50000, N''04114|:|Quantity-tracked items do not have lots.'', 1;
        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = ''Lot'' AND [LotId] IS NULL AND [LotNumber] IS NULL)
            THROW 50000, N''04114|:|Lot-tracked items need a lotId or lotNumber.'', 1;

        -- Stock enters the books only when there is no from location (Receive, AdjustIn,
        -- or the reversal of a movement that took it off the books).
        DECLARE @IsInbound BIT = CASE WHEN @FromLocationId IS NULL THEN 1 ELSE 0 END;

        -- Lots: resolve numbers; an inbound movement may create new lots.
        UPDATE LN SET LN.[LotId] = LO.[LotID]
        FROM @Lines AS LN
        INNER JOIN [INE].[Lots] AS LO
            ON LO.[StockItemId] = LN.[StockItemId] AND LO.[LotNumber] = LN.[LotNumber]
        WHERE LN.[LotId] IS NULL AND LN.[LotNumber] IS NOT NULL;

        IF EXISTS (SELECT 1 FROM @Lines AS LN
                   WHERE LN.[LotId] IS NOT NULL
                     AND NOT EXISTS (SELECT 1 FROM [INE].[Lots] AS LO
                                     WHERE LO.[LotID] = LN.[LotId] AND LO.[StockItemId] = LN.[StockItemId]
                                       AND LO.[DealerTenantId] = @TenantId))
            THROW 50000, N''04115|:|A lot does not belong to its stock item.'', 1;

        IF @IsInbound = 0 AND EXISTS (SELECT 1 FROM @Lines WHERE [LotId] IS NULL AND [LotNumber] IS NOT NULL)
        BEGIN
            SELECT TOP (1) @Msg = CONCAT(N''04115|:|Lot "'', [LotNumber], N''" was not found.'') FROM @Lines WHERE [LotId] IS NULL AND [LotNumber] IS NOT NULL;
            THROW 50000, @Msg, 1;
        END;

        -- Serial units: resolve numbers to existing units.
        UPDATE LN SET LN.[SerialUnitId] = SU.[SerialUnitID]
        FROM @Lines AS LN
        INNER JOIN [INE].[SerialUnits] AS SU
            ON SU.[StockItemId] = LN.[StockItemId] AND SU.[SerialNumber] = LN.[SerialNumber]
        WHERE LN.[SerialUnitId] IS NULL AND LN.[SerialNumber] IS NOT NULL;

        IF EXISTS (SELECT 1 FROM @Lines AS LN
                   WHERE LN.[SerialUnitId] IS NOT NULL
                     AND NOT EXISTS (SELECT 1 FROM [INE].[SerialUnits] AS SU
                                     WHERE SU.[SerialUnitID] = LN.[SerialUnitId] AND SU.[StockItemId] = LN.[StockItemId]
                                       AND SU.[DealerTenantId] = @TenantId))
            THROW 50000, N''04116|:|A serial unit does not belong to its stock item.'', 1;

        IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = ''Serial''
                   GROUP BY [StockItemId], ISNULL([SerialNumber], CAST([SerialUnitId] AS NVARCHAR(60)))
                   HAVING COUNT(*) > 1)
            THROW 50000, N''04117|:|A serial number appears more than once in the movement.'', 1;

        IF @IsInbound = 1
        BEGIN
            -- Coming onto the books: a unit that already exists must be off the books
            -- (Scrapped, Missing, Voided); otherwise it is a duplicate.
            IF EXISTS (SELECT 1 FROM @Lines AS LN
                       INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = LN.[SerialUnitId]
                       WHERE SU.[CurrentLocationId] IS NOT NULL)
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N''04118|:|Serial number "'', SU.[SerialNumber], N''" is already in stock ('', SU.[Status], N'').'')
                FROM @Lines AS LN INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = LN.[SerialUnitId]
                WHERE SU.[CurrentLocationId] IS NOT NULL;
                THROW 50000, @Msg, 1;
            END;
        END
        ELSE
        BEGIN
            IF EXISTS (SELECT 1 FROM @Lines WHERE [TrackingMode] = ''Serial'' AND [SerialUnitId] IS NULL)
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N''04118|:|Serial number "'', [SerialNumber], N''" was not found.'')
                FROM @Lines WHERE [TrackingMode] = ''Serial'' AND [SerialUnitId] IS NULL;
                THROW 50000, @Msg, 1;
            END;
            -- Lock every serial unit on the movement until it commits, so a concurrent post
            -- cannot move the same unit between this check and the update below.
            DECLARE @LockedSerialUnits INT =
            (
                SELECT COUNT(*)
                FROM [INE].[SerialUnits] AS SU WITH (UPDLOCK, HOLDLOCK)
                INNER JOIN @Lines AS LN ON LN.[SerialUnitId] = SU.[SerialUnitID]
            );
            IF EXISTS (SELECT 1 FROM @Lines AS LN
                       INNER JOIN [INE].[SerialUnits] AS SU WITH (UPDLOCK) ON SU.[SerialUnitID] = LN.[SerialUnitId]
                       WHERE ISNULL(SU.[CurrentLocationId], -1) <> @FromLocationId)
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N''04118|:|Serial number "'', SU.[SerialNumber], N''" is not at the from location.'')
                FROM @Lines AS LN INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = LN.[SerialUnitId]
                WHERE ISNULL(SU.[CurrentLocationId], -1) <> @FromLocationId;
                THROW 50000, @Msg, 1;
            END;
        END;

        -- An existing serial unit carries its own lot.
        UPDATE LN SET LN.[LotId] = SU.[LotId]
        FROM @Lines AS LN
        INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = LN.[SerialUnitId]
        WHERE SU.[LotId] IS NOT NULL;

        -- Purchase order lines (Receive, or the Reversal of one).
        IF EXISTS (SELECT 1 FROM @Lines WHERE [PurchaseOrderLineId] IS NOT NULL)
        BEGIN
            IF @TypeCode NOT IN (''Receive'', ''Reversal'')
                THROW 50000, N''04119|:|Only a Receive movement can fill a purchase order line.'', 1;
            IF EXISTS (SELECT 1 FROM @Lines AS LN
                       WHERE LN.[PurchaseOrderLineId] IS NOT NULL
                         AND NOT EXISTS (SELECT 1 FROM [INE].[PurchaseOrderLines] AS POL
                                         INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
                                         WHERE POL.[PurchaseOrderLineID] = LN.[PurchaseOrderLineId]
                                           AND POL.[StockItemId] = LN.[StockItemId]
                                           AND PO.[DealerTenantId] = @TenantId
                                           AND POL.[IsDeleted] = 0))
                THROW 50000, N''04119|:|A purchase order line was not found or is for another item.'', 1;
            IF @TypeCode = ''Receive'' AND EXISTS (
                    SELECT 1 FROM @Lines AS LN
                    INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderLineID] = LN.[PurchaseOrderLineId]
                    INNER JOIN [INE].[PurchaseOrders] AS PO ON PO.[PurchaseOrderID] = POL.[PurchaseOrderId]
                    WHERE PO.[Status] NOT IN (''Submitted'', ''PartiallyReceived''))
                THROW 50000, N''04119|:|Stock can only be received on a Submitted or PartiallyReceived purchase order.'', 1;
            IF @TypeCode = ''Receive'' AND EXISTS (
                    SELECT 1 FROM @Lines AS LN
                    INNER JOIN [INE].[Receipts] AS R ON R.[ReceiptID] = @ReceiptId
                    INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderLineID] = LN.[PurchaseOrderLineId]
                    WHERE R.[PurchaseOrderId] IS NOT NULL AND POL.[PurchaseOrderId] <> R.[PurchaseOrderId])
                THROW 50000, N''04119|:|A line belongs to a different purchase order than the receipt.'', 1;
            IF @TypeCode = ''Receive'' AND EXISTS (
                    SELECT 1
                    FROM (SELECT [PurchaseOrderLineId], SUM([Quantity]) AS [Qty] FROM @Lines
                          WHERE [PurchaseOrderLineId] IS NOT NULL GROUP BY [PurchaseOrderLineId]) AS Q
                    INNER JOIN [INE].[PurchaseOrderLines] AS POL WITH (UPDLOCK) ON POL.[PurchaseOrderLineID] = Q.[PurchaseOrderLineId]
                    WHERE POL.[QuantityReceived] + Q.[Qty] > POL.[QuantityOrdered])
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N''04120|:|PO line '', POL.[LineNumber], N'' ordered '', CAST(POL.[QuantityOrdered] AS DECIMAL(19, 2)),
                                             N'', already received '', CAST(POL.[QuantityReceived] AS DECIMAL(19, 2)),
                                             N''; receiving '', CAST(Q.[Qty] AS DECIMAL(19, 2)), N'' more is too many.'')
                FROM (SELECT [PurchaseOrderLineId], SUM([Quantity]) AS [Qty] FROM @Lines
                      WHERE [PurchaseOrderLineId] IS NOT NULL GROUP BY [PurchaseOrderLineId]) AS Q
                INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderLineID] = Q.[PurchaseOrderLineId]
                WHERE POL.[QuantityReceived] + Q.[Qty] > POL.[QuantityOrdered];
                THROW 50000, @Msg, 1;
            END;
        END;

        -- Allocations (IssueToJob consumes them; a Reversal gives them back).
        IF EXISTS (SELECT 1 FROM @Lines WHERE [AllocationId] IS NOT NULL)
        BEGIN
            IF @TypeCode NOT IN (''IssueToJob'', ''Reversal'')
                THROW 50000, N''04121|:|Only an IssueToJob movement can consume an allocation.'', 1;
            IF EXISTS (SELECT 1 FROM @Lines AS LN
                       WHERE LN.[AllocationId] IS NOT NULL
                         AND NOT EXISTS (SELECT 1 FROM [INE].[Allocations] AS A
                                         WHERE A.[AllocationID] = LN.[AllocationId]
                                           AND A.[DealerTenantId] = @TenantId
                                           AND A.[StockItemId] = LN.[StockItemId]
                                           AND (A.[LotId] IS NULL OR A.[LotId] = LN.[LotId])
                                           AND A.[LeadId] = @LeadId
                                           -- issue: leaves the reserved location; reversal: comes back to it
                                           AND A.[LocationId] = CASE WHEN @IsReversal = 1 THEN @ToLocationId ELSE @FromLocationId END
                                           AND (A.[Status] = ''Open'' OR @IsReversal = 1)))
                THROW 50000, N''04121|:|An allocation was not found, is not open, or is for a different job, item, lot or location.'', 1;
            IF @IsReversal = 0 AND EXISTS (
                    SELECT 1
                    FROM (SELECT [AllocationId], SUM([Quantity]) AS [Qty] FROM @Lines
                          WHERE [AllocationId] IS NOT NULL GROUP BY [AllocationId]) AS Q
                    INNER JOIN [INE].[Allocations] AS A WITH (UPDLOCK) ON A.[AllocationID] = Q.[AllocationId]
                    WHERE A.[QuantityIssued] + Q.[Qty] > A.[QuantityAllocated])
                THROW 50000, N''04121|:|Issuing more than the allocation reserved; issue the extra on a line without the allocation.'', 1;
        END;

        -- Lot items on an allocation line inherit the allocation''s lot when none was given.
        UPDATE LN SET LN.[LotId] = A.[LotId]
        FROM @Lines AS LN INNER JOIN [INE].[Allocations] AS A ON A.[AllocationID] = LN.[AllocationId]
        WHERE LN.[LotId] IS NULL AND LN.[LotNumber] IS NULL AND A.[LotId] IS NOT NULL;

        /** WRITE */

        INSERT INTO [INE].[Movements]
            ([DealerTenantId], [MovementTypeId], [MovementDate], [FromLocationId], [ToLocationId], [LeadId],
             [ReceiptId], [StockCountId], [ReversesMovementId], [Reference], [Notes], [CreatedById])
        VALUES
            (@TenantId, @MovementTypeId, @MovementDate, @FromLocationId, @ToLocationId, @LeadId,
             @ReceiptId, @StockCountId, @ReversesMovementId, @Reference, @Notes, @UserId);
        SET @MovementId = SCOPE_IDENTITY();

        -- New lots (inbound only; checked above).
        INSERT INTO [INE].[Lots] ([DealerTenantId], [StockItemId], [LotNumber], [ModifiedById], [CreatedById])
        SELECT DISTINCT @TenantId, LN.[StockItemId], LN.[LotNumber], @UserId, @UserId
        FROM @Lines AS LN
        WHERE LN.[LotId] IS NULL AND LN.[LotNumber] IS NOT NULL;

        UPDATE LN SET LN.[LotId] = LO.[LotID]
        FROM @Lines AS LN
        INNER JOIN [INE].[Lots] AS LO ON LO.[StockItemId] = LN.[StockItemId] AND LO.[LotNumber] = LN.[LotNumber]
        WHERE LN.[LotId] IS NULL AND LN.[LotNumber] IS NOT NULL;

        -- New serial units (inbound only), created straight into the to location.
        INSERT INTO [INE].[SerialUnits]
            ([DealerTenantId], [StockItemId], [SerialNumber], [LotId], [CurrentLocationId], [Status],
             [PurchaseOrderLineId], [UnitCost], [ReceivedDate], [ModifiedById], [CreatedById])
        SELECT @TenantId, LN.[StockItemId], LN.[SerialNumber], LN.[LotId], @ToLocationId, ''InStock'',
               LN.[PurchaseOrderLineId], LN.[UnitCost], @MovementDate, @UserId, @UserId
        FROM @Lines AS LN
        WHERE LN.[SerialUnitId] IS NULL AND LN.[SerialNumber] IS NOT NULL;

        UPDATE LN SET LN.[SerialUnitId] = SU.[SerialUnitID]
        FROM @Lines AS LN
        INNER JOIN [INE].[SerialUnits] AS SU ON SU.[StockItemId] = LN.[StockItemId] AND SU.[SerialNumber] = LN.[SerialNumber]
        WHERE LN.[SerialUnitId] IS NULL AND LN.[SerialNumber] IS NOT NULL;

        INSERT INTO [INE].[MovementLines]
            ([MovementId], [StockItemId], [LotId], [SerialUnitId], [Quantity], [UnitCost], [PurchaseOrderLineId], [AllocationId], [CreatedById])
        SELECT @MovementId, LN.[StockItemId], LN.[LotId], LN.[SerialUnitId], LN.[Quantity], LN.[UnitCost],
               LN.[PurchaseOrderLineId], LN.[AllocationId], @UserId
        FROM @Lines AS LN
        ORDER BY LN.[RowNo];

        -- Quantity per item and lot, and how much of it consumes (or restores) allocations.
        DECLARE @Totals TABLE
        (
            [StockItemId] INT NOT NULL
            , [LotId] INT NULL
            , [Quantity] DECIMAL(19, 4) NOT NULL
            , [AllocatedQuantity] DECIMAL(19, 4) NOT NULL
        );
        -- A reversed issue gives stock back to its allocation only while the allocation is
        -- still live; stock from a Cancelled allocation comes back unreserved.
        INSERT INTO @Totals ([StockItemId], [LotId], [Quantity], [AllocatedQuantity])
        SELECT LN.[StockItemId], LN.[LotId], SUM(LN.[Quantity]),
               SUM(CASE WHEN LN.[AllocationId] IS NOT NULL AND ISNULL(A.[Status], '''') <> ''Cancelled'' THEN LN.[Quantity] ELSE 0 END)
        FROM @Lines AS LN
        LEFT JOIN [INE].[Allocations] AS A ON A.[AllocationID] = LN.[AllocationId]
        GROUP BY LN.[StockItemId], LN.[LotId];

        /** FROM: take stock out */
        IF @FromLocationId IS NOT NULL
        BEGIN
            -- Available = on hand - allocated, plus what this movement''s own allocations free up.
            IF EXISTS (SELECT 1
                       FROM @Totals AS T
                       LEFT JOIN [INE].[StockBalances] AS SB WITH (UPDLOCK, HOLDLOCK)
                           ON SB.[LocationId] = @FromLocationId AND SB.[StockItemId] = T.[StockItemId]
                          AND ((SB.[LotId] = T.[LotId]) OR (SB.[LotId] IS NULL AND T.[LotId] IS NULL))
                       WHERE ISNULL(SB.[QuantityOnHand], 0)
                             - ISNULL(SB.[QuantityAllocated], 0)
                             + CASE WHEN @IsReversal = 0 THEN T.[AllocatedQuantity] ELSE 0 END
                             < T.[Quantity])
            BEGIN
                SELECT TOP (1) @Msg = CONCAT(N''04122|:|Not enough '', SI.[Sku],
                        CASE WHEN LO.[LotNumber] IS NOT NULL THEN CONCAT(N'' (lot '', LO.[LotNumber], N'')'') ELSE N'''' END,
                        N'' at the from location: '', CAST(ISNULL(SB.[QuantityOnHand], 0) - ISNULL(SB.[QuantityAllocated], 0) AS DECIMAL(19, 2)),
                        N'' '', SI.[UnitOfMeasure], N'' available, '', CAST(T.[Quantity] AS DECIMAL(19, 2)), N'' needed.'')
                FROM @Totals AS T
                INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = T.[StockItemId]
                LEFT JOIN [INE].[Lots] AS LO ON LO.[LotID] = T.[LotId]
                LEFT JOIN [INE].[StockBalances] AS SB
                    ON SB.[LocationId] = @FromLocationId AND SB.[StockItemId] = T.[StockItemId]
                   AND ((SB.[LotId] = T.[LotId]) OR (SB.[LotId] IS NULL AND T.[LotId] IS NULL))
                WHERE ISNULL(SB.[QuantityOnHand], 0) - ISNULL(SB.[QuantityAllocated], 0)
                      + CASE WHEN @IsReversal = 0 THEN T.[AllocatedQuantity] ELSE 0 END < T.[Quantity];
                THROW 50000, @Msg, 1;
            END;

            UPDATE SB SET
                SB.[QuantityOnHand] = SB.[QuantityOnHand] - T.[Quantity]
                , SB.[QuantityAllocated] = SB.[QuantityAllocated] - CASE WHEN @IsReversal = 0 THEN T.[AllocatedQuantity] ELSE 0 END
                , SB.[LastMovementId] = @MovementId
                , SB.[ModifiedDate] = SYSDATETIMEOFFSET()
            FROM [INE].[StockBalances] AS SB
            INNER JOIN @Totals AS T
                ON SB.[LocationId] = @FromLocationId AND SB.[StockItemId] = T.[StockItemId]
               AND ((SB.[LotId] = T.[LotId]) OR (SB.[LotId] IS NULL AND T.[LotId] IS NULL));
        END;

        /** TO: put stock in */
        IF @ToLocationId IS NOT NULL
        BEGIN
            UPDATE SB SET
                SB.[QuantityOnHand] = SB.[QuantityOnHand] + T.[Quantity]
                -- A reversed issue puts the stock back under its allocation.
                , SB.[QuantityAllocated] = SB.[QuantityAllocated] + CASE WHEN @IsReversal = 1 THEN T.[AllocatedQuantity] ELSE 0 END
                , SB.[LastMovementId] = @MovementId
                , SB.[ModifiedDate] = SYSDATETIMEOFFSET()
            FROM [INE].[StockBalances] AS SB WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN @Totals AS T
                ON SB.[LocationId] = @ToLocationId AND SB.[StockItemId] = T.[StockItemId]
               AND ((SB.[LotId] = T.[LotId]) OR (SB.[LotId] IS NULL AND T.[LotId] IS NULL));

            INSERT INTO [INE].[StockBalances]
                ([DealerTenantId], [LocationId], [StockItemId], [LotId], [QuantityOnHand], [QuantityAllocated], [LastMovementId])
            SELECT @TenantId, @ToLocationId, T.[StockItemId], T.[LotId], T.[Quantity],
                   CASE WHEN @IsReversal = 1 THEN T.[AllocatedQuantity] ELSE 0 END, @MovementId
            FROM @Totals AS T
            WHERE NOT EXISTS (SELECT 1 FROM [INE].[StockBalances] AS SB
                              WHERE SB.[LocationId] = @ToLocationId AND SB.[StockItemId] = T.[StockItemId]
                                AND ((SB.[LotId] = T.[LotId]) OR (SB.[LotId] IS NULL AND T.[LotId] IS NULL)));
        END;

        /** SERIAL UNITS: where each unit is now */
        UPDATE SU SET
            SU.[CurrentLocationId] = @ToLocationId
            , SU.[Status] = CASE
                WHEN @ToLocationId IS NULL AND @TypeCode = ''Scrap'' THEN ''Scrapped''
                WHEN @ToLocationId IS NULL AND @TypeCode = ''Reversal'' THEN ''Voided''
                WHEN @ToLocationId IS NULL THEN ''Missing''
                WHEN @ToTypeCode = ''Job'' THEN ''Installed''
                WHEN @ToTypeCode = ''Vendor'' THEN ''Returned''
                ELSE ''InStock'' END
            , SU.[ModifiedDate] = SYSDATETIMEOFFSET()
            , SU.[ModifiedById] = @UserId
        FROM [INE].[SerialUnits] AS SU
        INNER JOIN @Lines AS LN ON LN.[SerialUnitId] = SU.[SerialUnitID];

        /** PURCHASE ORDERS */
        IF EXISTS (SELECT 1 FROM @Lines WHERE [PurchaseOrderLineId] IS NOT NULL)
        BEGIN
            UPDATE POL SET
                POL.[QuantityReceived] = POL.[QuantityReceived] + CASE WHEN @IsReversal = 1 THEN -Q.[Qty] ELSE Q.[Qty] END
                , POL.[ModifiedDate] = SYSDATETIMEOFFSET()
                , POL.[ModifiedById] = @UserId
            FROM [INE].[PurchaseOrderLines] AS POL
            INNER JOIN (SELECT [PurchaseOrderLineId], SUM([Quantity]) AS [Qty] FROM @Lines
                        WHERE [PurchaseOrderLineId] IS NOT NULL GROUP BY [PurchaseOrderLineId]) AS Q
                ON Q.[PurchaseOrderLineId] = POL.[PurchaseOrderLineID];

            -- Re-derive the receiving status of every PO touched (Closed stays Closed).
            UPDATE PO SET
                PO.[Status] = CASE
                    WHEN S.[Outstanding] = 0 THEN ''Received''
                    WHEN S.[Received] > 0 THEN ''PartiallyReceived''
                    ELSE ''Submitted'' END
                , PO.[ModifiedDate] = SYSDATETIMEOFFSET()
                , PO.[ModifiedById] = @UserId
            FROM [INE].[PurchaseOrders] AS PO
            INNER JOIN (SELECT POL.[PurchaseOrderId]
                               , SUM(POL.[QuantityReceived]) AS [Received]
                               , SUM(POL.[QuantityOrdered] - POL.[QuantityReceived]) AS [Outstanding]
                        FROM [INE].[PurchaseOrderLines] AS POL
                        WHERE POL.[IsDeleted] = 0
                          AND POL.[PurchaseOrderId] IN (SELECT P2.[PurchaseOrderId] FROM [INE].[PurchaseOrderLines] AS P2
                                                        INNER JOIN @Lines AS LN ON LN.[PurchaseOrderLineId] = P2.[PurchaseOrderLineID])
                        GROUP BY POL.[PurchaseOrderId]) AS S
                ON S.[PurchaseOrderId] = PO.[PurchaseOrderID]
            WHERE PO.[Status] IN (''Submitted'', ''PartiallyReceived'', ''Received'');
        END;

        /** ALLOCATIONS */
        IF EXISTS (SELECT 1 FROM @Lines WHERE [AllocationId] IS NOT NULL)
        BEGIN
            UPDATE A SET
                A.[QuantityIssued] = A.[QuantityIssued] + CASE WHEN @IsReversal = 1 THEN -Q.[Qty] ELSE Q.[Qty] END
                -- A Cancelled allocation stays Cancelled when an issue against it is reversed.
                , A.[Status] = CASE WHEN A.[Status] = ''Cancelled'' THEN ''Cancelled''
                                    WHEN A.[QuantityIssued] + CASE WHEN @IsReversal = 1 THEN -Q.[Qty] ELSE Q.[Qty] END
                                         >= A.[QuantityAllocated] THEN ''Fulfilled'' ELSE ''Open'' END
                , A.[ModifiedDate] = SYSDATETIMEOFFSET()
                , A.[ModifiedById] = @UserId
            FROM [INE].[Allocations] AS A
            INNER JOIN (SELECT [AllocationId], SUM([Quantity]) AS [Qty] FROM @Lines
                        WHERE [AllocationId] IS NOT NULL GROUP BY [AllocationId]) AS Q
                ON Q.[AllocationId] = A.[AllocationID];
        END;

        IF @OwnsTransaction = 1
            COMMIT TRANSACTION;

        IF @ReturnResult = 1
            SELECT @MovementId AS [MovementID];
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @OwnsTransaction = 1 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
';

    -- INE.spAllocationCreate: 04190 (Procedures/INE/spAllocationCreate.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spAllocationCreate]
(
    @LeadId BIGINT,
    @LocationId INT,
    @StockItemId INT,
    @Quantity DECIMAL(19, 4),
    @LotId INT = NULL,
    @NeededByDate DATE = NULL,
    @Notes NVARCHAR(500) = NULL,
    @AllocationId BIGINT = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @TenantId INT, @UserId UNIQUEIDENTIFIER, @Msg NVARCHAR(2048);
        SELECT @TenantId = SC.[DealerTenantId], @UserId = SC.[UserId] FROM [INE].[fxGetSessionContext]() AS SC;
        IF @TenantId IS NULL
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;
        SET @UserId = ISNULL(@UserId, ''E6872B58-52B2-415C-A32B-45805F95A70A'');

        IF @Quantity IS NULL OR @Quantity <= 0
            THROW 50000, N''04150|:|The quantity must be greater than zero.'', 1;
        IF NOT EXISTS (SELECT 1 FROM [QAL].[Leads] WHERE [LeadID] = @LeadId AND [DealerTenantId] = @TenantId)
            THROW 50000, N''04108|:|The lead was not found.'', 1;
        IF NOT EXISTS (SELECT 1 FROM [INE].[Locations] AS L
                       INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
                       WHERE L.[LocationID] = @LocationId AND L.[DealerTenantId] = @TenantId
                         AND L.[IsActive] = 1 AND L.[IsDeleted] = 0 AND LT.[IsStockHolding] = 1)
            THROW 50000, N''04151|:|Stock can only be allocated at an active warehouse, vehicle or staging location.'', 1;

        DECLARE @TrackingMode VARCHAR(10);
        SELECT @TrackingMode = [TrackingMode] FROM [INE].[StockItems]
        WHERE [StockItemID] = @StockItemId AND [DealerTenantId] = @TenantId AND [IsActive] = 1 AND [IsDeleted] = 0;
        IF @TrackingMode IS NULL
            THROW 50000, N''04112|:|The stock item was not found or is inactive.'', 1;
        IF EXISTS (SELECT 1 FROM [INE].[StockItems]
                   WHERE [ParentStockItemId] = @StockItemId AND [IsActive] = 1 AND [IsDeleted] = 0)
            THROW 50000, N''04190|:|The stock item has variants; stock is kept on its variants. Allocate a variant.'', 1;
        IF @TrackingMode = ''Quantity'' AND @LotId IS NOT NULL
            THROW 50000, N''04114|:|Quantity-tracked items do not have lots.'', 1;
        IF @LotId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [INE].[Lots] WHERE [LotID] = @LotId AND [StockItemId] = @StockItemId)
            THROW 50000, N''04115|:|The lot does not belong to the stock item.'', 1;
        IF @TrackingMode = ''Serial'' AND @Quantity <> ROUND(@Quantity, 0)
            THROW 50000, N''04150|:|Serial-tracked items are allocated in whole units.'', 1;

        BEGIN TRANSACTION;

        -- Without a lot, availability is across all lots of the item at the location; the
        -- reservation then sits on the lot-less balance row only when one exists.
        DECLARE @Available DECIMAL(19, 4);
        SELECT @Available = ISNULL(SUM(SB.[QuantityOnHand] - SB.[QuantityAllocated]), 0)
        FROM [INE].[StockBalances] AS SB WITH (UPDLOCK, HOLDLOCK)
        WHERE SB.[LocationId] = @LocationId AND SB.[StockItemId] = @StockItemId
          AND ((@LotId IS NULL AND SB.[LotId] IS NULL) OR SB.[LotId] = @LotId);

        IF @Available < @Quantity
        BEGIN
            SET @Msg = CONCAT(N''04122|:|Only '', CAST(@Available AS DECIMAL(19, 2)), N'' available at the location; '',
                              CAST(@Quantity AS DECIMAL(19, 2)), N'' requested.'',
                              CASE WHEN @TrackingMode = ''Lot'' AND @LotId IS NULL THEN N'' Lot-tracked items are allocated by lot.'' ELSE N'''' END);
            THROW 50000, @Msg, 1;
        END;

        INSERT INTO [INE].[Allocations]
            ([DealerTenantId], [LeadId], [StockItemId], [LocationId], [LotId], [QuantityAllocated], [NeededByDate], [Notes], [ModifiedById], [CreatedById])
        VALUES
            (@TenantId, @LeadId, @StockItemId, @LocationId, @LotId, @Quantity, @NeededByDate, @Notes, @UserId, @UserId);
        SET @AllocationId = SCOPE_IDENTITY();

        UPDATE [INE].[StockBalances] SET
            [QuantityAllocated] = [QuantityAllocated] + @Quantity
            , [ModifiedDate] = SYSDATETIMEOFFSET()
        WHERE [LocationId] = @LocationId AND [StockItemId] = @StockItemId
          AND (([LotId] IS NULL AND @LotId IS NULL) OR [LotId] = @LotId);

        COMMIT TRANSACTION;

        SELECT @AllocationId AS [AllocationID];
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
';

    -- INE.spStockCountPost: 04190 (Procedures/INE/spStockCountPost.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE [INE].[spStockCountPost]
(
    @StockCountId BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @TenantId INT, @UserId UNIQUEIDENTIFIER, @Msg NVARCHAR(2048);
        SELECT @TenantId = SC.[DealerTenantId], @UserId = SC.[UserId] FROM [INE].[fxGetSessionContext]() AS SC;
        IF @TenantId IS NULL
            THROW 50000, N''04100|:|No dealer tenant in the session context. Call ACC.spSessionContextCreate first.'', 1;
        SET @UserId = ISNULL(@UserId, ''E6872B58-52B2-415C-A32B-45805F95A70A'');

        BEGIN TRANSACTION;

        DECLARE @LocationId INT;
        SELECT @LocationId = SC.[LocationId]
        FROM [INE].[StockCounts] AS SC WITH (UPDLOCK, HOLDLOCK)
        WHERE SC.[StockCountID] = @StockCountId AND SC.[DealerTenantId] = @TenantId AND SC.[Status] = ''Open'';
        IF @LocationId IS NULL
            THROW 50000, N''04160|:|The stock count was not found or is not open.'', 1;

        -- Stock lives on variants only (the line trigger checks this too; lines may predate the variants).
        IF EXISTS (SELECT 1 FROM [INE].[StockCountLines] AS CL
                   WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0
                     AND EXISTS (SELECT 1 FROM [INE].[StockItems] AS C
                                 WHERE C.[ParentStockItemId] = CL.[StockItemId] AND C.[IsActive] = 1 AND C.[IsDeleted] = 0))
            THROW 50000, N''04190|:|A count line names a stock item that has variants; count its variants instead.'', 1;

        IF EXISTS (SELECT 1 FROM [INE].[StockCountLines] AS CL
                   INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = CL.[StockItemId]
                   WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0
                     AND ((SI.[TrackingMode] = ''Serial'' AND CL.[SerialUnitId] IS NULL)
                       OR (SI.[TrackingMode] <> ''Serial'' AND CL.[SerialUnitId] IS NOT NULL)))
            THROW 50000, N''04161|:|Serial items are counted one line per serial unit, and only serial items name a unit.'', 1;

        IF EXISTS (SELECT 1 FROM [INE].[StockCountLines] AS CL
                   INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = CL.[SerialUnitId]
                   WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0 AND CL.[CountedQuantity] = 1
                     AND SU.[CurrentLocationId] IS NOT NULL AND SU.[CurrentLocationId] <> @LocationId)
        BEGIN
            SELECT TOP (1) @Msg = CONCAT(N''04162|:|Serial number "'', SU.[SerialNumber], N''" was found here but the books have it at location '',
                                         SU.[CurrentLocationId], N''. Post a transfer for it, then post the count.'')
            FROM [INE].[StockCountLines] AS CL
            INNER JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = CL.[SerialUnitId]
            WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0 AND CL.[CountedQuantity] = 1
              AND SU.[CurrentLocationId] IS NOT NULL AND SU.[CurrentLocationId] <> @LocationId;
            THROW 50000, @Msg, 1;
        END;

        -- Expected quantity: the balance for non-serial lines, 1/0 (here or not) for serial lines.
        UPDATE CL SET
            CL.[ExpectedQuantity] = CASE
                WHEN CL.[SerialUnitId] IS NOT NULL THEN CASE WHEN SU.[CurrentLocationId] = @LocationId THEN 1 ELSE 0 END
                ELSE ISNULL(SB.[QuantityOnHand], 0) END
            , CL.[ModifiedDate] = SYSDATETIMEOFFSET()
            , CL.[ModifiedById] = @UserId
        FROM [INE].[StockCountLines] AS CL
        LEFT JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = CL.[SerialUnitId]
        LEFT JOIN [INE].[StockBalances] AS SB WITH (UPDLOCK, HOLDLOCK)
            ON CL.[SerialUnitId] IS NULL AND SB.[LocationId] = @LocationId AND SB.[StockItemId] = CL.[StockItemId]
           AND ((SB.[LotId] = CL.[LotId]) OR (SB.[LotId] IS NULL AND CL.[LotId] IS NULL))
        WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0;

        -- Non-serial lines for the same item and lot are summed (two people counted two shelves).
        DECLARE @Diffs TABLE ([StockItemId] INT NOT NULL, [LotId] INT NULL, [SerialUnitId] BIGINT NULL, [Diff] DECIMAL(19, 4) NOT NULL);
        INSERT INTO @Diffs ([StockItemId], [LotId], [SerialUnitId], [Diff])
        SELECT CL.[StockItemId], CL.[LotId], NULL, SUM(CL.[CountedQuantity]) - MAX(CL.[ExpectedQuantity])
        FROM [INE].[StockCountLines] AS CL
        WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0 AND CL.[SerialUnitId] IS NULL
        GROUP BY CL.[StockItemId], CL.[LotId]
        UNION ALL
        SELECT CL.[StockItemId], NULL, CL.[SerialUnitId], CL.[CountedQuantity] - CL.[ExpectedQuantity]
        FROM [INE].[StockCountLines] AS CL
        WHERE CL.[StockCountId] = @StockCountId AND CL.[IsDeleted] = 0 AND CL.[SerialUnitId] IS NOT NULL;

        DECLARE @Results TABLE ([MovementID] BIGINT NOT NULL, [MovementType] VARCHAR(20) NOT NULL);
        DECLARE @Json NVARCHAR(MAX), @NewId BIGINT, @Rc INT;

        IF EXISTS (SELECT 1 FROM @Diffs WHERE [Diff] > 0)
        BEGIN
            SET @Json = (SELECT ''AdjustIn'' AS [movementType], @LocationId AS [toLocationId], @StockCountId AS [stockCountId],
                                CONCAT(N''Stock count '', @StockCountId) AS [reference],
                                (SELECT D.[StockItemId] AS [stockItemId], D.[LotId] AS [lotId], D.[SerialUnitId] AS [serialUnitId],
                                        D.[Diff] AS [quantity]
                                 FROM @Diffs AS D WHERE D.[Diff] > 0 FOR JSON PATH) AS [lines]
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
            EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @NewId OUTPUT, @ReturnResult = 0;
            IF @Rc <> 0 THROW 50000, N''04163|:|The count overages could not be posted.'', 1;
            INSERT INTO @Results VALUES (@NewId, ''AdjustIn'');
        END;

        IF EXISTS (SELECT 1 FROM @Diffs WHERE [Diff] < 0)
        BEGIN
            SET @NewId = NULL;
            SET @Json = (SELECT ''AdjustOut'' AS [movementType], @LocationId AS [fromLocationId], @StockCountId AS [stockCountId],
                                CONCAT(N''Stock count '', @StockCountId) AS [reference],
                                (SELECT D.[StockItemId] AS [stockItemId], D.[LotId] AS [lotId], D.[SerialUnitId] AS [serialUnitId],
                                        -D.[Diff] AS [quantity]
                                 FROM @Diffs AS D WHERE D.[Diff] < 0 FOR JSON PATH) AS [lines]
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
            EXEC @Rc = [INE].[spMovementPost] @MovementJson = @Json, @MovementId = @NewId OUTPUT, @ReturnResult = 0;
            IF @Rc <> 0 THROW 50000, N''04163|:|The count shortages could not be posted (release allocations on short items first).'', 1;
            INSERT INTO @Results VALUES (@NewId, ''AdjustOut'');
        END;

        UPDATE [INE].[StockCounts] SET
            [Status] = ''Posted''
            , [PostedDate] = SYSDATETIMEOFFSET()
            , [ModifiedDate] = SYSDATETIMEOFFSET()
            , [ModifiedById] = @UserId
        WHERE [StockCountID] = @StockCountId;

        COMMIT TRANSACTION;

        SELECT [MovementID], [MovementType] FROM @Results;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        -- A nested INE procedure already formatted this error; pass it on unchanged so the
        -- API still sees ERROR_MESSAGE starting with the 041xx code.
        IF ERROR_MESSAGE() LIKE N''{"ERROR_NUMBER":%''
            THROW;
        EXEC [GEN].[spExceptionsThrown];
        RETURN -1;
    END CATCH;
END;
';

    -- INE.vwStockOnHand: ParentStockItemId, VariantName (Views/INE/vwStockOnHand.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER VIEW [INE].[vwStockOnHand]
AS
    SELECT
        SB.[DealerTenantId]
        , SB.[LocationId]
        , L.[Code] AS [LocationCode]
        , L.[Name] AS [LocationName]
        , LT.[Code] AS [LocationType]
        , LT.[IsStockHolding]
        , L.[LeadId]
        , SB.[StockItemId]
        , SI.[Sku]
        , SI.[Name] AS [StockItemName]
        , SI.[ParentStockItemId]
        , SI.[VariantName]
        , SI.[TrackingMode]
        , SI.[UnitOfMeasure]
        , SB.[LotId]
        , LO.[LotNumber]
        , SB.[QuantityOnHand]
        , SB.[QuantityAllocated]
        , SB.[QuantityOnHand] - SB.[QuantityAllocated] AS [QuantityAvailable]
        , SB.[QuantityOnHand] * SI.[StandardCost] AS [ExtendedStandardCost]
        , SB.[LastMovementId]
        , SB.[ModifiedDate] AS [LastChangedDate]
    FROM [INE].[StockBalances] AS SB
    INNER JOIN [INE].[Locations] AS L ON L.[LocationID] = SB.[LocationId]
    INNER JOIN [INE].[LocationTypes] AS LT ON LT.[LocationTypeID] = L.[LocationTypeId]
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = SB.[StockItemId]
    LEFT JOIN [INE].[Lots] AS LO ON LO.[LotID] = SB.[LotId]
    WHERE SB.[QuantityOnHand] <> 0 OR SB.[QuantityAllocated] <> 0;
';

    -- INE.vwReorderSuggestions: ParentStockItemId, VariantName (Views/INE/vwReorderSuggestions.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER VIEW [INE].[vwReorderSuggestions]
AS
    WITH [Available] AS
    (
        SELECT SB.[LocationId], SB.[StockItemId], SUM(SB.[QuantityOnHand] - SB.[QuantityAllocated]) AS [Quantity]
        FROM [INE].[StockBalances] AS SB
        GROUP BY SB.[LocationId], SB.[StockItemId]
    ),
    [OnOrder] AS
    (
        SELECT PO.[ShipToLocationId] AS [LocationId], POL.[StockItemId], SUM(POL.[QuantityOrdered] - POL.[QuantityReceived]) AS [Quantity]
        FROM [INE].[PurchaseOrders] AS PO
        INNER JOIN [INE].[PurchaseOrderLines] AS POL ON POL.[PurchaseOrderId] = PO.[PurchaseOrderID]
        WHERE PO.[Status] IN (''Draft'', ''Submitted'', ''PartiallyReceived'') AND PO.[IsDeleted] = 0 AND POL.[IsDeleted] = 0
        GROUP BY PO.[ShipToLocationId], POL.[StockItemId]
    )
    SELECT
        SL.[DealerTenantId]
        , SL.[StockLevelID]
        , SL.[LocationId]
        , L.[Code] AS [LocationCode]
        , L.[Name] AS [LocationName]
        , SL.[StockItemId]
        , SI.[Sku]
        , SI.[Name] AS [StockItemName]
        , SI.[ParentStockItemId]
        , SI.[VariantName]
        , SI.[UnitOfMeasure]
        , SI.[DefaultVendorId]
        , V.[Name] AS [DefaultVendorName]
        , SL.[ReorderPoint]
        , SL.[MaximumQuantity]
        , ISNULL(A.[Quantity], 0) AS [QuantityAvailable]
        , ISNULL(O.[Quantity], 0) AS [QuantityOnOrder]
        , CAST(CASE WHEN ISNULL(A.[Quantity], 0) + ISNULL(O.[Quantity], 0) <= SL.[ReorderPoint] THEN 1 ELSE 0 END AS BIT) AS [NeedsReorder]
        , CASE WHEN ISNULL(A.[Quantity], 0) + ISNULL(O.[Quantity], 0) <= SL.[ReorderPoint]
               THEN SL.[MaximumQuantity] - ISNULL(A.[Quantity], 0) - ISNULL(O.[Quantity], 0) ELSE 0 END AS [SuggestedOrderQuantity]
    FROM [INE].[StockLevels] AS SL
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = SL.[StockItemId]
    INNER JOIN [INE].[Locations] AS L ON L.[LocationID] = SL.[LocationId]
    LEFT JOIN [INE].[Vendors] AS V ON V.[VendorID] = SI.[DefaultVendorId]
    LEFT JOIN [Available] AS A ON A.[LocationId] = SL.[LocationId] AND A.[StockItemId] = SL.[StockItemId]
    LEFT JOIN [OnOrder] AS O ON O.[LocationId] = SL.[LocationId] AND O.[StockItemId] = SL.[StockItemId]
    WHERE SL.[IsActive] = 1 AND SL.[IsDeleted] = 0 AND SI.[IsActive] = 1 AND SI.[IsDeleted] = 0;
';

    -- INE.vwMovementHistory: ParentStockItemId, VariantName (Views/INE/vwMovementHistory.sql)
    EXEC sys.sp_executesql N'CREATE OR ALTER VIEW [INE].[vwMovementHistory]
AS
    SELECT
        M.[DealerTenantId]
        , M.[MovementID]
        , ML.[MovementLineID]
        , M.[MovementDate]
        , MT.[Code] AS [MovementType]
        , M.[FromLocationId]
        , FL.[Code] AS [FromLocationCode]
        , M.[ToLocationId]
        , TL.[Code] AS [ToLocationCode]
        , M.[LeadId]
        , M.[ReceiptId]
        , M.[StockCountId]
        , M.[ReversesMovementId]
        , CAST(CASE WHEN EXISTS (SELECT 1 FROM [INE].[Movements] AS R WHERE R.[ReversesMovementId] = M.[MovementID])
                    THEN 1 ELSE 0 END AS BIT) AS [IsReversed]
        , ML.[StockItemId]
        , SI.[Sku]
        , SI.[ParentStockItemId]
        , SI.[VariantName]
        , SI.[UnitOfMeasure]
        , ML.[LotId]
        , LO.[LotNumber]
        , ML.[SerialUnitId]
        , SU.[SerialNumber]
        , ML.[Quantity]
        , ML.[UnitCost]
        , ML.[PurchaseOrderLineId]
        , ML.[AllocationId]
        , M.[Reference]
        , M.[Notes]
        , M.[CreatedById]
        , M.[CreatedDate]
    FROM [INE].[Movements] AS M
    INNER JOIN [INE].[MovementTypes] AS MT ON MT.[MovementTypeID] = M.[MovementTypeId]
    INNER JOIN [INE].[MovementLines] AS ML ON ML.[MovementId] = M.[MovementID]
    INNER JOIN [INE].[StockItems] AS SI ON SI.[StockItemID] = ML.[StockItemId]
    LEFT JOIN [INE].[Locations] AS FL ON FL.[LocationID] = M.[FromLocationId]
    LEFT JOIN [INE].[Locations] AS TL ON TL.[LocationID] = M.[ToLocationId]
    LEFT JOIN [INE].[Lots] AS LO ON LO.[LotID] = ML.[LotId]
    LEFT JOIN [INE].[SerialUnits] AS SU ON SU.[SerialUnitID] = ML.[SerialUnitId];
';

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Part variants: INE.StockItems parent/variant columns and price adder, INE.StockItemVariantAttributes, variant guards, MAC.QuoteLines variant snapshot',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success])
    VALUES (N'20261120_0100_AddINE_PartVariants', N'FAILED: ' + LEFT(@ErrorMessage, 490), 0);

    PRINT 'Migration failed: ' + @ErrorMessage;
    THROW;
END CATCH;
GO
