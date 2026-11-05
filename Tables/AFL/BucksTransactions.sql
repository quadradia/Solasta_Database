/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: BucksTransactions
 * Description: Append-only Solasta Bucks ledger (1 Buck = $1 store credit). Credits
 *              are positive and debits negative; an affiliate's balance is SUM([Amount]).
 *              Rows are never updated or deleted; corrections are new Adjustment rows.
 * Dependencies: ACC.DealerTenants, AFL.Affiliates, AFL.BucksTransactionTypes
 * Author: Andres Sosa
 * Created: 2026-11-03
 ******************************************************************************/

IF OBJECT_ID(N'AFL.BucksTransactions', N'U') IS NULL
BEGIN
    CREATE TABLE [AFL].[BucksTransactions]
    (
        [BucksTransactionID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [AffiliateId] [bigint] NOT NULL,
        [BucksTransactionTypeId] [int] NOT NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        -- Whole Bucks; 1 Buck = $1 store credit. Credits are positive, debits negative.
        [Amount] [int] NOT NULL,
        [TransactionDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactions_TransactionDate] DEFAULT (SYSDATETIMEOFFSET()),
        [Description] [nvarchar](500) NULL,
        -- Proxy of what earned or spent the Bucks (placement, lead, order), when there is one.
        [SourceProxy] [varchar](100) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_BucksTransactions_IsActive] DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_BucksTransactions_IsDeleted] DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactions_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactions_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactions_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_BucksTransactions] PRIMARY KEY CLUSTERED ([BucksTransactionID]),
        CONSTRAINT [FK_BucksTransactions_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_BucksTransactions_Affiliates] FOREIGN KEY ([AffiliateId])
            REFERENCES [AFL].[Affiliates] ([AffiliateID]),
        CONSTRAINT [FK_BucksTransactions_BucksTransactionTypes] FOREIGN KEY ([BucksTransactionTypeId])
            REFERENCES [AFL].[BucksTransactionTypes] ([BucksTransactionTypeID]),
        CONSTRAINT [UQ_BucksTransactions_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [CK_BucksTransactions_Amount] CHECK ([Amount] <> 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.BucksTransactions') AND [name] = N'IX_BucksTransactions_AffiliateId_TransactionDate')
    CREATE NONCLUSTERED INDEX [IX_BucksTransactions_AffiliateId_TransactionDate]
        ON [AFL].[BucksTransactions] ([AffiliateId], [TransactionDate] DESC) INCLUDE ([Amount]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'AFL.BucksTransactions') AND [name] = N'IX_BucksTransactions_PartKey_BucksTransactionTypeId')
    CREATE NONCLUSTERED INDEX [IX_BucksTransactions_PartKey_BucksTransactionTypeId]
        ON [AFL].[BucksTransactions] ([PartKey], [BucksTransactionTypeId]);
GO
