/*******************************************************************************
 * Object Type: Seed Data
 * Schema: DOC
 * Name: DocumentTypes
 * Description: Seeds one General Document type (DOCT); preserves existing rows.
 * Dependencies: DOC.DocumentTypes
 * Author: Database Team
 * Created: 2026-10-24
 ******************************************************************************/

SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
-- A deployed prefix is immutable: fail rather than silently reassigning it.
IF EXISTS (SELECT 1 FROM [DOC].[DocumentTypes]
           WHERE ([DocumentTypeID] = 1 AND [Prefix] <> 'DOCT')
              OR ([Prefix] = 'DOCT' AND [DocumentTypeID] <> 1))
    THROW 50001, 'Document type 1 must use the registered DOCT prefix.', 1;

SET IDENTITY_INSERT [DOC].[DocumentTypes] ON;
BEGIN TRY
    MERGE INTO [DOC].[DocumentTypes] AS target
    USING (VALUES (1, 'DOCT', N'General Document',
        N'General-purpose document, including signed contracts and engineering files such as DXF.'))
        AS source ([DocumentTypeID], [Prefix], [DocumentTypeName], [DocumentTypeDescription])
    ON target.[DocumentTypeID] = source.[DocumentTypeID]
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([DocumentTypeID], [Prefix], [DocumentTypeName], [DocumentTypeDescription],
                [ModifiedById], [CreatedById])
        VALUES (source.[DocumentTypeID], source.[Prefix], source.[DocumentTypeName],
                source.[DocumentTypeDescription],
                'E6872B58-52B2-415C-A32B-45805F95A70A', 'E6872B58-52B2-415C-A32B-45805F95A70A');
    SET IDENTITY_INSERT [DOC].[DocumentTypes] OFF;
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT [DOC].[DocumentTypes] OFF;
    THROW;
END CATCH;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

