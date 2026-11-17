/*******************************************************************************
 * Object Type: Trigger
 * Schema: INE
 * Name: trgAutoGen_Locations_CUD
 * Description: Audits inserts and updates of INE.Locations into AUD.AuditActions and
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

CREATE OR ALTER TRIGGER [INE].[trgAutoGen_Locations_CUD]
ON [INE].[Locations]
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
    SELECT I.[LocationID], CASE WHEN D.[LocationID] IS NULL THEN 1 ELSE 0 END, V.[ColumnName], V.[OldValue], V.[NewValue]
    FROM inserted AS I
    LEFT JOIN deleted AS D ON D.[LocationID] = I.[LocationID]
    CROSS APPLY (VALUES
            (N'LocationID', CAST(D.[LocationID] AS NVARCHAR(500)), CAST(I.[LocationID] AS NVARCHAR(500))),
            (N'DealerTenantId', CAST(D.[DealerTenantId] AS NVARCHAR(500)), CAST(I.[DealerTenantId] AS NVARCHAR(500))),
            (N'LocationTypeId', CAST(D.[LocationTypeId] AS NVARCHAR(500)), CAST(I.[LocationTypeId] AS NVARCHAR(500))),
            (N'UserId', CAST(D.[UserId] AS NVARCHAR(500)), CAST(I.[UserId] AS NVARCHAR(500))),
            (N'LeadId', CAST(D.[LeadId] AS NVARCHAR(500)), CAST(I.[LeadId] AS NVARCHAR(500))),
            (N'VendorId', CAST(D.[VendorId] AS NVARCHAR(500)), CAST(I.[VendorId] AS NVARCHAR(500))),
            (N'PoliticalStateId', CAST(D.[PoliticalStateId] AS NVARCHAR(500)), CAST(I.[PoliticalStateId] AS NVARCHAR(500))),
            (N'Code', CAST(D.[Code] AS NVARCHAR(500)), CAST(I.[Code] AS NVARCHAR(500))),
            (N'Name', CAST(D.[Name] AS NVARCHAR(500)), CAST(I.[Name] AS NVARCHAR(500))),
            (N'StreetAddress', CAST(D.[StreetAddress] AS NVARCHAR(500)), CAST(I.[StreetAddress] AS NVARCHAR(500))),
            (N'StreetAddress2', CAST(D.[StreetAddress2] AS NVARCHAR(500)), CAST(I.[StreetAddress2] AS NVARCHAR(500))),
            (N'City', CAST(D.[City] AS NVARCHAR(500)), CAST(I.[City] AS NVARCHAR(500))),
            (N'PostalCode', CAST(D.[PostalCode] AS NVARCHAR(500)), CAST(I.[PostalCode] AS NVARCHAR(500))),
            (N'Notes', CAST(D.[Notes] AS NVARCHAR(500)), CAST(I.[Notes] AS NVARCHAR(500))),
            (N'IsActive', CAST(D.[IsActive] AS NVARCHAR(500)), CAST(I.[IsActive] AS NVARCHAR(500))),
            (N'IsDeleted', CAST(D.[IsDeleted] AS NVARCHAR(500)), CAST(I.[IsDeleted] AS NVARCHAR(500)))
    ) AS V ([ColumnName], [OldValue], [NewValue])
    WHERE (D.[LocationID] IS NULL AND V.[NewValue] IS NOT NULL)
       OR (D.[LocationID] IS NOT NULL
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
        , 'Locations'
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
