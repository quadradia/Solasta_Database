/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: trgAutoGen_StockLevels_CUD
 * Description: Audits inserts and updates of INE.StockLevels into AUD.AuditActions and
 *              AUD.AuditActionColumns, like the trgAutoGen_*_CUD triggers on QAL and ACE
 *              (one action per row: INSERT, UPDATE, DELETE when IsDeleted turns 1,
 *              UNDELETE when it turns 0; one column row per changed value). Unlike those,
 *              it also records a value changed to NULL or only in letter case, and it
 *              takes the user from the API's session context (INE.fxGetSessionContext),
 *              falling back to CONTEXT_INFO.
 *              Rows are soft-deleted, so physical deletes are not audited.
 * Dependencies: INE.fxGetSessionContext, ACC.fxGetContextUserTable, AUD.AuditActions,
 *               AUD.AuditActionColumns
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER [INE].[trgAutoGen_StockLevels_CUD]
ON [INE].[StockLevels]
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
    SELECT I.[StockLevelID], CASE WHEN D.[StockLevelID] IS NULL THEN 1 ELSE 0 END, V.[ColumnName], V.[OldValue], V.[NewValue]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[StockLevelID] = I.[StockLevelID]
    CROSS APPLY (VALUES
            (N'StockLevelID', CAST(D.[StockLevelID] AS NVARCHAR(500)), CAST(I.[StockLevelID] AS NVARCHAR(500))),
            (N'DealerTenantId', CAST(D.[DealerTenantId] AS NVARCHAR(500)), CAST(I.[DealerTenantId] AS NVARCHAR(500))),
            (N'StockItemId', CAST(D.[StockItemId] AS NVARCHAR(500)), CAST(I.[StockItemId] AS NVARCHAR(500))),
            (N'LocationId', CAST(D.[LocationId] AS NVARCHAR(500)), CAST(I.[LocationId] AS NVARCHAR(500))),
            (N'ReorderPoint', CAST(D.[ReorderPoint] AS NVARCHAR(500)), CAST(I.[ReorderPoint] AS NVARCHAR(500))),
            (N'MaximumQuantity', CAST(D.[MaximumQuantity] AS NVARCHAR(500)), CAST(I.[MaximumQuantity] AS NVARCHAR(500))),
            (N'IsActive', CAST(D.[IsActive] AS NVARCHAR(500)), CAST(I.[IsActive] AS NVARCHAR(500))),
            (N'IsDeleted', CAST(D.[IsDeleted] AS NVARCHAR(500)), CAST(I.[IsDeleted] AS NVARCHAR(500)))
    ) AS V ([ColumnName], [OldValue], [NewValue])
    WHERE (D.[StockLevelID] IS NULL AND V.[NewValue] IS NOT NULL)
       OR (D.[StockLevelID] IS NOT NULL
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
            WHEN MAX(CAST(C.[IsInsert] AS INT)) = 1 THEN 'INSERT'
            WHEN MAX(CASE WHEN C.[ColumnName] = N'IsDeleted' AND C.[NewValue] = N'1' THEN 1 ELSE 0 END) = 1 THEN 'DELETE'
            WHEN MAX(CASE WHEN C.[ColumnName] = N'IsDeleted' AND C.[NewValue] = N'0' THEN 1 ELSE 0 END) = 1 THEN 'UNDELETE'
            ELSE 'UPDATE'
        END
        , 'INE'
        , 'StockLevels'
        , CAST(C.[PKID] AS VARCHAR(50))
        , @UserID
    FROM @Changes AS C
    GROUP BY C.[PKID];

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT A.[AuditActionID], C.[ColumnName], C.[OldValue], C.[NewValue]
    FROM @Changes AS C
    INNER JOIN @Actions AS A ON A.[PKID] = CAST(C.[PKID] AS VARCHAR(50));
END;
GO
