/*
Migration: 20261120_2330_AddINE_LightStrandLengths
Author: Andres Sosa
Date: 2026-11-20
Description: Light strands for the light inventory report (Admin > Reports > Light inventory).
               INE.StockItems.PodsPerStrand     pods (pucks) on one strand, e.g. 40 for PLD-40
               INE.StockItems.PodSpacingInches  inches between pods, e.g. 10
             One strand is PodsPerStrand x PodSpacingInches inches long, so 4 x PLD-40 = 4 x 40 x 10 = 1,600 in
             = 133 ft 4 in. Both columns are set together or both NULL (CK_StockItems_LightStrand); an item with
             them set is a light strand. trgAutoGen_StockItems_CUD audits the new columns.
             Flags Solasta's strand SKUs in every tenant that has them:
               PLD-40  40 pods, 10 in
               PLD-4    4 pods, 10 in
               PLD-2    2 pods, 10 in
               PLD-1    1 pod,   1 in
Dependencies:
  20261120_0100_AddINE_PartVariants
Rollback:
  Re-apply trgAutoGen_StockItems_CUD from 20261120_0100_AddINE_PartVariants.
  ALTER TABLE [INE].[StockItems] DROP CONSTRAINT [CK_StockItems_LightStrand];
  ALTER TABLE [INE].[StockItems] DROP COLUMN [PodsPerStrand], [PodSpacingInches];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261120_2330_AddINE_LightStrandLengths';
Expected impact: two new nullable columns on INE.StockItems (NULL for every row), then the four PLD SKUs above get
                 their values (one audited UPDATE per row found). No other data changes.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261120_2330_AddINE_LightStrandLengths';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF COL_LENGTH(N'INE.StockItems', N'ParentStockItemId') IS NULL
        THROW 50001, 'Light strands require INE part variants (20261120_0100_AddINE_PartVariants).', 1;

    -- INE.StockItems: PodsPerStrand, PodSpacingInches
    IF COL_LENGTH(N'INE.StockItems', N'PodsPerStrand') IS NULL
    BEGIN
        ALTER TABLE [INE].[StockItems] ADD [PodsPerStrand] [int] NULL;
        PRINT 'Added [INE].[StockItems].[PodsPerStrand]';
    END;
    IF COL_LENGTH(N'INE.StockItems', N'PodSpacingInches') IS NULL
    BEGIN
        ALTER TABLE [INE].[StockItems] ADD [PodSpacingInches] [decimal](9, 3) NULL;
        PRINT 'Added [INE].[StockItems].[PodSpacingInches]';
    END;

    IF OBJECT_ID(N'INE.CK_StockItems_LightStrand', N'C') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE [INE].[StockItems] WITH CHECK ADD CONSTRAINT [CK_StockItems_LightStrand]
            CHECK (([PodsPerStrand] IS NULL AND [PodSpacingInches] IS NULL) OR ([PodsPerStrand] > 0 AND [PodSpacingInches] > 0));';

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
            (N''PodsPerStrand'', CAST(D.[PodsPerStrand] AS NVARCHAR(500)), CAST(I.[PodsPerStrand] AS NVARCHAR(500))),
            (N''PodSpacingInches'', CAST(D.[PodSpacingInches] AS NVARCHAR(500)), CAST(I.[PodSpacingInches] AS NVARCHAR(500))),
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
END;';

    -- Solasta's light strand SKUs (audited by the trigger above).
    EXEC sys.sp_executesql N'UPDATE SI
        SET SI.[PodsPerStrand] = V.[PodsPerStrand], SI.[PodSpacingInches] = V.[PodSpacingInches],
            SI.[ModifiedDate] = SYSDATETIMEOFFSET(), SI.[DEX_ROW_TS] = SYSDATETIMEOFFSET()
        FROM [INE].[StockItems] AS SI
        INNER JOIN (VALUES (N''PLD-40'', 40, 10.0), (N''PLD-4'', 4, 10.0), (N''PLD-2'', 2, 10.0), (N''PLD-1'', 1, 1.0))
            AS V ([Sku], [PodsPerStrand], [PodSpacingInches]) ON V.[Sku] = SI.[Sku]
        WHERE SI.[IsDeleted] = 0
          AND (SI.[PodsPerStrand] IS NULL OR SI.[PodsPerStrand] <> V.[PodsPerStrand]
               OR SI.[PodSpacingInches] <> V.[PodSpacingInches]);
        PRINT CONCAT(''Flagged '', @@ROWCOUNT, '' light strand stock item(s)'');';

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Light strands: INE.StockItems.PodsPerStrand and PodSpacingInches; flags PLD-40, PLD-4, PLD-2, PLD-1',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
