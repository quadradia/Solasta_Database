/*******************************************************************************
 * Object Type: Seed Data
 * Schema: AFL
 * Name: BucksTransactionTypes
 * Description: Seeds the Solasta Bucks ledger entry types (AFBP, AFBR, AFBD, AFBA);
 *              preserves existing rows.
 * Dependencies: AFL.BucksTransactionTypes
 * Author: Andres Sosa
 * Created: 2026-11-03
 ******************************************************************************/

SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
DECLARE @Seed TABLE ([Id] INT, [Prefix] VARCHAR(4), [Name] NVARCHAR(100), [Description] NVARCHAR(2000));
INSERT INTO @Seed VALUES
    (1, 'AFBP', N'Post Reward',      N'Credit for an approved social media post.'),
    (2, 'AFBR', N'Referral Reward',  N'Credit for a qualifying purchase by a referred customer.'),
    (3, 'AFBD', N'Redemption',       N'Debit when Bucks are applied to an order.'),
    (4, 'AFBA', N'Adjustment',       N'Manual staff correction; credit or debit.');

-- A deployed prefix is immutable: fail rather than silently reassigning it.
IF EXISTS (SELECT 1 FROM [AFL].[BucksTransactionTypes] AS T
           JOIN @Seed AS S ON (T.[BucksTransactionTypeID] = S.[Id] AND T.[Prefix] <> S.[Prefix])
                           OR (T.[Prefix] = S.[Prefix] AND T.[BucksTransactionTypeID] <> S.[Id]))
    THROW 50001, 'BucksTransactionTypes rows must keep their registered prefixes and IDs.', 1;

SET IDENTITY_INSERT [AFL].[BucksTransactionTypes] ON;
BEGIN TRY
    MERGE INTO [AFL].[BucksTransactionTypes] AS target
    USING @Seed AS source
    ON target.[BucksTransactionTypeID] = source.[Id]
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([BucksTransactionTypeID], [Prefix], [BucksTransactionTypeName], [BucksTransactionTypeDescription],
                [ModifiedById], [CreatedById])
        VALUES (source.[Id], source.[Prefix], source.[Name], source.[Description],
                'E6872B58-52B2-415C-A32B-45805F95A70A', 'E6872B58-52B2-415C-A32B-45805F95A70A');
    SET IDENTITY_INSERT [AFL].[BucksTransactionTypes] OFF;
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT [AFL].[BucksTransactionTypes] OFF;
    THROW;
END CATCH;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
