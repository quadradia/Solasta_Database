/*******************************************************************************
 * Object Type: Seed Data
 * Schema: AFL
 * Name: AffiliateApplicationTypes
 * Description: Seeds the Website Application type (AFAW); preserves existing rows.
 * Dependencies: AFL.AffiliateApplicationTypes
 * Author: Andres Sosa
 * Created: 2026-11-03
 ******************************************************************************/

SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
-- A deployed prefix is immutable: fail rather than silently reassigning it.
IF EXISTS (SELECT 1 FROM [AFL].[AffiliateApplicationTypes]
           WHERE ([AffiliateApplicationTypeID] = 1 AND [Prefix] <> 'AFAW')
              OR ([Prefix] = 'AFAW' AND [AffiliateApplicationTypeID] <> 1))
    THROW 50001, 'Affiliate application type 1 must use the registered AFAW prefix.', 1;

SET IDENTITY_INSERT [AFL].[AffiliateApplicationTypes] ON;
BEGIN TRY
    MERGE INTO [AFL].[AffiliateApplicationTypes] AS target
    USING (VALUES (1, 'AFAW', N'Website Application', N'Submitted through the public affiliate signup form.'))
        AS source ([AffiliateApplicationTypeID], [Prefix], [AffiliateApplicationTypeName], [AffiliateApplicationTypeDescription])
    ON target.[AffiliateApplicationTypeID] = source.[AffiliateApplicationTypeID]
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([AffiliateApplicationTypeID], [Prefix], [AffiliateApplicationTypeName], [AffiliateApplicationTypeDescription],
                [ModifiedById], [CreatedById])
        VALUES (source.[AffiliateApplicationTypeID], source.[Prefix], source.[AffiliateApplicationTypeName],
                source.[AffiliateApplicationTypeDescription],
                'E6872B58-52B2-415C-A32B-45805F95A70A', 'E6872B58-52B2-415C-A32B-45805F95A70A');
    SET IDENTITY_INSERT [AFL].[AffiliateApplicationTypes] OFF;
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT [AFL].[AffiliateApplicationTypes] OFF;
    THROW;
END CATCH;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
